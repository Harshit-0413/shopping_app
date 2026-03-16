import 'package:flutter/material.dart';
import 'address.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressProvider extends ChangeNotifier {
  final List<Address> _allAddresses = [];
  Address? _selectedAddress;

  List<Address> get allAddresses => List.unmodifiable(_allAddresses);
  Address? get selected => _selectedAddress;

  //Load addresses from Firestore
  Future<void> loadAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .get();

    _allAddresses.clear();

    _allAddresses.addAll(
      snapshot.docs.map((doc) {
        final data = doc.data();

        return Address(
          id: doc.id,
          name: data['name'] ?? '',
          street: data['street'] ?? '',
          city: data['city'] ?? '',
          pincode: data['pincode'] ?? '',
          state: data['state'] ?? '',
          phone: data['phone'] ?? '',
          type: AddressType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => AddressType.home,
          ),
        );
      }).toList(),
    );

    //Set default selected address
    if (_allAddresses.isNotEmpty) {
      _selectedAddress = _allAddresses.first;
    } else {
      _selectedAddress = null;
    }

    notifyListeners();
  }

  //Add address to Firestore
  Future<void> addAddress(Address address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .add({
          'name': address.name,
          'street': address.street,
          'city': address.city,
          'pincode': address.pincode,
          'state': address.state,
          'phone': address.phone,
          'type': address.type.name,
        });

    _allAddresses.add(
      Address(
        id: docRef.id,
        name: address.name,
        street: address.street,
        city: address.city,
        pincode: address.pincode,
        state: address.state,
        phone: address.phone,
        type: address.type,
      ),
    );

    if (_allAddresses.length == 1) {
      _selectedAddress = _allAddresses.first;
    }

    notifyListeners();
  }

  //Delete address
  Future<void> deleteAddress(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(id)
        .delete();

    _allAddresses.removeWhere((addr) => addr.id == id);

    if (_selectedAddress?.id == id) {
      _selectedAddress = _allAddresses.isNotEmpty ? _allAddresses.first : null;
    }

    notifyListeners();
  }

  //Select address (local only)
  void setSelectedAddress(String id) {
    try {
      _selectedAddress = _allAddresses.firstWhere((addr) => addr.id == id);
      notifyListeners();
    } catch (_) {}
  }

  //Update address
  Future<void> updateAddress(Address updatedAddress) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc(updatedAddress.id)
        .update({
          'name': updatedAddress.name,
          'street': updatedAddress.street,
          'city': updatedAddress.city,
          'pincode': updatedAddress.pincode,
          'state': updatedAddress.state,
          'phone': updatedAddress.phone,
          'type': updatedAddress.type.name,
        });

    final index = _allAddresses.indexWhere((a) => a.id == updatedAddress.id);

    if (index != -1) {
      _allAddresses[index] = updatedAddress;
      notifyListeners();
    }
  }

  //Clear on logout
  void clear() {
    _allAddresses.clear();
    _selectedAddress = null;
    notifyListeners();
  }
}
