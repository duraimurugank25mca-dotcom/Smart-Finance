import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_summary.dart';
import '../core/theme/app_theme.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final List<MonthlyTrendPoint> trend;

  const IncomeExpenseBarChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Insufficient historical monthly data for chart.')),
      );
    }

    final displayTrend = trend.length > 5 ? trend.sublist(trend.length - 5) : trend;

    double maxVal = 10000;
    for (final p in displayTrend) {
      if (p.income > maxVal) maxVal = p.income;
      if (p.expense > maxVal) maxVal = p.expense;
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final isIncome = rodIndex == 0;
                return BarTooltipItem(
                  '${isIncome ? 'Income' : 'Expense'}: ₹${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < displayTrend.length) {
                    final monthStr = displayTrend[idx].month;
                    // Format YYYY-MM into MMM
                    final parts = monthStr.split('-');
                    final monthName = parts.length > 1 ? _monthName(parts[1]) : monthStr;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(monthName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxVal / 3),
            getDrawingHorizontalLine: (val) => FlLine(
              color: Colors.grey.withOpacity(0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: displayTrend.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: p.income,
                  color: AppTheme.incomeGreen,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                BarChartRodData(
                  toY: p.expense,
                  color: AppTheme.expenseRed,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _monthName(String monthNum) {
    switch (monthNum) {
      case '01': return 'Jan';
      case '02': return 'Feb';
      case '03': return 'Mar';
      case '04': return 'Apr';
      case '05': return 'May';
      case '06': return 'Jun';
      case '07': return 'Jul';
      case '08': return 'Aug';
      case '09': return 'Sep';
      case '10': return 'Oct';
      case '11': return 'Nov';
      case '12': return 'Dec';
      default: return monthNum;
    }
  }
}
