import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/export_import_models.dart';
import '../models/product_model.dart';
import '../models/category_model.dart' as cat_model;
import '../models/order_model.dart';
import '../models/transaction_model.dart' as models;
import '../utils/constants.dart';
import 'database_service.dart';

// Conditional import for web download
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download.dart'
    as web_download;

class ExportImportService {
  static final ExportImportService _instance = ExportImportService._internal();
  final DatabaseService _databaseService = DatabaseService();

  factory ExportImportService() => _instance;

  ExportImportService._internal();

  // ============================================
  // CSV/JSON Conversion Methods
  // ============================================

  /// Convert list of maps to CSV string with header row
  String toCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final buffer = StringBuffer();

    // Header row
    buffer.writeln(headers.join(','));

    // Data rows
    for (final row in data) {
      final values = headers.map((header) {
        final value = row[header];
        if (value == null) return '';
        final stringValue = value.toString();
        // Escape values containing comma, quote, or newline
        if (stringValue.contains(',') ||
            stringValue.contains('"') ||
            stringValue.contains('\n')) {
          return '"${stringValue.replaceAll('"', '""')}"';
        }
        return stringValue;
      }).toList();
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }

  /// Convert list of maps to JSON string
  String toJson(List<Map<String, dynamic>> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Parse CSV string to list of maps using first row as headers
  List<Map<String, dynamic>> parseCsv(String content) {
    final lines = const LineSplitter().convert(content.trim());
    if (lines.isEmpty) return [];

    final headers = _parseCsvLine(lines.first);
    final result = <Map<String, dynamic>>[];

    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = _parseCsvLine(lines[i]);
      final row = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = _parseValue(values[j]);
      }
      result.add(row);
    }

