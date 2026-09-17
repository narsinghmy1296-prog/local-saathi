/// Matches the REAL backend invoice shape exactly (see
/// backend/app/routers/orders.py -> get_invoice):
/// {invoice_number, generated_at, order_id, customer, seller,
///  items: [{name, quantity, unit_price, amount}], subtotal,
///  delivery_charge, discount, grand_total, payment_status}
class InvoiceItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceItem({required this.name, required this.quantity, required this.unitPrice, required this.amount});

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    double num_(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return InvoiceItem(
      name: json['name']?.toString() ?? '',
      quantity: num_(json['quantity']),
      unitPrice: num_(json['unit_price']),
      amount: num_(json['amount']),
    );
  }
}

class Invoice {
  final String invoiceNumber;
  final DateTime? generatedAt;
  final int orderId;
  final String? customer;
  final String? seller;
  final List<InvoiceItem> items;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double grandTotal;
  final String paymentStatus;

  Invoice({
    required this.invoiceNumber,
    this.generatedAt,
    required this.orderId,
    this.customer,
    this.seller,
    required this.items,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.grandTotal,
    required this.paymentStatus,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    double num_(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    final rawItems = (json['items'] as List?) ?? const [];
    return Invoice(
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      generatedAt: json['generated_at'] != null ? DateTime.tryParse(json['generated_at'].toString()) : null,
      orderId: json['order_id'] ?? 0,
      customer: json['customer']?.toString(),
      seller: json['seller']?.toString(),
      items: rawItems.whereType<Map<String, dynamic>>().map(InvoiceItem.fromJson).toList(),
      subtotal: num_(json['subtotal']),
      deliveryCharge: num_(json['delivery_charge']),
      discount: num_(json['discount']),
      grandTotal: num_(json['grand_total']),
      paymentStatus: json['payment_status']?.toString() ?? '',
    );
  }
}
