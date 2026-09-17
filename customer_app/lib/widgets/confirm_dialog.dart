import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../models/product.dart';

/// Every cart-mutating action (from voice search, product detail, product
/// card, etc.) must route through this so the customer explicitly confirms
/// before anything is added — per spec: "Any cart addition or purchase
/// action must require explicit customer confirmation."
Future<double?> showConfirmAddToCart(BuildContext context, Product product) async {
  double qty = product.minOrderQty > 0 ? product.minOrderQty : 1;
  return showDialog<double>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(AppStrings.t('confirm_add_to_cart')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
              Text('₹${product.price.toStringAsFixed(0)} / ${product.unit}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: qty > product.minOrderQty
                        ? () => setState(() => qty = (qty - 1).clamp(product.minOrderQty, product.availableQty))
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 2)} ${product.unit}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    onPressed: qty < product.availableQty
                        ? () => setState(() => qty = (qty + 1).clamp(product.minOrderQty, product.availableQty))
                        : null,
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: Text(AppStrings.t('no'))),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(qty), child: Text(AppStrings.t('yes'))),
          ],
        ),
      );
    },
  );
}
