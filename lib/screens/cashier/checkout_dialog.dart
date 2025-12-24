import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../services/midtrans_service.dart';
import 'dart:async';

class CheckoutDialog extends StatefulWidget {
  final Future<bool> Function(PaymentMethod, double, String?, bool) onComplete;

  const CheckoutDialog({super.key, required this.onComplete});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  String _inputAmount = '';
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isDineIn = true;
  bool _isPercentage = false;
  bool _isProcessing = false;

  double get _amountPaid => double.tryParse(_inputAmount) ?? 0;

  double _getChange(double total) => _amountPaid - total;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      if (provider.discount > 0) {
        _discountController.text = provider.discount.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _onNumpadPress(String value) {
    setState(() {
      if (value == 'clear') {
        _inputAmount = '';
      } else if (value == 'backspace') {
        if (_inputAmount.isNotEmpty) {
          _inputAmount = _inputAmount.substring(0, _inputAmount.length - 1);
        }
      } else if (value == '.') {
        if (!_inputAmount.contains('.')) {
          _inputAmount = _inputAmount.isEmpty ? '0.' : '$_inputAmount.';
        }
      } else {
        if (_inputAmount == '0') {
          _inputAmount = value;
        } else {
          _inputAmount += value;
        }
      }
    });
  }

  void _addQuickAmount(double amount) {
    setState(() {
      _inputAmount = amount.toStringAsFixed(0);
    });
  }

  void _updateDiscount(OrderProvider provider) {
    final val = double.tryParse(_discountController.text) ?? 0;
    if (_isPercentage) {
      final amount = provider.subtotal * (val / 100);
      provider.setDiscount(amount);
    } else {
      provider.setDiscount(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        // Increased threshold to 1000 to trigger mobile layout on tablets if needed,
        // or ensure desktop layout has enough space.
        final isMobile = screenWidth < 1000;

        // Dynamic size calculation for desktop
        final dialogWidth = isMobile
            ? double.infinity
            : (screenWidth > 1200 ? 1100.0 : screenWidth * 0.95);
        final dialogHeight = isMobile
            ? screenHeight * 0.95
            : (screenHeight > 800 ? 750.0 : screenHeight * 0.95);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.background,
          insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
          child: Container(
            width: dialogWidth,
            height: isMobile
                ? null
                : dialogHeight, // Fixed height for desktop to force layout fit
            constraints: BoxConstraints(maxHeight: screenHeight * 0.95),
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: isMobile
                ? _buildMobileLayout(context)
                : _buildDesktopLayout(context),
          ),
        );
      },
    );
  }

