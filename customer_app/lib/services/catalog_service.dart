import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/category.dart';
import '../models/product.dart';

/// Categories + products + search live together since they're all simple
/// read-only "catalog" calls.
class CatalogService {
  final _client = ApiClient.instance;

  List<Map<String, dynamic>> _asList(dynamic resp) {
    if (resp is List) return resp.cast<Map<String, dynamic>>();
    if (resp is Map && resp['items'] is List) return (resp['items'] as List).cast<Map<String, dynamic>>();
    if (resp is Map && resp['results'] is List) return (resp['results'] as List).cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Category>> getCategories() async {
    final resp = await _client.get(ApiEndpoints.categories);
    return _asList(resp).map((e) => Category.fromJson(e)).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<Product>> getProducts({int? categoryId}) async {
    final resp = await _client.get(
      ApiEndpoints.products,
      query: categoryId != null ? {'category_id': categoryId} : null,
    );
    return _asList(resp).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> getProduct(int id) async {
    final products = await getProducts();
    return products.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Product नहीं मिला।'),
    );
  }

  /// Same endpoint for both typed and voice search — voice search just does
  /// speech-to-text on-device first (see VoiceSearchController) and calls
  /// this with the resulting text, exactly like the README describes.
  Future<List<Product>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final resp = await _client.get(ApiEndpoints.search, query: {'q': query.trim()});
    return _asList(resp).map((e) => Product.fromJson(e)).toList();
  }
}
