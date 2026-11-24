import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/income_expense_bar_chart.dart';
import '../../widgets/voice_assistant_modal.dart';
import '../../routes/app_routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchAllData();
    });
  }

  void _openVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceAssistantModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final summary = finance.dashboardSummary;

    final totalIncome = summary?.totalIncome ?? 0.0;
    final totalExpenses = summary?.totalExpenses ?? 0.0;
    final totalBalance = summary?.totalBalance ?? (totalIncome - totalExpenses);
    final monthlySavings = summary?.monthlySavings ?? 0.0;
    final savingsPct = summary?.savingsPercentage ?? 0.0;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDarkNavy,
          ),
        ),
        actions: [
          // Mode Switcher pill (Admin <-> User)
          if (auth.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.purplePillBg,
                  side: const BorderSide(color: AppTheme.purpleBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppTheme.primaryPurple),
                label: const Text('Admin Console', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
              ),
            ),

          // Add Expense Quick Action Pill
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('+ Add Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction, arguments: {'type': 'expense'}),
            ),
          ),

          // Add Income Quick Action Pill
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('+ Add Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction, arguments: {'type': 'income'}),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => finance.fetchAllData(),
        child: finance.isLoading && summary == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: PRIMARY FINANCIAL METRIC CARDS (Matching Reference Image 2)
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                              child: MetricCard(
                                title: 'Total Income',
                                value: '₹${NumberFormat('#,##,##0.00').format(totalIncome)}',
                                subtitle: 'Direct credits & salary',
                                icon: Icons.currency_rupee_rounded,
                                accentColor: AppTheme.incomeGreen,
                              ),
                            ),
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                              child: MetricCard(
                                title: 'Total Expenses',
                                value: '₹${NumberFormat('#,##,##0.00').format(totalExpenses)}',
                                subtitle: 'Operations, bills & spending',
                                icon: Icons.trending_down_rounded,
                                accentColor: AppTheme.expenseRed,
                              ),
                            ),
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                              child: MetricCard(
                                title: 'Available Balance',
                                value: '₹${NumberFormat('#,##,##0.00').format(totalBalance)}',
                                subtitle: 'Total Income - Total Expenses',
                                icon: Icons.account_balance_rounded,
                                accentColor: AppTheme.balanceBlue,
                              ),
                            ),
                            SizedBox(
                              width: isWide ? (constraints.maxWidth - 42) / 4 : (constraints.maxWidth - 14) / 2,
                              child: MetricCard(
                                title: 'Monthly Savings',
                                value: '₹${NumberFormat('#,##,##0.00').format(monthlySavings)}',
                                subtitle: '$savingsPct% of monthly income saved',
                                icon: Icons.savings_rounded,
                                accentColor: AppTheme.advancesGold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // SECONDARY SUMMARY ROW (Matching Reference Image 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniMetric(
                            'TOTAL INCOME',
                            '₹${NumberFormat('#,##,##0.00').format(summary?.monthlyIncome ?? 0)}',
                            AppTheme.incomeGreen,
                            Icons.folder_open_rounded,
                          ),
                          Container(width: 1, height: 36, color: AppTheme.dividerColor),
                          _buildMiniMetric(
                            'TOTAL EXPENSES',
                            '₹${NumberFormat('#,##,##0.00').format(summary?.monthlyExpenses ?? 0)}',
                            AppTheme.expenseRed,
                            Icons.bar_chart_rounded,
                          ),
                          Container(width: 1, height: 36, color: AppTheme.dividerColor),
                          _buildMiniMetric(
                            'NET SAVINGS',
                            '₹${NumberFormat('#,##,##0.00').format(monthlySavings)}',
                            AppTheme.primaryPurple,
                            Icons.rocket_launch_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // QUICK ACTION NAVIGATION BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickButton(
                            label: 'Voice AI Assistant',
                            icon: Icons.mic_rounded,
                            color: AppTheme.primaryPurple,
                            onTap: _openVoiceAssistant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickButton(
                            label: 'Smart Bill Scanner',
                            icon: Icons.qr_code_scanner_rounded,
                            color: const Color(0xFF6366F1),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.billScanner),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickButton(
                            label: 'PDF Statement',
                            icon: Icons.picture_as_pdf_rounded,
                            color: AppTheme.advancesGold,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.reports),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickButton(
                            label: 'EMI Commitments',
                            icon: Icons.account_balance_outlined,
                            color: AppTheme.clientIndigo,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.emi),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // CHARTS SECTION (Income vs Expense & Category Pie)
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        final isWide = constraints.maxWidth > 700;
                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildChartCard(
                                  title: 'Income vs Expense Trend',
                                  child: IncomeExpenseBarChart(trend: summary?.monthlyTrend ?? []),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: _buildChartCard(
                                  title: 'Expense Category Breakdown',
                                  child: CategoryPieChart(categories: summary?.categoryBreakdown ?? []),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildChartCard(
                                title: 'Income vs Expense Trend',
                                child: IncomeExpenseBarChart(trend: summary?.monthlyTrend ?? []),
                              ),
                              const SizedBox(height: 16),
                              _buildChartCard(
                                title: 'Expense Category Breakdown',
                                child: CategoryPieChart(categories: summary?.categoryBreakdown ?? []),
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 22),

                    // RECENT TRANSACTIONS TABLE (Matching Reference Image 2 Table Format)
                    _buildRecentTransactionsTable(finance),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 14, color: color),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTable(FinanceProvider finance) {
    final recent = finance.dashboardSummary?.recentTransactions ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions Ledger',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.transactions),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          // Table Header
          Container(
            color: const Color(0xFFFBFBFE),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('CATEGORY / NOTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                Expanded(flex: 2, child: Text('PAYMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),

          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('No transactions recorded yet.', style: TextStyle(color: AppTheme.textMuted))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.dividerColor),
              itemBuilder: (ctx, idx) {
                final tx = recent[idx];
                final isIncome = tx.isIncome;
                final dateStr = DateFormat('MMM dd, yyyy').format(tx.transactionDate);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      // Category & Note
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.purplePillBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx.categoryName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Payment
                      Expanded(
                        flex: 2,
                        child: Text(
                          tx.paymentMethod,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          dateStr,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ),
                      // Amount
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${isIncome ? '+' : '-'}₹${NumberFormat('#,##,##0.00').format(tx.amount)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isIncome ? AppTheme.incomeGreenDark : AppTheme.expenseRedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
