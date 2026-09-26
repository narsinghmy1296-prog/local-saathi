import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_endpoints.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/product.dart';
import '../../state/locale_provider.dart';
import '../../state/products_provider.dart';
import '../../state/seller_provider.dart';
import '../../widgets/common_states.dart';
import 'product_form_screen.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});
  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final sellerId = context.read<SellerProvider>().profile?.id;
    if (sellerId != null) await context.read<ProductsProvider>().load(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final s = AppStrings(locale.lang);
    final prov = context.watch<ProductsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(s.products)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (changed == true) _load();
        },
        icon: const Icon(Icons.add),
        label: Text(s.addProduct),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: prov.loading && prov.products.isEmpty
            ? const LoadingView()
            : prov.error != null && prov.products.isEmpty
                ? ErrorView(message: prov.error!, retryLabel: s.retry, onRetry: _load)
                : prov.products.isEmpty
                    ? EmptyView(icon: Icons.inventory_2_outlined, message: s.noProductsYet)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                        itemCount: prov.products.length,
                        itemBuilder: (ctx, i) => _ProductTile(
                          product: prov.products[i],
                          strings: s,
                          onTap: () async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => ProductFormScreen(existing: prov.products[i])),
                            );
                            if (changed == true) _load();
                          },
                          onDeactivate: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: s.deactivate,
                              message: prov.products[i].name,
                              confirmLabel: s.confirm,
                              cancelLabel: s.cancel,
                              danger: true,
                            );
                            if (ok) await context.read<ProductsProvider>().deactivate(prov.products[i].id);
                          },
                        ),
                      ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onDeactivate;
  const _ProductTile({required this.product, required this.strings, required this.onTap, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final fullImageUrl = (imageUrl != null && imageUrl.startsWith('/')) ? '${ApiConfig.baseUrl}$imageUrl' : imageUrl;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.black12,
          backgroundImage: fullImageUrl != null ? NetworkImage(fullImageUrl) : null,
          child: fullImageUrl == null ? const Icon(Icons.image_outlined, color: Colors.black38) : null,
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('₹${product.price.toStringAsFixed(0)} / ${product.unit} · ${product.availableQty.toStringAsFixed(product.availableQty == product.availableQty.roundToDouble() ? 0 : 1)} ${product.unit}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!product.isActive)
              const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.visibility_off, color: Colors.black38, size: 20))
            else if (!product.inStock)
              const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20)),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: product.isActive ? onDeactivate : null),
          ],
        ),
      ),
    );
  }
}
