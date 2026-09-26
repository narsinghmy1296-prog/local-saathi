import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Small colored pill for an order/product status — used across the
/// dashboard, orders list, and order detail so a status always looks the
/// same everywhere.
class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  const StatusBadge({super.key, required this.status, required this.label});

  Color get _color {
    switch (status) {
      case 'placed':
        return Colors.blueGrey;
      case 'accepted':
      case 'preparing':
        return AppTheme.accent;
      case 'delivery_assigned':
      case 'picked_up':
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return AppTheme.primary;
      case 'cancelled':
      case 'rejected':
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: _color, fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
