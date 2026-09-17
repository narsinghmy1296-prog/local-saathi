import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/cart.dart';

class CartService {
  final _client = ApiClient.instance;

  Future<Cart> getCart() async {
    final resp = await _client.get(ApiEndpoints.cart);
    return Cart.fromJson(resp as Map<String, dynamic>);
  }

  Future<Cart> addItem({required int productId, required double quantity}) async {
    await _client.post(
      ApiEndpoints.cartItems,
      body: {'product_id': productId, 'quantity': quantity},
    );
    return getCart();
  }

  Future<Cart> updateItem({required int cartItemId, required int productId, required double quantity}) async {
    await _client.put(
      ApiEndpoints.cartItem(cartItemId),
      body: {'product_id': productId, 'quantity': quantity},
    );
    return getCart();
  }

  Future<Cart> removeItem(int cartItemId) async {
    await _client.delete(ApiEndpoints.cartItem(cartItemId));
    return getCart();
  }
}
