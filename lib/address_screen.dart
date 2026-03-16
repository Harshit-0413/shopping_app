import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/address_form.dart';
import 'package:shopping_app/address_provider.dart';
import 'package:shopping_app/cart_provider.dart';
import 'package:shopping_app/order.dart';
import 'package:shopping_app/order_details_screen.dart';
import 'address.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AddressProvider>().loadAddresses();
    });
  }

  void _showAddAddressBottomSheet(
    BuildContext context,
    AddressProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddressForm(provider: provider, existingAddress: null),
      ),
    );
  }

  void _showEditAddressBottomSheet(
    BuildContext context,
    AddressProvider provider,
    Address address,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddressForm(provider: provider, existingAddress: address),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Addresses',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddAddressBottomSheet(context, addressProvider),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add new address',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (addressProvider.allAddresses.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No saved addresses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: addressProvider.allAddresses.length,
                  itemBuilder: (context, index) {
                    final address = addressProvider.allAddresses[index];
                    final isSelected =
                        addressProvider.selected?.id == address.id;

                    return Card(
                      color: isSelected ? Colors.green.shade50 : null,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  address.type == AddressType.home
                                      ? Icons.home
                                      : address.type == AddressType.work
                                      ? Icons.work
                                      : Icons.location_on,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  address.type.name.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),

                                PopupMenuButton(
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      addressProvider.deleteAddress(address.id);
                                    } else if (value == 'edit') {
                                      _showEditAddressBottomSheet(
                                        context,
                                        addressProvider,
                                        address,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text(
                              address.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              address.phone,
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              '${address.street}, ${address.city}, ${address.state} - ${address.pincode}',
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  addressProvider.setSelectedAddress(
                                    address.id,
                                  );

                                  final cartProvider = context
                                      .read<CartProvider>();

                                  final previewOrder = Order(
                                    id: "preview",
                                    createdAt: DateTime.now(),
                                    total: cartProvider.totalPrice,
                                    items: cartProvider.items
                                        .map(
                                          (i) => OrderItem(
                                            product: i.product,
                                            quantity: i.quantity,
                                            selectedSize: i.selectedSize,
                                          ),
                                        )
                                        .toList(),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailsScreen(
                                        order: previewOrder,
                                        isPreview: true,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Deliver Here'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
