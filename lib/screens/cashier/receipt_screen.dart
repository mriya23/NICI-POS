import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../services/printer_service.dart';
import '../../providers/settings_provider.dart';

class ReceiptScreen extends StatelessWidget {
  final Order order;

  const ReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(settings.tr('digital_receipt')),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await PrinterService().printReceipt(order, settings);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Print failed: $e')));
                }
              }
            },
            icon: const Icon(Icons.print),
            tooltip: 'Print Receipt',
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
            icon: const Icon(Icons.share),
            tooltip: 'Share Receipt',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: isMobile ? double.infinity : 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.elevatedShadowList,
            ),
            child: Column(
              children: [
                // Receipt Header
                _buildReceiptHeader(settings),

                const Divider(height: 1),

                // Order Info
                _buildOrderInfo(settings),

                const Divider(height: 1),

                // Items List
                _buildItemsList(settings),

                const Divider(height: 1),

                // Totals
                _buildTotals(settings),

                const Divider(height: 1),

                // Payment Info
                _buildPaymentInfo(settings),

                const Divider(height: 1),

                // Barcode
                _buildBarcode(),

                // Footer
                _buildFooter(settings),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    settings.tr('new_order'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await PrinterService().printReceipt(order, settings);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Print failed: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    settings.tr('print_receipt'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptHeader(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          if (settings.companyLogo.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Builder(
                builder: (context) {
                  Widget placeholder() => Container(
                    color: AppColors.primaryBg,
                    child: const Icon(
                      Icons.store_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  );

                  if (kIsWeb) {
                    if (settings.companyLogo.startsWith('http') ||
                        settings.companyLogo.startsWith('data:')) {
                      return Image.network(
                        settings.companyLogo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => placeholder(),
                      );
                    }
                    return placeholder();
                  }

                  return Image.file(
                    File(settings.companyLogo),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholder(),
                  );
                },
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.store_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),

          // Title
          Text(
            settings.companyName.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            settings.companyAddress,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          Text(
            settings.companyPhone,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          const Divider(),

          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  settings.tr('payment_successful'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(settings.tr('order_number'), '#${order.orderNumber}'),
          const SizedBox(height: 8),
          _buildInfoRow(
            settings.tr('order_date'),
            Formatters.formatReceiptDate(order.createdAt),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Time', Formatters.formatReceiptTime(order.createdAt)),
          const SizedBox(height: 8),
          if (order.customerName != null && order.customerName!.isNotEmpty) ...[
            _buildInfoRow(settings.tr('customer'), order.customerName!),
            const SizedBox(height: 8),
          ],
          _buildInfoRow(
            settings.tr('order_type_label'),
            order.isDineIn ? settings.tr('dine_in') : settings.tr('take_away'),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Cashier', order.cashierName ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settings.tr('items'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                settings.tr('price'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => _buildItemRow(item, settings)),
        ],
      ),
    );
  }

  Widget _buildItemRow(OrderItem item, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Qty
          Text(
            '${item.quantity}x',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          // Name + Price per item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Total Price
          Text(
            settings.formatCurrency(item.subtotal),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTotalRow(settings.tr('subtotal'), order.subtotal, settings),
          if (order.tax > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(settings.tr('tax'), order.tax, settings),
          ],
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            _buildTotalRow(
              settings.tr('discount'),
              -order.discount,
              settings,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settings.tr('total'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                settings.formatCurrency(order.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    SettingsProvider settings, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          isDiscount
              ? '-${settings.formatCurrency(amount.abs())}'
              : settings.formatCurrency(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoRow(
            settings.tr('payment_method'),
            order.paymentMethod?.toString().split('.').last.toUpperCase() ??
                'CASH',
          ),
          if (order.amountPaid != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              settings.tr('amount_paid'),
              settings.formatCurrency(order.amountPaid!),
            ),
          ],
          if (order.change != null && order.change! > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  settings.tr('change'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  settings.formatCurrency(order.change!),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBarcode() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: order.orderNumber,
            width: 200,
            height: 50,
            drawText: false,
          ),
          const SizedBox(height: 8),
          Text(
            order.orderNumber,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          if (settings.receiptHeader.isNotEmpty) ...[
            Text(
              settings.receiptHeader,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
          ],

          if (settings.receiptFooter.isNotEmpty) ...[
            Text(
              settings.receiptFooter,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
          ],

          Text(
            settings.tr('come_again'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
