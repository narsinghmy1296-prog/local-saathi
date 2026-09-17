class CartItem {
  final int id;
  final int productId;
  final String name;
  final double price;
  final double quantity;
  final double amount;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.amount,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    double numValue(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    return CartItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id'] ?? 0}') ?? 0,
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse('${json['product_id'] ?? 0}') ?? 0,
      name: json['name']?.toString() ?? 'Product',
      price: numValue(json['price']),
      quantity: numValue(json['quantity']),
      amount: numValue(json['amount']),
    );
  }

  double get lineTotal => amount > 0 ? amount : price * quantity;
}

class Cart {
  final List<CartItem> items;
  final double serverSubtotal;

  Cart({required this.items, required this.serverSubtotal});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? [];
    double numValue(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;
    return Cart(
      items: rawItems.whereType<Map<String, dynamic>>().map(CartItem.fromJson).toList(),
      serverSubtotal: numValue(json['subtotal']),
    );
  }

  double get subtotal => serverSubtotal > 0
      ? serverSubtotal
      : items.fold(0.0, (sum, i) => sum + i.lineTotal);

  int get totalItemCount => items.length;
}
