class OrderModel {
  final String id;
  final String orderNumber;
  final String orderType;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? tableNumber;
  final String? customerName;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String? cashierName;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.tableNumber,
    this.customerName,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.cashierName,
    this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? json['id']?.toString() ?? '',
      orderType: json['order_type'] ?? json['orderType'] ?? 'dine_in',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? json['paymentMethod'],
      tableNumber: json['table_number']?.toString() ?? json['tableNumber']?.toString(),
      customerName: json['customer_name'] ?? json['customerName'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      cashierName: json['cashier_name'] ?? json['cashierName'] ?? json['User']?['name_ar'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      items: (json['items'] as List? ?? json['OrderItems'] as List? ?? [])
          .map((i) => OrderItemModel.fromJson(i))
          .toList(),
    );
  }

  String get orderTypeLabel {
    switch (orderType) {
      case 'dine_in': return 'صالة';
      case 'takeaway': return 'سفري';
      case 'delivery': return 'توصيل';
      default: return orderType;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'معلق';
      case 'confirmed': return 'مؤكد';
      case 'preparing': return 'يجهز';
      case 'ready': return 'جاهز';
      case 'delivered': return 'مسلّم';
      case 'completed': return 'مكتمل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}

class OrderItemModel {
  final String? nameAr;
  final int quantity;
  final double unitPrice;
  final double total;

  OrderItemModel({
    this.nameAr,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      nameAr: json['name_ar'] ?? json['nameAr'] ?? json['MenuItem']?['name_ar'] ?? json['menu_item_name'],
      quantity: (json['quantity'] ?? 1).toInt(),
      unitPrice: (json['unit_price'] ?? json['price'] ?? 0).toDouble(),
      total: (json['total'] ?? json['subtotal'] ?? 0).toDouble(),
    );
  }
}
