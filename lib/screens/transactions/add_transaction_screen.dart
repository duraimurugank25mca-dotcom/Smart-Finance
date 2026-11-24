import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/finance_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category_item.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;

  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _selectedType;
  CategoryItem? _selectedCategory;
  String _selectedPaymentMethod = 'UPI';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _paymentMethods = [
    'UPI',
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Net Banking',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'expense';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final available = _selectedType == 'income' ? finance.incomeCategories : finance.expenseCategories;
    if (_selectedCategory == null && available.isNotEmpty) {
      _selectedCategory = available.first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final finance = Provider.of<FinanceProvider>(context, listen: false);

    final success = await finance.addTransaction(
      categoryId: _selectedCategory!.id,
      type: _selectedType,
      amount: double.parse(_amountController.text.trim()),
      transactionDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      paymentMethod: _selectedPaymentMethod,
      description: _descriptionController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType == 'income' ? 'Income' : 'Expense'} saved successfully!'),
          backgroundColor: AppTheme.incomeGreenDark,
        ),
      );
      Navigator.pop(context);
    } else if (mounted && finance.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(finance.errorMessage!), backgroundColor: AppTheme.expenseRedDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final availableCategories = _selectedType == 'income'
        ? finance.incomeCategories
        : finance.expenseCategories;

    final isIncome = _selectedType == 'income';
    final primaryColor = isIncome ? AppTheme.incomeGreenDark : AppTheme.expenseRedDark;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Record New ${_selectedType == 'income' ? 'Income' : 'Expense'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDarkNavy),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Segmented Type Selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.appBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = 'income';
                                  if (finance.incomeCategories.isNotEmpty) {
                                    _selectedCategory = finance.incomeCategories.first;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isIncome ? AppTheme.incomeGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+ Add Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isIncome ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedType = 'expense';
                                  if (finance.expenseCategories.isNotEmpty) {
                                    _selectedCategory = finance.expenseCategories.first;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isIncome ? AppTheme.primaryPurple : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '- Add Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !isIncome ? Colors.white : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount (INR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                            hintText: '0.00',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter amount';
                            final n = double.tryParse(val.trim());
                            if (n == null || n <= 0) return 'Enter a valid positive amount';
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category Selector
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<CategoryItem>(
                          value: _selectedCategory != null && availableCategories.contains(_selectedCategory)
                              ? _selectedCategory
                              : (availableCategories.isNotEmpty ? availableCategories.first : null),
                          items: availableCategories.map((c) {
                            return DropdownMenuItem<CategoryItem>(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(c.iconData, color: AppTheme.primaryPurple, size: 18),
                                  const SizedBox(width: 8),
                                  Text(c.name, style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Date Picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.textMuted),
                            ),
                            child: Text(
                              DateFormat('dd MMMM, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Payment Method
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          items: _paymentMethods.map((m) {
                            return DropdownMenuItem<String>(
                              value: m,
                              child: Text(m, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPaymentMethod = val);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description / Notes
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Swiggy dinner, fuel refill at HP, client project payment',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Save ${_selectedType == 'income' ? 'Income' : 'Expense'}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
