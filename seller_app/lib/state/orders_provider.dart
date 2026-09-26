import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrdersProvider extends ChangeNotifier {
  final _service = OrderService();

  List<OrderSummary> orders = [];
  bool loading = false;
  String? error;

  int get newCount => orders.where((o) => o.status == 'placed').length;
  int get inProgressCount =>
      orders.where((o) => ['accepted', 'preparing', 'delivery_assigned', 'picked_up', 'out_for_delivery'].contains(o.status)).length;
  int get completedCount => orders.where((o) => o.status == 'delivered').length;

  List<OrderSummary> get recent {
    final sorted = [...orders]..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    return sorted.take(5).toList();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      orders = await _service.getMyOrders();
    } on ApiException catch (e) {
      error = e.message;
    } on NetworkException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
