import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'product.dart';
import 'cart_provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String? _selectedSize;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bool requiresSize = product.sizes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PRODUCT IMAGE (NO HERO — SAFE)
            SizedBox(
              width: double.infinity,
              height: 260,
              child: product.imageUrl.startsWith('http')
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 120,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Image.asset(product.imageUrl, fit: BoxFit.cover),
            ),

            const SizedBox(height: 24),

            // TITLE
            Text(
              product.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            // PRICE
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 18),

            // DELIVERY INFO
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Free delivery by Mon, 12 Feb',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.assignment_return_outlined, size: 20),
                const SizedBox(width: 10),
                Text(
                  '7 days easy return',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),

            // SIZE SELECTION
            if (requiresSize) ...[
              const SizedBox(height: 28),

              const Text(
                'Select Size :',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: product.sizes.map((size) {
                  final isSelected = _selectedSize == size;

                  return ChoiceChip(
                    label: Text(
                      product.category == Category.shoes ? '$size UK' : size,
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedSize = size);
                    },
                    selectedColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: Colors.black,
                    ),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isSelected ? Colors.black : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),
            ],

            // SPACE FOR FIXED BUTTON
            SizedBox(height: MediaQuery.of(context).padding.bottom + 96),
          ],
        ),
      ),

      // ADD TO CART BUTTON
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (!requiresSize || _selectedSize != null)
                  ? () {
                      context.read<CartProvider>().addToCart(
                        product,
                        size: _selectedSize,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text(
                'Add to Cart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
