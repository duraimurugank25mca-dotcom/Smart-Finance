import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/budget_item.dart';

class BudgetProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<BudgetItem> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetItem> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBudgets({String? monthYear}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _budgets = await _api.getBudgets(monthYear: monthYear);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBudget({
    required int categoryId,
    required String monthYear,
    required double amount,
  }) async {
    try {
      await _api.saveBudget(
        categoryId: categoryId,
        monthYear: monthYear,
        amount: amount,
      );
      await fetchBudgets(monthYear: monthYear);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
