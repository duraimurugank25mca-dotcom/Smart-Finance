import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/models/transaction_item.dart';
import 'package:smart_finance/models/dashboard_summary.dart';
import 'package:smart_finance/models/emi_item.dart';
import 'package:smart_finance/models/budget_item.dart';
import 'package:smart_finance/models/savings_goal.dart';
import 'package:smart_finance/services/voice_service.dart';

void main() {
  group('Smart Finance Manager Unit & Model Test Suite', () {
    test('TransactionItem parses JSON and computes types correctly', () {
      final tx = TransactionItem.fromJson({
        'id': 'tx-123',
        'category_id': 6,
        'category_name': 'Food',
        'type': 'expense',
        'amount': '450.50',
        'transaction_date': '2026-11-17',
        'payment_method': 'UPI',
        'description': 'Lunch',
      });

      expect(tx.id, 'tx-123');
      expect(tx.isExpense, true);
      expect(tx.isIncome, false);
      expect(tx.amount, 450.50);
      expect(tx.categoryName, 'Food');
      expect(tx.paymentMethod, 'UPI');
    });

    test('DashboardSummary computes net balance and savings percentage', () {
      final summary = DashboardSummary.fromJson({
        'totalBalance': 85000.0,
        'totalIncome': 120000.0,
        'totalExpenses': 35000.0,
        'monthlyIncome': 65000.0,
        'monthlyExpenses': 25000.0,
        'monthlySavings': 40000.0,
        'savingsPercentage': 61.5,
        'recentTransactions': [],
        'monthlyTrend': [],
        'categoryBreakdown': [],
      });

      expect(summary.totalBalance, 85000.0);
      expect(summary.monthlySavings, 40000.0);
      expect(summary.savingsPercentage, 61.5);
    });

    test('EmiItem identifies active and overdue status correctly', () {
      final futureEmi = EmiItem.fromJson({
        'id': 'emi-1',
        'emi_name': 'Bike Loan',
        'loan_provider': 'HDFC Bank',
        'emi_amount': 4500.0,
        'due_date': '2026-11-28',
        'status': 'active',
        'total_installments': 24,
        'paid_installments': 8,
        'days_remaining': 11,
      });

      expect(futureEmi.isOverdue, false);
      expect(futureEmi.isPaid, false);
      expect(futureEmi.daysRemaining, 11);

      final overdueEmi = EmiItem.fromJson({
        'id': 'emi-2',
        'emi_name': 'Card Bill',
        'loan_provider': 'ICICI Bank',
        'emi_amount': 2500.0,
        'due_date': '2026-11-01',
        'status': 'overdue',
        'total_installments': 12,
        'paid_installments': 4,
        'days_remaining': -15,
      });

      expect(overdueEmi.isOverdue, true);
    });

    test('BudgetItem calculates exceeded and warning states', () {
      final budgetWarning = BudgetItem.fromJson({
        'id': 'b-1',
        'category_id': 6,
        'category_name': 'Food',
        'month_year': '2026-11',
        'budget_limit': 6000.0,
        'spent_amount': 5200.0,
        'remaining_amount': 800.0,
        'progress_percentage': 86.7,
        'is_exceeded': false,
        'is_warning': true,
      });

      expect(budgetWarning.isWarning, true);
      expect(budgetWarning.isExceeded, false);
      expect(budgetWarning.remainingAmount, 800.0);

      final budgetExceeded = BudgetItem.fromJson({
        'id': 'b-2',
        'category_id': 7,
        'category_name': 'Petrol',
        'month_year': '2026-11',
        'budget_limit': 3000.0,
        'spent_amount': 3400.0,
        'remaining_amount': 0.0,
        'progress_percentage': 113.3,
        'is_exceeded': true,
        'is_warning': true,
      });

      expect(budgetExceeded.isExceeded, true);
    });

    test('SavingsGoal progress percentage and remaining amounts', () {
      final goal = SavingsGoal.fromJson({
        'id': 'g-1',
        'goal_name': 'Laptop Upgrade',
        'target_amount': 100000.0,
        'current_amount': 45000.0,
        'target_date': '2027-01-01',
        'category': 'Gadgets',
      });

      expect(goal.targetAmount, 100000.0);
      expect(goal.currentAmount, 45000.0);
      expect(goal.remainingAmount, 55000.0);
      expect(goal.progressPercentage, 45.0);
    });

    test('VoiceService state and language selection', () {
      final voice = VoiceService();
      expect(voice.selectedLanguage, 'en');
      expect(voice.state, VoiceListeningState.idle);

      voice.setLanguage('ta');
      expect(voice.selectedLanguage, 'ta');

      voice.setLanguage('tanglish');
      expect(voice.selectedLanguage, 'tanglish');

      voice.toggleMute();
      expect(voice.isMuted, true);
      voice.toggleMute();
      expect(voice.isMuted, false);
    });
  });
}
