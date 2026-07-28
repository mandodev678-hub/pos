class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double totalSpent;
  final int totalOrders;
  final double loyaltyPoints;
  final DateTime? createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.totalSpent = 0,
    this.totalOrders = 0,
    this.loyaltyPoints = 0,
    this.createdAt,
  });

  String get nameAr => name;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['name_ar'] ?? json['nameAr'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      loyaltyPoints: (json['loyalty_points'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }
}
