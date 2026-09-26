import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();
  StreamSubscription? _sessionExpiredSub;

  AuthStatus status = AuthStatus.unknown;
  String? name;
  String? role;
  String? phone;
  bool loading = false;
  String? error;
  bool sessionExpiredFlag = false;

  AuthProvider() {
    _sessionExpiredSub = ApiClient.instance.sessionExpired.listen((_) async {
      await TokenStorage.instance.clear();
      status = AuthStatus.loggedOut;
      sessionExpiredFlag = true;
      notifyListeners();
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final has = await TokenStorage.instance.hasSession();
    name = await TokenStorage.instance.getName();
    role = await TokenStorage.instance.getRole();
    phone = await TokenStorage.instance.getPhone();
    status = has ? AuthStatus.loggedIn : AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> login(String phoneNum, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.login(phone: phoneNum, password: password);
      name = await TokenStorage.instance.getName();
      role = await TokenStorage.instance.getRole();
      phone = await TokenStorage.instance.getPhone();
      status = AuthStatus.loggedIn;
      sessionExpiredFlag = false;
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } on NetworkException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String phone,
    required String name,
    required String password,
    required String shopName,
    required String ownerName,
    required String area,
    String? upiId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.register(
        phone: phone, name: name, password: password,
        shopName: shopName, ownerName: ownerName, area: area, upiId: upiId,
      );
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } on NetworkException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    status = AuthStatus.loggedOut;
    name = null;
    role = null;
    phone = null;
    notifyListeners();
  }

  void clearSessionExpiredFlag() {
    sessionExpiredFlag = false;
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }
}
