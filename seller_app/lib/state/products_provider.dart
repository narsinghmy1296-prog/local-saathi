import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductsProvider extends ChangeNotifier {
  final _service = ProductService();

  List<Product> products = [];
  bool loading = false;
  String? error;

  int get totalCount => products.length;
  int get activeCount => products.where((p) => p.isActive).length;
  int get outOfStockCount => products.where((p) => p.isActive && !p.inStock).length;

  Future<void> load(int sellerId) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await _service.getMyProducts(sellerId);
    } on ApiException catch (e) {
      error = e.message;
    } on NetworkException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> deactivate(int productId) async {
    error = null;
    try {
      await _service.deactivateProduct(productId);
      products = products.map((p) => p.id == productId
          ? Product(
              id: p.id, sellerId: p.sellerId, categoryId: p.categoryId, isOther: p.isOther,
              name: p.name, description: p.description, price: p.price, unit: p.unit,
              availableQty: p.availableQty, minOrderQty: p.minOrderQty, stockStatus: p.stockStatus,
              imageUrl: p.imageUrl, isActive: false, sellerShopName: p.sellerShopName,
            )
          : p).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } on NetworkException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }
}
