import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/category.dart';

class CatalogService {
  final _client = ApiClient.instance;

  Future<List<Category>> getCategories() async {
    final resp = await _client.get(ApiEndpoints.categories, auth: false);
    return (resp as List).map((e) => Category.fromJson(e)).toList();
  }
}
