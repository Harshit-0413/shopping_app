import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedCard {
  final String id;
  final String last4;
  final String holderName;
  final String expiry;
  final String type; // 'visa', 'mastercard', 'rupay'
  final bool isDefault;

  SavedCard({
    required this.id,
    required this.last4,
    required this.holderName,
    required this.expiry,
    required this.type,
    this.isDefault = false,
  });

  factory SavedCard.fromMap(Map<String, dynamic> map) => SavedCard(
    id: map['id'],
    last4: map['last4'],
    holderName: map['holderName'],
    expiry: map['expiry'],
    type: map['type'],
    isDefault: map['isDefault'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'last4': last4,
    'holderName': holderName,
    'expiry': expiry,
    'type': type,
    'isDefault': isDefault,
  };

  SavedCard copyWith({bool? isDefault}) => SavedCard(
    id: id,
    last4: last4,
    holderName: holderName,
    expiry: expiry,
    type: type,
    isDefault: isDefault ?? this.isDefault,
  );
}

class SavedUpi {
  final String id;
  final String upiId;
  final String app; // 'gpay', 'phonepe', 'paytm', 'other'
  final bool isDefault;

  SavedUpi({
    required this.id,
    required this.upiId,
    required this.app,
    this.isDefault = false,
  });

  factory SavedUpi.fromMap(Map<String, dynamic> map) => SavedUpi(
    id: map['id'],
    upiId: map['upiId'],
    app: map['app'],
    isDefault: map['isDefault'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'upiId': upiId,
    'app': app,
    'isDefault': isDefault,
  };

  SavedUpi copyWith({bool? isDefault}) => SavedUpi(
    id: id,
    upiId: upiId,
    app: app,
    isDefault: isDefault ?? this.isDefault,
  );
}

class PaymentMethodsProvider with ChangeNotifier {
  final List<SavedCard> _cards = [];
  final List<SavedUpi> _upis = [];
  double _walletBalance = 0.0;
  bool _isLoading = false;

  List<SavedCard> get cards => List.unmodifiable(_cards);
  List<SavedUpi> get upis => List.unmodifiable(_upis);
  double get walletBalance => _walletBalance;
  bool get isLoading => _isLoading;

  // Default getters
  SavedCard? get defaultCard => _cards.where((c) => c.isDefault).isNotEmpty
      ? _cards.firstWhere((c) => c.isDefault)
      : null;

  SavedUpi? get defaultUpi => _upis.where((u) => u.isDefault).isNotEmpty
      ? _upis.firstWhere((u) => u.isDefault)
      : null;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference _cardsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedCards');

  CollectionReference _upisRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedUpis');

  DocumentReference _walletRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('wallet')
      .doc('balance');

  //LOAD

  Future<void> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final cardSnap = await _cardsRef(user.uid).get();
      _cards.clear();
      for (var doc in cardSnap.docs) {
        _cards.add(SavedCard.fromMap(doc.data() as Map<String, dynamic>));
      }

      final upiSnap = await _upisRef(user.uid).get();
      _upis.clear();
      for (var doc in upiSnap.docs) {
        _upis.add(SavedUpi.fromMap(doc.data() as Map<String, dynamic>));
      }

      final walletSnap = await _walletRef(user.uid).get();
      if (walletSnap.exists) {
        _walletBalance =
            (walletSnap.data() as Map<String, dynamic>)['balance']
                ?.toDouble() ??
            0.0;
      } else {
        // First time — initialise wallet with $0
        await _walletRef(user.uid).set({'balance': 0.0});
        _walletBalance = 0.0;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //CARDS

  Future<void> addCard(SavedCard card) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // If this is the first card, make it default automatically
    final shouldBeDefault = _cards.isEmpty;
    final cardToSave = card.copyWith(isDefault: shouldBeDefault);

    await _cardsRef(user.uid).doc(card.id).set(cardToSave.toMap());
    _cards.add(cardToSave);
    notifyListeners();
  }

  Future<void> deleteCard(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wasDefault = _cards.firstWhere((c) => c.id == id).isDefault;
    await _cardsRef(user.uid).doc(id).delete();
    _cards.removeWhere((c) => c.id == id);

    // Auto-assign default to first remaining card
    if (wasDefault && _cards.isNotEmpty) {
      await setDefaultCard(_cards.first.id);
    }

    notifyListeners();
  }

  Future<void> setDefaultCard(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    for (var card in _cards) {
      batch.update(_cardsRef(user.uid).doc(card.id), {
        'isDefault': card.id == id,
      });
    }

    await batch.commit();

    for (int i = 0; i < _cards.length; i++) {
      _cards[i] = _cards[i].copyWith(isDefault: _cards[i].id == id);
    }

    notifyListeners();
  }

  //UPI

  Future<void> addUpi(SavedUpi upi) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final shouldBeDefault = _upis.isEmpty;
    final upiToSave = upi.copyWith(isDefault: shouldBeDefault);

    await _upisRef(user.uid).doc(upi.id).set(upiToSave.toMap());
    _upis.add(upiToSave);
    notifyListeners();
  }

  Future<void> deleteUpi(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wasDefault = _upis.firstWhere((u) => u.id == id).isDefault;
    await _upisRef(user.uid).doc(id).delete();
    _upis.removeWhere((u) => u.id == id);

    if (wasDefault && _upis.isNotEmpty) {
      await setDefaultUpi(_upis.first.id);
    }

    notifyListeners();
  }

  Future<void> setDefaultUpi(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    for (var upi in _upis) {
      batch.update(_upisRef(user.uid).doc(upi.id), {'isDefault': upi.id == id});
    }

    await batch.commit();

    for (int i = 0; i < _upis.length; i++) {
      _upis[i] = _upis[i].copyWith(isDefault: _upis[i].id == id);
    }

    notifyListeners();
  }

  //WALLET

  Future<void> topUpWallet(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _walletBalance += amount;
    await _walletRef(user.uid).update({'balance': _walletBalance});
    notifyListeners();
  }

  //CLEAR

  void clear() {
    _cards.clear();
    _upis.clear();
    _walletBalance = 0.0;
    notifyListeners();
  }

  //HELPERS

  //Detects card type from card number prefix
  static String detectCardType(String cardNumber) {
    final number = cardNumber.replaceAll(' ', '');
    if (number.startsWith('4')) return 'visa';
    if (number.startsWith('5') || number.startsWith('2')) return 'mastercard';
    if (number.startsWith('6')) return 'rupay';
    return 'unknown';
  }
}
