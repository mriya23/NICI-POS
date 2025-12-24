import 'order_model.dart';

class Transaction {
  final String id;
  final String orderId;
  final String orderNumber;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? cashierId;
  final String? cashierName;
  final String? customerName;
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.paymentMethod,
    this.cashierId,
    this.cashierName,
    this.customerName,
    this.reference,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Transaction copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    double? amount,
    PaymentMethod? paymentMethod,
    String? cashierId,
    String? cashierName,
    String? customerName,
    String? reference,
    String? notes,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'amount': amount,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'customerName': customerName,
      'reference': reference,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      orderNumber: map['orderNumber'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      cashierId: map['cashierId'] as String?,
      cashierName: map['cashierName'] as String?,
      customerName: map['customerName'] as String?,
      reference: map['reference'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  factory Transaction.fromOrder(Order order) {
    return Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: order.id,
      orderNumber: order.orderNumber,
      amount: order.total,
      paymentMethod: order.paymentMethod ?? PaymentMethod.cash,
      cashierId: order.cashierId,
      cashierName: order.cashierName,
      customerName: order.customerName,
      createdAt: DateTime.now(),
    );
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  @override
  String toString() {
    return 'Transaction(id: $id, orderNumber: $orderNumber, amount: $amount, paymentMethod: ${paymentMethod.toString().split('.').last})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
