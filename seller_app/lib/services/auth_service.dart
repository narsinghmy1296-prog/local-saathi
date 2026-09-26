import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../core/token_storage.dart';

class AuthService {
  final _client = ApiClient.instance;

  Future<void> register({
    required String phone,
    required String name,
    required String password,
    required String shopName,
    required String ownerName,
    required String area,
    String? upiId,
  }) async {
    await _client.post(
      ApiEndpoints.register,
      auth: false,
      body: {
        'phone': phone,
        'name': name,
        'password': password,
        'role': 'seller',
        'shop_name': shopName,
        'owner_name': ownerName,
        'area': area,
        if (upiId != null && upiId.isNotEmpty) 'upi_id': upiId,
      },
    );
  }

  /// Returns the logged-in user's role so the caller can reject a non-seller
  /// account trying to use this app (backend has no "seller-only login"
  /// concept — any registered phone+password can hit /auth/login — so this
  /// app enforces it client-side right after login, same as the Customer
  /// App would for any other role).
  Future<String> login({required String phone, required String password}) async {
    final resp = await _client.post(
      ApiEndpoints.login,
      auth: false,
      body: {'phone': phone, 'password': password},
    );
    final map = resp as Map<String, dynamic>;
    final token = map['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Login response did not include access_token.');
    }
    final role = (map['role'] ?? '').toString();

    await TokenStorage.instance.saveSession(
      token: token, role: role, userId: 0, name: '', phone: phone,
    );

    if (role != 'seller') {
      // Don't keep a session for a non-seller account inside the Seller App.
      await TokenStorage.instance.clear();
      throw Exception('यह मोबाइल नंबर Seller खाता नहीं है।');
    }

    try {
      final me = await _client.get(ApiEndpoints.me);
      final user = me as Map<String, dynamic>;
      await TokenStorage.instance.saveSession(
        token: token,
        role: role,
        userId: user['id'] is int ? user['id'] : int.tryParse('${user['id'] ?? 0}') ?? 0,
        name: (user['name'] ?? '').toString(),
        phone: (user['phone'] ?? phone).toString(),
      );
    } catch (_) {
      // Token already stored; /me metadata is non-critical to proceed.
    }
    return role;
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
  }
}
