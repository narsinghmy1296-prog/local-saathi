import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../state/cart_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/product_card.dart';
import '../common/state_widgets.dart';
import '../product/product_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _catalog = CatalogService();
  late final TextEditingController _ctrl;
  List<Product> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _search(widget.initialQuery);
  }

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _results = await _catalog.search(q);
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addToCart(Product product) async {
    final qty = await showConfirmAddToCart(context, product);
    if (qty == null || !mounted) return;
    final ok = await context.read<CartProvider>().addItem(product.id, qty);
    if (!mounted) return;
    final msg = ok
        ? (AppStrings.lang == 'hi' ? 'कार्ट में डाल दिया' : 'Added to cart')
        : (context.read<CartProvider>().error ?? 'Error');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(border: InputBorder.none, hintText: '', hintStyle: TextStyle(color: Colors.white70)),
          cursorColor: Colors.white,
          onSubmitted: _search,
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => _search(_ctrl.text))],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: () => _search(_ctrl.text))
              : _results.isEmpty
                  ? EmptyView(message: AppStrings.t('empty_search'), icon: Icons.search_off)
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        return ProductCard(
                          product: p,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                          onAddToCart: () => _addToCart(p),
                        );
                      },
                    ),
    );
  }
}
