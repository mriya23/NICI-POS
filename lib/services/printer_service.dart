import 'dart:io';
import 'package:esc_pos_utils_updated/esc_pos_utils_updated.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../services/bluetooth_printer_service.dart';
import '../utils/formatters.dart';
import '../providers/settings_provider.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();

  factory PrinterService() => _instance;

  PrinterService._internal();

  Future<void> printReceipt(Order order, SettingsProvider settings) async {
    if (!kIsWeb) {
      final btService = BluetoothPrinterService();
      bool printedViaBluetooth = false;

      try {
        await btService.init();
        if (btService.connectedDeviceId != null) {
          final bytes = await _buildEscPosReceipt(order, settings);
          printedViaBluetooth = await btService.printReceipt(bytes);
        }
      } catch (_) {
        printedViaBluetooth = false;
      } finally {
        btService.dispose();
      }

      if (printedViaBluetooth) {
        return;
      }
    }

    final pdf = pw.Document();

    // Use the same formatters as Digital Receipt
    final dateStr = Formatters.formatReceiptDate(order.createdAt);
    final timeStr = Formatters.formatReceiptTime(order.createdAt);

    // Load Logo
    pw.MemoryImage? logoImage;
    if (settings.companyLogo.isNotEmpty) {
      final file = File(settings.companyLogo);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Logo ---
              if (logoImage != null)
                pw.Center(
                  child: pw.Container(
                    width: 60,
                    height: 60,
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Image(logoImage),
                  ),
                )
              else
                // Matches Admin Preview Placeholder logic if needed, or just skip
                pw.Container(),

              // --- Header ---
              pw.Center(
                child: pw.Text(
                  settings.companyName.toUpperCase(),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  settings.companyAddress,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Center(
                child: pw.Text(
                  settings.companyPhone,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),

              // --- Payment Successful ---
              pw.Center(
                child: pw.Text(
                  settings.tr('payment_successful'),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              pw.Divider(thickness: 0.5),

              // --- Order Info ---
              pw.SizedBox(height: 8),
              _buildInfoRow(
                settings.tr('order_number'),
                '#${order.orderNumber}',
              ),
              pw.SizedBox(height: 4),
              _buildInfoRow(settings.tr('order_date'), dateStr),
              pw.SizedBox(height: 4),
              _buildInfoRow('Time', timeStr),
              if (order.customerName != null &&
                  order.customerName!.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                _buildInfoRow(settings.tr('customer'), order.customerName!),
              ],
              pw.SizedBox(height: 4),
              _buildInfoRow(
                settings.tr('order_type_label'),
                order.isDineIn
                    ? settings.tr('dine_in')
                    : settings.tr('take_away'),
              ),
              pw.SizedBox(height: 4),
              _buildInfoRow(settings.tr('cashier'), order.cashierName ?? "-"),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),

              // --- Items Header ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    settings.tr('items'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    settings.tr('price'),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // --- Items List ---
              ...order.items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Qty
                      pw.Text(
                        '${item.quantity}x',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      // Name
                      pw.Expanded(
                        child: pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      // Subtotal
                      pw.Text(
                        settings.formatCurrency(item.price * item.quantity),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),

              // --- Summaries ---
              _buildSummaryRow(
                settings.tr('subtotal'),
                settings.formatCurrency(order.subtotal),
              ),
              if (order.tax > 0) ...[
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  settings.tr('tax'),
                  settings.formatCurrency(order.tax),
                ),
              ],
              if (order.discount > 0) ...[
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  settings.tr('discount'),
                  '-${settings.formatCurrency(order.discount)}',
                ),
              ],

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),

              // --- Total ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    settings.tr('total'),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  pw.Text(
                    settings.formatCurrency(order.total),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 12),

              // --- Payment Info ---
              _buildInfoRow(
                settings.tr('payment_method'),
                order.paymentMethod?.toString().split('.').last.toUpperCase() ??
                    "CASH",
              ),
              if (order.amountPaid != null) ...[
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  settings.tr('amount_paid'),
                  settings.formatCurrency(order.amountPaid!),
                ),
              ],
              if ((order.change ?? 0) > 0) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      settings.tr('change'),
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      settings.formatCurrency(order.change ?? 0),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 24),

              // --- Barcode ---
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: order.orderNumber,
                  width: 200,
                  height: 50,
                  drawText: true,
                  textStyle: const pw.TextStyle(fontSize: 10, letterSpacing: 3),
                ),
              ),

              pw.SizedBox(height: 24),

              // --- Footer ---
              if (settings.receiptHeader.isNotEmpty) ...[
                pw.Text(
                  settings.receiptHeader,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
              ],

              if (settings.receiptFooter.isNotEmpty) ...[
                pw.Text(
                  settings.receiptFooter,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
              ],

              pw.Center(
                child: pw.Text(
                  settings.tr('come_again'),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt-${order.orderNumber}',
    );
  }

  Future<List<int>> _buildEscPosReceipt(
    Order order,
    SettingsProvider settings,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final dateStr = Formatters.formatReceiptDate(order.createdAt);
    final timeStr = Formatters.formatReceiptTime(order.createdAt);

    if (settings.companyName.isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings.companyName.toUpperCase(),
          styles: PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      );
    }

    if (settings.companyAddress.isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings.companyAddress,
          styles: PosStyles(align: PosAlign.center),
        ),
      );
    }

    if (settings.companyPhone.isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings.companyPhone,
          styles: PosStyles(align: PosAlign.center),
        ),
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.text(
        settings.tr('payment_successful'),
        styles: PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.row([
        PosColumn(
          text: settings.tr('order_number'),
          width: 6,
        ),
        PosColumn(
          text: '#${order.orderNumber}',
          width: 6,
          styles: PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: settings.tr('order_date'), width: 6),
        PosColumn(
          text: dateStr,
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Time', width: 6),
        PosColumn(
          text: timeStr,
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    if (order.customerName != null && order.customerName!.isNotEmpty) {
      bytes.addAll(
        generator.row([
          PosColumn(text: settings.tr('customer'), width: 6),
          PosColumn(
            text: order.customerName!,
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(
      generator.row([
        PosColumn(text: settings.tr('order_type_label'), width: 6),
        PosColumn(
          text: order.isDineIn
              ? settings.tr('dine_in')
              : settings.tr('take_away'),
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: settings.tr('cashier'), width: 6),
        PosColumn(
          text: order.cashierName ?? '-',
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.row([
        PosColumn(
          text: settings.tr('items'),
          width: 8,
          styles: PosStyles(bold: true),
        ),
        PosColumn(
          text: settings.tr('price'),
          width: 4,
          styles: PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );
    bytes.addAll(generator.hr());

    for (final item in order.items) {
      bytes.addAll(
        generator.row([
          PosColumn(
            text: '${item.quantity}x',
            width: 2,
            styles: PosStyles(bold: true),
          ),
          PosColumn(text: item.productName, width: 6),
          PosColumn(
            text: settings.formatCurrency(item.price * item.quantity),
            width: 4,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.row([
        PosColumn(text: settings.tr('subtotal'), width: 6),
        PosColumn(
          text: settings.formatCurrency(order.subtotal),
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    if (order.tax > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(text: settings.tr('tax'), width: 6),
          PosColumn(
            text: settings.formatCurrency(order.tax),
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    if (order.discount > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(text: settings.tr('discount'), width: 6),
          PosColumn(
            text: '-${settings.formatCurrency(order.discount)}',
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.row([
        PosColumn(
          text: settings.tr('total'),
          width: 6,
          styles: PosStyles(bold: true),
        ),
        PosColumn(
          text: settings.formatCurrency(order.total),
          width: 6,
          styles: PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );

    bytes.addAll(generator.hr());

    bytes.addAll(
      generator.row([
        PosColumn(text: settings.tr('payment_method'), width: 6),
        PosColumn(
          text: order.paymentMethod?.toString().split('.').last.toUpperCase() ??
              'CASH',
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]),
    );

    if (order.amountPaid != null) {
      bytes.addAll(
        generator.row([
          PosColumn(text: settings.tr('amount_paid'), width: 6),
          PosColumn(
            text: settings.formatCurrency(order.amountPaid!),
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    if ((order.change ?? 0) > 0) {
      bytes.addAll(
        generator.row([
          PosColumn(text: settings.tr('change'), width: 6),
          PosColumn(
            text: settings.formatCurrency(order.change ?? 0),
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.feed(1));

    if (settings.receiptHeader.isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings.receiptHeader,
          styles: PosStyles(align: PosAlign.center, bold: true),
        ),
      );
      bytes.addAll(generator.feed(1));
    }

    if (settings.receiptFooter.isNotEmpty) {
      bytes.addAll(
        generator.text(
          settings.receiptFooter,
          styles: PosStyles(align: PosAlign.center),
        ),
      );
      bytes.addAll(generator.feed(1));
    }

    bytes.addAll(
      generator.text(
        settings.tr('come_again'),
        styles: PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
