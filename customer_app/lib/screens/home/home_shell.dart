import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [HomeScreen(), CartScreen(), OrdersScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home, color: AppTheme.primary), label: AppStrings.lang == 'hi' ? 'होम' : 'Home'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.itemCount > 0,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart, color: AppTheme.primary),
            label: AppStrings.t('cart'),
          ),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long, color: AppTheme.primary), label: AppStrings.t('my_orders')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person, color: AppTheme.primary), label: AppStrings.t('profile')),
        ],
      ),
    );
  }
}
