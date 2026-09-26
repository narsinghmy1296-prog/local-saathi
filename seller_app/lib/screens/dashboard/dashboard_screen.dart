import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../core/order_status_labels.dart';
import '../../state/locale_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/products_provider.dart';
import '../../state/seller_provider.dart';
import '../../widgets/status_badge.dart';
import '../orders/order_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final sellerId = context.read<SellerProvider>().profile?.id;
    if (sellerId != null) {
      await context.read<ProductsProvider>().load(sellerId);
    }
    await context.read<OrdersProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);
    final seller = context.watch<SellerProvider>();
    final products = context.watch<ProductsProvider>();
    final orders = context.watch<OrdersProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(s.dashboard)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 26, backgroundColor: AppTheme.primary, child: Icon(Icons.storefront, color: Colors.white)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(seller.profile?.shopName ?? '', style: Theme.of(context).textTheme.titleMedium),
                          Text(seller.profile?.area ?? '', style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(label: s.totalProducts, value: '${products.totalCount}', color: AppTheme.primary, icon: Icons.inventory_2),
                _StatCard(label: s.outOfStock, value: '${products.outOfStockCount}', color: AppTheme.danger, icon: Icons.warning_amber_rounded),
                _StatCard(label: s.newOrders, value: '${orders.newCount}', color: AppTheme.accent, icon: Icons.fiber_new_rounded),
                _StatCard(label: s.completedOrders, value: '${orders.completedCount}', color: Colors.indigo, icon: Icons.check_circle_outline),
              ],
            ),
            const SizedBox(height: 8),
            _StatCard(label: s.pendingOrders, value: '${orders.inProgressCount}', color: Colors.blueGrey, icon: Icons.hourglass_bottom, wide: true),
            const SizedBox(height: 20),
            Text(s.recentOrders, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (orders.loading && orders.orders.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (orders.recent.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(s.noOrdersYet))
            else
              ...orders.recent.map((o) => Card(
                    child: ListTile(
                      title: Text('#${o.id} · ₹${o.grandTotal.toStringAsFixed(0)}'),
                      subtitle: Text('${o.itemCount} ${s.items}'),
                      trailing: StatusBadge(status: o.status, label: orderStatusLabel(o.status, locale.lang)),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id))),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool wide;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon, this.wide = false});

  @override
  Widget build(BuildContext context) => Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
