class ApiConfig {
  /// FIX (Phase 1 stabilization audit): this used to be a hardcoded LAN IP
  /// (192.168.43.40) that only ever worked on the one Wi-Fi network it was
  /// typed on — every other developer/device/tester and any real deploy
  /// would silently fail every request. Now read from a build-time
  /// --dart-define, with the Android-emulator loopback (10.0.2.2, which
  /// reaches the host machine's localhost) as a safe default so a fresh
  /// checkout still runs against `uvicorn --reload` out of the box.
  ///
  /// Usage:
  ///   Emulator + local backend (default, no flag needed):
  ///     flutter run
  ///   Physical phone on the same Wi-Fi as your dev machine:
  ///     flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
  ///   Real deployment:
  ///     flutter build apk --release --dart-define=API_BASE_URL=https://api.localsaathi.in
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
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
