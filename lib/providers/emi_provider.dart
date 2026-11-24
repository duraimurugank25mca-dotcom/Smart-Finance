import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/emi_item.dart';

class EmiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<EmiItem> _emis = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmiItem> get emis => _emis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEmis() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _emis = await _api.getEmis();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEmi({
    required String emiName,
    required String loanProvider,
    required double emiAmount,
    required String dueDate,
    String paymentFrequency = 'monthly',
    String category = 'Personal Loan',
    int totalInstallments = 12,
  }) async {
    try {
      await _api.addEmi(
        emiName: emiName,
        loanProvider: loanProvider,
        emiAmount: emiAmount,
        dueDate: dueDate,
        paymentFrequency: paymentFrequency,
        category: category,
        totalInstallments: totalInstallments,
      );
      await fetchEmis();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsPaid(String id) async {
    try {
      await _api.markEmiPaid(id);
      await fetchEmis();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
