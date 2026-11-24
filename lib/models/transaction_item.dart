import 'package:flutter/material.dart';

class TransactionItem {
  final String id;
  final String? userId;
  final int categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String type; // 'income' or 'expense'
  final double amount;
  final DateTime transactionDate;
  final String paymentMethod;
  final String description;
  final String? attachmentUrl;
  final DateTime? createdAt;

  TransactionItem({
    required this.id,
    this.userId,
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.type,
    required this.amount,
    required this.transactionDate,
    required this.paymentMethod,
    this.description = '',
    this.attachmentUrl,
    this.createdAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Color get color {
    if (categoryColor != null) {
      try {
        final hex = categoryColor!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] ?? '',
      userId: json['user_id'],
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name'] ?? 'General',
      categoryIcon: json['category_icon'],
      categoryColor: json['category_color'],
      type: json['type'] ?? 'expense',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: json['payment_method'] ?? 'Cash',
      description: json['description'] ?? '',
      attachmentUrl: json['attachment_url'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'payment_method': paymentMethod,
      'description': description,
      'attachment_url': attachmentUrl,
    };
  }
}
