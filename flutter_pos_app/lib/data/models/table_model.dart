class CurrentOrderInfo {
  final String id;
  final String orderNumber;
  final double total;
  final String? customerName;
  final String status;

  CurrentOrderInfo({
    required this.id,
    required this.orderNumber,
    required this.total,
    this.customerName,
    required this.status,
  });

  factory CurrentOrderInfo.fromJson(Map<String, dynamic> json) {
    return CurrentOrderInfo(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      customerName: json['customerName'],
      status: json['status'] ?? '',
    );
  }
}

class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final String status;
  final String area;
  final String? currentOrderId;
  final String? currentOrderNumber;
  final String? customerName;
  final double totalAmount;
  final List<CurrentOrderInfo> currentOrders;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.area = 'صالة',
    this.currentOrderId,
    this.currentOrderNumber,
    this.customerName,
    this.totalAmount = 0,
    this.currentOrders = const [],
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    final ordersList = (json['currentOrders'] as List<dynamic>?)
            ?.map((o) => CurrentOrderInfo.fromJson(o as Map<String, dynamic>))
            .toList() ??
        [];
    return TableModel(
      id: json['id'] ?? '',
      tableNumber: json['table_number']?.toString() ?? json['name'] ?? '',
      capacity: json['capacity'] ?? 4,
      status: json['status'] ?? 'available',
      area: json['area'] ?? 'صالة',
      currentOrderId: json['currentOrderId'],
      currentOrderNumber: json['currentOrderNumber'],
      customerName: json['customerName'],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      currentOrders: ordersList,
    );
  }

  bool get isOccupied => status == 'occupied';
  bool get isReserved => status == 'reserved';
  bool get isAvailable => status == 'available';
  bool get isBillPrinted => status == 'bill_printed';
}
