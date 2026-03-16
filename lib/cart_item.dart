import 'product.dart';

class CartItem {
  final Product product;
  final String? selectedSize;
  int quantity;

  CartItem({required this.product, this.selectedSize, this.quantity = 1});

  // Convert CartItem -> Map (for saving)
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'size': selectedSize,
      'quantity': quantity,
    };
  }

  //Convert Map -> CartItem (for loading)
  static CartItem fromMap(Map<String, dynamic> map, List<Product> allProducts) {
    final product = allProducts.firstWhere((p) => p.id == map['productId']);

    return CartItem(
      product: product,
      selectedSize: map['size'],
      quantity: map['quantity'],
    );
  }
}
