class BudgetItem {
  final String id;
  final int? categoryId;
  final String categoryName;
  final String categoryColor;
  final String? categoryIcon;
  final String monthYear;
  final double budgetLimit;
  final double spentAmount;
  final double remainingAmount;
  final double progressPercentage;
  final bool isExceeded;
  final bool isWarning;

  BudgetItem({
    required this.id,
    this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.categoryIcon,
    required this.monthYear,
    required this.budgetLimit,
    required this.spentAmount,
    required this.remainingAmount,
    required this.progressPercentage,
    required this.isExceeded,
    required this.isWarning,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'] ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '0'),
      categoryName: json['category_name'] ?? 'General',
      categoryColor: json['category_color'] ?? '#6366F1',
      categoryIcon: json['category_icon'],
      monthYear: json['month_year'] ?? '',
      budgetLimit: double.tryParse(json['budget_limit']?.toString() ?? '0') ?? 0.0,
      spentAmount: double.tryParse(json['spent_amount']?.toString() ?? '0') ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0.0,
      progressPercentage: double.tryParse(json['progress_percentage']?.toString() ?? '0') ?? 0.0,
      isExceeded: json['is_exceeded'] ?? false,
      isWarning: json['is_warning'] ?? false,
    );
  }
}
