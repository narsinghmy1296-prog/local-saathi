class Product {
  final int id;
  final int sellerId;
  final int? categoryId;
  final bool isOther;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final double availableQty;
  final double minOrderQty;
  final String stockStatus;
  final String? imageUrl;
  final bool isActive;
  final String? sellerShopName; // present only if backend embeds seller info

  Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    this.isOther = false,
    required this.name,
    this.description,
    required this.price,
    required this.unit,
    required this.availableQty,
    required this.minOrderQty,
    required this.stockStatus,
    this.imageUrl,
    this.isActive = true,
    this.sellerShopName,
  });

  bool get inStock => stockStatus.toLowerCase() != 'out_of_stock' && availableQty > 0;

factory Product.fromJson(Map<String, dynamic> json) {
    double num(dynamic v) => v == null ? 0 : (v is int || v is double ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return Product(
      id: json['id'],
      sellerId: json['seller_id'] ?? 0,
      categoryId: json['category_id'],
      isOther: json['is_other'] ?? (json['category_id'] == null),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: num(json['price']),
      unit: json['unit']?.toString() ?? '',
      availableQty: num(json['available_qty']),
      minOrderQty: num(json['min_order_qty'] ?? 1),
      stockStatus: json['stock_status']?.toString() ?? 'in_stock',
      imageUrl: json['image_url']?.toString(),
      isActive: json['is_active'] ?? true,
      sellerShopName: json['seller']?['shop_name']?.toString() ?? json['shop_name']?.toString(),
    );
  }
}
