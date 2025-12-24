import 'package:flutter/material.dart';
import '../models/export_import_models.dart';
import '../utils/constants.dart';

class ImportResultDialog extends StatelessWidget {
  final ImportResult result;
  final VoidCallback? onDownloadErrorReport;

  const ImportResultDialog({
    super.key,
    required this.result,
    this.onDownloadErrorReport,
  });

  @override
  Widget build(BuildContext context) {
    final hasErrors = result.errors.isNotEmpty;
    final isSuccess = result.success && result.successCount > 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.warning,
            color: isSuccess ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Text(isSuccess ? 'Import Complete' : 'Import Completed with Issues'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Rows',
                    result.totalRows.toString(),
                    Icons.list_alt,
                    AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Successful',
                    result.successCount.toString(),
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Failed',
                    result.failedCount.toString(),
                    Icons.error,
                    AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Skipped',
                    result.skippedCount.toString(),
                    Icons.skip_next,
                    AppColors.warning,
                  ),
                ),
              ],
            ),

            // Error List
            if (hasErrors) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Errors',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (onDownloadErrorReport != null)
                    TextButton.icon(
                      onPressed: onDownloadErrorReport,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download Report'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: result.errors.length > 10 ? 10 : result.errors.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final error = result.errors[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        child: Text(
                          '${error.rowNumber}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      title: Text(
                        error.fieldName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        error.errorMessage,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              if (result.errors.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... and ${result.errors.length - 10} more errors',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
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
