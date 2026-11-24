import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/savings_goal.dart';

class SavingsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<SavingsGoal> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SavingsGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSavingsGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _api.getSavingsGoals();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSavingsGoal({
    required String goalName,
    required double targetAmount,
    double currentAmount = 0.0,
    required String targetDate,
    String category = 'General',
  }) async {
    try {
      await _api.addSavingsGoal(
        goalName: goalName,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        category: category,
      );
      await fetchSavingsGoals();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
