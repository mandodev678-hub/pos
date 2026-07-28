class SupplierModel {
  final String id;
  final String nameAr;
  final String? nameEn;
  final String? phone;
  final String? email;
  final String? address;
  final double balance;
  final String status;

  SupplierModel({
    required this.id,
    required this.nameAr,
    this.nameEn,
    this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
    this.status = 'active',
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? '',
      nameAr: json['name_ar'] ?? json['nameAr'] ?? json['name'] ?? '',
      nameEn: json['name_en'] ?? json['nameEn'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      balance: (json['balance'] ?? json['current_balance'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }
}
