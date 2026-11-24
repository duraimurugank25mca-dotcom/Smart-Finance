import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/finance_provider.dart';
import 'package:smart_finance/providers/emi_provider.dart';
import 'package:smart_finance/providers/budget_provider.dart';
import 'package:smart_finance/providers/savings_provider.dart';
import 'package:smart_finance/providers/ai_provider.dart';
import 'package:smart_finance/services/voice_service.dart';
import 'package:smart_finance/main.dart';

void main() {
  testWidgets('Smart Finance Manager app initialization smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
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

    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Welcome to SMART FINANCE'), findsOneWidget);
    expect(find.text('Sign In to Portal'), findsOneWidget);
  });
}
