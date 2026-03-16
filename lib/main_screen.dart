import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/address_provider.dart';
import 'package:shopping_app/app_drawer.dart';
import 'package:shopping_app/cart_badge_icon.dart';
import 'package:shopping_app/cart_page.dart';
import 'package:shopping_app/cart_provider.dart';
import 'package:shopping_app/home_page.dart';
import 'package:shopping_app/order_history_page.dart';
import 'package:shopping_app/payment_methods_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<AddressProvider>(context, listen: false).loadAddresses();
      Provider.of<CartProvider>(context, listen: false).loadCart();
      Provider.of<PaymentMethodsProvider>(context, listen: false).load();
    });
  }

  int _selectedIndex = 0;

  void goToHome() => setState(() => _selectedIndex = 0);
  void goToCart() => setState(() => _selectedIndex = 1);
  void goToOrders() => setState(() => _selectedIndex = 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,

      drawer: AppDrawer(onOrdersTap: goToOrders),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(scaffoldKey: scaffoldKey),
          CartPage(onBack: goToHome),
          OrderHistoryPage(
            scaffoldKey: scaffoldKey,
            onReorderGoToCart: goToCart,
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 1 ? 0 : _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: CartBadgeIcon(icon: Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}
