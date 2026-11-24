import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/ai/ai_assistant_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/emi/emi_management_screen.dart';
import '../screens/budgets/budget_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/scanner/bill_scanner_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String mainShell = '/main';
  static const String transactions = '/transactions';
  static const String addTransaction = '/add-transaction';
  static const String aiAssistant = '/ai-assistant';
  static const String reports = '/reports';
  static const String profile = '/profile';
  static const String emi = '/emi';
  static const String budgets = '/budgets';
  static const String savings = '/savings';
  static const String billScanner = '/bill-scanner';
  static const String adminDashboard = '/admin';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case mainShell:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case transactions:
        return MaterialPageRoute(builder: (_) => const TransactionsScreen());
      case addTransaction:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionScreen(initialType: args?['type']),
        );
      case aiAssistant:
        return MaterialPageRoute(builder: (_) => const AiAssistantScreen());
      case reports:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case emi:
        return MaterialPageRoute(builder: (_) => const EmiManagementScreen());
      case budgets:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());
      case savings:
        return MaterialPageRoute(builder: (_) => const SavingsScreen());
      case billScanner:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialOpt = args?['mode'] == 'upload'
            ? BillInputOption.uploadBill
            : BillInputOption.scanBill;
        return MaterialPageRoute(
          builder: (_) => BillScannerScreen(initialOption: initialOpt),
        );
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
