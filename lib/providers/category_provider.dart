import 'package:flutter/foundation.dart' hide Category;
import '../models/category_model.dart';
import '../services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    // Don't notify here to avoid "setState during build" when called from didChangeDependencies

    try {
      _categories = await _databaseService.getAllCategories();
    } catch (e) {
      _errorMessage = 'Failed to load categories: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners(); // Only notify once, after the operation completes
    }
  }

  Future<bool> addCategory(Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.insertCategory(category);
      await loadCategories(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.updateCategory(category);
      await loadCategories(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.deleteCategory(id);
      await loadCategories(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete category: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper to check if a category name already exists (case-insensitive)
  bool isCategoryNameTaken(String name, {String? excludeId}) {
    return _categories.any(
      (cat) =>
          cat.name.toLowerCase() == name.toLowerCase() && cat.id != excludeId,
    );
  }
}
