import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'address_screen.dart';
import 'login_screen.dart';
import 'cart_provider.dart';
import 'address_provider.dart';
import 'payment_methods_screen.dart';
import 'payment_methods_provider.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onOrdersTap;

  const AppDrawer({super.key, required this.onOrdersTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Shopping App',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //Home
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),

          //Orders
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Orders'),
            onTap: () {
              Navigator.pop(context);
              onOrdersTap();
            },
          ),

          //Addresses
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Addresses'),
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 250), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressScreen()),
                );
              });
            },
          ),

          //Payment methods
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Payment Methods'),
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 250), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                );
              });
            },
          ),

          const Divider(),

          //Login/Logout
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;

              return ListTile(
                leading: Icon(user == null ? Icons.login : Icons.logout),
                title: Text(user == null ? 'Login' : 'Logout'),
                onTap: () async {
                  Navigator.pop(context);

                  if (user == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    final cartProvider = context.read<CartProvider>();
                    final addressProvider = context.read<AddressProvider>();
                    final paymentProvider = context
                        .read<PaymentMethodsProvider>();

                    final confirm = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Logout"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      cartProvider.clear();
                      addressProvider.clear();
                      paymentProvider.clear(); //clear on logout
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
