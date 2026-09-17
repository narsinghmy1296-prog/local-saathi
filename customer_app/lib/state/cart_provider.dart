import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final _service = CartService();

  Cart? cart;
  bool loading = false;
  String? error;

  int get itemCount => cart?.items.length ?? 0;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      cart = await _service.getCart();
    } on ApiException catch (e) {
      error = e.message;
    } on NetworkException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Explicit-confirmation add-to-cart, per spec: voice search and browsing
  /// only ever *suggest* a product — this is the one path that actually
  /// mutates the cart, and every caller must have gotten a yes/no from the
  /// customer first (see ConfirmAddToCartDialog).
  Future<bool> addItem(int productId, double quantity) async {
    error = null;
    try {
      cart = await _service.addItem(productId: productId, quantity: quantity);
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

  Future<bool> updateQuantity(int cartItemId, int productId, double quantity) async {
    error = null;
    try {
      cart = await _service.updateItem(cartItemId: cartItemId, productId: productId, quantity: quantity);
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

  Future<bool> removeItem(int cartItemId) async {
    error = null;
    try {
      cart = await _service.removeItem(cartItemId);
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

  void clearLocal() {
    cart = null;
    notifyListeners();
  }
}
