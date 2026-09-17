import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_exceptions.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
import '../../models/invoice.dart';
import '../../services/order_service.dart';
import '../common/state_widgets.dart';

/// Backend currently returns JSON invoice data, not a generated PDF file
/// (see README). This screen renders that real JSON as a clean, structured
/// receipt — it does NOT fabricate a PDF or a fake download button; wiring
/// the real `pdf` skill in is called out in the spec as a later, isolated
/// task.
class InvoiceScreen extends StatefulWidget {
  final int orderId;
  const InvoiceScreen({super.key, required this.orderId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _service = OrderService();
  Invoice? _invoice;
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
      _invoice = await _service.getInvoice(widget.orderId);
    } on ApiException catch (e) {
      _error = e.message;
    } on NetworkException catch (e) {
      _error = e.message;
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('invoice'))),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildInvoice(_invoice!),
    );
  }

  Widget _buildInvoice(Invoice inv) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t('appName'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryDark)),
                const SizedBox(height: 4),
                Text(AppStrings.lang == 'hi' ? 'बिल / रसीद' : 'Invoice / Receipt', style: const TextStyle(color: Colors.black54)),
                const Divider(height: 28),
                _row(AppStrings.lang == 'hi' ? 'बिल नंबर' : 'Invoice No.', inv.invoiceNumber),
                _row(AppStrings.lang == 'hi' ? 'ऑर्डर नंबर' : 'Order No.', '#${inv.orderId}'),
                if (inv.generatedAt != null)
                  _row(AppStrings.lang == 'hi' ? 'तारीख' : 'Date', DateFormat('d MMM y, h:mm a').format(inv.generatedAt!)),
                if (inv.customer != null) _row(AppStrings.lang == 'hi' ? 'ग्राहक' : 'Customer', inv.customer!),
                if (inv.seller != null) _row(AppStrings.t('seller'), inv.seller!),
                const Divider(height: 28),
                Text(AppStrings.t('products'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ...inv.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.name, style: const TextStyle(fontSize: 14)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'x${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('₹${item.amount.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 28),
                _amountRow(AppStrings.t('subtotal'), inv.subtotal),
                _amountRow(AppStrings.t('delivery_charge'), inv.deliveryCharge),
                if (inv.discount > 0) _amountRow(AppStrings.t('discount'), -inv.discount),
                const Divider(height: 20),
                _amountRow(AppStrings.t('grand_total'), inv.grandTotal, bold: true),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.t('payment_status')),
                    Text(inv.paymentStatus, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.lang == 'hi'
              ? 'नोट: यह बिल अभी टेक्स्ट के रूप में है — PDF डाउनलोड बाद में जोड़ा जाएगा।'
              : 'Note: this invoice is text-only for now — PDF download will be added in a later update.',
          style: const TextStyle(color: Colors.black54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: bold ? 17 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('₹${value.toStringAsFixed(0)}', style: TextStyle(fontSize: bold ? 17 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
