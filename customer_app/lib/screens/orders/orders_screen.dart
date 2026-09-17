import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../common/state_widgets.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final _service = OrderService();
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _orders = await _service.getMyOrders();
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isActive(Order o) {
    final s = OrderStatusInfo.parse(o.status);
    return s != OrderStatus.delivered && s != OrderStatus.cancelled && s != OrderStatus.rejected;
  }

  @override
  Widget build(BuildContext context) {
    final active = _orders.where(_isActive).toList();
    final previous = _orders.where((o) => !_isActive(o)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('my_orders')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: AppStrings.lang == 'hi' ? 'चालू' : 'Active'),
            Tab(text: AppStrings.lang == 'hi' ? 'पिछले' : 'Previous'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _list(active),
                    _list(previous),
                  ],
                ),
    );
  }

  Widget _list(List<Order> orders) {
    if (orders.isEmpty) {
      return EmptyView(message: AppStrings.t('empty_orders'), icon: Icons.receipt_long_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final o = orders[i];
          final status = OrderStatusInfo.parse(o.status);
          return Card(
            child: ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
              title: Text('#${o.id} · ₹${o.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Text(
                [
                  if (o.createdAt != null) DateFormat('d MMM, h:mm a').format(o.createdAt!),
                  '${o.items.length} ${AppStrings.t('products')}',
                ].join(' · '),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (status == OrderStatus.cancelled || status == OrderStatus.rejected) ? Colors.red.shade50 : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  OrderStatusInfo.label(status, o.status, AppStrings.lang),
                  style: TextStyle(
                    color: (status == OrderStatus.cancelled || status == OrderStatus.rejected) ? AppTheme.danger : AppTheme.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