    return result;
  }

  /// Parse a single CSV line handling quoted values
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());

    return result;
  }

  /// Parse string value to appropriate type
  dynamic _parseValue(String value) {
    if (value.isEmpty) return null;

    // Try parsing as int
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;

    // Try parsing as double
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;

    // Try parsing as bool
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    return value;
  }

  /// Parse JSON string to list of maps
  List<Map<String, dynamic>> parseJson(String content) {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw FormatException('Expected JSON array');
  }

  // ============================================
  // File Operations
  // ============================================

  /// Pick a file for import
  Future<String?> pickImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          // For web, return the file content directly
          final bytes = result.files.first.bytes;
          if (bytes != null) {
            return utf8.decode(bytes);
          }
        } else {
          final path = result.files.first.path;
          if (path != null) {
            return await File(path).readAsString();
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error picking file: $e');
      return null;
    }
  }

  /// Get file extension from picked file
  Future<ExportFormat?> getPickedFileFormat() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final extension = result.files.first.extension?.toLowerCase();
        if (extension == 'csv') return ExportFormat.csv;
        if (extension == 'json') return ExportFormat.json;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save export content to file
  Future<String?> saveExportFile(
    String content,
    String fileName,
    ExportFormat format,
  ) async {
    try {
      final extension = format == ExportFormat.csv ? 'csv' : 'json';
      final fullFileName = '$fileName.$extension';

      if (kIsWeb) {
        // For web, trigger download using JavaScript
        await _downloadFileWeb(content, fullFileName, format);
        return fullFileName;
      } else {
        // For desktop/mobile, let user choose location
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Export File',
          fileName: fullFileName,
          type: FileType.custom,
          allowedExtensions: [extension],
        );

        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(content);
          return outputPath;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error saving file: $e');
      return null;
    }
  }

  /// Download file on web using Blob and anchor element
  Future<void> _downloadFileWeb(
    String content,
    String fileName,
    ExportFormat format,
  ) async {
    final bytes = utf8.encode(content);
    final mimeType = format == ExportFormat.csv
        ? 'text/csv'
        : 'application/json';
    web_download.downloadFileWeb(bytes, fileName, mimeType);
  }

  // ============================================
  // Export Methods
  // ============================================

  /// Export all active products
  Future<ExportResult> exportProducts(ExportFormat format) async {
    try {
      final products = await _databaseService.getAllProducts();
      final data = products.map((p) => _productToExportMap(p)).toList();

      if (data.isEmpty) {
        return ExportResult.failure('No products to export');
      }

      final content = format == ExportFormat.csv ? toCsv(data) : toJson(data);
      final fileName = 'products_export_${_getTimestamp()}';
      final filePath = await saveExportFile(content, fileName, format);

      if (filePath != null) {
        return ExportResult.success(
          filePath: filePath,
          recordCount: data.length,
        );
      }
      return ExportResult.failure('Export cancelled');
    } catch (e) {
      return ExportResult.failure('Export failed: ${e.toString()}');
    }
  }

  /// Export all active categories
  Future<ExportResult> exportCategories(ExportFormat format) async {
    try {
      final categories = await _databaseService.getAllCategories();
      final data = categories.map((c) => _categoryToExportMap(c)).toList();

      if (data.isEmpty) {
        return ExportResult.failure('No categories to export');
      }

      final content = format == ExportFormat.csv ? toCsv(data) : toJson(data);
      final fileName = 'categories_export_${_getTimestamp()}';
      final filePath = await saveExportFile(content, fileName, format);

      if (filePath != null) {
        return ExportResult.success(
          filePath: filePath,
          recordCount: data.length,
        );
      }
      return ExportResult.failure('Export cancelled');
    } catch (e) {
      return ExportResult.failure('Export failed: ${e.toString()}');
    }
  }

  /// Export orders with optional date range filter
  Future<ExportResult> exportOrders(
    ExportFormat format, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<Order> orders;
      if (startDate != null && endDate != null) {
        orders = await _databaseService.getOrdersByDateRange(
          startDate,
          endDate,
        );
      } else {
        orders = await _databaseService.getAllOrders();
      }

      final data = orders.map((o) => _orderToExportMap(o)).toList();

      if (data.isEmpty) {
        return ExportResult.failure('No orders to export');
      }

      final content = format == ExportFormat.csv ? toCsv(data) : toJson(data);
      final fileName = 'orders_export_${_getTimestamp()}';
      final filePath = await saveExportFile(content, fileName, format);

      if (filePath != null) {
        return ExportResult.success(
          filePath: filePath,
          recordCount: data.length,
        );
      }
      return ExportResult.failure('Export cancelled');
    } catch (e) {
      return ExportResult.failure('Export failed: ${e.toString()}');
    }
  }

  /// Export transactions with optional date range filter
  Future<ExportResult> exportTransactions(
    ExportFormat format, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      List<models.Transaction> transactions;
      if (startDate != null && endDate != null) {
        transactions = await _databaseService.getTransactionsByDateRange(
          startDate,
          endDate,
        );
      } else {
        transactions = await _databaseService.getAllTransactions();
      }

      final data = transactions.map((t) => _transactionToExportMap(t)).toList();

      if (data.isEmpty) {
        return ExportResult.failure('No transactions to export');
      }

      final content = format == ExportFormat.csv ? toCsv(data) : toJson(data);
      final fileName = 'transactions_export_${_getTimestamp()}';
      final filePath = await saveExportFile(content, fileName, format);

      if (filePath != null) {
        return ExportResult.success(
          filePath: filePath,
          recordCount: data.length,
        );
      }
      return ExportResult.failure('Export cancelled');
    } catch (e) {
      return ExportResult.failure('Export failed: ${e.toString()}');
    }
  }

  /// Export all data as full backup
  Future<ExportResult> exportAllData() async {
    try {
      final products = await _databaseService.getAllProducts();
      final categories = await _databaseService.getAllCategories();
      final orders = await _databaseService.getAllOrders();
      final transactions = await _databaseService.getAllTransactions();

      final now = DateTime.now();
      final backup = FullBackup(
        metadata: BackupMetadata(
          exportDate: now,
          appVersion: AppConstants.appVersion,
          productCount: products.length,
          categoryCount: categories.length,
          orderCount: orders.length,
          transactionCount: transactions.length,
        ),
        products: products.map((p) => p.toMap()).toList(),
        categories: categories.map((c) => c.toMap()).toList(),
        orders: orders.map((o) => o.toMap()).toList(),
        transactions: transactions.map((t) => t.toMap()).toList(),
      );

      final content = const JsonEncoder.withIndent(
        '  ',
      ).convert(backup.toMap());
      final fileName = FullBackup.generateFilename(now);

      // Remove .json extension since saveExportFile adds it
      final fileNameWithoutExt = fileName.replaceAll('.json', '');
      final filePath = await saveExportFile(
        content,
        fileNameWithoutExt,
        ExportFormat.json,
      );

      if (filePath != null) {
        final totalRecords =
            products.length +
            categories.length +
            orders.length +
            transactions.length;
        return ExportResult.success(
          filePath: filePath,
          recordCount: totalRecords,
        );
      }
      return ExportResult.failure('Export cancelled');
    } catch (e) {
      return ExportResult.failure('Backup failed: ${e.toString()}');
    }
  }

  // ============================================
  // Helper Methods for Export
  // ============================================

  Map<String, dynamic> _productToExportMap(Product p) {
    return {
      'id': p.id,
      'name': p.name,
      'category': p.category,
      'price': p.price,
      'stock': p.stock,
      'imageUrl': p.imageUrl,
      'description': p.description,
      'isActive': p.isActive,
    };
  }

  Map<String, dynamic> _categoryToExportMap(cat_model.Category c) {
    return {
      'id': c.id,
      'name': c.name,
      'color': c.color,
      'isActive': c.isActive,
    };
  }

  Map<String, dynamic> _orderToExportMap(Order o) {
    return {
      'orderNumber': o.orderNumber,
      'items': jsonEncode(o.items.map((i) => i.toMap()).toList()),
      'subtotal': o.subtotal,
      'tax': o.tax,
      'discount': o.discount,
      'total': o.total,
      'status': o.status.toString().split('.').last,
      'paymentMethod': o.paymentMethod?.toString().split('.').last,
      'cashierName': o.cashierName,
      'customerName': o.customerName,
      'createdAt': o.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _transactionToExportMap(models.Transaction t) {
    return {
      'orderNumber': t.orderNumber,
      'amount': t.amount,
      'paymentMethod': t.paymentMethod.toString().split('.').last,
      'cashierName': t.cashierName,
      'customerName': t.customerName,
      'createdAt': t.createdAt.toIso8601String(),
    };
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  // ============================================
  // Validation Methods
  // ============================================

  /// Validate product data for import
  List<ImportError> validateProductData(List<Map<String, dynamic>> data) {
    final errors = <ImportError>[];

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final rowNumber = i + 1; // 1-based row number

      // Validate name
      final name = row['name'];
      if (name == null || name.toString().trim().isEmpty) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            fieldName: 'name',
            errorMessage: 'Product name is required',
            rowData: row,
          ),
        );
      }

      // Validate price
      final price = row['price'];
      if (price == null) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            fieldName: 'price',
            errorMessage: 'Price is required',
            rowData: row,
          ),
        );
      } else {
        final priceValue = price is num
            ? price.toDouble()
            : double.tryParse(price.toString());
        if (priceValue == null || priceValue <= 0) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              fieldName: 'price',
              errorMessage: 'Price must be a positive number',
              rowData: row,
            ),
          );
        }
      }

      // Validate stock
      final stock = row['stock'];
      if (stock != null) {
        final stockValue = stock is int
            ? stock
            : int.tryParse(stock.toString());
        if (stockValue == null || stockValue < 0) {
          errors.add(
            ImportError(
              rowNumber: rowNumber,
              fieldName: 'stock',
              errorMessage: 'Stock cannot be negative',
              rowData: row,
            ),
          );
        }
      }
    }

    return errors;
  }

  /// Validate category data for import
  Future<List<ImportError>> validateCategoryData(
    List<Map<String, dynamic>> data,
  ) async {
    final errors = <ImportError>[];
    final seenNames = <String>{};

    // Get existing categories
    final existingCategories = await _databaseService.getAllCategories();
    final existingNames = existingCategories
        .map((c) => c.name.toLowerCase())
        .toSet();

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final rowNumber = i + 1;

      // Validate name
      final name = row['name'];
      if (name == null || name.toString().trim().isEmpty) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            fieldName: 'name',
            errorMessage: 'Category name is required',
            rowData: row,
          ),
        );
        continue;
      }

      final nameLower = name.toString().toLowerCase();

      // Check for duplicates in import file
      if (seenNames.contains(nameLower)) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            fieldName: 'name',
            errorMessage: 'Duplicate category name in import file',
            rowData: row,
          ),
        );
        continue;
      }

      // Check for existing in database
      if (existingNames.contains(nameLower)) {
        errors.add(
          ImportError(
            rowNumber: rowNumber,
            fieldName: 'name',
            errorMessage: 'Category name already exists',
            rowData: row,
          ),
        );
        continue;
      }

      seenNames.add(nameLower);
    }

    return errors;
  }

  // ============================================
  // Import Methods
  // ============================================

  /// Import products from file
  Future<ImportResult> importProducts(
    String content,
    ExportFormat format,
    ImportConflictResolution resolution,
  ) async {
    try {
      // Parse file content
      List<Map<String, dynamic>> data;
      try {
        data = format == ExportFormat.csv
            ? parseCsv(content)
            : parseJson(content);
      } catch (e) {
        return ImportResult.failure(
          errorMessage: 'Failed to parse file: ${e.toString()}',
        );
      }

      if (data.isEmpty) {
        return ImportResult.failure(errorMessage: 'No data found in file');
      }

      // Validate data
      final validationErrors = validateProductData(data);
      final errorRowNumbers = validationErrors.map((e) => e.rowNumber).toSet();

      int successCount = 0;
      int failedCount = validationErrors.length;
      int skippedCount = 0;
      final allErrors = List<ImportError>.from(validationErrors);

      // Process valid rows
      for (var i = 0; i < data.length; i++) {
        final rowNumber = i + 1;
        if (errorRowNumbers.contains(rowNumber)) continue;

        final row = data[i];
        try {
          final productId = row['id']?.toString();
          Product? existingProduct;

          if (productId != null && productId.isNotEmpty) {
            existingProduct = await _databaseService.getProductById(productId);
          }

          if (existingProduct != null) {
            // Handle conflict
            switch (resolution) {
              case ImportConflictResolution.skip:
                skippedCount++;
                continue;
              case ImportConflictResolution.overwrite:
                final updatedProduct = _mapToProduct(
                  row,
                  existingId: productId,
                );
                await _databaseService.updateProduct(updatedProduct);
                successCount++;
                break;
              case ImportConflictResolution.createNew:
                final newProduct = _mapToProduct(row);
                await _databaseService.insertProduct(newProduct);
                successCount++;
                break;
            }
          } else {
            // Insert new product
            final newProduct = _mapToProduct(row);
            await _databaseService.insertProduct(newProduct);
            successCount++;
          }
        } catch (e) {
          failedCount++;
          allErrors.add(
            ImportError(
              rowNumber: rowNumber,
              fieldName: 'database',
              errorMessage: 'Failed to save: ${e.toString()}',
              rowData: row,
            ),
          );
        }
      }

      return ImportResult.success(
        totalRows: data.length,
        successCount: successCount,
        failedCount: failedCount,
        skippedCount: skippedCount,
        errors: allErrors,
      );
    } catch (e) {
      return ImportResult.failure(
        errorMessage: 'Import failed: ${e.toString()}',
      );
    }
  }

  /// Import categories from file
  Future<ImportResult> importCategories(
    String content,
    ExportFormat format,
  ) async {
    try {
      // Parse file content
      List<Map<String, dynamic>> data;
      try {
        data = format == ExportFormat.csv
            ? parseCsv(content)
            : parseJson(content);
      } catch (e) {
        return ImportResult.failure(
          errorMessage: 'Failed to parse file: ${e.toString()}',
        );
      }

      if (data.isEmpty) {
        return ImportResult.failure(errorMessage: 'No data found in file');
      }

      // Validate data
      final validationErrors = await validateCategoryData(data);
      final errorRowNumbers = validationErrors.map((e) => e.rowNumber).toSet();

      int successCount = 0;
      int failedCount = validationErrors.length;
      int skippedCount = 0;
      final allErrors = List<ImportError>.from(validationErrors);

      // Process valid rows
      for (var i = 0; i < data.length; i++) {
        final rowNumber = i + 1;
        if (errorRowNumbers.contains(rowNumber)) {
          // Check if it's a "already exists" error - count as skipped
          final error = validationErrors.firstWhere(
            (e) => e.rowNumber == rowNumber,
            orElse: () =>
                ImportError(rowNumber: 0, fieldName: '', errorMessage: ''),
          );
          if (error.errorMessage.contains('already exists')) {
            skippedCount++;
            failedCount--;
          }
          continue;
        }

        final row = data[i];
        try {
          final newCategory = _mapToCategory(row);
          await _databaseService.insertCategory(newCategory);
          successCount++;
        } catch (e) {
          failedCount++;
          allErrors.add(
            ImportError(
              rowNumber: rowNumber,
              fieldName: 'database',
              errorMessage: 'Failed to save: ${e.toString()}',
              rowData: row,
            ),
          );
        }
      }

      return ImportResult.success(
        totalRows: data.length,
        successCount: successCount,
        failedCount: failedCount,
        skippedCount: skippedCount,
        errors: allErrors,
      );
    } catch (e) {
      return ImportResult.failure(
        errorMessage: 'Import failed: ${e.toString()}',
      );
    }
  }

  // ============================================
  // Helper Methods for Import
  // ============================================

  Product _mapToProduct(Map<String, dynamic> row, {String? existingId}) {
    return Product(
      id:
          existingId ??
          row['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: row['name']?.toString() ?? '',
      category: row['category']?.toString() ?? 'Other',
      price: _parseDouble(row['price']) ?? 0.0,
      stock: _parseInt(row['stock']) ?? 0,
      imageUrl: row['imageUrl']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      isActive: _parseBool(row['isActive']) ?? true,
    );
  }

  cat_model.Category _mapToCategory(Map<String, dynamic> row) {
    return cat_model.Category(
      id:
          row['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: row['name']?.toString() ?? '',
      color: _parseInt(row['color']),
      isActive: _parseBool(row['isActive']) ?? true,
      createdAt: DateTime.now(),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final str = value.toString().toLowerCase();
    if (str == 'true' || str == '1') return true;
    if (str == 'false' || str == '0') return false;
    return null;
  }

  /// Generate error report as CSV
  String generateErrorReport(List<ImportError> errors) {
    final buffer = StringBuffer();
    buffer.writeln('Row Number,Field,Error Message');
    for (final error in errors) {
      buffer.writeln(
        '${error.rowNumber},"${error.fieldName}","${error.errorMessage}"',
      );
    }
    return buffer.toString();
  }
}
