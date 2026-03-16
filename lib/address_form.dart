import 'package:flutter/material.dart';
import 'address.dart';
import 'address_provider.dart';

class AddressForm extends StatefulWidget {
  final AddressProvider provider;
  final Address? existingAddress;

  const AddressForm({
    super.key,
    required this.provider,
    required this.existingAddress,
  });

  @override
  State<AddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<AddressForm> {
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  AddressType _selectedType = AddressType.home;

  @override
  void initState() {
    super.initState();
    if (widget.existingAddress != null) {
      final addr = widget.existingAddress!;
      _nameController.text = addr.name;
      _phoneController.text = addr.phone;
      _streetController.text = addr.street;
      _cityController.text = addr.city;
      _stateController.text = addr.state;
      _pincodeController.text = addr.pincode;
      _selectedType = addr.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final fields = {
      'Full Name': _nameController.text,
      'Phone Number': _phoneController.text,
      'Street Address': _streetController.text,
      'City': _cityController.text,
      'State': _stateController.text,
      'Pincode': _pincodeController.text,
    };

    final emptyField = fields.entries.firstWhere(
      (entry) => entry.value.trim().isEmpty,
      orElse: () => const MapEntry('', ''),
    );
    if (emptyField.key.isNotEmpty) {
      setState(() => _errorMessage = 'Please fill : ${emptyField.key}');
      return;
    }

    if (widget.existingAddress == null) {
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        phone: _phoneController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        type: _selectedType,
      );
      await widget.provider.addAddress(newAddress);
    } else {
      final updatedAddress = Address(
        id: widget.existingAddress!.id,
        name: _nameController.text,
        phone: _phoneController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        type: _selectedType,
      );
      await widget.provider.updateAddress(updatedAddress);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingAddress == null
                    ? 'Add New Address'
                    : 'Edit Address',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Address type selector
              SegmentedButton<AddressType>(
                segments: const [
                  ButtonSegment(
                    value: AddressType.home,
                    label: Text(
                      'Home',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    icon: Icon(Icons.home),
                  ),
                  ButtonSegment(
                    value: AddressType.work,
                    label: Text(
                      'Work',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    icon: Icon(Icons.work),
                  ),
                  ButtonSegment(
                    value: AddressType.other,
                    label: Text(
                      'Other',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    icon: Icon(Icons.location_on),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (value) {
                  setState(() => _selectedType = value.first);
                },
              ),

              const SizedBox(height: 16),

              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),

              // Phone
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Street
              TextField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street Address'),
              ),
              const SizedBox(height: 12),

              // City + State
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pincode
              TextField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // Save / Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                    widget.existingAddress == null
                        ? 'Save Address'
                        : 'Update Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
