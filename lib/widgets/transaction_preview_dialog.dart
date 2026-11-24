import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class TransactionPreviewDialog extends StatefulWidget {
  final String title;
  final String type; // 'income' or 'expense'
  final double initialAmount;
  final String initialCategory;
  final String initialPaymentMethod;
  final String initialDate;
  final String initialDescription;
  final Future<void> Function({
    required double amount,
    required String category,
    required String paymentMethod,
    required String date,
    required String description,
  }) onConfirm;

  const TransactionPreviewDialog({
    super.key,
    required this.title,
    required this.type,
    required this.initialAmount,
    required this.initialCategory,
    required this.initialPaymentMethod,
    required this.initialDate,
    required this.initialDescription,
    required this.onConfirm,
  });

  @override
  State<TransactionPreviewDialog> createState() => _TransactionPreviewDialogState();
}

class _TransactionPreviewDialogState extends State<TransactionPreviewDialog> {
  late TextEditingController _amountController;
  late TextEditingController _categoryController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _descriptionController;
  late String _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount.toStringAsFixed(2));
    _categoryController = TextEditingController(text: widget.initialCategory);
    _paymentMethodController = TextEditingController(text: widget.initialPaymentMethod);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _paymentMethodController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == 'income';
    final themeColor = isIncome ? AppTheme.incomeGreenDark : AppTheme.expenseRedDark;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isIncome ? AppTheme.incomeGreenBg : AppTheme.expenseRedBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: themeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.advancesGoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.advancesGold.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: AppTheme.advancesGold, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please verify transaction details before saving to your financial ledger.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
              decoration: InputDecoration(
                labelText: 'Amount (INR)',
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paymentMethodController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy),
              decoration: const InputDecoration(labelText: 'Payment Method (UPI, Cash, Card)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy),
              decoration: const InputDecoration(labelText: 'Description / Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Discard / Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  final amt = double.tryParse(_amountController.text) ?? widget.initialAmount;
                  try {
                    await widget.onConfirm(
                      amount: amt,
                      category: _categoryController.text.trim(),
                      paymentMethod: _paymentMethodController.text.trim(),
                      date: _date,
                      description: _descriptionController.text.trim(),
                    );
                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    setState(() => _isSaving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: AppTheme.expenseRedDark,
                        ),
                      );
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirm & Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
