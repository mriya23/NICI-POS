import 'product_model.dart';

enum OrderStatus { pending, completed, cancelled }

enum PaymentMethod { cash, card, qris }

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? notes;
  final String? productImage;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.notes,
    this.productImage,
  });

  double get subtotal => price * quantity;

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? notes,
    String? productImage,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      productImage: productImage ?? this.productImage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'productImage': productImage,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      notes: map['notes'] as String?,
      productImage: map['productImage'] as String?,
    );
  }

  factory OrderItem.fromProduct(
    Product product, {
    int quantity = 1,
    String? notes,
  }) {
    return OrderItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      price: product.price,
      quantity: quantity,
      notes: notes,
      productImage: product.imageUrl,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, productName: $productName, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Order {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final OrderStatus status;
  final PaymentMethod? paymentMethod;
  final double? amountPaid;
  final double? change;
  final String? cashierId;
  final String? cashierName;
  final String? customerName;
  final String? notes;
  final bool isDineIn;
  final DateTime createdAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    this.tax = 0,
    this.discount = 0,
    required this.total,
    this.status = OrderStatus.pending,
    this.paymentMethod,
    this.amountPaid,
    this.change,
    this.cashierId,
    this.cashierName,
    this.customerName,
    this.notes,
    this.isDineIn = true,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? id,
    String? orderNumber,
    List<OrderItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    double? amountPaid,
    double? change,
    String? cashierId,
    String? cashierName,
    String? customerName,
    String? notes,
    bool? isDineIn,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountPaid: amountPaid ?? this.amountPaid,
      change: change ?? this.change,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      isDineIn: isDineIn ?? this.isDineIn,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status.toString().split('.').last,
      'paymentMethod': paymentMethod?.toString().split('.').last,
      'amountPaid': amountPaid,
      'change': change,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'customerName': customerName,
      'notes': notes,
      'isDineIn': isDineIn ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      orderNumber: map['orderNumber'] as String,
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString().split('.').last == map['paymentMethod'],
              orElse: () => PaymentMethod.cash,
            )
          : null,
      amountPaid: (map['amountPaid'] as num?)?.toDouble(),
      change: (map['change'] as num?)?.toDouble(),
      cashierId: map['cashierId'] as String?,
      cashierName: map['cashierName'] as String?,
      customerName: map['customerName'] as String?,
      notes: map['notes'] as String?,
      isDineIn: map['isDineIn'] == null
          ? true
          : (map['isDineIn'] == 1 || map['isDineIn'] == true),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, total: $total, status: ${status.toString().split('.').last})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
