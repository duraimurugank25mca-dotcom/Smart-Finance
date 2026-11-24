import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/finance_provider.dart';
import '../../models/budget_item.dart';
import '../../core/theme/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late String _currentMonthYear;

  @override
  void initState() {
    super.initState();
    _currentMonthYear = DateFormat('yyyy-MM').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BudgetProvider>(context, listen: false).fetchBudgets(monthYear: _currentMonthYear);
    });
  }

  void _showSetBudgetDialog() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final expenseCats = finance.expenseCategories;
    final amountCtrl = TextEditingController();
    int? selectedCatId = expenseCats.isNotEmpty ? expenseCats.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Set Monthly Budget',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDarkNavy),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedCatId,
                decoration: const InputDecoration(labelText: 'Expense Category'),
                items: expenseCats.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.iconData, color: c.color, size: 18),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCatId = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget Limit (INR)',
                  prefixText: '₹ ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (selectedCatId == null || amt == null || amt <= 0) return;

                final bProv = Provider.of<BudgetProvider>(context, listen: false);
                await bProv.saveBudget(
                  categoryId: selectedCatId!,
                  monthYear: _currentMonthYear,
                  amount: amt,
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bProv = Provider.of<BudgetProvider>(context);
    final budgets = bProv.budgets;

    final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.budgetLimit);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spentAmount);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Budget Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDarkNavy,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ Set Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _showSetBudgetDialog,
            ),
          ),
        ],
      ),
      body: bProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Monthly Budget Summary Card (Matching Reference Purple Gradient)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL MONTHLY BUDGET LIMIT',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹ ${NumberFormat('#,##,##0.00').format(totalBudget)}',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Spent: ₹ ${NumberFormat('#,##,##0.00').format(totalSpent)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          color: totalSpent > totalBudget ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Category Spending Budgets',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.purpleBorder),
                          backgroundColor: AppTheme.purplePillBg,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 14, color: AppTheme.primaryPurple),
                        label: const Text('Add / Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                        onPressed: _showSetBudgetDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (budgets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.purplePillBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.pie_chart_outline, size: 40, color: AppTheme.primaryPurple),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No category budgets set for this month.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDarkNavy),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Set limits for Food, Fuel, Shopping, and Entertainment.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _showSetBudgetDialog,
                              child: const Text('Set Category Budget'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...budgets.map((b) => _buildBudgetCard(b)),
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetCard(BudgetItem b) {
    final isExceeded = b.isExceeded;
    final isWarning = b.isWarning;
    final progressColor = isExceeded
        ? AppTheme.expenseRed
        : (isWarning ? AppTheme.advancesGold : AppTheme.incomeGreen);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.purplePillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  b.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryPurple),
                ),
              ),
              Text(
                '₹ ${NumberFormat('#,##,##0').format(b.spentAmount)} / ₹ ${NumberFormat('#,##,##0').format(b.budgetLimit)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isExceeded ? AppTheme.expenseRed : AppTheme.textDarkNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (b.progressPercentage / 100).clamp(0.0, 1.0),
            backgroundColor: AppTheme.purpleLightBg,
            color: progressColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${b.progressPercentage}% spent',
                style: TextStyle(fontSize: 12, color: progressColor, fontWeight: FontWeight.bold),
              ),
              Text(
                isExceeded
                    ? 'Exceeded by ₹ ${NumberFormat('#,##,##0').format(b.spentAmount - b.budgetLimit)}'
                    : '₹ ${NumberFormat('#,##,##0').format(b.remainingAmount)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                  color: isExceeded ? AppTheme.expenseRed : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
