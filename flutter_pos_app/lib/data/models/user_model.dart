class UserModel {
  final String id;
  final String username;
  final String nameAr;
  final String role;
  final String branchId;

  UserModel({
    required this.id,
    required this.username,
    required this.nameAr,
    required this.role,
    required this.branchId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      nameAr: json['name_ar'] ?? '',
      role: json['role'] ?? 'cashier',
      branchId: json['branch_id'] ?? '',
    );
  }
}
