import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/emi_provider.dart';
import '../../models/emi_item.dart';
import '../../core/theme/app_theme.dart';

class EmiManagementScreen extends StatefulWidget {
  const EmiManagementScreen({super.key});

  @override
  State<EmiManagementScreen> createState() => _EmiManagementScreenState();
}

class _EmiManagementScreenState extends State<EmiManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmiProvider>(context, listen: false).fetchEmis();
    });
  }

  void _showAddEmiDialog() {
    final nameCtrl = TextEditingController();
    final providerCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Bike Loan';
    String frequency = 'monthly';
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Add EMI / Bill Commitment',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDarkNavy),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Commitment Name (e.g. Bike Loan)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerCtrl,
                  decoration: const InputDecoration(labelText: 'Provider / Bank (e.g. HDFC Bank)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'EMI Amount (INR)', prefixText: '₹ '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Commitment Category'),
                  items: const [
                    DropdownMenuItem(value: 'Bike Loan', child: Text('Bike Loan')),
                    DropdownMenuItem(value: 'Car Loan', child: Text('Car Loan')),
                    DropdownMenuItem(value: 'Personal Loan', child: Text('Personal Loan')),
                    DropdownMenuItem(value: 'Home Loan', child: Text('Home Loan')),
                    DropdownMenuItem(value: 'Credit Card Bill', child: Text('Credit Card Bill')),
                    DropdownMenuItem(value: 'Electricity Bill', child: Text('Electricity Bill')),
                    DropdownMenuItem(value: 'Internet Bill', child: Text('Internet Bill')),
                    DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                    DropdownMenuItem(value: 'Insurance', child: Text('Insurance')),
                    DropdownMenuItem(value: 'Subscriptions', child: Text('Subscriptions')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  subtitle: Text(DateFormat('dd MMMM, yyyy').format(dueDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy)),
                  trailing: const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryPurple),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setDialogState(() => dueDate = picked);
                    }
                  },
                ),
              ],
            ),
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
                if (nameCtrl.text.trim().isEmpty || amt == null || amt <= 0) {
                  return;
                }
                final emiProv = Provider.of<EmiProvider>(context, listen: false);
                await emiProv.addEmi(
                  emiName: nameCtrl.text.trim(),
                  loanProvider: providerCtrl.text.trim().isEmpty ? 'Bank' : providerCtrl.text.trim(),
                  emiAmount: amt,
                  dueDate: DateFormat('yyyy-MM-dd').format(dueDate),
                  category: category,
                  paymentFrequency: frequency,
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Commitment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emiProv = Provider.of<EmiProvider>(context);
    final emis = emiProv.emis;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'EMI & Bill Reminders',
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
              label: const Text('+ Add EMI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _showAddEmiDialog,
            ),
          ),
        ],
      ),
      body: emiProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : emis.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppTheme.purplePillBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_outlined, size: 48, color: AppTheme.primaryPurple),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No EMI or Bill Reminders registered.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDarkNavy),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add your loan payments, credit bills, or subscriptions.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showAddEmiDialog,
                        child: const Text('Add First EMI'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => emiProv.fetchEmis(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: emis.length,
                    itemBuilder: (ctx, idx) {
                      final item = emis[idx];
                      return _buildEmiCard(item, emiProv);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmiCard(EmiItem item, EmiProvider emiProv) {
    final isOverdue = item.isOverdue;
    final formattedDue = DateFormat('dd MMM, yyyy').format(item.dueDate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Colored Accent Stripe (Gold/Amber for Advances & EMI matching Image 2)
          Container(
            height: 3.5,
            color: isOverdue ? AppTheme.expenseRed : AppTheme.advancesGold,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.emiName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDarkNavy),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.loanProvider} • ${item.category}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOverdue ? AppTheme.expenseRedBg : AppTheme.purplePillBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOverdue ? 'OVERDUE' : (item.daysRemaining <= 3 ? 'DUE SOON' : 'ACTIVE'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? AppTheme.expenseRedDark : AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount Due', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${NumberFormat('#,##,##0.00').format(item.emiAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textDarkNavy),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Due Date', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          formattedDue,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isOverdue ? AppTheme.expenseRed : AppTheme.textDarkNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: item.totalInstallments > 0 ? (item.paidInstallments / item.totalInstallments) : 0,
                  backgroundColor: AppTheme.purpleLightBg,
                  color: AppTheme.advancesGold,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paid ${item.paidInstallments} of ${item.totalInstallments} installments',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.purpleBorder),
                        backgroundColor: AppTheme.purplePillBg,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primaryPurple),
                      label: const Text('Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Mark EMI Paid?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy)),
                            content: Text(
                              'This will record a ₹${item.emiAmount} expense transaction in your ledger and advance the due date to next month.',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Confirm Payment'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await emiProv.markAsPaid(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.incomeGreenDark,
                                content: Text('${item.emiName} marked paid! Expense logged.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
