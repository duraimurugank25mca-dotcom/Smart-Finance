class EmiItem {
  final String id;
  final String emiName;
  final String loanProvider;
  final double emiAmount;
  final DateTime dueDate;
  final String paymentFrequency;
  final String category;
  final String status; // 'active', 'paid', 'overdue'
  final int totalInstallments;
  final int paidInstallments;
  final int daysRemaining;

  EmiItem({
    required this.id,
    required this.emiName,
    required this.loanProvider,
    required this.emiAmount,
    required this.dueDate,
    this.paymentFrequency = 'monthly',
    this.category = 'Personal Loan',
    this.status = 'active',
    this.totalInstallments = 12,
    this.paidInstallments = 0,
    this.daysRemaining = 0,
  });

  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue' || daysRemaining < 0;

  factory EmiItem.fromJson(Map<String, dynamic> json) {
    return EmiItem(
      id: json['id'] ?? '',
      emiName: json['emi_name'] ?? '',
      loanProvider: json['loan_provider'] ?? '',
      emiAmount: double.tryParse(json['emi_amount']?.toString() ?? '0') ?? 0.0,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentFrequency: json['payment_frequency'] ?? 'monthly',
      category: json['category'] ?? 'Loan',
      status: json['status'] ?? 'active',
      totalInstallments: json['total_installments'] is int
          ? json['total_installments']
          : int.tryParse(json['total_installments']?.toString() ?? '12') ?? 12,
      paidInstallments: json['paid_installments'] is int
          ? json['paid_installments']
          : int.tryParse(json['paid_installments']?.toString() ?? '0') ?? 0,
      daysRemaining: json['days_remaining'] is int
          ? json['days_remaining']
          : int.tryParse(json['days_remaining']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emi_name': emiName,
      'loan_provider': loanProvider,
      'emi_amount': emiAmount,
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'payment_frequency': paymentFrequency,
      'category': category,
      'status': status,
      'total_installments': totalInstallments,
      'paid_installments': paidInstallments,
    };
  }
}
