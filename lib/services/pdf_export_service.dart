import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/shift_model.dart';
import 'package:flutter/material.dart' show DateTimeRange;

class PdfExportService {
  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormat = DateFormat('dd MMM yyyy HH:mm');
  final shortDate = DateFormat('dd MMM yyyy');

  // --- SHIFT REPORT ---
  Future<Uint8List> generateShiftReport(
    List<Shift> shifts,
    DateTimeRange? dateRange,
    String userName,
  ) async {
    final pdf = pw.Document();

    double totalDiff = 0;
    double totalDeficit = 0;
    double totalActual = 0;
    int closedShifts = 0;

    for (var s in shifts) {
      if (s.status == 'closed') {
        closedShifts++;
        totalDiff += s.difference;
        if (s.difference < 0) totalDeficit += s.difference;
        totalActual += (s.actualCash ?? 0);
      }
    }

    final period = dateRange != null
        ? '${shortDate.format(dateRange.start)} - ${shortDate.format(dateRange.end)}'
        : 'Semua Tanggal';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader('LAPORAN SHIFT KASIR', period, userName),
            pw.SizedBox(height: 20),
            _buildShiftSummary(
              shifts.length,
              closedShifts,
              totalActual,
              totalDiff,
              totalDeficit,
            ),
            pw.SizedBox(height: 24),
            _buildShiftTable(shifts),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- SALES REPORT ---
  Future<Uint8List> generateSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    required String userName,
    required double totalRevenue,
    required int totalOrders,
    required List<Map<String, dynamic>> topProducts,
    required Map<String, int> orderStats,
    required List<Map<String, dynamic>> salesData,
  }) async {
    final pdf = pw.Document();
    final period =
        '${shortDate.format(startDate)} - ${shortDate.format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4, // Portrait biasanya cukup untuk sales
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader('LAPORAN PENJUALAN', period, userName),
            pw.SizedBox(height: 20),
            _buildSalesSummary(totalRevenue, totalOrders, orderStats),
            pw.SizedBox(height: 24),
            pw.Text(
              'Produk Terlaris (Top 5)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildTopProductsTable(topProducts),
            pw.SizedBox(height: 24),
            pw.Text(
              'Rincian Tren Penjualan',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildSalesTrendTable(salesData, startDate, endDate),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- SHARED WIDGETS ---

  pw.Widget _buildHeader(String title, String period, String userName) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'POS System Report',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Periode: $period'),
            pw.Text('Dicetak oleh: $userName'),
            pw.Text('Tanggal Cetak: ${dateFormat.format(DateTime.now())}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Text(
          'Dokumen ini digenerate secara otomatis oleh POS System.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryItem(
    String label,
    String value, {
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            color: color ?? PdfColors.black,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // --- SHIFT WIDGETS ---

  pw.Widget _buildShiftSummary(
    int total,
    int closed,
    double totalActual,
    double totalDiff,
    double totalDeficit,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Shift', '$total'),
          _buildSummaryItem('Total Closed', '$closed'),
          _buildSummaryItem(
            'Total Uang Aktual',
            currencyFormat.format(totalActual),
          ),
          _buildSummaryItem(
            'Net Selisih',
            currencyFormat.format(totalDiff),
            color: totalDiff >= 0 ? PdfColors.teal : PdfColors.red,
          ),
          _buildSummaryItem(
            'Total Defisit',
            currencyFormat.format(totalDeficit),
            color: PdfColors.red700,
            isBold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildShiftTable(List<Shift> shifts) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'KASIR',
        'MULAI',
        'SELESAI',
        'MODAL',
        'SISTEM',
        'AKTUAL',
        'SELISIH',
        'STATUS',
      ],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
        7: pw.Alignment.center,
      },
      data: shifts.map((s) {
        final isClosed = s.status == 'closed';
        final diff = s.difference;
        final isDeficit = diff < 0;

        return [
          s.cashierName ?? '-',
          dateFormat.format(s.startTime),
          s.endTime != null ? dateFormat.format(s.endTime!) : '-',
          currencyFormat.format(s.startCash),
          currencyFormat.format(s.expectedCash),
          isClosed ? currencyFormat.format(s.actualCash ?? 0) : '-',
          isClosed ? currencyFormat.format(diff) : '-',
          isClosed ? (isDeficit ? 'DEFISIT' : 'OK') : 'OPEN',
        ];
      }).toList(),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  // --- SALES WIDGETS ---

  pw.Widget _buildSalesSummary(
    double totalRevenue,
    int totalOrders,
    Map<String, int> stats,
  ) {
    // Hitung rata-rata
    double avgOrder = totalOrders > 0 ? totalRevenue / totalOrders : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total Revenue',
            currencyFormat.format(totalRevenue),
            color: PdfColors.green700,
            isBold: true,
          ),
          _buildSummaryItem('Total Order', '$totalOrders'),
          _buildSummaryItem('Rata-rata Order', currencyFormat.format(avgOrder)),
          _buildSummaryItem('Sukses', '${stats['completed'] ?? 0}'),
          _buildSummaryItem('Batal', '${stats['cancelled'] ?? 0}'),
        ],
      ),
    );
  }

  pw.Widget _buildTopProductsTable(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return pw.Text('Tidak ada data produk.');
    }
    return pw.TableHelper.fromTextArray(
      headers: ['PRODUK', 'KATEGORI', 'TERJUAL', 'REVENUE'],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      data: products.map((p) {
        return [
          p['name'] ?? '-',
          p['category'] ?? '-',
          '${p['totalSold'] ?? 0}',
          currencyFormat.format(p['revenue'] ?? 0),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildSalesTrendTable(
    List<Map<String, dynamic>> data,
    DateTime start,
    DateTime end,
  ) {
    if (data.isEmpty) return pw.Text('Tidak ada data penjualan.');

    // Cek apakah hourly atau daily
    bool isHourly =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    return pw.TableHelper.fromTextArray(
      headers: [isHourly ? 'JAM' : 'TANGGAL', 'TOTAL REVENUE'],
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
      data: data.map((d) {
        String label = '-';
        if (isHourly) {
          label = '${d['hour']}:00';
        } else {
          // Format tanggal yyyy-MM-dd ke dd MMM yyyy
          try {
            final dt = DateTime.parse(d['date']);
            label = shortDate.format(dt);
          } catch (e) {
            label = d['date'] ?? '-';
          }
        }
        return [label, currencyFormat.format(d['total'] ?? 0)];
      }).toList(),
    );
  }
}
