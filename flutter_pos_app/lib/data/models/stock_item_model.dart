class StockItemModel {
  final String menuId;
  final String nameAr;
  final String? nameEn;
  final String? categoryName;
  final String? warehouseName;
  final double quantity;
  final String unit;
  final double? minQuantity;
  final double? avgCost;
  final double? totalValue;
  final bool isLowStock;

  StockItemModel({
    required this.menuId,
    required this.nameAr,
    this.nameEn,
    this.categoryName,
    this.warehouseName,
    required this.quantity,
    this.unit = 'قطعة',
    this.minQuantity,
    this.avgCost,
    this.totalValue,
    this.isLowStock = false,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] ?? json['current_quantity'] ?? 0).toDouble();
    final minQty = (json['minStock'] ?? json['min_quantity'] ?? json['min_stock'])?.toDouble();
    final cost = (json['costPrice'] ?? json['avg_cost'] ?? json['avgCost'])?.toDouble();
    final price = (json['price'])?.toDouble();

    return StockItemModel(
      menuId: json['menuId']?.toString() ?? json['menu_id']?.toString() ?? json['id']?.toString() ?? '',
      nameAr: json['productName'] ?? json['name_ar'] ?? json['nameAr'] ?? json['item_name'] ?? '',
      nameEn: json['productNameEn'] ?? json['name_en'] ?? json['nameEn'],
      categoryName: json['category_name'] ?? json['categoryName'],
      warehouseName: json['warehouseName'] ?? json['warehouse_name'],
      quantity: qty,
      unit: json['unit'] ?? 'قطعة',
      minQuantity: minQty,
      avgCost: cost ?? price,
      totalValue: (cost ?? price ?? 0.0) * qty,
      isLowStock: minQty != null && qty <= minQty,
    );
  }
}

class StockAlertModel {
  final String menuId;
  final String nameAr;
  final double currentStock;
  final double minStock;
  final String alertType;

  StockAlertModel({
    required this.menuId,
    required this.nameAr,
    required this.currentStock,
    required this.minStock,
    required this.alertType,
  });

  factory StockAlertModel.fromJson(Map<String, dynamic> json, {String alertType = 'low_stock'}) {
    return StockAlertModel(
      menuId: json['menuId']?.toString() ?? json['menu_id']?.toString() ?? '',
      nameAr: json['productName'] ?? json['name_ar'] ?? json['nameAr'] ?? '',
      currentStock: (json['quantity'] ?? json['current_stock'] ?? 0).toDouble(),
      minStock: (json['minStock'] ?? json['min_stock'] ?? 0).toDouble(),
      alertType: json['alertType'] ?? json['alert_type'] ?? alertType,
    );
  }
}
