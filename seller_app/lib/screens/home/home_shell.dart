import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../state/locale_provider.dart';
import '../../state/seller_provider.dart';
import '../auth/pending_approval_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/products_list_screen.dart';
import '../orders/orders_list_screen.dart';
import '../profile/profile_screen.dart';
import '../common/loading_screen.dart';

/// Root shell after login: loads the seller's own profile first (need
/// is_approved before showing anything else), then shows the 4-tab bottom
/// navigation the master prompt asks for (Dashboard / Products / Orders /
/// Profile).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SellerProvider>().load();
      if (mounted) setState(() => _bootstrapped = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);
    final sellerProv = context.watch<SellerProvider>();

    if (!_bootstrapped || sellerProv.loading) {
      return const LoadingScreen();
    }

    if (sellerProv.error != null && sellerProv.profile == null) {
      // Couldn't even fetch the profile (network/server issue) — show a
      // simple retry rather than guessing approval status.
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sellerProv.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.read<SellerProvider>().load(), child: Text(s.retry)),
            ],
          ),
        ),
      );
    }

    if (!sellerProv.isApproved) {
      return const PendingApprovalScreen();
    }

    final screens = [
      const DashboardScreen(),
      const ProductsListScreen(),
      const OrdersListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: s.dashboard),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: s.products),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long), label: s.orders),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: s.profile),
        ],
      ),
    );
  }
}
