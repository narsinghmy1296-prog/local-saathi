import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../core/token_storage.dart';

class AuthService {
  final _client = ApiClient.instance;

  Future<void> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    await _client.post(
      ApiEndpoints.register,
      auth: false,
      body: {
        'phone': phone,
        'name': name,
        'password': password,
        'role': 'customer',
      },
    );
  }

  Future<void> login({required String phone, required String password}) async {
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

    await TokenStorage.instance.saveSession(
      token: token,
      role: (map['role'] ?? 'customer').toString(),
      userId: 0,
      name: '',
      phone: phone,
    );

    // The backend's login response contains the token + role only. Fetch /me
    // to get the authoritative user id/name rather than inventing fields.
    try {
      final me = await _client.get(ApiEndpoints.me);
      final user = me as Map<String, dynamic>;
      await TokenStorage.instance.saveSession(
        token: token,
        role: (user['role'] ?? map['role'] ?? 'customer').toString(),
        userId: user['id'] is int ? user['id'] : int.tryParse('${user['id'] ?? 0}') ?? 0,
        name: (user['name'] ?? '').toString(),
        phone: (user['phone'] ?? phone).toString(),
      );
    } catch (_) {
      // Token is already validly stored; /me metadata is non-critical.
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
  }
}
