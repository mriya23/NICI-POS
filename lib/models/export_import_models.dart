/// Export format options
enum ExportFormat { csv, json }

/// Import conflict resolution options
enum ImportConflictResolution { skip, overwrite, createNew }

/// Result of an export operation
class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final int recordCount;

  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.recordCount = 0,
  });

  factory ExportResult.success({
    required String filePath,
    required int recordCount,
  }) {
    return ExportResult(
      success: true,
      filePath: filePath,
      recordCount: recordCount,
    );
  }

  factory ExportResult.failure(String errorMessage) {
    return ExportResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    return 'ExportResult(success: $success, filePath: $filePath, recordCount: $recordCount, error: $errorMessage)';
  }
}

/// Error details for a single import row
class ImportError {
  final int rowNumber;
  final String fieldName;
  final String errorMessage;
  final Map<String, dynamic>? rowData;

  ImportError({
    required this.rowNumber,
    required this.fieldName,
    required this.errorMessage,
    this.rowData,
  });

  Map<String, dynamic> toMap() {
    return {
      'rowNumber': rowNumber,
      'fieldName': fieldName,
      'errorMessage': errorMessage,
      'rowData': rowData,
    };
  }

  @override
  String toString() {
    return 'ImportError(row: $rowNumber, field: $fieldName, error: $errorMessage)';
  }
}

/// Result of an import operation
class ImportResult {
  final bool success;
  final int totalRows;
  final int successCount;
  final int failedCount;
  final int skippedCount;
  final List<ImportError> errors;

  ImportResult({
    required this.success,
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    this.skippedCount = 0,
    this.errors = const [],
  });

  factory ImportResult.success({
    required int totalRows,
    required int successCount,
    int failedCount = 0,
    int skippedCount = 0,
    List<ImportError> errors = const [],
  }) {
    return ImportResult(
      success: true,
      totalRows: totalRows,
      successCount: successCount,
      failedCount: failedCount,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  factory ImportResult.failure({
    required String errorMessage,
    int totalRows = 0,
  }) {
    return ImportResult(
      success: false,
      totalRows: totalRows,
      successCount: 0,
      failedCount: totalRows,
      errors: [
        ImportError(
          rowNumber: 0,
          fieldName: 'file',
          errorMessage: errorMessage,
        ),
      ],
    );
  }

  /// Check if counts are consistent (successCount + failedCount + skippedCount == totalRows)
  bool get countsAreValid =>
      successCount + failedCount + skippedCount == totalRows;

  @override
  String toString() {
    return 'ImportResult(success: $success, total: $totalRows, success: $successCount, failed: $failedCount, skipped: $skippedCount)';
  }
}

/// Metadata for full backup export
class BackupMetadata {
  final DateTime exportDate;
  final String appVersion;
  final int productCount;
  final int categoryCount;
  final int orderCount;
  final int transactionCount;

  BackupMetadata({
    required this.exportDate,
    required this.appVersion,
    required this.productCount,
    required this.categoryCount,
    required this.orderCount,
    required this.transactionCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'exportDate': exportDate.toIso8601String(),
      'appVersion': appVersion,
      'counts': {
        'products': productCount,
        'categories': categoryCount,
        'orders': orderCount,
        'transactions': transactionCount,
      },
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    final counts = map['counts'] as Map<String, dynamic>;
    return BackupMetadata(
      exportDate: DateTime.parse(map['exportDate'] as String),
      appVersion: map['appVersion'] as String,
      productCount: counts['products'] as int,
      categoryCount: counts['categories'] as int,
      orderCount: counts['orders'] as int,
      transactionCount: counts['transactions'] as int,
    );
  }
}

/// Full backup data structure
class FullBackup {
  final BackupMetadata metadata;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> transactions;

  FullBackup({
    required this.metadata,
    required this.products,
    required this.categories,
    required this.orders,
    required this.transactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'metadata': metadata.toMap(),
      'products': products,
      'categories': categories,
      'orders': orders,
      'transactions': transactions,
    };
  }

  factory FullBackup.fromMap(Map<String, dynamic> map) {
    return FullBackup(
      metadata: BackupMetadata.fromMap(map['metadata'] as Map<String, dynamic>),
      products: List<Map<String, dynamic>>.from(map['products'] as List),
      categories: List<Map<String, dynamic>>.from(map['categories'] as List),
      orders: List<Map<String, dynamic>>.from(map['orders'] as List),
      transactions: List<Map<String, dynamic>>.from(map['transactions'] as List),
    );
  }

  /// Generate backup filename with format: pos_backup_YYYYMMDD_HHMMSS.json
  static String generateFilename(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return 'pos_backup_$year$month${day}_$hour$minute$second.json';
  }
}
