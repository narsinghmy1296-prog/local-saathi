/// Thrown by ApiClient for any non-2xx response, carrying enough info for
/// screens to show a sensible message without guessing.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, [this.body]);

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => message;
}

/// Thrown when there's no internet / the server can't be reached at all —
/// kept distinct from ApiException so the UI can show a "check connection"
/// message instead of a generic server-error message.
class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Could not reach the server.']);

  @override
  String toString() => message;
}
