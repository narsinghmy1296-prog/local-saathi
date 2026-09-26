class ApiConfig {
  /// Same fix as the Customer App: no hardcoded LAN IP. Defaults to the
  /// Android-emulator loopback for a zero-config local dev run; every
  /// other target (physical phone, staging, production) passes the real
  /// URL via --dart-define.
  ///
  ///   Emulator + local backend (default): flutter run
  ///   Physical phone on dev Wi-Fi:  flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
  ///   Production build:             flutter build apk --release --dart-define=API_BASE_URL=https://api.localsaathi.in
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

  static const sellerMe = "$_p/sellers/me";

  static const categories = "$_p/categories";

  static const products = "$_p/products"; // GET ?seller_id= , POST
  static String product(int id) => "$_p/products/$id"; // PUT, DELETE
  static String productStock(int id) => "$_p/products/$id/stock"; // PATCH

  static const uploadProductImage = "$_p/uploads/product-image";

  static const orders = "$_p/orders"; // GET — auto-scoped to caller's role by backend
  static String order(int id) => "$_p/orders/$id";
  static String orderStatus(int id) => "$_p/orders/$id/status";
  static String orderPayment(int id) => "$_p/orders/$id/payment/mark-received";
  static String orderCancel(int id) => "$_p/orders/$id/cancel";
}
