import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/dashboard_summary.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';

class FinanceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  DashboardSummary? _dashboardSummary;
  List<TransactionItem> _transactions = [];
  List<CategoryItem> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String? _selectedTypeFilter;
  int? _selectedCategoryFilter;
  String _searchQuery = '';

  DashboardSummary? get dashboardSummary => _dashboardSummary;
  List<TransactionItem> get transactions => _transactions;
  List<CategoryItem> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedTypeFilter => _selectedTypeFilter;
  int? get selectedCategoryFilter => _selectedCategoryFilter;

  List<CategoryItem> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();
  List<CategoryItem> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchDashboardSummary(),
        fetchTransactions(),
        fetchCategories(),
      ]);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardSummary() async {
    try {
      _dashboardSummary = await _api.getDashboardSummary();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dashboard summary: $e');
    }
  }

  Future<void> fetchTransactions() async {
    try {
      _transactions = await _api.getTransactions(
        type: _selectedTypeFilter,
        categoryId: _selectedCategoryFilter,
        search: _searchQuery,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  Future<void> fetchCategories() async {
    try {
      _categories = await _api.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }
  }

  void setTypeFilter(String? type) {
    _selectedTypeFilter = type;
    fetchTransactions();
  }

  void setCategoryFilter(int? categoryId) {
    _selectedCategoryFilter = categoryId;
    fetchTransactions();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchTransactions();
  }

  Future<bool> addTransaction({
    required int categoryId,
    required String type,
    required double amount,
    required String transactionDate,
    required String paymentMethod,
    String description = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.addTransaction(
        categoryId: categoryId,
        type: type,
        amount: amount,
        transactionDate: transactionDate,
        paymentMethod: paymentMethod,
        description: description,
      );

      // Dashboard data must update automatically after transactions are saved
      await Future.wait([
        fetchDashboardSummary(),
        fetchTransactions(),
      ]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _api.deleteTransaction(id);
      await Future.wait([
        fetchDashboardSummary(),
        fetchTransactions(),
      ]);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
