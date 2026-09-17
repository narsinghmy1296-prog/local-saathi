import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../state/cart_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../common/state_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _catalog = CatalogService();
  Product? _product;
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
      _product = await _catalog.getProduct(widget.productId);
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addToCart() async {
    final p = _product!;
    final qty = await showConfirmAddToCart(context, p);
    if (qty == null || !mounted) return;
    final ok = await context.read<CartProvider>().addItem(p.id, qty);
    if (!mounted) return;
    final msg = ok
        ? (AppStrings.lang == 'hi' ? 'कार्ट में डाल दिया' : 'Added to cart')
        : (context.read<CartProvider>().error ?? 'Error');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_product?.name ?? '')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildDetail(_product!),
    );
  }

  Widget _buildDetail(Product p) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.black12, child: const Icon(Icons.image_not_supported_outlined, size: 60)))
                : Container(color: Colors.black12, child: const Icon(Icons.shopping_bag_outlined, size: 60)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.isOther)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(AppStrings.t('other_product_note'), style: const TextStyle(fontSize: 13)),
                  ),
                Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
                if (p.sellerShopName != null) ...[
                  const SizedBox(height: 4),
                  Text('${AppStrings.t('seller')}: ${p.sellerShopName}', style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 12),
                Text('₹${p.price.toStringAsFixed(0)} / ${p.unit}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                const SizedBox(height: 12),
                _infoRow(AppStrings.t('available'), '${p.availableQty.toStringAsFixed(0)} ${p.unit}'),
                _infoRow(AppStrings.t('min_order'), '${p.minOrderQty.toStringAsFixed(0)} ${p.unit}'),
                if (!p.inStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(AppStrings.lang == 'hi' ? 'स्टॉक में नहीं है' : 'Out of stock',
                        style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                if (p.description != null && p.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(p.description!, style: Theme.of(context).textTheme.bodyLarge),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: p.inStock ? _addToCart : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(AppStrings.t('add_to_cart')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
