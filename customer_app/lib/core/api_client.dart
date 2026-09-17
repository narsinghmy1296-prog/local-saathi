import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_endpoints.dart';
import 'api_exceptions.dart';
import 'token_storage.dart';

/// Single place that actually talks HTTP. Every service (auth, products,
/// cart, ...) goes through this so that:
///   - the Authorization header is attached automatically whenever a token
///     exists (never hardcoded, always read fresh from secure storage)
///   - a 401 anywhere in the app is caught in one place and turned into a
///     forced-logout event the UI can react to (see [sessionExpired])
///   - error bodies (FastAPI's {"detail": ...} / 422 validation errors) are
///     turned into a single readable message instead of leaking raw JSON
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Screens/providers listen to this to know when to bounce to the login
  /// screen after a 401 (session expiry / invalid token).
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  Stream<void> get sessionExpired => _sessionExpiredController.stream;

  Future<Map<String, String>> _headers({bool auth = true, bool json = true}) async {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth) {
      final token = await TokenStorage.instance.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final full = '${ApiConfig.baseUrl}$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    final cleaned = <String, String>{};
    query.forEach((k, v) {
      if (v != null) cleaned[k] = v.toString();
    });
    return uri.replace(queryParameters: {...uri.queryParameters, ...cleaned});
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    return _send('GET', _uri(path, query), headers: await _headers(auth: auth));
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) async {
    return _send('POST', _uri(path),
        headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body));
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) async {
    return _send('PUT', _uri(path),
        headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body));
  }

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) async {
    return _send('PATCH', _uri(path),
        headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body));
  }

  Future<dynamic> delete(String path, {bool auth = true}) async {
    return _send('DELETE', _uri(path), headers: await _headers(auth: auth));
  }

  Future<dynamic> _send(String method, Uri uri, {Map<String, String>? headers, String? body}) async {
    http.Response resp;
    try {
      switch (method) {
        case 'GET':
          resp = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          resp = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 20));
          break;
        case 'PUT':
          resp = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 20));
          break;
        case 'PATCH':
          resp = await http.patch(uri, headers: headers, body: body).timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          resp = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        default:
          throw ArgumentError('Unsupported method $method');
      }
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException('Server is taking too long to respond.');
    } on http.ClientException {
      throw NetworkException();
    }

    return _handleResponse(resp);
  }

  dynamic _handleResponse(http.Response resp) {
    final status = resp.statusCode;
    dynamic decoded;
    if (resp.body.isNotEmpty) {
      try {
        decoded = jsonDecode(resp.body);
      } catch (_) {
        decoded = resp.body;
      }
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    if (status == 401) {
      _sessionExpiredController.add(null);
      throw ApiException(401, 'Your session has expired. Please log in again.', decoded);
    }

    final message = _extractMessage(status, decoded);
    throw ApiException(status, message, decoded);
  }

  String _extractMessage(int status, dynamic decoded) {
    // FastAPI convention: {"detail": "..."} or, for 422,
    // {"detail": [{"loc": [...], "msg": "...", "type": "..."}]}
    if (decoded is Map && decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          final loc = (first['loc'] is List) ? (first['loc'] as List).join('.') : '';
          return loc.isEmpty ? '${first['msg']}' : '$loc: ${first['msg']}';
        }
      }
    }
    switch (status) {
      case 403:
        return "You don't have permission to do that.";
      case 404:
        return 'Not found.';
      case 422:
        return 'Some information is invalid. Please check and try again.';
      case 500:
      default:
        return status >= 500
            ? 'Something went wrong on the server. Please try again shortly.'
            : 'Something went wrong (code $status).';
    }
  }
}
