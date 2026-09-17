import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({super.key, required this.product, required this.onTap, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.black12,
                        child: const Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.black38),
                      ),
                    )
                  : Container(
                      color: Colors.black12,
                      child: const Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.black38),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryDark, fontWeight: FontWeight.w600),
                  ),
                  if (!product.inStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppStrings.lang == 'hi' ? 'स्टॉक में नहीं' : 'Out of stock',
                        style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: product.inStock ? onAddToCart : null,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40), textStyle: const TextStyle(fontSize: 14)),
                      child: Text(AppStrings.t('add_to_cart')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
