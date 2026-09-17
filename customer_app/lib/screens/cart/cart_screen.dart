import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../state/cart_provider.dart';
import '../checkout/checkout_screen.dart';
import '../common/state_widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('cart'))),
      body: cartProvider.loading
          ? const LoadingView()
          : cartProvider.error != null
              ? ErrorView(message: cartProvider.error!, onRetry: cartProvider.load)
              : (cartProvider.cart == null || cartProvider.cart!.items.isEmpty)
                  ? EmptyView(message: AppStrings.t('empty_cart'), icon: Icons.shopping_cart_outlined)
                  : RefreshIndicator(
                      onRefresh: cartProvider.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartProvider.cart!.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final item = cartProvider.cart!.items[i];
                          final productName = item.name;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: Container(
                                        color: Colors.black12,
                                        child: const Icon(Icons.shopping_bag_outlined),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text('₹${item.lineTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () {
                                          final newQty = item.quantity - 1;
                                          if (newQty <= 0) {
                                            cartProvider.removeItem(item.id);
                                          } else {
                                            cartProvider.updateQuantity(item.id, item.productId, newQty);
                                          }
                                        },
                                      ),
                                      Text(item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => cartProvider.updateQuantity(item.id, item.productId, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                    onPressed: () => cartProvider.removeItem(item.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: (cartProvider.cart != null && cartProvider.cart!.items.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t('subtotal'), style: const TextStyle(color: Colors.black54)),
                        Text('₹${cartProvider.cart!.subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      child: Text(AppStrings.t('checkout')),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
