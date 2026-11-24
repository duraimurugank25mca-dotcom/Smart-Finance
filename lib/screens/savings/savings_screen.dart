import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/savings_provider.dart';
import '../../models/savings_goal.dart';
import '../../core/theme/app_theme.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SavingsProvider>(context, listen: false).fetchSavingsGoals();
    });
  }

  void _showAddGoalDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    String category = 'Emergency';
    DateTime targetDate = DateTime.now().add(const Duration(days: 180));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Create Savings Goal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDarkNavy),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Goal Title (e.g. Emergency Fund, Laptop)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target Amount (INR)', prefixText: '₹ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Initial Saved (INR)', prefixText: '₹ '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'Emergency', child: Text('Emergency Fund')),
                    DropdownMenuItem(value: 'Gadget', child: Text('Gadgets & Electronics')),
                    DropdownMenuItem(value: 'Travel', child: Text('Travel & Vacation')),
                    DropdownMenuItem(value: 'Vehicle', child: Text('Vehicle Purchase')),
                    DropdownMenuItem(value: 'General', child: Text('General Savings')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Target Date', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  subtitle: Text(DateFormat('dd MMMM, yyyy').format(targetDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy)),
                  trailing: const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryPurple),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => targetDate = picked);
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
                final targetAmt = double.tryParse(targetCtrl.text.trim());
                if (nameCtrl.text.trim().isEmpty || targetAmt == null || targetAmt <= 0) return;

                final currentAmt = double.tryParse(currentCtrl.text.trim()) ?? 0.0;
                final sProv = Provider.of<SavingsProvider>(context, listen: false);
                await sProv.addSavingsGoal(
                  goalName: nameCtrl.text.trim(),
                  targetAmount: targetAmt,
                  currentAmount: currentAmt,
                  targetDate: DateFormat('yyyy-MM-dd').format(targetDate),
                  category: category,
                );
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sProv = Provider.of<SavingsProvider>(context);
    final goals = sProv.goals;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Savings Goals',
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
              label: const Text('+ New Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: _showAddGoalDialog,
            ),
          ),
        ],
      ),
      body: sProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppTheme.incomeGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.savings_outlined, size: 48, color: AppTheme.incomeGreenDark),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No savings goals created yet.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDarkNavy),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set target amounts for emergency funds, gadgets, or travel.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _showAddGoalDialog,
                        child: const Text('Set First Goal'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => sProv.fetchSavingsGoals(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: goals.length,
                    itemBuilder: (ctx, idx) {
                      final g = goals[idx];
                      return _buildGoalCard(g);
                    },
                  ),
                ),
    );
  }

  Widget _buildGoalCard(SavingsGoal g) {
    final progress = (g.progressPercentage / 100).clamp(0.0, 1.0);
    final formattedDate = DateFormat('dd MMM, yyyy').format(g.targetDate);

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
          // Top Colored Accent Stripe (Emerald Green for savings matching Image 2)
          Container(
            height: 3.5,
            color: AppTheme.incomeGreen,
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        g.goalName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDarkNavy),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.incomeGreenBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${g.progressPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.incomeGreenDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹ ${NumberFormat('#,##,##0').format(g.currentAmount)} saved',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.incomeGreenDark),
                    ),
                    Text(
                      'Target: ₹ ${NumberFormat('#,##,##0').format(g.targetAmount)}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppTheme.purpleLightBg,
                  color: AppTheme.incomeGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining: ₹ ${NumberFormat('#,##,##0').format(g.remainingAmount)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'Target: $formattedDate (${g.daysLeft} days left)',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