  // --- Mobile Layout ---
  Widget _buildMobileLayout(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final provider = Provider.of<OrderProvider>(context);
    final totalAmount = provider.total;
    final change = _getChange(totalAmount);
    final suggestions = _buildSuggestions(context, totalAmount);

    return Column(
      children: [
        // Mobile Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              settings.tr('checkout'),
              style: const TextStyle(
                fontSize: 22, // Slightly smaller for mobile
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 24),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.tr('total_amount'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.formatCurrency(totalAmount),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Input Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.centerRight,
                  child: Text(
                    _inputAmount.isEmpty
                        ? settings.formatCurrency(0)
                        : settings.formatCurrency(_amountPaid),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Suggestion Chips (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestions.map((amount) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () => _addQuickAmount(amount),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 36), // More compact
                          ),
                          child: Text(
                            settings.formatCurrency(amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Numpad - Compact
                SizedBox(
                  height: 280,
                  child: Column(
                    children: [
                      _buildNumpadRow(['1', '2', '3'], compact: true),
                      const SizedBox(height: 8),
                      _buildNumpadRow(['4', '5', '6'], compact: true),
                      const SizedBox(height: 8),
                      _buildNumpadRow(['7', '8', '9'], compact: true),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            _buildNumpadButton('.', flex: 1, compact: true),
                            const SizedBox(width: 8),
                            _buildNumpadButton('0', flex: 1, compact: true),
                            const SizedBox(width: 8),
                            _buildNumpadButton(
                              'backspace',
                              flex: 1,
                              icon: Icons.backspace_outlined,
                              isAction: true,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Form Fields
                _buildCustomerSection(settings, compact: true),
                const SizedBox(height: 12),
                _buildDiscountSection(settings, provider, compact: true),
                const SizedBox(height: 12),
                _buildPaymentMethodSection(settings, compact: true),

                const SizedBox(height: 16),

                // Change Display
                if (_selectedPayment == PaymentMethod.cash)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:
                          (_amountPaid >= totalAmount &&
                              _inputAmount.isNotEmpty)
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            (_amountPaid >= totalAmount &&
                                _inputAmount.isNotEmpty)
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          settings.tr('change'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          settings.formatCurrency(change >= 0 ? change : 0),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: (_amountPaid >= totalAmount)
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Mobile Actions
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(settings.tr('cancel')),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      (_amountPaid >= totalAmount ||
                          _selectedPayment != PaymentMethod.cash)
                      ? (_isProcessing ? null : _processPayment)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    settings.tr('complete_payment'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Desktop Layout ---
  Widget _buildDesktopLayout(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final provider = Provider.of<OrderProvider>(context);
    final totalAmount = provider.total;
    final change = _getChange(totalAmount);
    final suggestions = _buildSuggestions(
      context,
      totalAmount,
    ).take(4).toList();

    return Column(
      children: [
        // Header - Compact
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Checkout',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                // Total inline with header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    settings.formatCurrency(totalAmount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 24),
              color: AppColors.textSecondary,
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Column (Details) - More compact
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order Type
                    Text(
                      'Tipe Pesanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 60,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildCompactOrderTypeButton(
                              icon: Icons.restaurant_rounded,
                              label: 'Dine In',
                              isSelected: _isDineIn,
                              onTap: () => setState(() => _isDineIn = true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactOrderTypeButton(
                              icon: Icons.shopping_bag_rounded,
                              label: 'Take Away',
                              isSelected: !_isDineIn,
                              onTap: () => setState(() => _isDineIn = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    const SizedBox(height: 14),
                    // Customer Name
                    Text(
                      'Pelanggan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        hintText: 'Nama pelanggan (opsional)',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),

                    const SizedBox(height: 14),
                    // Discount Section
                    Text(
                      'Diskon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // Quick percents row
                          Row(
                            children: [5, 10, 15, 20]
                                .map(
                                  (p) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (_isPercentage &&
                                                _discountController.text ==
                                                    p.toString()) {
                                              _discountController.clear();
                                            } else {
                                              _isPercentage = true;
                                              _discountController.text = p
                                                  .toString();
                                            }
                                          });
                                          _updateDiscount(provider);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (_isPercentage &&
                                                    _discountController.text ==
                                                        p.toString())
                                                ? AppColors.primary
                                                : AppColors.primary.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$p%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (_isPercentage &&
                                                      _discountController
                                                              .text ==
                                                          p.toString())
                                                  ? Colors.white
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          // Discount applied indicator
                          if (provider.discount > 0) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.discount_outlined,
                                        size: 16,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Potongan',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '-${settings.formatCurrency(provider.discount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    const SizedBox(height: 14),
                    // Payment Method Section
                    Text(
                      'Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCompactPaymentButton(
                            icon: Icons.attach_money_rounded,
                            label: 'CASH',
                            isSelected: _selectedPayment == PaymentMethod.cash,
                            onTap: () => setState(
                              () => _selectedPayment = PaymentMethod.cash,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildCompactPaymentButton(
                            icon: Icons.qr_code_rounded,
                            label: 'QRIS',
                            isSelected: _selectedPayment == PaymentMethod.qris,
                            onTap: () => setState(
                              () => _selectedPayment = PaymentMethod.qris,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Change Display - At bottom
                    if (_selectedPayment == PaymentMethod.cash)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (_amountPaid >= totalAmount &&
                                  _inputAmount.isNotEmpty)
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                (_amountPaid >= totalAmount &&
                                    _inputAmount.isNotEmpty)
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Kembalian',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              settings.formatCurrency(change >= 0 ? change : 0),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _amountPaid >= totalAmount
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Divider
              Container(
                width: 1,
                color: AppColors.border,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),

              // Right Column (Numpad) - Optimized
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // Input Display - Compact
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.centerRight,
                      child: Text(
                        _inputAmount.isEmpty
                            ? 'Rp 0'
                            : settings.formatCurrency(_amountPaid),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Amount Suggestions
                    Row(
                      children: suggestions.map((amount) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ElevatedButton(
                              onPressed: () => _addQuickAmount(amount),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                settings.formatCurrency(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Numpad - Flexible
                    Expanded(
                      child: Column(
                        children: [
                          _buildNumpadRow(['1', '2', '3']),
                          const SizedBox(height: 6),
                          _buildNumpadRow(['4', '5', '6']),
                          const SizedBox(height: 6),
                          _buildNumpadRow(['7', '8', '9']),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Row(
                              children: [
                                _buildNumpadButton('.', flex: 1),
                                const SizedBox(width: 6),
                                _buildNumpadButton('0', flex: 1),
                                const SizedBox(width: 6),
                                _buildNumpadButton(
                                  'backspace',
                                  flex: 1,
                                  icon: Icons.backspace_outlined,
                                  isAction: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Action Buttons - Compact
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed:
                                  (_amountPaid >= totalAmount ||
                                      _selectedPayment != PaymentMethod.cash)
                                  ? (_isProcessing ? null : _processPayment)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isProcessing
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Selesaikan Pembayaran',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactOrderTypeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPaymentButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildCustomerSection(
    SettingsProvider settings, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order Type - More prominent and clear
        Text(
          'Tipe Pesanan',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOrderTypeButton(
                icon: Icons.restaurant_rounded,
                label: 'Dine In',
                subtitle: 'Makan di tempat',
                isSelected: _isDineIn,
                onTap: () => setState(() => _isDineIn = true),
                compact: compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOrderTypeButton(
                icon: Icons.shopping_bag_rounded,
                label: 'Take Away',
                subtitle: 'Bawa pulang',
                isSelected: !_isDineIn,
                onTap: () => setState(() => _isDineIn = false),
                compact: compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Customer Name - Optional
        Text(
          'Nama Pelanggan (Opsional)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _customerNameController,
          decoration: InputDecoration(
            hintText: 'Masukkan nama...',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 10 : 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildOrderTypeButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: compact ? 20 : 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (!compact)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: compact ? 18 : 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection(
    SettingsProvider settings,
    OrderProvider provider, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diskon',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (provider.discount > 0)
              TextButton.icon(
                onPressed: () {
                  _discountController.clear();
                  provider.setDiscount(0);
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick discount buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [5, 10, 15, 20].map((percent) {
              final isSelected =
                  _isPercentage &&
                  _discountController.text == percent.toString();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isPercentage = true;
                      _discountController.text = percent.toString();
                    });
                    _updateDiscount(provider);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '$percent%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Custom discount input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                onChanged: (val) => _updateDiscount(provider),
                decoration: InputDecoration(
                  hintText: 'Masukkan nilai diskon',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: compact ? 10 : 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  prefixIcon: Icon(
                    _isPercentage ? Icons.percent : Icons.payments_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixText: _isPercentage ? '%' : 'Rp',
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            // Toggle type
            Container(
              height: compact ? 44 : 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDiscountTypeToggle(
                    icon: Icons.percent,
                    label: '%',
                    isSelected: _isPercentage,
                    isLeft: true,
                    onTap: () {
                      setState(() => _isPercentage = true);
                      _updateDiscount(provider);
                    },
                  ),
                  Container(width: 1, color: AppColors.border),
                  _buildDiscountTypeToggle(
                    icon: Icons.payments_outlined,
                    label: 'Rp',
                    isSelected: !_isPercentage,
                    isLeft: false,
                    onTap: () {
                      setState(() => _isPercentage = false);
                      _updateDiscount(provider);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        // Discount result display
        if (provider.discount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Potongan:',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '- ${settings.formatCurrency(provider.discount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscountTypeToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isLeft,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : null,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(11) : Radius.zero,
            right: !isLeft ? const Radius.circular(11) : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(
    SettingsProvider settings, {
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          settings.tr('payment_method'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: PaymentMethod.values
              .where((method) => method != PaymentMethod.card)
              .map((method) {
                final isSelected = _selectedPayment == method;
                IconData icon;
                switch (method) {
                  case PaymentMethod.cash:
                    icon = Icons.attach_money_rounded;
                    break;
                  case PaymentMethod.card:
                    icon = Icons.credit_card_rounded;
                    break;
                  case PaymentMethod.qris:
                    icon = Icons.qr_code_rounded;
                    break;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPayment = method),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: EdgeInsets.symmetric(
                        vertical: compact ? 12 : 14,
                      ), // Compact padding
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? AppShadows.cardShadowList
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: compact ? 22 : 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 12 : 13,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }

  List<double> _buildSuggestions(BuildContext context, double totalAmount) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    List<double> suggestions = [];
    if (settings.currency == AppCurrency.idr) {
      suggestions = [totalAmount];
      final denominations = [2000, 5000, 10000, 20000, 50000, 100000];
      for (final denom in denominations) {
        if (totalAmount < denom.toDouble()) {
          suggestions.add(denom.toDouble());
        }
      }
    } else {
      suggestions = [totalAmount];
      final denominations = [10, 20, 50, 100, 200];
      for (final denom in denominations) {
        if (totalAmount < denom.toDouble()) {
          suggestions.add(denom.toDouble());
        }
      }
    }
    return suggestions.where((s) => s >= totalAmount).toSet().toList()..sort();
  }

  Widget _buildNumpadRow(List<String> values, {bool compact = false}) {
    return Expanded(
      child: Row(
        children: [
          _buildNumpadButton(values[0], flex: 1, compact: compact),
          const SizedBox(width: 10),
          _buildNumpadButton(values[1], flex: 1, compact: compact),
          const SizedBox(width: 10),
          _buildNumpadButton(values[2], flex: 1, compact: compact),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(
    String value, {
    required int flex,
    IconData? icon,
    bool isAction = false,
    bool compact = false,
  }) {
    return Expanded(
      flex: flex,
      child: Material(
        color: isAction ? AppColors.error.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _onNumpadPress(value),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAction
                    ? Colors.transparent
                    : AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: icon != null
                ? Icon(
                    icon,
                    color: isAction ? AppColors.error : AppColors.textPrimary,
                    size: compact ? 22 : 24,
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: compact ? 20 : 22,
                      fontWeight: FontWeight.w600,
                      color: isAction ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final totalAmount = provider.total;

    if (_selectedPayment == PaymentMethod.cash && _amountPaid < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran tunai kurang dari total tagihan!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Determine the amount to record. For QRIS, it's always the full total.
    final finalAmount = _selectedPayment == PaymentMethod.qris
        ? totalAmount
        : _amountPaid;

    if (_selectedPayment == PaymentMethod.qris) {
      if (settings.isMidtransEnabled) {
        await _processMidtransPayment(totalAmount, settings);
      } else {
        // Manual QRIS
        await _showManualQrisDialog(totalAmount);
      }
    } else {
      // Manual Cash
      await _executeOrderCompletion(finalAmount);
    }
  }

  Future<void> _processMidtransPayment(
    double amount,
    SettingsProvider settings,
  ) async {
    setState(() => _isProcessing = true);

    final orderId =
        'MID-${DateTime.now().millisecondsSinceEpoch}'; // Simple unique ID
    final service = MidtransService(
      serverKey: settings.midtransServerKey,
      isProduction: false, // Assuming sandbox for now
    );

    try {
      final result = await service.createQrisTransaction(
        orderId: orderId,
        amount: amount.toInt(),
      );

      if (!mounted) return;
      setState(() => _isProcessing = false); // Stop spinning on main dialog

      // Check actions for generate-qr-code
      String? qrString;
      if (result['actions'] != null) {
        for (final action in result['actions']) {
          if (action['name'] == 'generate-qr-code') {
            qrString = action['url'];
            break;
          }
        }
      }

      // Fallback if direct qr_string exists (depends on API version)
      if (qrString == null && result['qr_string'] != null) {
        qrString = result['qr_string'];
      }

      if (qrString != null) {
        await _showQrDialog(qrString, orderId, service, amount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendapatkan QR Code dari Midtrans'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showQrDialog(
    String qrContent,
    String orderId,
    MidtransService service,
    double amount,
  ) async {
    Timer? timer;
    bool isPaid = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Start polling
        timer = Timer.periodic(const Duration(seconds: 3), (t) async {
          final status = await service.checkTransactionStatus(orderId);
          if (status == 'settlement' || status == 'capture') {
            t.cancel();
            isPaid = true;
            if (context.mounted) Navigator.pop(context); // Close QR Dialog
          }
        });

        return AlertDialog(
          title: const Text('Scan QRIS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: BarcodeWidget(
                  barcode: Barcode.qrCode(),
                  data: qrContent,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Silakan scan QR Code di atas'),
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Menunggu pembayaran...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                timer?.cancel();
                service.cancelTransaction(orderId); // Cancel on backend
                Navigator.pop(context);
              },
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );

    if (isPaid) {
      await _executeOrderCompletion(amount);
    }
  }

  Future<void> _showManualQrisDialog(double amount) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_2_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran QRIS',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tunjukkan QRIS Toko kepada pelanggan untuk melakukan pembayaran.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Tagihan:'),
                    Text(
                      settings.formatCurrency(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _executeOrderCompletion(amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sudah Dibayar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeOrderCompletion(double amount) async {
    setState(() => _isProcessing = true);
    final success = await widget.onComplete(
      _selectedPayment,
      amount,
      _customerNameController.text,
      _isDineIn,
    );
    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() => _isProcessing = false);
      }
    }
  }
}
