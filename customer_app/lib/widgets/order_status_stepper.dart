import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../models/order.dart';

class OrderStatusStepper extends StatelessWidget {
  final String rawStatus;
  const OrderStatusStepper({super.key, required this.rawStatus});

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusInfo.parse(rawStatus);

    if (status == OrderStatus.cancelled || status == OrderStatus.rejected) {
      return Row(
        children: [
          const Icon(Icons.cancel, color: AppTheme.danger),
          const SizedBox(width: 8),
          Text(OrderStatusInfo.label(status, rawStatus, AppStrings.lang),
              style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      );
    }

    const flow = OrderStatusInfo.orderedFlow;
    final currentIndex = flow.indexOf(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < flow.length; i++)
          _StepRow(
            label: OrderStatusInfo.label(flow[i], flow[i].name, AppStrings.lang),
            done: currentIndex >= 0 && i <= currentIndex,
            isLast: i == flow.length - 1,
          ),
        if (currentIndex < 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${AppStrings.lang == 'hi' ? 'स्थिति' : 'Status'}: $rawStatus'),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final bool done;
  final bool isLast;
  const _StepRow({required this.label, required this.done, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppTheme.primary : Colors.black26;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 22),
              if (!isLast) Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(label, style: TextStyle(fontSize: 16, color: done ? Colors.black87 : Colors.black45, fontWeight: done ? FontWeight.w600 : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}
