import 'package:flutter/material.dart';
import '../models/export_import_models.dart';
import '../utils/constants.dart';

class ImportDialog extends StatefulWidget {
  final String dataType;
  final bool showConflictResolution;
  final Function(ExportFormat, ImportConflictResolution) onImport;

  const ImportDialog({
    super.key,
    required this.dataType,
    this.showConflictResolution = false,
    required this.onImport,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  ImportConflictResolution _conflictResolution = ImportConflictResolution.skip;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Import ${widget.dataType}'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select file format:',
                style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildFormatOption(ExportFormat.csv, 'CSV', 'Comma-separated values file'),
              const SizedBox(height: 8),
              _buildFormatOption(ExportFormat.json, 'JSON', 'JavaScript Object Notation file'),
              if (widget.showConflictResolution) ...[
                const SizedBox(height: 24),
                const Text(
                  'If item already exists:',
                  style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _buildConflictOption(ImportConflictResolution.skip, 'Skip', 'Keep existing data', Icons.skip_next),
                const SizedBox(height: 8),
                _buildConflictOption(ImportConflictResolution.overwrite, 'Overwrite', 'Replace with imported', Icons.sync),
                const SizedBox(height: 8),
                _buildConflictOption(ImportConflictResolution.createNew, 'Create New', 'Create with new ID', Icons.add_circle_outline),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will be prompted to select a file.',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
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
            widget.onImport(_selectedFormat, _conflictResolution);
          },
          child: const Text('Import'),
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
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictOption(ImportConflictResolution resolution, String title, String subtitle, IconData icon) {
    final isSelected = _conflictResolution == resolution;
    return InkWell(
      onTap: () => setState(() => _conflictResolution = resolution),
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
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
