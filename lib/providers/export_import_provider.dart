import 'package:flutter/foundation.dart';
import '../models/export_import_models.dart';
import '../services/export_import_service.dart';

class ExportImportProvider with ChangeNotifier {
  final ExportImportService _service = ExportImportService();

  bool _isLoading = false;
  double _progress = 0.0;
  String? _errorMessage;
  ExportResult? _lastExportResult;
  ImportResult? _lastImportResult;

  // Getters
  bool get isLoading => _isLoading;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  ExportResult? get lastExportResult => _lastExportResult;
  ImportResult? get lastImportResult => _lastImportResult;

  // ============================================
  // Export Methods
  // ============================================

  Future<void> exportProducts(ExportFormat format) async {
    _setLoading(true);
    _clearResults();

    try {
      _lastExportResult = await _service.exportProducts(format);
      if (!_lastExportResult!.success) {
        _errorMessage = _lastExportResult!.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Export failed: ${e.toString()}';
      _lastExportResult = ExportResult.failure(_errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> exportCategories(ExportFormat format) async {
    _setLoading(true);
    _clearResults();

    try {
      _lastExportResult = await _service.exportCategories(format);
      if (!_lastExportResult!.success) {
        _errorMessage = _lastExportResult!.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Export failed: ${e.toString()}';
      _lastExportResult = ExportResult.failure(_errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> exportOrders(
    ExportFormat format, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearResults();

    try {
      _lastExportResult = await _service.exportOrders(
        format,
        startDate: startDate,
        endDate: endDate,
      );
      if (!_lastExportResult!.success) {
        _errorMessage = _lastExportResult!.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Export failed: ${e.toString()}';
      _lastExportResult = ExportResult.failure(_errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> exportTransactions(
    ExportFormat format, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _setLoading(true);
    _clearResults();

    try {
      _lastExportResult = await _service.exportTransactions(
        format,
        startDate: startDate,
        endDate: endDate,
      );
      if (!_lastExportResult!.success) {
        _errorMessage = _lastExportResult!.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Export failed: ${e.toString()}';
      _lastExportResult = ExportResult.failure(_errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> exportAllData() async {
    _setLoading(true);
    _clearResults();

    try {
      _lastExportResult = await _service.exportAllData();
      if (!_lastExportResult!.success) {
        _errorMessage = _lastExportResult!.errorMessage;
      }
    } catch (e) {
      _errorMessage = 'Backup failed: ${e.toString()}';
      _lastExportResult = ExportResult.failure(_errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // Import Methods
  // ============================================

  Future<void> importProducts(
    ExportFormat format,
    ImportConflictResolution resolution,
  ) async {
    _setLoading(true);
    _clearResults();

    try {
      // Pick file
      final content = await _service.pickImportFile();
      if (content == null) {
        _errorMessage = 'No file selected';
        _lastImportResult = ImportResult.failure(errorMessage: _errorMessage!);
        _setLoading(false);
        return;
      }

      _lastImportResult = await _service.importProducts(
        content,
        format,
        resolution,
      );
      if (!_lastImportResult!.success) {
        _errorMessage = _lastImportResult!.errors.isNotEmpty
            ? _lastImportResult!.errors.first.errorMessage
            : 'Import failed';
      }
    } catch (e) {
      _errorMessage = 'Import failed: ${e.toString()}';
      _lastImportResult = ImportResult.failure(errorMessage: _errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> importCategories(ExportFormat format) async {
    _setLoading(true);
    _clearResults();

    try {
      // Pick file
      final content = await _service.pickImportFile();
      if (content == null) {
        _errorMessage = 'No file selected';
        _lastImportResult = ImportResult.failure(errorMessage: _errorMessage!);
        _setLoading(false);
        return;
      }

      _lastImportResult = await _service.importCategories(content, format);
      if (!_lastImportResult!.success) {
        _errorMessage = _lastImportResult!.errors.isNotEmpty
            ? _lastImportResult!.errors.first.errorMessage
            : 'Import failed';
      }
    } catch (e) {
      _errorMessage = 'Import failed: ${e.toString()}';
      _lastImportResult = ImportResult.failure(errorMessage: _errorMessage!);
    } finally {
      _setLoading(false);
    }
  }

  // ============================================
  // Error Report
  // ============================================

  String? generateErrorReport() {
    if (_lastImportResult == null || _lastImportResult!.errors.isEmpty) {
      return null;
    }
    return _service.generateErrorReport(_lastImportResult!.errors);
  }

  // ============================================
  // Helper Methods
  // ============================================

  void _setLoading(bool value) {
    _isLoading = value;
    _progress = value ? 0.0 : 1.0;
    notifyListeners();
  }

  void _clearResults() {
    _errorMessage = null;
    _lastExportResult = null;
    _lastImportResult = null;
  }

  void clearResults() {
    _clearResults();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
