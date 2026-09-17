import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so the JWT never touches plain
/// SharedPreferences / disk in cleartext, and is never hardcoded anywhere.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'ls_access_token';
  static const _roleKey = 'ls_role';
  static const _userIdKey = 'ls_user_id';
  static const _nameKey = 'ls_name';
  static const _phoneKey = 'ls_phone';

  Future<void> saveSession({
    required String token,
    required String role,
    required int userId,
    required String name,
    String? phone,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _userIdKey, value: userId.toString());
    await _storage.write(key: _nameKey, value: name);
    if (phone != null) await _storage.write(key: _phoneKey, value: phone);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getRole() => _storage.read(key: _roleKey);
  Future<String?> getName() => _storage.read(key: _nameKey);
  Future<String?> getPhone() => _storage.read(key: _phoneKey);
  Future<int?> getUserId() async {
    final v = await _storage.read(key: _userIdKey);
    return v == null ? null : int.tryParse(v);
  }

  Future<bool> hasSession() async => (await getToken()) != null;

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
