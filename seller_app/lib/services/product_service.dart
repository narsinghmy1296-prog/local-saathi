import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/product.dart';

class ProductService {
  final _client = ApiClient.instance;

  /// Backend has no "my products" endpoint — GET /products?seller_id= is
  /// the real, existing contract (same one the public catalog uses), so
  /// we resolve our own seller_id first via /sellers/me... but to avoid
  /// an extra round trip on every list refresh, callers should pass the
  /// seller's numeric id (from SellerProfile) once it's known.
  Future<List<Product>> getMyProducts(int sellerId) async {
    final resp = await _client.get(ApiEndpoints.products, query: {'seller_id': sellerId});
    return (resp as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> createProduct({
    int? categoryId,
    required String name,
    String? description,
    required double price,
    required String unit,
    required double availableQty,
    double minOrderQty = 1,
    String? imageUrl,
    List<String> keywords = const [],
  }) async {
    final resp = await _client.post(ApiEndpoints.products, body: {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'available_qty': availableQty,
      'min_order_qty': minOrderQty,
      'image_url': imageUrl,
      'keywords': keywords,
    });
    return Product.fromJson(resp as Map<String, dynamic>);
  }

  Future<Product> updateProduct(
    int productId, {
    int? categoryId,
    bool clearCategory = false,
    String? name,
    String? description,
    double? price,
    String? unit,
    double? minOrderQty,
    String? imageUrl,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (clearCategory) {
      body['category_id'] = null;
    } else if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (unit != null) body['unit'] = unit;
    if (minOrderQty != null) body['min_order_qty'] = minOrderQty;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (isActive != null) body['is_active'] = isActive;

    final resp = await _client.put(ApiEndpoints.product(productId), body: body);
    return Product.fromJson(resp as Map<String, dynamic>);
  }

  Future<Product> updateStock(int productId, {required double availableQty, required String stockStatus}) async {
    final resp = await _client.patch(ApiEndpoints.productStock(productId), body: {
      'available_qty': availableQty,
      'stock_status': stockStatus,
    });
    return Product.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> deactivateProduct(int productId) async {
    await _client.delete(ApiEndpoints.product(productId));
  }
}
