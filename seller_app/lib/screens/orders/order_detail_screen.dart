import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../core/order_status_labels.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../state/locale_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  OrderDetail? _order;
  bool _loading = true;
  bool _actionInProgress = false;
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
      _order = await _service.getOrderDetail(widget.orderId);
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runAction(Future<void> Function() action, {required String successMsg}) async {
    setState(() => _actionInProgress = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    } on NetworkException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);

    return Scaffold(
      appBar: AppBar(title: Text('${s.orderDetail} #${widget.orderId}')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, retryLabel: s.retry, onRetry: _load)
              : _order == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹${_order!.grandTotal.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium),
                              StatusBadge(status: _order!.status, label: orderStatusLabel(_order!.status, locale.lang)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_order!.paymentMethod.toUpperCase()} · ${paymentStatusLabel(_order!.paymentStatus, locale.lang)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          _SectionCard(
                            title: s.customerDetails,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_order!.customer.name ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                if (_order!.customer.phone != null)
                                  Row(children: [
                                    const Icon(Icons.call_outlined, size: 16, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(_order!.customer.phone!),
                                  ]),
                              ],
                            ),
                          ),
                          if (_order!.address != null)
                            _SectionCard(
                              title: s.deliveryAddress,
                              child: Text(
                                '${_order!.address!.house}, ${_order!.address!.villageTown}'
                                '${_order!.address!.landmark != null && _order!.address!.landmark!.isNotEmpty ? ', ${_order!.address!.landmark}' : ''}'
                                ' — ${_order!.address!.pincode}\n${s.phone}: ${_order!.address!.mobile}',
                              ),
                            ),
                          _SectionCard(
                            title: s.items,
                            child: Column(
                              children: _order!.items
                                  .map((i) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text('${i.name} × ${i.quantity.toStringAsFixed(i.quantity == i.quantity.roundToDouble() ? 0 : 2)}')),
                                            Text('₹${i.amount.toStringAsFixed(0)}'),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ..._buildActions(s),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildActions(AppStrings s) {
    if (_order == null) return [];
    final status = _order!.status;
    final widgets = <Widget>[];

    void addButton(String label, Future<void> Function() action, {bool danger = false, bool outlined = false}) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: outlined
            ? OutlinedButton(
                onPressed: _actionInProgress ? null : () => action(),
                style: danger ? OutlinedButton.styleFrom(foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)) : null,
                child: Text(label),
              )
            : ElevatedButton(
                onPressed: _actionInProgress ? null : () => action(),
                style: danger ? ElevatedButton.styleFrom(backgroundColor: AppTheme.danger) : null,
                child: Text(label),
              ),
      ));
    }

    // Transitions allowed for role=seller per app/core/state_machine.py:
    // placed -> accepted/rejected/cancelled; accepted -> preparing/cancelled;
    // preparing -> delivery_assigned/cancelled.
    if (status == 'placed') {
      addButton(s.accept, () => _runAction(() => _service.updateStatus(_order!.id, 'accepted'), successMsg: s.accept));
      addButton(s.reject, () => _runAction(() => _service.updateStatus(_order!.id, 'rejected'), successMsg: s.reject), danger: true, outlined: true);
    } else if (status == 'accepted') {
      addButton(s.markPreparing, () => _runAction(() => _service.updateStatus(_order!.id, 'preparing'), successMsg: s.markPreparing));
    } else if (status == 'preparing') {
      addButton(s.markReadyForPickup, () => _runAction(() => _service.updateStatus(_order!.id, 'delivery_assigned'), successMsg: s.markReadyForPickup));
    }

    if (['placed', 'accepted', 'preparing', 'delivery_assigned'].contains(status)) {
      addButton(s.cancelOrder, () => _runAction(() => _service.cancelOrder(_order!.id), successMsg: s.cancelOrder), danger: true, outlined: true);
    }

    // COD cash collected directly by the seller (pending -> cash_received is
    // an allowed transition per app/core/state_machine.py).
    if (_order!.paymentMethod == 'cod' && _order!.paymentStatus == 'pending') {
      addButton(
        s.markPaymentReceived,
        () => _runAction(() => _service.markPaymentReceived(_order!.id, 'cash_received'), successMsg: s.markPaymentReceived),
      );
    }

    return widgets;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}
