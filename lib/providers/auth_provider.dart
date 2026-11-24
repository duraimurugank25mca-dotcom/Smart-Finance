import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _api.isAuthenticated && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> checkAuthStatus() async {
    await _api.init();
    if (_api.isAuthenticated) {
      try {
        _isLoading = true;
        notifyListeners();
        _currentUser = await _api.getProfile();
      } catch (e) {
        await _api.setToken(null);
        _currentUser = null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.login(email, password);
      _currentUser = UserModel.fromJson(data['user']);
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

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
      );
      _currentUser = UserModel.fromJson(data['user']);
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

  Future<void> logout() async {
    await _api.logout();
    _currentUser = null;
    notifyListeners();
  }
}
