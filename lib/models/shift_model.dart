class Shift {
  final int? id;
  final String userId;
  final String? cashierName; // Optional, for display purpose
  final DateTime startTime;
  final DateTime? endTime;
  final double startCash; // Modal awal di laci
  final double expectedCash; // startCash + totalCashTransactions
  final double? actualCash; // Uang fisik yang dihitung saat tutup
  final String status; // 'open' or 'closed'

  Shift({
    this.id,
    required this.userId,
    this.cashierName,
    required this.startTime,
    this.endTime,
    required this.startCash,
    this.expectedCash = 0,
    this.actualCash,
    this.status = 'open',
  });

  // Calculate difference
  double get difference => (actualCash ?? 0) - expectedCash;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_cash': startCash,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'status': status,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      userId: map['user_id'].toString(),
      cashierName: map['cashier_name'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      startCash: (map['start_cash'] as num).toDouble(),
      expectedCash: (map['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (map['actual_cash'] as num?)?.toDouble(),
      status: map['status'],
    );
  }

  Shift copyWith({
    int? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    double? startCash,
    double? expectedCash,
    double? actualCash,
    String? status,
  }) {
    return Shift(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startCash: startCash ?? this.startCash,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      status: status ?? this.status,
    );
  }
}
