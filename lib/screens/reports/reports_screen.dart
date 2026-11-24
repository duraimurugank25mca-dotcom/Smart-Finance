import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_downloader.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _api = ApiService();

  late DateTime _startDate;
  late DateTime _endDate;
  String _reportType = 'all'; // 'all', 'income', 'expense'

  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _fetchReportSummary();
  }

  Future<void> _fetchReportSummary() async {
    setState(() => _isLoading = true);
    try {
      final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final eStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final data = await _api.getReportSummary(
        startDate: sStr,
        endDate: eStr,
        reportType: _reportType,
      );
      setState(() => _reportData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRedDark,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDarkNavy,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReportSummary();
    }
  }

  Future<void> _generatePdf() async {
    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date cannot be after end date'),
          backgroundColor: AppTheme.expenseRedDark,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    try {
      final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final eStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final filename = 'SmartFinance_Statement_${sStr}_to_$eStr.pdf';
      final pdfBytes = await _api.generatePdfReport(
        startDate: sStr,
        endDate: eStr,
        reportType: _reportType,
      );

      setState(() => _isGeneratingPdf = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: AppTheme.expenseRedDark, size: 24),
                SizedBox(width: 10),
                Text('PDF Statement Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDarkNavy)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.purplePillBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primaryPurple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$filename (${(pdfBytes.length / 1024).toStringAsFixed(1)} KB)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryPurple),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Statement period: $sStr to $eStr\n'
                  'Type: ${_reportType.toUpperCase()}\n\n'
                  'Your document has been compiled with complete account records, category breakdown, totals, and transaction ledger.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryPurple,
                  side: const BorderSide(color: AppTheme.primaryPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('View in Browser'),
                onPressed: () {
                  openPdfFile(pdfBytes, filename);
                },
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download / Save'),
                onPressed: () {
                  Navigator.pop(ctx);
                  downloadPdfFile(pdfBytes, filename);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.incomeGreenDark,
                      content: Row(
                        children: [
                          const Icon(Icons.file_download_done_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Downloaded "$filename" successfully!'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRedDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sStr = DateFormat('dd MMM, yyyy').format(_startDate);
    final eStr = DateFormat('dd MMM, yyyy').format(_endDate);

    final totalIncome = double.tryParse(_reportData?['totalIncome']?.toString() ?? '0') ?? 0.0;
    final totalExpenses = double.tryParse(_reportData?['totalExpenses']?.toString() ?? '0') ?? 0.0;
    final netSavings = double.tryParse(_reportData?['netSavings']?.toString() ?? '0') ?? 0.0;
    final categories = (_reportData?['categoryBreakdown'] as List<dynamic>? ?? []);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Financial Reports & Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDarkNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: AppTheme.primaryPurple),
            tooltip: 'Select Date Range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Filter Header Card (Matching Reference Image 3 & 4)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statement Period', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('$sStr  ➔  $eStr', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDarkNavy)),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.purpleBorder),
                          backgroundColor: AppTheme.purplePillBg,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded, size: 15, color: AppTheme.primaryPurple),
                        label: const Text('Change Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                        onPressed: _pickDateRange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Report Type Segment Pills (Matching Reference Image 4)
                  Row(
                    children: [
                      _buildTypeSegment('all', 'Income & Expenses'),
                      const SizedBox(width: 8),
                      _buildTypeSegment('income', 'Income Only'),
                      const SizedBox(width: 8),
                      _buildTypeSegment('expense', 'Expense Only'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Totals
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryPurple)))
            else ...[
              LayoutBuilder(
                builder: (ctx, constraints) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'TOTAL INCOME',
                          '₹ ${NumberFormat('#,##,##0.00').format(totalIncome)}',
                          AppTheme.incomeGreen,
                          Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          'TOTAL EXPENSES',
                          '₹ ${NumberFormat('#,##,##0.00').format(totalExpenses)}',
                          AppTheme.expenseRed,
                          Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          'NET SAVINGS',
                          '₹ ${NumberFormat('#,##,##0.00').format(netSavings)}',
                          netSavings >= 0 ? AppTheme.primaryPurple : AppTheme.expenseRedDark,
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // Category-Wise Breakdown Table Card (Matching Reference Image 2 & 3)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Category-Wise Spending Breakdown',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.cardBorder),

                    if (categories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(
                          child: Text(
                            'No transactions found in this date range.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.dividerColor),
                        itemBuilder: (ctx, idx) {
                          final cat = categories[idx];
                          final amt = double.tryParse(cat['total_amount']?.toString() ?? '0') ?? 0.0;
                          final count = cat['count'] ?? 1;
                          final isIncome = cat['type'] == 'income';

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.purplePillBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cat['name'] ?? 'General',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                            title: Text(
                              '$count transaction(s) recorded',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            trailing: Text(
                              '${isIncome ? '+' : '-'} ₹${NumberFormat('#,##,##0.00').format(amt)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Generate PDF Report Button (Matching Reference Image 2 & 5 Purple CTA)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _isGeneratingPdf
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                  label: Text(
                    _isGeneratingPdf ? 'Generating PDF Document...' : 'Generate & Download PDF Statement',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isGeneratingPdf ? null : _generatePdf,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegment(String type, String label) {
    final isSelected = _reportType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _reportType = type);
          _fetchReportSummary();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryPurple : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
