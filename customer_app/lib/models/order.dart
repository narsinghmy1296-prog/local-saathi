import 'product.dart';

/// The 8 customer-facing statuses per the Phase 7 spec. The exact raw string
/// values coming from the backend are UNCONFIRMED (inferred from the DB
/// column being VARCHAR(17) and README step-by-step flow), so matching is
/// done loosely (case/underscore-insensitive) and falls back to showing the
/// raw backend string rather than crashing or silently hiding it.
enum OrderStatus { placed, accepted, preparing, deliveryAssigned, pickedUp, outForDelivery, delivered, cancelled, rejected, unknown }

class OrderStatusInfo {
  static OrderStatus parse(String raw) {
    final v = raw.toLowerCase().replaceAll(' ', '_');
    switch (v) {
      case 'placed':
        return OrderStatus.placed;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'delivery_assigned':
        return OrderStatus.deliveryAssigned;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'rejected':
        return OrderStatus.rejected;
      default:
        return OrderStatus.unknown;
    }
  }

  static String label(OrderStatus s, String raw, String lang) {
    const hi = {
      OrderStatus.placed: 'ऑर्डर हुआ',
      OrderStatus.accepted: 'स्वीकार किया गया',
      OrderStatus.preparing: 'तैयार हो रहा है',
      OrderStatus.deliveryAssigned: 'डिलीवरी तय हुई',
      OrderStatus.pickedUp: 'उठा लिया गया',
      OrderStatus.outForDelivery: 'डिलीवरी के लिए निकला',
      OrderStatus.delivered: 'डिलीवर हो गया',
      OrderStatus.cancelled: 'रद्द',
      OrderStatus.rejected: 'अस्वीकृत',
    };
    const en = {
      OrderStatus.placed: 'Placed',
      OrderStatus.accepted: 'Accepted',
      OrderStatus.preparing: 'Preparing',
      OrderStatus.deliveryAssigned: 'Delivery Assigned',
      OrderStatus.pickedUp: 'Picked Up',
      OrderStatus.outForDelivery: 'Out for Delivery',
      OrderStatus.delivered: 'Delivered',
      OrderStatus.cancelled: 'Cancelled',
      OrderStatus.rejected: 'Rejected',
    };
    final map = lang == 'hi' ? hi : en;
    return map[s] ?? raw;
  }

  static const orderedFlow = [
    OrderStatus.placed,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.deliveryAssigned,
    OrderStatus.pickedUp,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];
}

class OrderItem {
  final int id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String? name;
  final Product? product;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.name,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double _num(dynamic v) => v == null ? 0 : (v is int || v is double ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
  return OrderItem(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: _num(json['quantity']),
      unitPrice: _num(json['unit_price']),
      amount: _num(json['amount']),
      name: json['name']?.toString(),
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
  );
  }
}

class OrderStatusEvent {
  final String status;
  final DateTime? timestamp;

  OrderStatusEvent({required this.status, this.timestamp});

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: json['status']?.toString() ?? '',
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
    );
  }
}

class Order {
  final int id;
  final int addressId;
  final int sellerId;
  final String status;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double grandTotal;
  final String paymentMethod; // COD / UPI
  final String paymentStatus;
  final DateTime? createdAt;
  final List<OrderItem> items;
  final String? sellerShopName;

  Order({
    required this.id,
    required this.addressId,
    required this.sellerId,
    required this.status,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    this.createdAt,
    this.items = const [],
    this.sellerShopName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
    v == null ? 0 : ((v is int || v is double)
        ? v.toDouble()
        : double.tryParse(v.toString()) ?? 0);
    final rawItems = (json['items'] as List?) ?? [];
    return Order(
      id: json['id'] ?? json['order_id'] ?? 0,
      addressId: json['address_id'] ?? 0,
      sellerId: json['seller_id'] ?? 0,
      status: json['status']?.toString() ?? 'placed',
      subtotal: toDouble(json['subtotal']),
deliveryCharge: toDouble(json['delivery_charge']),
discount: toDouble(json['discount']),
grandTotal: toDouble(json['grand_total']),
      paymentMethod: json['payment_method']?.toString() ?? 'COD',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      items: rawItems.map((e) => OrderItem.fromJson(e)).toList(),
      sellerShopName: json['seller']?['shop_name']?.toString(),
    );
  }
}
