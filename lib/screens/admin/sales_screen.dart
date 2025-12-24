import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/order_model.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/date_range_picker_widget.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _filterOrders(List<Order> orders) {
    var filteredOrders = orders;

    // Filter by status
    if (_selectedFilter != 'All') {
      filteredOrders = filteredOrders.where((order) {
        switch (_selectedFilter) {
          case 'Completed':
            return order.status == OrderStatus.completed;
          case 'Pending':
            return order.status == OrderStatus.pending;
          case 'Cancelled':
            return order.status == OrderStatus.cancelled;
          default:
            return true;
        }
      }).toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredOrders = filteredOrders.where((order) {
        return order.orderNumber.toLowerCase().contains(query) ||
            (order.customerName?.toLowerCase().contains(query) ?? false) ||
            (order.cashierName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by date range
    if (_dateRange != null) {
      filteredOrders = filteredOrders.where((order) {
        return order.createdAt.isAfter(_dateRange!.start) &&
            order.createdAt.isBefore(
              _dateRange!.end.add(const Duration(days: 1)),
            );
      }).toList();
    }

    return filteredOrders;
  }

  void _showDateRangePickerDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DateRangePickerWidget(
            initialDateRange: _dateRange,
            locale: settings.isIndonesian ? 'id' : 'en',
            onDateRangeChanged: (range) {
              setState(() {
                _dateRange = range;
              });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _clearDateFilter() {
    setState(() {
      _dateRange = null;
    });
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 900;
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(settings, isSmall),

              const SizedBox(height: 24),

              // Filter Chips
              _buildFilterChips(settings, isSmall),

              const SizedBox(height: 16),

              // Sales Table
              Expanded(
                child: isSmall ? _buildSalesList(settings) : _buildSalesTable(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(SettingsProvider settings, bool isSmall) {
    final search = Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: settings.tr('search_orders'),
          hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textHint,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );

    final datePicker = CompactDateRangePicker(
      dateRange: _dateRange,
      onTap: () => _showDateRangePickerDialog(settings),
      onClear: _clearDateFilter,
      isIndonesian: settings.isIndonesian,
    );

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          const SizedBox(height: 12),
          Row(children: [Expanded(child: datePicker)]),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: 16),
        datePicker,
      ],
    );
  }

  Widget _buildFilterChips(SettingsProvider settings, bool isSmall) {
    final filters = [
      {'key': 'All', 'labelId': 'Semua', 'labelEn': 'All'},
      {'key': 'Completed', 'labelId': 'Selesai', 'labelEn': 'Completed'},
      {'key': 'Pending', 'labelId': 'Menunggu', 'labelEn': 'Pending'},
      {'key': 'Cancelled', 'labelId': 'Dibatalkan', 'labelEn': 'Cancelled'},
    ];

    final summary = Consumer<OrderProvider>(
      builder: (context, provider, child) {
        final filteredOrders = _filterOrders(provider.orders);
        final totalAmount = filteredOrders
            .where((o) => o.status == OrderStatus.completed)
            .fold(0.0, (sum, order) => sum + order.total);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${settings.tr('total')}: ${settings.formatCurrency(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Text(
                '${filteredOrders.length} ${settings.tr('orders_count')}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );

    final filterWidgets = [
      Text(
        'Filter by status:',
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(width: 12),
      ...filters.map((filter) {
        final isSelected = _selectedFilter == filter['key'];
        final label = settings.isIndonesian
            ? filter['labelId']!
            : filter['labelEn']!;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter['key']!;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary.withValues(alpha: 0.1),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
        );
      }),
    ];

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(children: filterWidgets),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: summary,
          ),
        ],
      );
    }

    return Row(children: [...filterWidgets, const Spacer(), summary]);
  }

  Widget _buildSalesTable() {
    final settings = Provider.of<SettingsProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        boxShadow: AppShadows.cardShadowList,
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusMD),
                topRight: Radius.circular(AppDimensions.radiusMD),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    settings.tr('order_number'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    settings.tr('customer'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    settings.tr('cashier'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    settings.tr('order_type_label'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    settings.tr('items'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    settings.tr('order_date'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    settings.tr('order_status'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    settings.tr('total'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(width: 60),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = _filterOrders(provider.orders);

                if (orders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderRow(order, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Order order, int index) {
    final settings = Provider.of<SettingsProvider>(context);
    Color statusColor;
    switch (order.status) {
      case OrderStatus.completed:
        statusColor = AppColors.success;
        break;
      case OrderStatus.pending:
        statusColor = AppColors.warning;
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        break;
    }

    return InkWell(
      onTap: () => _showOrderDetails(order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: index.isEven
              ? Colors.white
              : AppColors.background.withValues(alpha: 0.5),
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            // Order Number
            Expanded(
              flex: 2,
              child: Text(
                '#${order.orderNumber}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Customer
            Expanded(
              flex: 2,
              child: Text(
                order.customerName ?? 'Walk-in',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Cashier
            Expanded(
              flex: 2,
              child: Text(
                order.cashierName ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Type
            Expanded(
              flex: 1,
              child: Text(
                order.isDineIn
                    ? settings.tr('dine_in')
                    : settings.tr('take_away'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Items Count
            Expanded(
              child: Text(
                '${order.totalItems} items',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),

            // Date
            Expanded(
              flex: 2,
              child: Text(
                Formatters.formatDateTime(order.createdAt),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ),

            // Total
            Expanded(
              child: Text(
                settings.formatCurrency(order.total),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Actions
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.visibility_outlined),
                    iconSize: 20,
                    color: AppColors.primary,
                    tooltip: 'View Details',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(SettingsProvider settings) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = _filterOrders(provider.orders);

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            Color statusColor;
            switch (order.status) {
              case OrderStatus.completed:
                statusColor = AppColors.success;
                break;
              case OrderStatus.pending:
                statusColor = AppColors.warning;
                break;
              case OrderStatus.cancelled:
                statusColor = AppColors.error;
                break;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                boxShadow: AppShadows.cardShadowList,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.customerName ?? 'Walk-in',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        Formatters.formatDateTime(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.totalItems} items • ${order.isDineIn ? settings.tr('dine_in') : settings.tr('take_away')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        settings.formatCurrency(order.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showOrderDetails(order),
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here once created',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class OrderDetailsDialog extends StatelessWidget {
  final Order order;

  const OrderDetailsDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final size = MediaQuery.of(context).size;

    Color statusColor;
    switch (order.status) {
      case OrderStatus.completed:
        statusColor = AppColors.success;
        break;
      case OrderStatus.pending:
        statusColor = AppColors.warning;
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.error;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.dialogShadow,
          ),
          child: Column(
            children: [
              // Header (Fixed)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Order #${order.orderNumber}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.status
                                      .toString()
                                      .split('.')
                                      .last
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatDateTime(order.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Grid
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 500;
                            if (isWide) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem(
                                          settings.tr('customer'),
                                          order.customerName ?? 'Walk-in',
                                          Icons.person_outline_rounded,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInfoItem(
                                          'Cashier',
                                          order.cashierName ?? '-',
                                          Icons.badge_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem(
                                          settings.tr('order_type_label'),
                                          order.isDineIn
                                              ? settings.tr('dine_in')
                                              : settings.tr('take_away'),
                                          Icons.restaurant_menu_rounded,
                                        ),
                                      ),
                                      Expanded(
                                        child: _buildInfoItem(
                                          settings.tr('payment_method'),
                                          order.paymentMethod
                                                  ?.toString()
                                                  .split('.')
                                                  .last
                                                  .toUpperCase() ??
                                              '-',
                                          Icons.payment_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildInfoItem(
                                    settings.tr('customer'),
                                    order.customerName ?? 'Walk-in',
                                    Icons.person_outline_rounded,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoItem(
                                    'Cashier',
                                    order.cashierName ?? '-',
                                    Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoItem(
                                    settings.tr('order_type_label'),
                                    order.isDineIn
                                        ? settings.tr('dine_in')
                                        : settings.tr('take_away'),
                                    Icons.restaurant_menu_rounded,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoItem(
                                    settings.tr('payment_method'),
                                    order.paymentMethod
                                            ?.toString()
                                            .split('.')
                                            .last
                                            .toUpperCase() ??
                                        '-',
                                    Icons.payment_rounded,
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Items Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                settings.tr('items'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Qty',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                settings.tr('price'),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                settings.tr('total'),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),

                      // Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: order.items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'x${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    settings.formatCurrency(item.price),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    settings.formatCurrency(item.subtotal),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(),

                      const SizedBox(height: 32),

                      // Totals Section
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 300,
                          child: Column(
                            children: [
                              _buildTotalRow(
                                settings.tr('subtotal'),
                                order.subtotal,
                                settings,
                              ),
                              const SizedBox(height: 12),
                              if (order.tax > 0) ...[
                                _buildTotalRow(
                                  settings.tr('tax'),
                                  order.tax,
                                  settings,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (order.discount > 0) ...[
                                _buildTotalRow(
                                  settings.tr('discount'),
                                  -order.discount,
                                  settings,
                                  isDiscount: true,
                                ),
                                const SizedBox(height: 12),
                              ],
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    settings.tr('total'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    settings.formatCurrency(order.total),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (order.amountPaid != null) ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      settings.tr('amount_paid'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      settings.formatCurrency(
                                        order.amountPaid!,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      settings.tr('change'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      settings.formatCurrency(
                                        order.change ?? 0,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer (Fixed)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.divider)),
                  color: AppColors.background.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Print feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: Text(settings.tr('print_receipt')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(settings.tr('close')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
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
}
