class SavingsGoal {
  final String id;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;
  final bool isCompleted;
  final double remainingAmount;
  final double progressPercentage;
  final int daysLeft;

  SavingsGoal({
    required this.id,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    this.category = 'General',
    this.isCompleted = false,
    required this.remainingAmount,
    required this.progressPercentage,
    required this.daysLeft,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    final target = double.tryParse(json['target_amount']?.toString() ?? '0') ?? 0.0;
    final current = double.tryParse(json['current_amount']?.toString() ?? '0') ?? 0.0;
    final remaining = json['remaining_amount'] != null
        ? (double.tryParse(json['remaining_amount'].toString()) ?? (target - current))
        : (target - current);
    final progress = json['progress_percentage'] != null
        ? (double.tryParse(json['progress_percentage'].toString()) ?? 0.0)
        : (target > 0 ? (current / target * 100) : 0.0);

    return SavingsGoal(
      id: json['id'] ?? '',
      goalName: json['goal_name'] ?? '',
      targetAmount: target,
      currentAmount: current,
      targetDate: json['target_date'] != null
          ? DateTime.tryParse(json['target_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] ?? 'General',
      isCompleted: json['is_completed'] ?? false,
      remainingAmount: remaining,
      progressPercentage: progress,
      daysLeft: json['days_left'] is int ? json['days_left'] : int.tryParse(json['days_left']?.toString() ?? '0') ?? 0,
    );
  }
}
