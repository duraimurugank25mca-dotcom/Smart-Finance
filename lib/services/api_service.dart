import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user.dart';
import '../models/dashboard_summary.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../models/emi_item.dart';
import '../models/budget_item.dart';
import '../models/savings_goal.dart';
import '../models/bill_scan_result.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, String> _headers([String? adminAuditPurpose]) {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      map['Authorization'] = 'Bearer $_token';
    }
    if (adminAuditPurpose != null) {
      map['x-admin-audit-purpose'] = adminAuditPurpose;
    }
    return map;
  }

  // 1. AUTH
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConstants.login),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final token = data['data']['token'];
      await setToken(token);
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to log in');
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String currency = 'INR',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.register),
      headers: _headers(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'preferred_currency': currency,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      final token = data['data']['token'];
      await setToken(token);
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to register account');
  }

  Future<void> logout() async {
    try {
      await http.post(Uri.parse(ApiConstants.logout), headers: _headers());
    } catch (_) {}
    await setToken(null);
  }

  Future<UserModel> getProfile() async {
    final res = await http.get(Uri.parse(ApiConstants.me), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  // 2. DASHBOARD & TRANSACTIONS
  Future<DashboardSummary> getDashboardSummary() async {
    final res = await http.get(Uri.parse(ApiConstants.dashboardSummary), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return DashboardSummary.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to load dashboard summary');
  }

  Future<List<TransactionItem>> getTransactions({
    String? type,
    int? categoryId,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) queryParams['type'] = type;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(ApiConstants.transactions).replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final list = data['data']['transactions'] as List<dynamic>? ?? [];
      return list.map((t) => TransactionItem.fromJson(t)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch transactions');
  }

  Future<TransactionItem> addTransaction({
    required int categoryId,
    required String type,
    required double amount,
    required String transactionDate,
    required String paymentMethod,
    String description = '',
    String? attachmentUrl,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.transactions),
      headers: _headers(),
      body: jsonEncode({
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'transaction_date': transactionDate,
        'payment_method': paymentMethod,
        'description': description,
        'attachment_url': attachmentUrl,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return TransactionItem.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to save transaction');
  }

  Future<void> deleteTransaction(String id) async {
    final res = await http.delete(Uri.parse('${ApiConstants.transactions}/$id'), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete transaction');
    }
  }

  // 3. CATEGORIES
  Future<List<CategoryItem>> getCategories({String? type}) async {
    final uri = Uri.parse(ApiConstants.categories).replace(
      queryParameters: type != null ? {'type': type} : null,
    );
    final res = await http.get(uri, headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((c) => CategoryItem.fromJson(c)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load categories');
  }

  // 4. REPORTS & PDF
  Future<Map<String, dynamic>> getReportSummary({
    required String startDate,
    required String endDate,
    String reportType = 'all',
  }) async {
    final uri = Uri.parse(ApiConstants.reportSummary).replace(queryParameters: {
      'start_date': startDate,
      'end_date': endDate,
      'report_type': reportType,
    });
    final res = await http.get(uri, headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to load report summary');
  }

  Future<Uint8List> generatePdfReport({
    required String startDate,
    required String endDate,
    String reportType = 'all',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.reportPdf),
      headers: _headers(),
      body: jsonEncode({
        'start_date': startDate,
        'end_date': endDate,
        'report_type': reportType,
      }),
    );
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    final data = jsonDecode(res.body);
    throw Exception(data['message'] ?? 'Failed to generate financial PDF');
  }

  // 5. EMI & REMINDERS
  Future<List<EmiItem>> getEmis() async {
    final res = await http.get(Uri.parse(ApiConstants.emi), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((e) => EmiItem.fromJson(e)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch EMIs');
  }

  Future<EmiItem> addEmi({
    required String emiName,
    required String loanProvider,
    required double emiAmount,
    required String dueDate,
    String paymentFrequency = 'monthly',
    String category = 'Personal Loan',
    int totalInstallments = 12,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.emi),
      headers: _headers(),
      body: jsonEncode({
        'emi_name': emiName,
        'loan_provider': loanProvider,
        'emi_amount': emiAmount,
        'due_date': dueDate,
        'payment_frequency': paymentFrequency,
        'category': category,
        'total_installments': totalInstallments,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return EmiItem.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create EMI');
  }

  Future<void> markEmiPaid(String emiId) async {
    final res = await http.post(Uri.parse('${ApiConstants.emi}/$emiId/pay'), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to mark EMI as paid');
    }
  }

  // 6. BUDGETS
  Future<List<BudgetItem>> getBudgets({String? monthYear}) async {
    final uri = Uri.parse(ApiConstants.budgets).replace(
      queryParameters: monthYear != null ? {'month_year': monthYear} : null,
    );
    final res = await http.get(uri, headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final list = data['data']['budgets'] as List<dynamic>? ?? [];
      return list.map((b) => BudgetItem.fromJson(b)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch budgets');
  }

  Future<void> saveBudget({
    required int categoryId,
    required String monthYear,
    required double amount,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.budgets),
      headers: _headers(),
      body: jsonEncode({
        'category_id': categoryId,
        'month_year': monthYear,
        'amount': amount,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save budget');
    }
  }

  // 7. SAVINGS GOALS
  Future<List<SavingsGoal>> getSavingsGoals() async {
    final res = await http.get(Uri.parse(ApiConstants.savings), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list.map((g) => SavingsGoal.fromJson(g)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to fetch savings goals');
  }

  Future<SavingsGoal> addSavingsGoal({
    required String goalName,
    required double targetAmount,
    double currentAmount = 0.0,
    required String targetDate,
    String category = 'General',
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.savings),
      headers: _headers(),
      body: jsonEncode({
        'goal_name': goalName,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate,
        'category': category,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201 && data['success'] == true) {
      return SavingsGoal.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to create savings goal');
  }

  // 8. BILL SCANNER
  Future<BillScanResult> scanBill({required String rawOcrText, String? imageUrl}) async {
    final res = await http.post(
      Uri.parse(ApiConstants.billScan),
      headers: _headers(),
      body: jsonEncode({
        'raw_ocr_text': rawOcrText,
        'image_url': imageUrl,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return BillScanResult.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to process bill scan');
  }

  Future<TransactionItem> confirmBill({
    required String billScanId,
    required int categoryId,
    required double finalAmount,
    required String paymentMethod,
    String? shopName,
    String? billDate,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.billConfirm),
      headers: _headers(),
      body: jsonEncode({
        'bill_scan_id': billScanId,
        'category_id': categoryId,
        'final_amount': finalAmount,
        'payment_method': paymentMethod,
        'shop_name': shopName,
        'bill_date': billDate,
        'description': description,
      }),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return TransactionItem.fromJson(data['data']['transaction']);
    }
    throw Exception(data['message'] ?? 'Failed to confirm bill transaction');
  }

  Future<List<dynamic>> getBillHistory() async {
    final res = await http.get(Uri.parse(ApiConstants.billHistory), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  Future<Map<String, dynamic>> getBillAnalytics() async {
    final res = await http.get(Uri.parse(ApiConstants.billAnalytics), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'] as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  // 9. AI & VOICE
  Future<Map<String, dynamic>> analyseFinancials() async {
    final res = await http.post(Uri.parse(ApiConstants.aiAnalyse), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to analyze financials');
  }

  Future<String> askAiAssistant(String question) async {
    final res = await http.post(
      Uri.parse(ApiConstants.aiChat),
      headers: _headers(),
      body: jsonEncode({'question': question}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data']['answer'] ?? 'I have analyzed your query.';
    }
    throw Exception(data['message'] ?? 'Failed to get AI assistant answer');
  }

  Future<Map<String, dynamic>> parseVoiceCommand(String text, {String language = 'en'}) async {
    final res = await http.post(
      Uri.parse(ApiConstants.voiceParse),
      headers: _headers(),
      body: jsonEncode({'text': text, 'language': language}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to parse voice command');
  }

  // 10. ADMIN
  Future<Map<String, dynamic>> getAdminUsers({String? search, int page = 1}) async {
    final uri = Uri.parse(ApiConstants.adminUsers).replace(queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to load users');
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    final res = await http.put(
      Uri.parse('${ApiConstants.adminUsers}/$userId/status'),
      headers: _headers(),
      body: jsonEncode({'is_active': isActive}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to toggle user status');
    }
  }

  Future<Map<String, dynamic>> getAdminAnalytics() async {
    final res = await http.get(Uri.parse(ApiConstants.adminAnalytics), headers: _headers());
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to load system analytics');
  }
}
