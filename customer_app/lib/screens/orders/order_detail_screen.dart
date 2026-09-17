import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/order_status_stepper.dart';
import '../common/state_widgets.dart';
import 'invoice_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  Order? _order;
  List<OrderStatusEvent> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getOrder(widget.orderId),
        _service.getStatusHistory(widget.orderId),
      ]);
      _order = results[0] as Order;
      _history = results[1] as List<OrderStatusEvent>;
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('#${widget.orderId}')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(_order!),
    );
  }

  Widget _buildBody(Order o) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OrderStatusStepper(rawStatus: o.status),
            ),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(AppStrings.lang == 'hi' ? 'स्थिति इतिहास' : 'Status history', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _history.map((h) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text(h.status)),
                          if (h.timestamp != null) Text(DateFormat('d MMM, h:mm a').format(h.timestamp!), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(AppStrings.t('products'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: o.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name ?? item.product?.name ?? 'Product #${item.productId}')),
                        Text('x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'),
                        const SizedBox(width: 12),
                        Text('₹${item.amount.toStringAsFixed(0)}'),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row(AppStrings.t('subtotal'), o.subtotal),
                  _row(AppStrings.t('delivery_charge'), o.deliveryCharge),
                  if (o.discount > 0) _row(AppStrings.t('discount'), -o.discount),
                  const Divider(),
                  _row(AppStrings.t('grand_total'), o.grandTotal, bold: true),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.t('payment_method')),
                      Text(o.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.t('payment_status')),
                      Text(o.paymentStatus, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceScreen(orderId: o.id))),
            icon: const Icon(Icons.receipt_outlined),
            label: Text(AppStrings.t('invoice')),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 17 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(0)}', style: TextStyle(fontSize: bold ? 17 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
