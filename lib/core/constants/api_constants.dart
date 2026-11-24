class ApiConstants {
  // Configurable base URL. Default is localhost for development.
  // For physical Android device / emulator, 10.0.2.2 or LAN IP can be substituted.
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String me = '$baseUrl/auth/me';
  static const String profile = '$baseUrl/auth/profile';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';

  // Transaction endpoints
  static const String transactions = '$baseUrl/transactions';
  static const String dashboardSummary = '$baseUrl/transactions/summary';
  static const String categories = '$baseUrl/categories';

  // Reports
  static const String reportSummary = '$baseUrl/reports/summary';
  static const String reportPdf = '$baseUrl/reports/pdf';

  // EMI & Reminders
  static const String emi = '$baseUrl/emi';
  static const String reminders = '$baseUrl/reminders';
  static const String notifications = '$baseUrl/reminders/notifications';

  // Budgets & Savings
  static const String budgets = '$baseUrl/budgets';
  static const String savings = '$baseUrl/savings';

  // Bill Scanner
  static const String billScan = '$baseUrl/bills/scan';
  static const String billConfirm = '$baseUrl/bills/confirm';
  static const String billHistory = '$baseUrl/bills';
  static const String billAnalytics = '$baseUrl/bills/analytics';

  // AI & Voice
  static const String aiAnalyse = '$baseUrl/ai/analyse';
  static const String aiChat = '$baseUrl/ai/chat';
  static const String aiInsights = '$baseUrl/ai/insights';
  static const String voiceParse = '$baseUrl/voice/parse';

  // Admin
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminAnalytics = '$baseUrl/admin/analytics';
  static const String adminLogs = '$baseUrl/admin/logs';
  static const String adminSettings = '$baseUrl/admin/settings';
}
