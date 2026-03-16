import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/payment_methods_provider.dart';
import 'package:uuid/uuid.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<PaymentMethodsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentMethodsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Wallet Section
                  _SectionHeader(title: 'Wallet'),
                  const SizedBox(height: 10),
                  _WalletCard(
                    balance: provider.walletBalance,
                    onTopUp: () => _showTopUpSheet(context, provider),
                  ),

                  const SizedBox(height: 24),

                  //UPI Section
                  _SectionHeader(
                    title: 'Saved UPI IDs',
                    onAdd: () => _showAddUpiSheet(context, provider),
                  ),
                  const SizedBox(height: 10),
                  if (provider.upis.isEmpty)
                    _EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'No saved UPI IDs',
                    )
                  else
                    ...provider.upis.map(
                      (upi) => _UpiTile(
                        upi: upi,
                        onDelete: () => _confirmDelete(
                          context,
                          onConfirm: () => provider.deleteUpi(upi.id),
                        ),
                        onSetDefault: () => provider.setDefaultUpi(upi.id),
                      ),
                    ),

                  const SizedBox(height: 24),

                  //  Cards Section
                  _SectionHeader(
                    title: 'Saved Cards',
                    onAdd: () => _showAddCardSheet(context, provider),
                  ),
                  const SizedBox(height: 10),
                  if (provider.cards.isEmpty)
                    _EmptyState(
                      icon: Icons.credit_card_outlined,
                      label: 'No saved cards',
                    )
                  else
                    ...provider.cards.map(
                      (card) => _CardTile(
                        card: card,
                        onDelete: () => _confirmDelete(
                          context,
                          onConfirm: () => provider.deleteCard(card.id),
                        ),
                        onSetDefault: () => provider.setDefaultCard(card.id),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  //Confirm Delete Dialog
  void _confirmDelete(BuildContext context, {required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove'),
        content: const Text('Remove this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  //Add UPI Bottom Sheet
  void _showAddUpiSheet(BuildContext context, PaymentMethodsProvider provider) {
    final upiController = TextEditingController();
    String selectedApp = 'gpay';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).viewPadding.bottom +
                24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add UPI ID',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              const Text(
                'Select App',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              //Wrap instead of Row — no overflow
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AppChip(
                    label: 'GPay',
                    color: const Color(0xFF4285F4),
                    selected: selectedApp == 'gpay',
                    onTap: () => setSheetState(() => selectedApp = 'gpay'),
                  ),
                  _AppChip(
                    label: 'PhonePe',
                    color: const Color(0xFF5F259F),
                    selected: selectedApp == 'phonepe',
                    onTap: () => setSheetState(() => selectedApp = 'phonepe'),
                  ),
                  _AppChip(
                    label: 'Paytm',
                    color: const Color(0xFF00BAF2),
                    selected: selectedApp == 'paytm',
                    onTap: () => setSheetState(() => selectedApp = 'paytm'),
                  ),
                  _AppChip(
                    label: 'Other',
                    color: Colors.grey,
                    selected: selectedApp == 'other',
                    onTap: () => setSheetState(() => selectedApp = 'other'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                controller: upiController,
                decoration: InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'yourname@upi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final val = upiController.text.trim();
                    if (val.isEmpty || !val.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid UPI ID')),
                      );
                      return;
                    }
                    provider.addUpi(
                      SavedUpi(
                        id: const Uuid().v4(),
                        upiId: val,
                        app: selectedApp,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Save UPI ID',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Add Card Bottom Sheet
  void _showAddCardSheet(
    BuildContext context,
    PaymentMethodsProvider provider,
  ) {
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    String detectedType = 'unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).viewPadding.bottom +
                24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (detectedType != 'unknown')
                    _CardTypeBadge(type: detectedType),
                ],
              ),

              const SizedBox(height: 20),

              // ── Card Number ──────────────────────────────
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                maxLength: 19, // 16 digits + 3 spaces
                onChanged: (val) {
                  //  Auto-format: insert space every 4 digits
                  final digitsOnly = val.replaceAll(' ', '');
                  if (digitsOnly.length > 16) return;

                  final formatted = digitsOnly
                      .replaceAllMapped(
                        RegExp(r'.{1,4}'),
                        (m) => '${m.group(0)} ',
                      )
                      .trim();

                  //Only update if text actually changed to avoid cursor jump
                  if (formatted != val) {
                    numberController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }

                  setSheetState(() {
                    detectedType = PaymentMethodsProvider.detectCardType(
                      digitsOnly,
                    );
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Name on Card ─────────────────────────────
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name on Card',
                  hintText: 'Rohit Sharma',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              //Expiry + CVV
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      keyboardType: TextInputType.number,
                      maxLength: 5, // MM/YY
                      onChanged: (val) {
                        //  Auto-insert slash after MM
                        String cleaned = val.replaceAll('/', '');
                        if (cleaned.length > 4) {
                          cleaned = cleaned.substring(0, 4);
                        }
                        String formatted = cleaned;
                        if (cleaned.length >= 2) {
                          formatted =
                              '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
                        }
                        if (formatted != val) {
                          expiryController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Expiry',
                        hintText: 'MM/YY',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  //  CVV field
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '•••',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              //Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final digits = numberController.text.replaceAll(' ', '');
                    if (digits.length < 16) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid 16-digit card number'),
                        ),
                      );
                      return;
                    }
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter the name on card')),
                      );
                      return;
                    }
                    if (expiryController.text.length < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid expiry date'),
                        ),
                      );
                      return;
                    }
                    if (cvvController.text.length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid CVV')),
                      );
                      return;
                    }
                    provider.addCard(
                      SavedCard(
                        id: const Uuid().v4(),
                        last4: digits.substring(digits.length - 4),
                        holderName: nameController.text.trim(),
                        expiry: expiryController.text.trim(),
                        type: detectedType,
                      ),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Save Card',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Wallet Top-Up Sheet
  void _showTopUpSheet(BuildContext context, PaymentMethodsProvider provider) {
    int? selectedAmount;
    String? selectedSource; // 'upi:{id}' or 'card:{id}'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final hasNoMethods = provider.upis.isEmpty && provider.cards.isEmpty;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(ctx).viewPadding.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Up Wallet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select amount and payment source',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                //Amount selector
                const Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [100, 500, 1000, 2000].map((amount) {
                    final isSelected = selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedAmount = amount),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '+ \$$amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                //Payment source
                const Text(
                  'Pay Via',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                if (hasNoMethods)
                  //No methods saved — block top-up
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add a UPI ID or Card first to top up your wallet.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  //Show saved UPIs and cards as source options
                  Column(
                    children: [
                      ...provider.upis.map((upi) {
                        final key = 'upi:${upi.id}';
                        final isSelected = selectedSource == key;
                        return _SourceTile(
                          title: upi.upiId,
                          subtitle: _upiAppLabel(upi.app),
                          color: _upiAppColor(upi.app),
                          letter: _upiAppLabel(upi.app)[0],
                          isSelected: isSelected,
                          onTap: () =>
                              setSheetState(() => selectedSource = key),
                        );
                      }),
                      ...provider.cards.map((card) {
                        final key = 'card:${card.id}';
                        final isSelected = selectedSource == key;
                        return _SourceTile(
                          title: '•••• ${card.last4}',
                          subtitle: card.holderName,
                          color: Colors.blueGrey,
                          letter: 'C',
                          isSelected: isSelected,
                          onTap: () =>
                              setSheetState(() => selectedSource = key),
                        );
                      }),
                    ],
                  ),

                const SizedBox(height: 20),

                //Confirm button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        (selectedAmount == null ||
                            selectedSource == null ||
                            hasNoMethods)
                        ? null //Disabled until both are selected
                        : () {
                            provider.topUpWallet(selectedAmount!.toDouble());
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '\$$selectedAmount added to wallet',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                    child: Text(
                      selectedAmount == null
                          ? 'Select an amount'
                          : 'Add \$$selectedAmount to Wallet',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  //helpers used inside the sheet
  String _upiAppLabel(String app) {
    switch (app) {
      case 'gpay':
        return 'GPay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      default:
        return 'UPI';
    }
  }

  Color _upiAppColor(String app) {
    switch (app) {
      case 'gpay':
        return const Color(0xFF4285F4);
      case 'phonepe':
        return const Color(0xFF5F259F);
      case 'paytm':
        return const Color(0xFF00BAF2);
      default:
        return Colors.grey;
    }
  }
}

//Section Header
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
      ],
    );
  }
}

//Wallet Card
class _WalletCard extends StatelessWidget {
  final double balance;
  final VoidCallback onTopUp;

  const _WalletCard({required this.balance, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onTopUp,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Top Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── UPI Tile ────────────────────────────────────────────────
class _UpiTile extends StatelessWidget {
  final SavedUpi upi;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _UpiTile({
    required this.upi,
    required this.onDelete,
    required this.onSetDefault,
  });

  Color _appColor() {
    switch (upi.app) {
      case 'gpay':
        return const Color(0xFF4285F4);
      case 'phonepe':
        return const Color(0xFF5F259F);
      case 'paytm':
        return const Color(0xFF00BAF2);
      default:
        return Colors.grey;
    }
  }

  String _appLabel() {
    switch (upi.app) {
      case 'gpay':
        return 'GPay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      default:
        return 'UPI';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _appColor(), shape: BoxShape.circle),
          child: Center(
            child: Text(
              _appLabel()[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          upi.upiId,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(_appLabel()),
            if (upi.isDefault) ...[const SizedBox(width: 8), _DefaultBadge()],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            if (!upi.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (val) {
            if (val == 'delete') onDelete();
            if (val == 'default') onSetDefault();
          },
        ),
      ),
    );
  }
}

// ── Card Tile ───────────────────────────────────────────────
class _CardTile extends StatelessWidget {
  final SavedCard card;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _CardTile({
    required this.card,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: _CardTypeBadge(type: card.type),
        title: Text(
          '•••• •••• •••• ${card.last4}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        subtitle: Column(
          children: [
            Text('${card.holderName}  •  ${card.expiry}'),
            if (card.isDefault) ...[const SizedBox(width: 8), _DefaultBadge()],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            if (!card.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Text('Set as Default'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
          onSelected: (val) {
            if (val == 'delete') onDelete();
            if (val == 'default') onSetDefault();
          },
        ),
      ),
    );
  }
}

// ── Card Type Badge ─────────────────────────────────────────
class _CardTypeBadge extends StatelessWidget {
  final String type;

  const _CardTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final config = switch (type) {
      'visa' => ('VISA', const Color(0xFF1A1F71), Colors.white),
      'mastercard' => ('MC', const Color(0xFFEB001B), Colors.white),
      'rupay' => ('RuPay', const Color(0xFF097A44), Colors.white),
      _ => ('CARD', Colors.grey, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.$2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config.$1,
        style: TextStyle(
          color: config.$3,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Default Badge ───────────────────────────────────────────
class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          color: Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Chip ────────────────────────────────────────────────
class _AppChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AppChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  label[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String letter;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.letter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
