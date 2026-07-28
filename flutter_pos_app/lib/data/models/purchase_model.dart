class PurchaseModel {
  final String id;
  final String? invoiceNumber;
  final String? supplierName;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? notes;
  final DateTime? createdAt;
  final List<PurchaseItemModel> items;

  PurchaseModel({
    required this.id,
    this.invoiceNumber,
    this.supplierName,
    this.status = 'pending',
    required this.totalAmount,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.notes,
    this.createdAt,
    this.items = const [],
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final total = (json['total_amount'] ?? json['totalAmount'] ?? 0).toDouble();
    final paid = (json['paid_amount'] ?? json['paidAmount'] ?? 0).toDouble();
    return PurchaseModel(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoice_number'] ?? json['invoiceNumber'],
      supplierName: json['supplier_name'] ?? json['supplierName'] ??
          json['Supplier']?['name_ar'],
      status: json['status'] ?? 'pending',
      totalAmount: total,
      paidAmount: paid,
      remainingAmount: (json['remaining_amount'] ?? json['remainingAmount'] ?? total - paid).toDouble(),
      notes: json['notes'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      items: (json['items'] as List? ?? [])
          .map((i) => PurchaseItemModel.fromJson(i))
          .toList(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'paid': return 'مدفوع';
      case 'partial': return 'مدفوع جزئياً';
      case 'pending': return 'معلق';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }
}

class PurchaseItemModel {
  final String? menuItemName;
  final double quantity;
  final double unitPrice;
  final double total;

  PurchaseItemModel({
    this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      menuItemName: json['menu_item_name'] ?? json['name_ar'] ?? json['MenuItem']?['name_ar'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unitPrice: (json['unit_price'] ?? json['unitPrice'] ?? 0).toDouble(),
      total: (json['total'] ?? json['total_price'] ?? 0).toDouble(),
    );
  }
}
