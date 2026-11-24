import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/voice_service.dart';
import 'providers/auth_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/emi_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/ai_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => EmiProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => VoiceService()),
      ],
      child: const SmartFinanceApp(),
    ),
  );
}

class SmartFinanceApp extends StatefulWidget {
  const SmartFinanceApp({super.key});

  @override
  State<SmartFinanceApp> createState() => _SmartFinanceAppState();
}

class _SmartFinanceAppState extends State<SmartFinanceApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Finance Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Default clean Duolink light fintech theme
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          if (auth.isLoading && auth.currentUser == null) {
            return const Scaffold(
              backgroundColor: AppTheme.appBackground,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryPurple),
                    SizedBox(height: 16),
                    Text(
                      'Loading Smart Finance Manager...',
                      style: TextStyle(color: AppTheme.textDarkNavy, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }

          if (auth.isAuthenticated) {
            return auth.isAdmin ? const AdminDashboardScreen() : const MainShell();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
