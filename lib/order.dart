import 'product.dart';

class Order {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final double total;

  Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'total': total,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      createdAt: DateTime.parse(map['createdAt']),
      total: (map['total'] as num).toDouble(),
      items: (map['items'] as List).map((e) => OrderItem.fromMap(e)).toList(),
    );
  }
}

class OrderItem {
  final Product product;
  final int quantity;
  final String? selectedSize;

  OrderItem({required this.product, required this.quantity, this.selectedSize});

  //total price for this item
  double get totalPrice => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'selectedSize': selectedSize,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      product: Product.fromMap(map['product']),
      quantity: map['quantity'],
      selectedSize: map['selectedSize'],
    );
  }
}
