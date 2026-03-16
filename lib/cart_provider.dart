import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'product.dart';
import 'cart_item.dart';
import 'order.dart' as app_order;

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final List<app_order.Order> _orders = [];

  List<CartItem> get items => List.unmodifiable(_items);
  List<app_order.Order> get orders => List.unmodifiable(_orders);

  int get totalItems => _items.fold(0, (t, i) => t + i.quantity);

  double get totalPrice =>
      _items.fold(0, (t, i) => t + (i.product.price * i.quantity));

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  //LOAD CART

  Future<void> loadCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    _items.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      _items.add(
        CartItem(
          product: Product.fromMap(data['product']),
          quantity: data['quantity'],
          selectedSize: data['selectedSize'],
        ),
      );
    }

    notifyListeners();
  }

  //LOAD ORDERS

  Future<void> loadOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    _orders.clear();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      _orders.add(app_order.Order.fromMap(data));
    }

    notifyListeners();
  }

  //ADD TO CART

  Future<void> addToCart(Product product, {String? size}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id && item.selectedSize == size,
    );

    if (existingIndex >= 0) {
      //Targeted query instead of full collection scan
      final snapshot = await cartRef
          .where('product.id', isEqualTo: product.id)
          .where('selectedSize', isEqualTo: size)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      _items[existingIndex].quantity++;

      await snapshot.docs.first.reference.update({
        'quantity': _items[existingIndex].quantity,
      });
    } else {
      final cartItem = CartItem(
        product: product,
        quantity: 1,
        selectedSize: size,
      );

      _items.add(cartItem);

      await cartRef.add({
        'product': product.toMap(),
        'quantity': 1,
        'selectedSize': size,
      });
    }

    notifyListeners();
  }

  //REMOVE FROM CART

  Future<void> removeFromCart(CartItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .where('product.id', isEqualTo: item.product.id)
        .where('selectedSize', isEqualTo: item.selectedSize)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }

    _items.remove(item);

    notifyListeners();
  }

  //INCREASE QUANTITY

  Future<void> increaseQty(CartItem item) async {
    await addToCart(item.product, size: item.selectedSize);
  }

  //DECREASE QUANTITY

  Future<void> decreaseQty(CartItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (item.quantity > 1) {
      item.quantity--;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({'quantity': item.quantity});
      }
    } else {
      await removeFromCart(item);
      return;
    }

    notifyListeners();
  }

  //CREATE ORDER

  Future<void> createOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) throw Exception("User not logged in");
    if (_items.isEmpty) throw Exception("Cart is empty");

    final userRef = _firestore.collection('users').doc(user.uid);
    final orderRef = userRef.collection('orders').doc();

    final order = app_order.Order(
      id: orderRef.id,
      createdAt: DateTime.now(),
      total: totalPrice,
      items: _items
          .map(
            (i) => app_order.OrderItem(
              product: i.product,
              quantity: i.quantity,
              selectedSize: i.selectedSize,
            ),
          )
          .toList(),
    );

    // Fetch cart docs before starting the batch
    final cartSnapshot = await userRef.collection('cart').get();

    // Atomic batch: write order + delete all cart docs together
    final batch = _firestore.batch();
    batch.set(orderRef, order.toMap());
    for (var doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit(); // All-or-nothing — no partial states

    // Update local state only after Firestore succeeds
    _orders.insert(0, order);
    _items.clear();
    notifyListeners();
  }

  //REORDER

  Future<void> reorderItems(app_order.Order order) async {
    for (var item in order.items) {
      await addToCart(item.product, size: item.selectedSize);
    }
  }

  //CLEAR

  void clear() {
    _items.clear();
    _orders.clear();
    notifyListeners();
  }
}
