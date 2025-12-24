import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/transaction_model.dart' as models;
import '../services/database_service.dart';

class OrderProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<OrderItem> _cartItems = [];
  List<Order> _orders = [];
  Order? _currentOrder;
  bool _isLoading = false;
  String? _errorMessage;
  double _taxRate = 0.0; // 0% tax rate, can be modified
  double _discount = 0.0;

  List<OrderItem> get cartItems => _cartItems;
  List<Order> get orders => _orders;
  Order? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get taxRate => _taxRate;
  double get discount => _discount;

  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  double get taxAmount => subtotal * _taxRate;

  double get total =>
      (subtotal + taxAmount - _discount).clamp(0.0, double.infinity);

  bool get isCartEmpty => _cartItems.isEmpty;

  // Cart operations
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex != -1) {
      // Update quantity if product already in cart
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item to cart
      _cartItems.add(OrderItem.fromProduct(product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateCartItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(itemId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void incrementCartItem(String itemId) {
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(
        quantity: _cartItems[index].quantity + 1,
      );
      notifyListeners();
    }
  }

  void decrementCartItem(String itemId) {
    final index = _cartItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index] = _cartItems[index].copyWith(
          quantity: _cartItems[index].quantity - 1,
        );
      } else {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems = [];
    _discount = 0;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  // Order operations
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _databaseService.getAllOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load orders: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrdersByDateRange(DateTime start, DateTime end) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _databaseService.getOrdersByDateRange(start, end);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load orders: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Order?> createOrder({
    required String cashierId,
    required String cashierName,
    String? customerName,
    String? notes,
    bool isDineIn = true,
  }) async {
    if (_cartItems.isEmpty) {
      _errorMessage = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderNumber = await _databaseService.generateOrderNumber();
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderNumber: orderNumber,
        items: List.from(_cartItems),
        subtotal: subtotal,
        tax: taxAmount,
        discount: _discount,
        total: total,
        status: OrderStatus.pending,
        cashierId: cashierId,
        cashierName: cashierName,
        customerName: customerName,
        notes: notes,
        isDineIn: isDineIn,
      );

      await _databaseService.insertOrder(order);
      _currentOrder = order;
      _orders.insert(0, order);
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _errorMessage = 'Failed to create order: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Order?> completeOrder({
    required String orderId,
    required PaymentMethod paymentMethod,
    required double amountPaid,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        _errorMessage = 'Order not found';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final order = _orders[orderIndex];
      final change = amountPaid - order.total;

      final completedOrder = order.copyWith(
        status: OrderStatus.completed,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        change: change,
        completedAt: DateTime.now(),
      );

      await _databaseService.updateOrder(completedOrder);

      // Create transaction record
      final transaction = models.Transaction.fromOrder(completedOrder);
      await _databaseService.insertTransaction(transaction);

      // Update stock for each product
      for (var item in completedOrder.items) {
        final product = await _databaseService.getProductById(item.productId);
        if (product != null) {
          final newStock = product.stock - item.quantity;
          await _databaseService.updateProductStock(item.productId, newStock);
        }
      }

      _orders[orderIndex] = completedOrder;
      _currentOrder = completedOrder;

      // Clear cart after successful order
      clearCart();

      _isLoading = false;
      notifyListeners();
      return completedOrder;
    } catch (e) {
      _errorMessage = 'Failed to complete order: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderIndex = _orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        _errorMessage = 'Order not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final order = _orders[orderIndex];
      final cancelledOrder = order.copyWith(status: OrderStatus.cancelled);

      await _databaseService.updateOrder(cancelledOrder);
      _orders[orderIndex] = cancelledOrder;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel order: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Order?> getOrderById(String id) async {
    try {
      return await _databaseService.getOrderById(id);
    } catch (e) {
      _errorMessage = 'Failed to get order: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  List<Order> getTodayOrders() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _orders.where((order) {
      return order.createdAt.isAfter(startOfDay) &&
          order.createdAt.isBefore(endOfDay);
    }).toList();
  }

  double getTodayRevenue() {
    return getTodayOrders()
        .where((order) => order.status == OrderStatus.completed)
        .fold(0, (sum, order) => sum + order.total);
  }

  void setCurrentOrder(Order? order) {
    _currentOrder = order;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
