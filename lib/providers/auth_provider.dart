import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final SupabaseService _supabaseService = SupabaseService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isCashier => _currentUser?.role == UserRole.cashier;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResult.contains(ConnectivityResult.none);
      final isSupabaseConfigured = !AppConstants.supabaseUrl.contains(
        'YOUR_SUPABASE_URL',
      );

      User? user;

      // 1. Try Online Login if configured and online
      if (isOnline && isSupabaseConfigured) {
        try {
          // Assuming user uses email/password for Supabase
          // If username is not email, we might need logic here.
          // For now, we pass username as email or assume user types email.
          user = await _supabaseService.login(username, password);

          if (user != null) {
            // Login Success Online -> Cache User Locally
            final existingUser = await _databaseService.getUserById(user.id);
            if (existingUser != null) {
              await _databaseService.updateUser(user);
            } else {
              await _databaseService.insertUser(user);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Online login failed, falling back to local: $e');
          }
        }
      }

      // 2. Fallback to Local Login if Online failed or Offline
      user ??= await _databaseService.authenticateUser(username, password);

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid username or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Verify current password locally
      final user = await _databaseService.authenticateUser(
        _currentUser!.username,
        currentPassword,
      );

      if (user == null) {
        _errorMessage = 'Current password is incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update password
      // Note: In a real hybrid app, we must sync this change to Supabase too.
      // For now, we update locally and mark as unsynced (handled by DatabaseService automatically setting isSynced=0)
      final updatedUser = _currentUser!.copyWith(password: newPassword);
      await _databaseService.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to change password: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      await _databaseService.updateUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
