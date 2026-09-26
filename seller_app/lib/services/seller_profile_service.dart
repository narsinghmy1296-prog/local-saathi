import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/seller_profile.dart';

class SellerProfileService {
  final _client = ApiClient.instance;

  Future<SellerProfile> getMyProfile() async {
    final resp = await _client.get(ApiEndpoints.sellerMe);
    return SellerProfile.fromJson(resp as Map<String, dynamic>);
  }

  Future<SellerProfile> updateMyProfile({
    String? shopName,
    String? ownerName,
    String? area,
    String? upiId,
  }) async {
    final body = <String, dynamic>{};
    if (shopName != null) body['shop_name'] = shopName;
    if (ownerName != null) body['owner_name'] = ownerName;
    if (area != null) body['area'] = area;
    if (upiId != null) body['upi_id'] = upiId;
    final resp = await _client.put(ApiEndpoints.sellerMe, body: body);
    return SellerProfile.fromJson(resp as Map<String, dynamic>);
  }
}
