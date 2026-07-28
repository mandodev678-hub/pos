class CategoryModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final int sortOrder;

  CategoryModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.sortOrder = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      nameAr: json['name_ar'] ?? json['name'] ?? '',
      nameEn: json['name_en'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
