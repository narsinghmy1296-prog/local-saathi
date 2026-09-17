class Address {
  final int id;
  final String name;
  final String mobile;
  final String villageTown;
  final String? house;
  final String? landmark;
  final String pincode;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.mobile,
    required this.villageTown,
    this.house,
    this.landmark,
    required this.pincode,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      villageTown: json['village_town']?.toString() ?? '',
      house: json['house']?.toString(),
      landmark: json['landmark']?.toString(),
      pincode: json['pincode']?.toString() ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'mobile': mobile,
        'village_town': villageTown,
        if (house != null && house!.isNotEmpty) 'house': house,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        'pincode': pincode,
        'is_default': isDefault,
      };

  String get oneLine => [house, villageTown, landmark, pincode]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}
