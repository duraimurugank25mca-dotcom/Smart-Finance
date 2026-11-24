import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final transactions = finance.transactions;

    final totalAmount = transactions.fold<double>(
      0,
      (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
    );

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Transactions Management',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDarkNavy,
          ),
        ),
        actions: [
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
              label: const Text('+ Add Transaction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FILTER CARD (Matching Reference Image 3)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by description, shop name, or category...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                finance.setSearchQuery('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (val) => finance.setSearchQuery(val),
                  ),
                  const SizedBox(height: 12),

                  // Type Chips
                  Row(
                    children: [
                      _buildTypeFilterChip(
                        label: 'All Ledger',
                        isSelected: finance.selectedTypeFilter == null,
                        onSelected: () => finance.setTypeFilter(null),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        label: 'Income Only',
                        isSelected: finance.selectedTypeFilter == 'income',
                        color: AppTheme.incomeGreen,
                        onSelected: () => finance.setTypeFilter('income'),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeFilterChip(
                        label: 'Expenses Only',
                        isSelected: finance.selectedTypeFilter == 'expense',
                        color: AppTheme.expenseRed,
                        onSelected: () => finance.setTypeFilter('expense'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TRANSACTIONS TABLE CARD (Matching Reference Image 3)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Card Top Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transactions Ledger',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Net Flow: ₹${NumberFormat('#,##,##0.00').format(totalAmount)} • ${transactions.length} Records',
                              style: const TextStyle(fontSize: 12, color: AppTheme.expenseRedDark, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 14, color: AppTheme.textSecondary),
                          label: const Text('Export Statement', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.reports),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),

                  // Table Header Columns
                  Container(
                    color: const Color(0xFFFBFBFE),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                        Expanded(flex: 3, child: Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                        Expanded(flex: 4, child: Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                        Expanded(flex: 2, child: Text('PAYMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                        Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                        SizedBox(width: 44, child: Text('ACTION', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),

                  // Rows
                  if (finance.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
                    )
                  else if (transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(
                        child: Text('No transaction records found matching your filters.', style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.dividerColor),
                      itemBuilder: (ctx, idx) {
                        final tx = transactions[idx];
                        final isIncome = tx.isIncome;
                        final dateStr = DateFormat('MMM dd, yyyy').format(tx.transactionDate);

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          child: Row(
                            children: [
                              // Date
                              Expanded(
                                flex: 2,
                                child: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              ),
                              // Category Pill
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isIncome ? AppTheme.incomeGreenBg : AppTheme.purplePillBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.categoryName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isIncome ? AppTheme.incomeGreenDark : AppTheme.primaryPurple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Description
                              Expanded(
                                flex: 4,
                                child: Text(
                                  tx.description.isNotEmpty ? tx.description : '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textDarkNavy),
                                ),
                              ),
                              // Payment Method
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.paymentMethod,
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
                              // Delete Action
                              SizedBox(
                                width: 44,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.expenseRed),
                                  tooltip: 'Delete Record',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Delete Transaction?'),
                                        content: Text('Remove ${tx.categoryName} (₹${tx.amount}) from ledger?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseRed),
                                            onPressed: () => Navigator.pop(c, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      finance.deleteTransaction(tx.id);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onSelected,
  }) {
    final activeColor = color ?? AppTheme.primaryPurple;
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
