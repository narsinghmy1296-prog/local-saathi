class SellerProfile {
  final int id;
  final String shopName;
  final String ownerName;
  final String area;
  final String? upiId;
  final bool isApproved;
  final String phone;
  final String name;

  SellerProfile({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.area,
    this.upiId,
    required this.isApproved,
    required this.phone,
    required this.name,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) => SellerProfile(
        id: json['id'],
        shopName: json['shop_name']?.toString() ?? '',
        ownerName: json['owner_name']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        upiId: json['upi_id']?.toString(),
        isApproved: json['is_approved'] ?? false,
        phone: json['phone']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}
