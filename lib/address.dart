enum AddressType { home, work, other }

class Address {
  final String id;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final AddressType type;

  Address({
    required this.id,
    required this.city,
    required this.name,
    required this.phone,
    required this.pincode,
    required this.state,
    required this.street,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'type': type.name,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'],
      city: map['city'],
      name: map['name'],
      phone: map['phone'],
      pincode: map['pincode'],
      state: map['state'],
      street: map['street'],
      type: AddressType.values.firstWhere((e) => e.name == map['type']),
    );
  }
}
