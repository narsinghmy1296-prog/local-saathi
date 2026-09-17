import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/invoice.dart';
import '../models/order.dart';

class OrderService {
  final _client = ApiClient.instance;

  Future<Order> placeOrder({required int addressId, required String paymentMethod}) async {
    final resp = await _client.post(
      ApiEndpoints.orders,
      body: {'address_id': addressId, 'payment_method': paymentMethod.toLowerCase()},
    );
    return Order.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<Order>> getMyOrders() async {
    final resp = await _client.get(ApiEndpoints.orders);
    final list = (resp is List) ? resp : (resp is Map ? (resp['items'] ?? []) : []);
    return (list as List)
        .whereType<Map<String, dynamic>>()
        .map(Order.fromJson)
        .toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
  }

  Future<Order> getOrder(int id) async {
    final resp = await _client.get(ApiEndpoints.order(id));
    return Order.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<OrderStatusEvent>> getStatusHistory(int orderId) async {
    final resp = await _client.get(ApiEndpoints.order(orderId));
    final map = resp as Map<String, dynamic>;
    final list = (map['status_history'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(OrderStatusEvent.fromJson).toList();
  }

  Future<Invoice> getInvoice(int orderId) async {
    final resp = await _client.get(ApiEndpoints.orderInvoice(orderId));
    return Invoice.fromJson(resp as Map<String, dynamic>);
  }
}
