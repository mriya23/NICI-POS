import 'package:flutter/material.dart';
import '../models/export_import_models.dart';
import '../utils/constants.dart';

class ExportDialog extends StatefulWidget {
  final String dataType;
  final bool showDateRange;
  final Function(ExportFormat, DateTime?, DateTime?) onExport;

  const ExportDialog({
    super.key,
    required this.dataType,
    this.showDateRange = false,
    required this.onExport,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.showDateRange) {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Export ${widget.dataType}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select export format:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildFormatOption(ExportFormat.csv, 'CSV', 'Comma-separated values'),
              const SizedBox(height: 8),
              _buildFormatOption(ExportFormat.json, 'JSON', 'For data backup'),
              if (widget.showDateRange) ...[
                const SizedBox(height: 24),
                const Text(
                  'Date Range (optional):',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildDateButton('Start', _startDate, true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateButton('End', _endDate, false)),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _startDate = null;
                    _endDate = null;
                  }),
                  child: const Text('Clear date filter'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onExport(_selectedFormat, _startDate, _endDate);
          },
          child: const Text('Export'),
        ),
      ],
    );
  }

  Widget _buildFormatOption(ExportFormat format, String title, String subtitle) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          color: isSelected ? AppColors.primaryBg : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(isStart),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text(
                    date != null ? '${date.day}/${date.month}/${date.year}' : 'Select',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
        } else {
          _endDate = picked;
          if (_startDate != null && _startDate!.isAfter(picked)) _startDate = picked;
        }
      });
    }
  }
}
