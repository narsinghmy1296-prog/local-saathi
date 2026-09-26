class Category {
  final int id;
  final String nameHi;
  final String nameEn;
  final String? iconUrl;
  final int sortOrder;
  final bool isActive;

  Category({
    required this.id,
    required this.nameHi,
    required this.nameEn,
    this.iconUrl,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameHi: json['name_hi']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString(),
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  String displayName(String lang) => lang == 'hi' ? nameHi : nameEn;
}
