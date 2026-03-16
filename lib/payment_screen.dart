import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/cart_provider.dart';
import 'package:shopping_app/payment_methods_provider.dart';
import 'package:shopping_app/success_screen.dart';

enum PaymentMethod { upi, card, wallet, cod }

class PaymentScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentScreen({super.key, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selected = PaymentMethod.upi;
  bool _isProcessing = false;

  String _selectedUpi = 'gpay';

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _upiIdController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_isProcessing) return;

    //Hard guard — wallet balance check
    if (_selected == PaymentMethod.wallet) {
      final walletBalance = context
          .read<PaymentMethodsProvider>()
          .walletBalance;
      if (widget.totalAmount > walletBalance) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Insufficient wallet balance. Please choose another payment method.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      await context.read<CartProvider>().createOrder();

      //Deduct wallet balance after successful order
      if (_selected == PaymentMethod.wallet) {
        await context.read<PaymentMethodsProvider>().topUpWallet(
          -widget.totalAmount,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = context.watch<PaymentMethodsProvider>().walletBalance;
    final isWalletInsufficient =
        _selected == PaymentMethod.wallet && widget.totalAmount > walletBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Amount Summary ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount to Pay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '\$${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Select Payment Method : ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // ── UPI ─────────────────────────────────────────
            _PaymentTile(
              title: 'UPI',
              subtitle: 'GPay, PhonePe, Paytm & more',
              icon: Icons.account_balance_wallet_outlined,
              isSelected: _selected == PaymentMethod.upi,
              onTap: () => setState(() => _selected = PaymentMethod.upi),
              child: _selected == PaymentMethod.upi
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _UpiChip(
                              label: 'GPay',
                              color: const Color(0xFF4285F4),
                              selected: _selectedUpi == 'gpay',
                              onTap: () =>
                                  setState(() => _selectedUpi = 'gpay'),
                            ),
                            _UpiChip(
                              label: 'PhonePe',
                              color: const Color(0xFF5F259F),
                              selected: _selectedUpi == 'phonepe',
                              onTap: () =>
                                  setState(() => _selectedUpi = 'phonepe'),
                            ),
                            _UpiChip(
                              label: 'Paytm',
                              color: const Color(0xFF00BAF2),
                              selected: _selectedUpi == 'paytm',
                              onTap: () =>
                                  setState(() => _selectedUpi = 'paytm'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _upiIdController,
                          decoration: InputDecoration(
                            labelText: 'Or enter UPI ID',
                            hintText: 'yourname@upi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 10),

            // ── Card ─────────────────────────────────────────
            _PaymentTile(
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, RuPay',
              icon: Icons.credit_card,
              isSelected: _selected == PaymentMethod.card,
              onTap: () => setState(() => _selected = PaymentMethod.card),
              child: _selected == PaymentMethod.card
                  ? Column(
                      children: [
                        _buildTextField(
                          controller: _cardNumberController,
                          label: 'Card Number',
                          hint: '1234 5678 9012 3456',
                          maxLength: 19,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _expiryController,
                                label: 'Expiry',
                                hint: 'MM/YY',
                                maxLength: 5,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _cvvController,
                                label: 'CVV',
                                hint: '•••',
                                maxLength: 3,
                                keyboardType: TextInputType.number,
                                obscure: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name on Card',
                          hint: 'John Doe',
                        ),
                      ],
                    )
                  : null,
            ),

            const SizedBox(height: 10),

            // ── Wallet ───────────────────────────────────────
            _PaymentTile(
              title: 'Wallet',
              subtitle:
                  'Available balance: \$${walletBalance.toStringAsFixed(2)}',
              icon: Icons.account_balance_outlined,
              isSelected: _selected == PaymentMethod.wallet,
              onTap: () => setState(() => _selected = PaymentMethod.wallet),
              child: _selected == PaymentMethod.wallet
                  ? isWalletInsufficient
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Insufficient balance. Choose another method.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null
                  : null,
            ),

            const SizedBox(height: 10),

            //COD
            _PaymentTile(
              title: 'Cash on Delivery',
              subtitle: 'Pay when your order arrives',
              icon: Icons.local_shipping_outlined,
              isSelected: _selected == PaymentMethod.cod,
              onTap: () => setState(() => _selected = PaymentMethod.cod),
              child: _selected == PaymentMethod.cod
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Keep exact change ready at the time of delivery.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),

      //Pay Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              //Disabled if wallet selected but insufficient
              onPressed: _isProcessing || isWalletInsufficient
                  ? null
                  : _handlePayment,
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Processing...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : Text(
                      // Button text reflects state
                      isWalletInsufficient
                          ? 'Insufficient Balance'
                          : _selected == PaymentMethod.cod
                          ? 'Confirm Order'
                          : 'Pay \$${widget.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

// ── Reusable Payment Tile ────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            trailing: Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            onTap: onTap,
          ),
          if (child != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child!,
            ),
        ],
      ),
    );
  }
}

//UPI App Chip
class _UpiChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _UpiChip({
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
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  label[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
