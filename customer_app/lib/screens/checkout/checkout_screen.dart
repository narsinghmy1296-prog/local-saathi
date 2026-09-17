import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/address.dart';
import '../../services/order_service.dart';
import '../../state/cart_provider.dart';
import '../address/address_list_screen.dart';
import '../common/state_widgets.dart';
import '../orders/order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderService = OrderService();
  Address? _selectedAddress;
  String _paymentMethod = 'COD';
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    // Revalidate: re-pull the cart fresh from the server rather than trusting
    // whatever was last loaded, per Phase 6.5 (server is the source of truth
    // for price/stock at checkout time).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().load();
    });
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddressListScreen(selectMode: true)));
    if (result is Address) setState(() => _selectedAddress = result);
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t('select_address'))));
      return;
    }
    setState(() => _placing = true);
    try {
      final order = await _orderService.placeOrder(addressId: _selectedAddress!.id, paymentMethod: _paymentMethod);
      if (!mounted) return;
      await context.read<CartProvider>().load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t('order_placed'))));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on NetworkException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('checkout'))),
      body: cartProvider.loading
          ? const LoadingView()
          : (cart == null || cart.items.isEmpty)
              ? EmptyView(message: AppStrings.t('empty_cart'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(AppStrings.t('select_address'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        onTap: _pickAddress,
                        leading: const Icon(Icons.location_on_outlined, color: AppTheme.primary),
                        title: Text(_selectedAddress?.name ?? AppStrings.t('select_address')),
                        subtitle: _selectedAddress != null ? Text(_selectedAddress!.oneLine) : null,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(AppStrings.t('products'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: cart.items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item.name)),
                                  Text('x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}'),
                                  const SizedBox(width: 12),
                                  Text('₹${item.lineTotal.toStringAsFixed(0)}'),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(AppStrings.t('payment_method'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'COD',
                            groupValue: _paymentMethod,
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            title: Text(AppStrings.t('cod')),
                          ),
                          RadioListTile<String>(
                            value: 'UPI',
                            groupValue: _paymentMethod,
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                            title: Text(AppStrings.t('upi')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _totalRow(AppStrings.t('subtotal'), cart.subtotal),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                AppStrings.lang == 'hi'
                                    ? 'डिलीवरी शुल्क व अंतिम राशि ऑर्डर पक्का करते समय दिखेगी'
                                    : 'Delivery charge & final total are confirmed when you place the order',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _placing ? null : _placeOrder,
                      child: _placing
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(AppStrings.t('place_order')),
                    ),
                  ],
                ),
    );
  }

  Widget _totalRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text('₹${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
