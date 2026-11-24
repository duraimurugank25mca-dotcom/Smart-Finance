import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_item.dart';
import '../core/theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionItem transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed;
    final formattedDate = DateFormat('dd MMM, yyyy').format(transaction.transactionDate);

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.expenseRedDark,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Transaction?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy)),
            content: const Text('Are you sure you want to delete this transaction record?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseRedDark, foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome ? AppTheme.incomeGreenBg : AppTheme.expenseRedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            transaction.categoryName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDarkNavy),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.description.isNotEmpty)
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              Text(
                '$formattedDate • ${transaction.paymentMethod}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'} ₹${NumberFormat('#,##,##0.00').format(transaction.amount)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
