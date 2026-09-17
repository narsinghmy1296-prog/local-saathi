import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/catalog_service.dart';
import '../../state/cart_provider.dart';
import '../../state/locale_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/product_card.dart';
import '../common/state_widgets.dart';
import '../product/product_detail_screen.dart';
import '../search/search_results_screen.dart';
import '../search/voice_search_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _catalog = CatalogService();
  final _searchCtrl = TextEditingController();

  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_catalog.getCategories(), _catalog.getProducts()]);
      setState(() {
        _categories = results[0] as List<Category>;
        _products = results[1] as List<Product>;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectCategory(int? id) async {
    setState(() {
      _selectedCategoryId = id;
      _loading = true;
    });
    try {
      _products = await _catalog.getProducts(categoryId: id);
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  void _runSearch(String q) {
    if (q.trim().isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchResultsScreen(initialQuery: q)));
  }

  Future<void> _openVoiceSearch() async {
    final result = await showVoiceSearchSheet(context);
    if (result != null && result.trim().isNotEmpty && mounted) {
      _runSearch(result);
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
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('appName')),
        actions: [
          IconButton(
            tooltip: locale.lang == 'hi' ? 'English' : 'हिंदी',
            onPressed: () => locale.toggle(),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: AppStrings.t('search_hint'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onSubmitted: _runSearch,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _openVoiceSearch,
                      child: const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.accent,
                        child: Icon(Icons.mic, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      CategoryChip(
                        category: Category(id: -1, nameHi: 'सभी', nameEn: 'All'),
                        selected: _selectedCategoryId == null,
                        onTap: () => _selectCategory(null),
                      ),
                      ..._categories.map((c) => CategoryChip(
                            category: c,
                            selected: _selectedCategoryId == c.id,
                            onTap: () => _selectCategory(c.id),
                          )),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (_loading)
              const SliverFillRemaining(child: LoadingView())
            else if (_error != null)
              SliverFillRemaining(child: ErrorView(message: _error!, onRetry: _load))
            else if (_products.isEmpty)
              SliverFillRemaining(child: EmptyView(message: AppStrings.t('empty_search'), icon: Icons.shopping_bag_outlined))
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = _products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id))),
                        onAddToCart: () => _addToCart(p),
                      );
                    },
                    childCount: _products.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
