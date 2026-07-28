class ShiftModel {
  final String id;
  final String userId;
  final String status;
  final double startingCash;
  final double? endingCash;
  final double? expectedCash;
  final double? cashSales;
  final double? cardSales;
  final int? orderCount;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;

  ShiftModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.startingCash,
    this.endingCash,
    this.expectedCash,
    this.cashSales,
    this.cardSales,
    this.orderCount,
    required this.startTime,
    this.endTime,
    this.notes,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      status: json['status'] ?? 'open',
      startingCash: (json['starting_cash'] as num?)?.toDouble() ?? 0.0,
      endingCash: (json['ending_cash'] as num?)?.toDouble(),
      expectedCash: (json['expected_cash'] as num?)?.toDouble(),
      cashSales: (json['cash_sales'] as num?)?.toDouble(),
      cardSales: (json['card_sales'] as num?)?.toDouble(),
      orderCount: json['order_count'] as int?,
      startTime: _parseDateTime(json['start_time']),
      endTime: json['end_time'] != null ? _parseDateTime(json['end_time']) : null,
      notes: json['notes'] as String?,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt;
    }
    if (value is DateTime) return value;
    return DateTime.now();
  }

  double get openingBalance => startingCash;
  double? get closingBalance => endingCash;
  double? get totalCashSales => cashSales;
  double? get totalCardSales => cardSales;

  double get expectedCashAmount {
    if (expectedCash != null) return expectedCash!;
    return startingCash + (cashSales ?? 0);
  }

  double? get difference {
    if (endingCash == null) return null;
    return endingCash! - expectedCashAmount;
  }
}
