class AppUser {
  final int id;
  final String phone;
  final String name;
  final String role;

  AppUser({required this.id, required this.phone, required this.name, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? json['user_id'] ?? 0,
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
    );
  }
}
