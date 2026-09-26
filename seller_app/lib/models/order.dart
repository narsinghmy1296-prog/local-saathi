class OrderSummary {
  final int id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double grandTotal;
  final DateTime? createdAt;
  final int itemCount;

  OrderSummary({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.grandTotal,
    this.createdAt,
    required this.itemCount,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    double num(dynamic v) => v == null ? 0 : (v is int || v is double ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return OrderSummary(
      id: json['id'],
      status: json['status']?.toString() ?? 'placed',
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      grandTotal: num(json['grand_total']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class OrderItemLine {
  final int productId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double amount;

  OrderItemLine({required this.productId, required this.name, required this.quantity, required this.unitPrice, required this.amount});

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    double num(dynamic v) => v == null ? 0 : (v is int || v is double ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return OrderItemLine(
      productId: json['product_id'],
      name: json['name']?.toString() ?? '',
      quantity: num(json['quantity']),
      unitPrice: num(json['unit_price']),
      amount: num(json['amount']),
    );
  }
}

class StatusHistoryEntry {
  final String status;
  final DateTime? timestamp;
  StatusHistoryEntry({required this.status, this.timestamp});
  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) => StatusHistoryEntry(
        status: json['status']?.toString() ?? '',
        timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
      );
}

class CustomerInfo {
  final String? name;
  final String? phone;
  CustomerInfo({this.name, this.phone});
  factory CustomerInfo.fromJson(Map<String, dynamic>? json) =>
      CustomerInfo(name: json?['name']?.toString(), phone: json?['phone']?.toString());
}

class DeliveryAddressInfo {
  final String villageTown;
  final String house;
  final String? landmark;
  final String pincode;
  final String mobile;
  DeliveryAddressInfo({required this.villageTown, required this.house, this.landmark, required this.pincode, required this.mobile});
  factory DeliveryAddressInfo.fromJson(Map<String, dynamic> json) => DeliveryAddressInfo(
        villageTown: json['village_town']?.toString() ?? '',
        house: json['house']?.toString() ?? '',
        landmark: json['landmark']?.toString(),
        pincode: json['pincode']?.toString() ?? '',
        mobile: json['mobile']?.toString() ?? '',
      );
}

class OrderDetail {
  final int id;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double grandTotal;
  final List<OrderItemLine> items;
  final List<StatusHistoryEntry> statusHistory;
  final CustomerInfo customer;
  final DeliveryAddressInfo? address;

  OrderDetail({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.grandTotal,
    required this.items,
    required this.statusHistory,
    required this.customer,
    this.address,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    double num(dynamic v) => v == null ? 0 : (v is int || v is double ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    return OrderDetail(
      id: json['id'],
      status: json['status']?.toString() ?? 'placed',
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      subtotal: num(json['subtotal']),
      deliveryCharge: num(json['delivery_charge']),
      discount: num(json['discount']),
      grandTotal: num(json['grand_total']),
      items: (json['items'] as List? ?? []).map((e) => OrderItemLine.fromJson(e)).toList(),
      statusHistory: (json['status_history'] as List? ?? []).map((e) => StatusHistoryEntry.fromJson(e)).toList(),
      customer: CustomerInfo.fromJson(json['customer']),
      address: json['address'] != null ? DeliveryAddressInfo.fromJson(json['address']) : null,
    );
  }
}
