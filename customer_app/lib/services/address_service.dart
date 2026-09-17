import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/address.dart';

class AddressService {
  final _client = ApiClient.instance;

  Future<List<Address>> getAddresses() async {
    final resp = await _client.get(ApiEndpoints.addresses);
    final list = (resp is List) ? resp : (resp is Map ? (resp['items'] ?? []) : []);
    return (list as List).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Address> addAddress(Address address) async {
    final resp = await _client.post(ApiEndpoints.addresses, body: address.toJson());
    return Address.fromJson(resp as Map<String, dynamic>);
  }

  Future<Address> updateAddress(int id, Address address) async {
    final resp = await _client.put(ApiEndpoints.address(id), body: address.toJson());
    return Address.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int id) async {
    await _client.delete(ApiEndpoints.address(id));
  }
}
