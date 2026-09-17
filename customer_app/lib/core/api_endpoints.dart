class ApiConfig {
  /// Android emulator -> host PC.
  /// For a physical phone, replace with the PC's LAN IP, e.g. http://192.168.1.10:8000
  static const String baseUrl = "http://192.168.43.40:8000";
  static const String apiPrefix = "/api/v1";
}

class ApiEndpoints {
  static const _p = ApiConfig.apiPrefix;

  static const register = "$_p/auth/register";
  static const login = "$_p/auth/login";
  static const me = "$_p/auth/me";

  static const categories = "$_p/categories";
  static const products = "$_p/products";
  // The current backend has no GET /products/{id}. Product details are
  // resolved from the list/search response on the client.

  static const search = "$_p/search";

  static const cart = "$_p/cart";
  static const cartItems = "$_p/cart/items";
  static String cartItem(int itemId) => "$_p/cart/items/$itemId";

  static const addresses = "$_p/addresses";
  static String address(int id) => "$_p/addresses/$id";

  static const orders = "$_p/orders";
  static String order(int id) => "$_p/orders/$id";
  static String orderInvoice(int id) => "$_p/orders/$id/invoice";
}
