import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/order_status_labels.dart';
import '../../state/locale_provider.dart';
import '../../state/orders_provider.dart';
import '../../widgets/common_states.dart';
import '../../widgets/status_badge.dart';
import 'order_detail_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});
  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  String _filter = 'all'; // all | new | active | completed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<OrdersProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);
    final prov = context.watch<OrdersProvider>();

    var list = prov.orders;
    if (_filter == 'new') {
      list = list.where((o) => o.status == 'placed').toList();
    } else if (_filter == 'active') {
      list = list.where((o) => ['accepted', 'preparing', 'delivery_assigned', 'picked_up', 'out_for_delivery'].contains(o.status)).toList();
    } else if (_filter == 'completed') {
      list = list.where((o) => ['delivered', 'cancelled', 'rejected'].contains(o.status)).toList();
    }
    list = [...list]..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));

    return Scaffold(
      appBar: AppBar(title: Text(s.orders)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: s.orders, selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                  _FilterChip(label: s.newOrders, selected: _filter == 'new', onTap: () => setState(() => _filter = 'new')),
                  _FilterChip(label: s.pendingOrders, selected: _filter == 'active', onTap: () => setState(() => _filter = 'active')),
                  _FilterChip(label: s.completedOrders, selected: _filter == 'completed', onTap: () => setState(() => _filter = 'completed')),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<OrdersProvider>().load(),
              child: prov.loading && prov.orders.isEmpty
                  ? const LoadingView()
                  : prov.error != null && prov.orders.isEmpty
                      ? ErrorView(message: prov.error!, retryLabel: s.retry, onRetry: () => context.read<OrdersProvider>().load())
                      : list.isEmpty
                          ? EmptyView(icon: Icons.receipt_long_outlined, message: s.noOrdersYet)
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: list.length,
                              itemBuilder: (ctx, i) {
                                final o = list[i];
                                return Card(
                                  child: ListTile(
                                    title: Text('#${o.id} · ₹${o.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('${o.itemCount} ${s.items} · ${paymentStatusLabel(o.paymentStatus, locale.lang)}'),
                                    trailing: StatusBadge(status: o.status, label: orderStatusLabel(o.status, locale.lang)),
                                    onTap: () async {
                                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)));
                                      if (mounted) context.read<OrdersProvider>().load();
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
