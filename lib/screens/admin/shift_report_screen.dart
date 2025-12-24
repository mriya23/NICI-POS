import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../providers/shift_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/shift_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../services/pdf_export_service.dart';

class ShiftReportScreen extends StatefulWidget {
  const ShiftReportScreen({super.key});

  @override
  State<ShiftReportScreen> createState() => _ShiftReportScreenState();
}

class _ShiftReportScreenState extends State<ShiftReportScreen> {
  late Future<List<Shift>> _shiftsFuture;
  DateTimeRange? _selectedDateRange;
  String _activeFilterLabel = 'Semua Tanggal';
  final PdfExportService _pdfService = PdfExportService();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  void _loadShifts() {
    setState(() {
      _shiftsFuture = Provider.of<ShiftProvider>(
        context,
        listen: false,
      ).getAllShifts();
    });
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final shifts = await _shiftsFuture;
      // Filter sesuai yang ada di layar
      final filteredShifts = _selectedDateRange == null
          ? shifts
          : shifts.where((s) {
              final start = _selectedDateRange!.start;
              final end = _selectedDateRange!.end
                  .add(const Duration(days: 1))
                  .subtract(const Duration(seconds: 1));

              return s.startTime.isAfter(
                    start.subtract(const Duration(seconds: 1)),
                  ) &&
                  s.startTime.isBefore(end);
            }).toList();

      if (filteredShifts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak ada data untuk diekspor')),
          );
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userName = authProvider.currentUser?.name ?? 'Admin';

      final pdfBytes = await _pdfService.generateShiftReport(
        filteredShifts,
        _selectedDateRange,
        userName,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Laporan-Shift-${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal export PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // --- Date Picker Logic ---

  Future<void> _showDateFilterOptions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16, bottom: 16),
                child: Text(
                  'Filter Tanggal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              _buildFilterOption(
                icon: Icons.today_rounded,
                label: 'Hari Ini',
                onTap: () => Navigator.pop(context, 'today'),
              ),
              _buildFilterOption(
                icon: Icons.history_rounded,
                label: 'Kemarin',
                onTap: () => Navigator.pop(context, 'yesterday'),
              ),
              _buildFilterOption(
                icon: Icons.date_range_rounded,
                label: '7 Hari Terakhir',
                onTap: () => Navigator.pop(context, 'week'),
              ),
              _buildFilterOption(
                icon: Icons.calendar_month_rounded,
                label: 'Bulan Ini',
                onTap: () => Navigator.pop(context, 'month'),
              ),
              const Divider(height: 32),
              _buildFilterOption(
                icon: Icons.edit_calendar_rounded,
                label: 'Pilih Rentang Tanggal...',
                isHighlight: true,
                onTap: () => Navigator.pop(context, 'custom'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    DateTimeRange? newRange;
    String newLabel = '';

    switch (result) {
      case 'today':
        newRange = DateTimeRange(start: today, end: today);
        newLabel = 'Hari Ini';
        break;
      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        newRange = DateTimeRange(start: yesterday, end: yesterday);
        newLabel = 'Kemarin';
        break;
      case 'week':
        newRange = DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
        newLabel = '7 Hari Terakhir';
        break;
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        newRange = DateTimeRange(start: startOfMonth, end: endOfMonth);
        newLabel = 'Bulan Ini';
        break;
      case 'custom':
        final picked = await _showCustomRangeDialog();
        if (picked != null) {
          newRange = picked;
          final start = DateFormat('dd MMM').format(picked.start);
          final end = DateFormat('dd MMM').format(picked.end);
          newLabel = '$start - $end';
        }
        break;
    }

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
        _activeFilterLabel = newLabel.isNotEmpty ? newLabel : 'Custom';
      });
    }
  }

