import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../services/database_service.dart';
import '../../utils/constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_range_picker_widget.dart';
import '../../services/pdf_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  final PdfExportService _pdfService = PdfExportService();

  String _selectedPeriod = 'This Week';
  DateTimeRange? _customDateRange;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, int> _orderStats = {'completed': 0, 'pending': 0, 'cancelled': 0};
  bool _isLoading = true;
  bool _isExporting = false;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isHourly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      DateTime start;
      DateTime end = DateTime.now();

      switch (_selectedPeriod) {
        case 'Today':
          start = DateTime(end.year, end.month, end.day);
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          break;
        case 'Yesterday':
          final yesterday = end.subtract(const Duration(days: 1));
          start = DateTime(yesterday.year, yesterday.month, yesterday.day);
          end = DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          );
          break;
        case 'This Week':
          start = DateTime(
            end.year,
            end.month,
            end.day,
          ).subtract(Duration(days: end.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          break;
        case 'This Month':
          start = DateTime(end.year, end.month, 1);
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          break;
        case 'This Year':
          start = DateTime(end.year, 1, 1);
          end = DateTime(end.year, end.month, end.day, 23, 59, 59);
          break;
        case 'Custom':
          if (_customDateRange != null) {
            start = _customDateRange!.start;
            end = _customDateRange!.end;
            if (end.hour == 0 && end.minute == 0 && end.second == 0) {
              end = end
                  .add(const Duration(days: 1))
                  .subtract(const Duration(seconds: 1));
            }
          } else {
            start = end.subtract(const Duration(days: 7));
          }
          break;
        default:
          start = end.subtract(const Duration(days: 7));
      }

      _startDate = start;
      _endDate = end;

      bool isHourly =
          start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;

      final results = await Future.wait([
        _databaseService.getTotalRevenue(start: start, end: end),
        _databaseService.getTotalOrders(start: start, end: end),
        _databaseService.getTotalProducts(),
        isHourly
            ? _databaseService.getHourlySalesTrend(start)
            : _databaseService.getSalesTrend(start: start, end: end),
        _databaseService.getTopProducts(limit: 5, start: start, end: end),
        _databaseService.getOrderStats(start: start, end: end),
      ]);

      if (mounted) {
        setState(() {
          _totalRevenue = results[0] as double;
          _totalOrders = results[1] as int;
          _totalProducts = results[2] as int;
          _salesData = results[3] as List<Map<String, dynamic>>;
          _topProducts = results[4] as List<Map<String, dynamic>>;
          _orderStats = results[5] as Map<String, int>;
          _isHourly = isHourly;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userName = authProvider.currentUser?.name ?? 'Admin';

      final pdfBytes = await _pdfService.generateSalesReport(
        startDate: _startDate,
        endDate: _endDate,
        userName: userName,
        totalRevenue: _totalRevenue,
        totalOrders: _totalOrders,
        topProducts: _topProducts,
        orderStats: _orderStats,
        salesData: _salesData,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            'Laporan-Penjualan-${DateFormat('yyyyMMdd').format(DateTime.now())}',
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

  Future<void> _selectCustomDateRange() async {
    await showDialog(
      context: context,
      builder: (context) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: DateRangePickerWidget(
              initialDateRange: _customDateRange,
              locale: settings.isIndonesian ? 'id' : 'en',
              onDateRangeChanged: (range) {
                if (range != null) {
                  setState(() {
                    _customDateRange = range;
                    _selectedPeriod = 'Custom';
                  });
                  _loadReportData();
                }
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummaryCards(),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              boxShadow: AppShadows.cardShadowList,
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Sales Overview'),
                    Tab(text: 'Top Products'),
                    Tab(text: 'Order Statistics'),
                  ],
                ),
                SizedBox(
                  height: 500, // Increased height for better visibility
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesOverview(),
                      _buildTopProducts(),
                      _buildOrderStatistics(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatistics() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasData = _orderStats.values.any((val) => val > 0);

    if (!hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No order data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                if (_orderStats['completed']! > 0)
                  PieChartSectionData(
                    value: _orderStats['completed']!.toDouble(),
                    title: '${_orderStats['completed']}',
                    color: AppColors.success,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (_orderStats['pending']! > 0)
                  PieChartSectionData(
                    value: _orderStats['pending']!.toDouble(),
                    title: '${_orderStats['pending']}',
                    color: AppColors.warning,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (_orderStats['cancelled']! > 0)
                  PieChartSectionData(
                    value: _orderStats['cancelled']!.toDouble(),
                    title: '${_orderStats['cancelled']}',
                    color: AppColors.error,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                'Completed',
                AppColors.success,
                _orderStats['completed']! /
                    (_totalOrders > 0 ? _totalOrders : 1),
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                'Pending',
                AppColors.warning,
                _orderStats['pending']! / (_totalOrders > 0 ? _totalOrders : 1),
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                'Cancelled',
                AppColors.error,
                _orderStats['cancelled']! /
                    (_totalOrders > 0 ? _totalOrders : 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final periods = ['Today', 'This Week', 'This Month', 'This Year', 'Custom'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final dropdown = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Row(
                    children: [
                      Icon(
                        period == 'Custom'
                            ? Icons.calendar_today
                            : Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        period == 'Custom' && _customDateRange != null
                            ? '${Formatters.formatShortDate(_customDateRange!.start)} - ${Formatters.formatShortDate(_customDateRange!.end)}'
                            : period,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == 'Custom') {
                  _selectCustomDateRange();
                } else if (value != null) {
                  setState(() => _selectedPeriod = value);
                  _loadReportData();
                }
              },
            ),
          ),
        );

        final buttons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Export Button
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPdf,
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf, size: 16),
              label: Text(_isExporting ? 'Exporting...' : 'Export PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Refresh Button (Icon Only)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: IconButton(
                onPressed: _loadReportData,
                icon: const Icon(Icons.refresh),
                color: AppColors.primary,
                tooltip: 'Refresh',
              ),
            ),
          ],
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [dropdown, buttons],
              ),
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            dropdown,
            const SizedBox(width: 16),
            buttons,
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    final settings = Provider.of<SettingsProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 4;
        if (width < 600) {
          columns = 1;
        } else if (width < 1000) {
          columns = 2;
        }

        final cards = [
          _buildSummaryCard(
            title: 'Total Revenue',
            value: settings.formatCurrency(_totalRevenue),
            icon: Icons.attach_money,
            color: AppColors.success,
          ),
          _buildSummaryCard(
            title: 'Total Orders',
            value: _totalOrders.toString(),
            icon: Icons.shopping_cart,
            color: AppColors.primary,
          ),
          _buildSummaryCard(
            title: 'Average Order',
            value: _totalOrders > 0
                ? settings.formatCurrency(_totalRevenue / _totalOrders)
                : '\$0.00',
            icon: Icons.receipt_long,
            color: AppColors.warning,
          ),
          _buildSummaryCard(
            title: 'Active Products',
            value: _totalProducts.toString(),
            icon: Icons.inventory_2,
            color: AppColors.secondary,
          ),
        ];

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((card) {
            final cardWidth = (width - ((columns - 1) * 16)) / columns - 0.1;
            return SizedBox(width: cardWidth, child: card);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        boxShadow: AppShadows.cardShadowList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesOverview() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildSalesChart()),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    final settings = Provider.of<SettingsProvider>(context);
    final spots = <FlSpot>[];
    double maxY = 100;

    double minX = 0;
    double maxX = 0;

    if (_isHourly) {
      minX = 0;
      maxX = 23;

      for (int i = 0; i < 24; i++) {
        final hourKey = i.toString().padLeft(2, '0');

        final salesEntry = _salesData.firstWhere(
          (e) => e['hour'] == hourKey,
          orElse: () => {'hour': hourKey, 'total': 0.0},
        );

        final total = (salesEntry['total'] as num?)?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), total));
        if (total > maxY) maxY = total;
      }
    } else {
      int totalDays = _endDate.difference(_startDate).inDays + 1;
      if (totalDays < 1) totalDays = 1;

      minX = 0;
      maxX = (totalDays - 1).toDouble();

      for (int i = 0; i < totalDays; i++) {
        final date = _startDate.add(Duration(days: i));
        final dateKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        final salesEntry = _salesData.firstWhere(
          (e) => e['date'] == dateKey,
          orElse: () => {'date': dateKey, 'total': 0.0},
        );

        final total = (salesEntry['total'] as num?)?.toDouble() ?? 0.0;
        spots.add(FlSpot(i.toDouble(), total));
        if (total > maxY) maxY = total;
      }
    }

    if (maxY == 0) maxY = 100;

    double interval = maxY / 4;
    double niceInterval = _getNiceInterval(interval);
    maxY = niceInterval * 4;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey.shade900,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                String label;
                if (_isHourly) {
                  label =
                      '${touchedSpot.x.toInt().toString().padLeft(2, '0')}:00';
                } else {
                  final date = _startDate.add(
                    Duration(days: touchedSpot.x.toInt()),
                  );
                  label = '${date.day}/${date.month}';
                }

                return LineTooltipItem(
                  '$label\n${settings.formatCurrency(touchedSpot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: niceInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.border.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: _isHourly ? 4 : (maxX + 1) / 7.ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                if (value < minX || value > maxX) return const Text('');

                Widget text;
                if (_isHourly) {
                  if (value % 4 == 0) {
                    text = Text(
                      '${value.toInt().toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    );
                  } else {
                    text = const Text('');
                  }
                } else {
                  final totalDays = (maxX + 1).toInt();
                  final date = _startDate.add(Duration(days: value.toInt()));
                  String label;
                  if (totalDays <= 7) {
                    const days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    label = days[date.weekday - 1];
                  } else {
                    label = "${date.day}/${date.month}";
                  }
                  text = Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: text,
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: niceInterval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                String label;
                if (value >= 1000000) {
                  label =
                      '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
                } else if (value >= 1000) {
                  label = '${(value / 1000).toStringAsFixed(0)}K';
                } else {
                  label = value.toStringAsFixed(0);
                }
                return Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                if (_isHourly) return true;
                return maxX < 30;
              },
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: AppColors.primary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getNiceInterval(double interval) {
    if (interval == 0) return 10;
    double magnitude = 1;
    while (interval >= 10) {
      interval /= 10;
      magnitude *= 10;
    }
    while (interval < 1 && interval > 0) {
      interval *= 10;
      magnitude /= 10;
    }
    if (interval <= 1) {
      interval = 1;
    } else if (interval <= 2) {
      interval = 2;
    } else if (interval <= 5) {
      interval = 5;
    } else {
      interval = 10;
    }
    return interval * magnitude;
  }

  Widget _buildTopProducts() {
    final settings = Provider.of<SettingsProvider>(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_topProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              settings.tr('no_data'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        final barChart = BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: _topProducts.isEmpty
                ? 100
                : (_topProducts.first['totalSold'] as num).toDouble() * 1.25,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.blueGrey.shade900,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final product = _topProducts[group.x.toInt()];
                  return BarTooltipItem(
                    '${product['name']}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '${product['totalSold']} Sold',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < _topProducts.length) {
                      final name =
                          _topProducts[value.toInt()]['name'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: RotatedBox(
                          quarterTurns: isSmall ? 1 : 0,
                          child: Text(
                            name.length > 10
                                ? '${name.substring(0, 10)}...'
                                : name,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const Text('');
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _topProducts.isEmpty
                  ? 10
                  : ((_topProducts.first['totalSold'] as num).toDouble() *
                            1.25) /
                        5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppColors.border.withValues(alpha: 0.5),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            barGroups: _topProducts.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: (entry.value['totalSold'] as num).toDouble(),
                    color: AppColors.primary,
                    width: isSmall ? 16 : 32,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top 5 Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: barChart),
            ],
          ),
        );
      },
    );
  }
}
