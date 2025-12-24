import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ShiftProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  Shift? _currentShift;
  bool _isLoading = false;
  String? _error;

  Shift? get currentShift => _currentShift;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasActiveShift => _currentShift != null;

  ShiftProvider() {
    _notificationService.init();
  }

  // Memeriksa apakah shift aktif, jika tidak, currentShift jadi null
  Future<void> checkActiveShift(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentShift = await _databaseService.getActiveShift(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startShift(String userId, double startCash) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentShift = await _databaseService.startShift(userId, startCash);

      // Attempt to get a better name if possible, otherwise generic
      // In a real scenario, we might pass the name from the UI or fetch user details.
      final userName = _currentShift?.cashierName ?? 'Kasir';

      _notificationService.showShiftOpenedNotification(userName, startCash);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Shift?> endShift(double actualCash) async {
    if (_currentShift == null || _currentShift!.id == null) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final closedShift = await _databaseService.endShift(
        _currentShift!.id!,
        actualCash,
      );

      _notificationService.showShiftClosedNotification(
        closedShift.cashierName ?? 'Kasir',
        actualCash,
        closedShift.difference,
      );

      // Setelah tutup, currentShift jadi null
      _currentShift = null;
      return closedShift;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Shift>> getAllShifts() async {
    return await _databaseService.getAllShifts();
  }
}
