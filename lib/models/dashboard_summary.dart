import 'transaction_item.dart';

class MonthlyTrendPoint {
  final String month;
  final double income;
  final double expense;

  MonthlyTrendPoint({required this.month, required this.income, required this.expense});

  factory MonthlyTrendPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPoint(
      month: json['month'] ?? '',
      income: double.tryParse(json['income']?.toString() ?? '0') ?? 0.0,
      expense: double.tryParse(json['expense']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CategoryBreakdownItem {
  final int id;
  final String name;
  final String colorHex;
  final String? icon;
  final double totalAmount;

  CategoryBreakdownItem({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon,
    required this.totalAmount,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      colorHex: json['color'] ?? '#6366F1',
      icon: json['icon'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DashboardSummary {
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlySavings;
  final double savingsPercentage;
  final List<TransactionItem> recentTransactions;
  final List<MonthlyTrendPoint> monthlyTrend;
  final List<CategoryBreakdownItem> categoryBreakdown;

  DashboardSummary({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlySavings,
    required this.savingsPercentage,
    required this.recentTransactions,
    required this.monthlyTrend,
    required this.categoryBreakdown,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final recentList = (json['recentTransactions'] as List<dynamic>? ?? [])
        .map((t) => TransactionItem.fromJson(t))
        .toList();

    final trendList = (json['monthlyTrend'] as List<dynamic>? ?? [])
        .map((m) => MonthlyTrendPoint.fromJson(m))
        .toList();

    final catList = (json['categoryBreakdown'] as List<dynamic>? ?? [])
        .map((c) => CategoryBreakdownItem.fromJson(c))
        .toList();

    return DashboardSummary(
      totalBalance: double.tryParse(json['totalBalance']?.toString() ?? '0') ?? 0.0,
      totalIncome: double.tryParse(json['totalIncome']?.toString() ?? '0') ?? 0.0,
      totalExpenses: double.tryParse(json['totalExpenses']?.toString() ?? '0') ?? 0.0,
      monthlyIncome: double.tryParse(json['monthlyIncome']?.toString() ?? '0') ?? 0.0,
      monthlyExpenses: double.tryParse(json['monthlyExpenses']?.toString() ?? '0') ?? 0.0,
      monthlySavings: double.tryParse(json['monthlySavings']?.toString() ?? '0') ?? 0.0,
      savingsPercentage: double.tryParse(json['savingsPercentage']?.toString() ?? '0') ?? 0.0,
      recentTransactions: recentList,
      monthlyTrend: trendList,
      categoryBreakdown: catList,
    );
  }
}
