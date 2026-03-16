import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/cart_provider.dart';
import 'package:shopping_app/order.dart';
import 'package:shopping_app/payment_screen.dart';
import 'package:shopping_app/product.dart'; // ✅ changed import

class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  final bool isPreview;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.isPreview = false,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isPlacingOrder = false;

  Future<void> _handleButtonPress() async {
    final cartProvider = context.read<CartProvider>();

    if (widget.isPreview) {
      //Navigate to PaymentScreen — it handles createOrder() after payment
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(totalAmount: widget.order.total),
        ),
      );
    } else {
      //Reorder flow unchanged
      setState(() => _isPlacingOrder = true);
      await cartProvider.reorderItems(widget.order);
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPreview ? "Order Summary" : "Order Details",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order ID: ${widget.order.id}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 4),

            Text(
              "Date: ${_formatDate(widget.order.createdAt)}",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Total: \$${widget.order.total.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),
            const Divider(thickness: 1),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: widget.order.items.length,
                itemBuilder: (context, index) {
                  final item = widget.order.items[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Image.asset(
                      item.product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      item.product.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "Qty: ${item.quantity}"
                      "${item.selectedSize != null ? " | Size: ${item.selectedSize}${item.product.category == Category.shoes ? ' UK' : ''}" : ""}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      "\$${(item.product.price * item.quantity).toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _handleButtonPress,
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.isPreview ? "Proceed to Payment" : "Reorder",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
