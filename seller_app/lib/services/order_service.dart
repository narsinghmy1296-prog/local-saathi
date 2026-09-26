import '../core/api_client.dart';
import '../core/api_endpoints.dart';
import '../models/order.dart';

class OrderService {
  final _client = ApiClient.instance;

  /// GET /orders is auto-scoped server-side to the caller's role — for a
  /// seller this already returns only their own shop's orders, so there is
  /// no seller_id filter to pass (and none exists in the API).
  Future<List<OrderSummary>> getMyOrders() async {
    final resp = await _client.get(ApiEndpoints.orders);
    return (resp as List).map((e) => OrderSummary.fromJson(e)).toList();
  }

  Future<OrderDetail> getOrderDetail(int orderId) async {
    final resp = await _client.get(ApiEndpoints.order(orderId));
    return OrderDetail.fromJson(resp as Map<String, dynamic>);
  }

  /// [status] must be one the backend's state machine allows a seller to
  /// set: accepted, rejected, preparing, delivery_assigned (see
  /// app/core/state_machine.py — ORDER_TRANSITION_ROLES). Any other target
  /// is rejected by the backend with a clear 400/403, which the UI simply
  /// shows to the seller rather than trying to predict every rule client-side.
  Future<void> updateStatus(int orderId, String status) async {
    await _client.post(ApiEndpoints.orderStatus(orderId), body: {'status': status});
  }

  Future<void> cancelOrder(int orderId) async {
    await _client.post(ApiEndpoints.orderCancel(orderId));
  }

  /// For a seller collecting cash directly (COD): moves payment_status
  /// pending -> cash_received. Backend enforces ownership + the payment
  /// state machine regardless of what the client sends.
  Future<void> markPaymentReceived(int orderId, String newStatus) async {
    await _client.post(ApiEndpoints.orderPayment(orderId), body: {'new_status': newStatus});
  }
}
