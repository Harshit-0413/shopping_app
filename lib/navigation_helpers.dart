import 'package:flutter/material.dart';

import 'product.dart';
import 'product_details_page.dart';

void openProductFromId({
  required BuildContext context,
  required String productId,
  required List<Product> products,
}) {
  Product? product;

  for (final p in products) {
    if (p.id == productId) {
      product = p;
      break;
    }
  }

  if (product == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product is currently unavailable')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product!)),
  );
}
