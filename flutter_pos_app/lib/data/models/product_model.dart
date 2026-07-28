class ProductModel {
  final String id;
  final String categoryId;
  final String nameAr;
  final String? nameEn;
  final double price;
  final String? image;
  final bool isAvailable;
  final String? sku;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.nameAr,
    this.nameEn,
    required this.price,
    this.image,
    this.isAvailable = true,
    this.sku,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      categoryId: json['category_id'] ?? '',
      nameAr: json['name_ar'] ?? json['name'] ?? '',
      nameEn: json['name_en'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] ?? json['image_url'],
      isAvailable: json['is_available'] ?? true,
      sku: json['sku'],
    );
  }
}
