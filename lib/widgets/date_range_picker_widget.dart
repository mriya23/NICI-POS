import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class DateRangePickerWidget extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final Function(DateTimeRange?) onDateRangeChanged;
  final String? locale;

  const DateRangePickerWidget({
    super.key,
    this.initialDateRange,
    required this.onDateRangeChanged,
    this.locale,
  });

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  late DateTime _displayedMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  late final bool _isIndonesian;

  @override
  void initState() {
    super.initState();
    _isIndonesian = widget.locale == 'id';
    _displayedMonth = widget.initialDateRange?.start ?? DateTime.now();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      if (_startDate != null && _endDate != null) {
        // Range already selected -> Reset to new single start date
        _startDate = day;
        _endDate = null;
      } else if (_startDate == null) {
        // No selection -> Select start
        _startDate = day;
      } else if (_startDate != null && _endDate == null) {
        // Start selected, waiting for end or modification
        if (day.isBefore(_startDate!)) {
          _startDate = day;
        } else if (_isSameDay(day, _startDate)) {
          // Clicked same day -> Keep it as single selection (do nothing)
        } else {
          _endDate = day;
        }
      }
    });
  }

  void _selectPreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end;

    switch (preset) {
      case 'Today':
        start = today;
        end = today;
        break;
      case 'Yesterday':
        start = today.subtract(const Duration(days: 1));
        end = start;
        break;
      case 'This Week':
        start = today.subtract(Duration(days: today.weekday - 1));
        end = today;
        break;
      case 'Last 7 Days':
        start = today.subtract(const Duration(days: 6));
        end = today;
        break;
      case 'This Month':
        start = DateTime(today.year, today.month, 1);
        end = DateTime(today.year, today.month + 1, 0);
        break;
      default:
        return;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _displayedMonth = start;
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Generate days for the displayed month
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final int weekdayOffset =
        firstDayOfMonth.weekday %
        7; // Sunday = 0 for this grid if we want S M T W T F S

    final List<DateTime?> calendarDays = [];
    // Pad start
    for (int i = 0; i < weekdayOffset; i++) {
      calendarDays.add(null);
    }
    // Add days
    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(
        DateTime(_displayedMonth.year, _displayedMonth.month, i),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      width: MediaQuery.of(context).size.width < 420
          ? MediaQuery.of(context).size.width * 0.95
          : 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(), // Close "x"
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Row(
                children: [
                  if (_startDate != null)
                    TextButton(
                      onPressed: () {
                        widget.onDateRangeChanged(
                          DateTimeRange(
                            start: _startDate!,
                            end: _endDate ?? _startDate!,
                          ),
                        );
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Title Section
          Text(
            _isIndonesian ? 'Pilih tanggal' : 'Select date',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _startDate == null
                ? (_isIndonesian ? 'Pilih Tanggal' : 'Select Date')
                : '${DateFormat('MMM dd, yyyy').format(_startDate!)}${(_endDate != null && !_isSameDay(_startDate, _endDate)) ? " - ${DateFormat('MMM dd, yyyy').format(_endDate!)}" : ""}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: _startDate == null
                  ? AppColors.textHint
                  : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          // Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('Today'),
                const SizedBox(width: 8),
                _buildPresetChip('Yesterday'),
                const SizedBox(width: 8),
                _buildPresetChip('Last 7 Days'),
                const SizedBox(width: 8),
                _buildPresetChip('This Month'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Calendar Header (Month & Year Pickers + Nav)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textSecondary,
              ),
              // Month and Year Selectors
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month Dropdown
                  DropdownButton<int>(
                    value: _displayedMonth.month,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: List.generate(12, (index) {
                      final date = DateTime(2022, index + 1);
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          DateFormat(
                            'MMM',
                            _isIndonesian ? 'id_ID' : 'en_US',
                          ).format(date),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _displayedMonth = DateTime(_displayedMonth.year, val);
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Year Dropdown
                  DropdownButton<int>(
                    value: _displayedMonth.year,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    items: List.generate(11, (index) {
                      final year = DateTime.now().year - 5 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(
                          '$year',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _displayedMonth = DateTime(
                            val,
                            _displayedMonth.month,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
                (_isIndonesian
                        ? ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                    .map(
                      (day) => SizedBox(
                        width: 32,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendarDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = calendarDays[index];
              if (day == null) return const SizedBox();

              final isStart = _isSameDay(day, _startDate);
              final isEnd = _isSameDay(day, _endDate);
              final inRange =
                  _startDate != null &&
                  _endDate != null &&
                  day.isAfter(_startDate!) &&
                  day.isBefore(_endDate!) &&
                  !isStart &&
                  !isEnd;
              final isToday = _isSameDay(day, DateTime.now());

              return GestureDetector(
                onTap: () => _onDaySelected(day),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isStart || isEnd
                        ? AppColors.primary
                        : (inRange
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isToday && !isStart && !isEnd
                        ? Border.all(color: AppColors.primary, width: 1)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isStart || isEnd
                          ? Colors.white
                          : (inRange
                                ? AppColors.primary
                                : AppColors.textPrimary),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label) {
    return InkWell(
      onTap: () => _selectPreset(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Compact version for use in headers/toolbars (keeping this as it's useful for the trigger)
class CompactDateRangePicker extends StatelessWidget {
  final DateTimeRange? dateRange;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool isIndonesian;

  const CompactDateRangePicker({
    super.key,
    this.dateRange,
    required this.onTap,
    this.onClear,
    this.isIndonesian = true,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44, // Match text field height often used
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            10,
          ), // AppDimensions.radiusSM usually
          border: Border.all(
            color: dateRange != null ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: dateRange != null
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              dateRange != null
                  ? '${_formatDate(dateRange!.start)} - ${_formatDate(dateRange!.end)}'
                  : (isIndonesian ? 'Filter Tanggal' : 'Filter Date'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: dateRange != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            if (dateRange != null && onClear != null)
              InkWell(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              )
            else
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
