import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class CartBadgeIcon extends StatelessWidget {
  final IconData icon;

  const CartBadgeIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final total = context.watch<CartProvider>().totalItems;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),

        if (total > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                total.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