  Future<DateTimeRange?> _showCustomRangeDialog() async {
    DateTime tempStart = _selectedDateRange?.start ?? DateTime.now();
    DateTime tempEnd = _selectedDateRange?.end ?? DateTime.now();

    return await showDialog<DateTimeRange>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Pilih Rentang Tanggal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  _buildDatePickerField(
                    context,
                    label: 'Dari Tanggal',
                    selectedDate: tempStart,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStart,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          tempStart = picked;
                          if (tempEnd.isBefore(tempStart)) {
                            tempEnd = tempStart;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerField(
                    context,
                    label: 'Sampai Tanggal',
                    selectedDate: tempEnd,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEnd,
                        firstDate: tempStart,
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          tempEnd = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.all(20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTimeRange(start: tempStart, end: tempEnd),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDatePickerField(
    BuildContext context, {
    required String label,
    required DateTime selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isHighlight ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          color: isHighlight ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Colors.grey,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _resetFilter() {
    setState(() {
      _selectedDateRange = null;
      _activeFilterLabel = 'Semua Tanggal';
    });
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadShifts();
          await _shiftsFuture;
        },
        child: FutureBuilder<List<Shift>>(
          future: _shiftsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final allShifts = snapshot.data ?? [];

            // Apply Date Filter
            final shifts = _selectedDateRange == null
                ? allShifts
                : allShifts.where((s) {
                    final start = _selectedDateRange!.start;
                    final end = _selectedDateRange!.end
                        .add(const Duration(days: 1))
                        .subtract(const Duration(seconds: 1));

                    return s.startTime.isAfter(
                          start.subtract(const Duration(seconds: 1)),
                        ) &&
                        s.startTime.isBefore(end);
                  }).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterBar(),
                        const SizedBox(height: 24),
                        if (shifts.isEmpty)
                          _buildEmptyStateFiltered()
                        else ...[
                          _buildSummarySection(shifts, settings),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
                if (shifts.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildShiftCard(shifts[index], settings);
                      }, childCount: shifts.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _showDateFilterOptions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDateRange == null
                          ? Icons.calendar_today_rounded
                          : Icons.event_available_rounded,
                      color: _selectedDateRange != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _activeFilterLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _selectedDateRange != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDateRange != null)
                      InkWell(
                        onTap: _resetFilter,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Export Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPdf,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Refresh Button (Icon Only now to save space, but styled same)
          SizedBox(
            height: 48,
            width: 48,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Memuat ulang data...'),
                    duration: Duration(milliseconds: 500),
                  ),
                );
                _loadShifts();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.refresh_rounded, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateFiltered() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.filter_list_off_rounded,
            size: 60,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Tidak ada shift pada periode ini",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _loadShifts,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(List<Shift> shifts, SettingsProvider settings) {
    double totalDiff = 0;
    double totalDefisit = 0;
    int activeShifts = 0;
    int count = shifts.length;

    for (var s in shifts) {
      if (s.status == 'open') activeShifts++;
      if (s.status == 'closed') {
        totalDiff += s.difference;

        if (s.difference < 0) {
          totalDefisit += s.difference;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Shift',
                value: '$count',
                icon: Icons.receipt_long_rounded,
                color: Colors.blue,
                subValue: activeShifts > 0
                    ? '$activeShifts sedang aktif'
                    : 'Semua closed',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Selisih',
                value: settings.formatCurrency(totalDiff),
                icon: Icons.account_balance_wallet_rounded,
                color: totalDiff == 0
                    ? AppColors.success
                    : (totalDiff > 0 ? Colors.teal : AppColors.error),
                subValue: totalDiff > 0
                    ? 'Surplus (Lebih)'
                    : (totalDiff < 0 ? 'Defisit (Kurang)' : 'Balance'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Defisit',
                value: settings.formatCurrency(totalDefisit),
                icon: Icons.money_off_rounded,
                color: AppColors.error,
                subValue: 'Total Kekurangan (Lost)',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subValue,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShiftCard(Shift shift, SettingsProvider settings) {
    final isClosed = shift.status == 'closed';
    final hasDifference = shift.difference != 0;

    Color statusColor = AppColors.primary;
    if (isClosed) {
      statusColor = AppColors.success;
    }
    final statusLabel = isClosed ? 'Closed' : 'Open';

    Color diffColor = AppColors.success;
    String diffText = 'Balance Sesuai';
    String diffValuePrefix = '';

    if (isClosed && hasDifference) {
      if (shift.difference > 0) {
        diffColor = Colors.teal;
        diffText = 'Lebih (Surplus)';
        diffValuePrefix = '+';
      } else {
        diffColor = AppColors.error;
        diffText = 'Kurang (Defisit)';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.background,
                  child: Text(
                    (shift.cashierName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.cashierName ?? 'Unknown Staff',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${Formatters.formatDateTime(shift.startTime)}  →  ${shift.endTime != null ? Formatters.formatTime(shift.endTime!) : "Now"}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isClosed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_checked_rounded,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                _buildStatColumn(
                  'Modal Awal',
                  settings.formatCurrency(shift.startCash),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildStatColumn(
                  'Sistem',
                  settings.formatCurrency(shift.expectedCash),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildStatColumn(
                  'Aktual',
                  shift.actualCash != null
                      ? settings.formatCurrency(shift.actualCash!)
                      : '-',
                  isMain: true,
                ),
              ],
            ),
          ),
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: diffColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    diffText,
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    diffValuePrefix + settings.formatCurrency(shift.difference),
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {bool isMain = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMain ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isMain ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
