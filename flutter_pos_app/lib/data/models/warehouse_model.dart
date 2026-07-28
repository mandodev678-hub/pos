class WarehouseModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? location;
  final String? branchName;
  final String? managerName;
  final String status;
  final bool isDefault;
  final WarehouseStats? stats;

  WarehouseModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.location,
    this.branchName,
    this.managerName,
    this.status = 'active',
    this.isDefault = false,
    this.stats,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr'] ?? json['name_ar'] ?? '',
      nameEn: json['nameEn'] ?? json['name_en'],
      location: json['location'],
      branchName: json['branchName'] ?? json['branch_name'],
      managerName: json['managerName'] ?? json['manager_name'],
      status: json['status'] ?? 'active',
      isDefault: json['isDefault'] == true || json['is_default'] == true,
      stats: json['stats'] != null ? WarehouseStats.fromJson(json['stats']) : null,
    );
  }
}

class WarehouseStats {
  final int productCount;
  final double totalItems;
  final double totalValue;

  WarehouseStats({
    required this.productCount,
    required this.totalItems,
    required this.totalValue,
  });

  factory WarehouseStats.fromJson(Map<String, dynamic> json) {
    return WarehouseStats(
      productCount: (json['productCount'] ?? 0).toInt(),
      totalItems: (json['totalItems'] ?? 0).toDouble(),
      totalValue: (json['totalValue'] ?? 0).toDouble(),
    );
  }
}
