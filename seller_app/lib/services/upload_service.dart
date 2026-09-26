import 'dart:typed_data';

import '../core/api_client.dart';
import '../core/api_endpoints.dart';

class UploadService {
  final _client = ApiClient.instance;

  /// Returns the relative image_url (e.g. "/static/products/xyz.png") that
  /// the caller then sends straight into product create/update payloads.
  Future<String> uploadProductImage({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final resp = await _client.postMultipartFile(
      ApiEndpoints.uploadProductImage,
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    final map = resp as Map<String, dynamic>;
    return map['image_url'].toString();
  }
}
