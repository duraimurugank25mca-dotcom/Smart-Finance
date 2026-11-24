import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/dashboard_summary.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryBreakdownItem> categories;

  const CategoryPieChart({super.key, required this.categories});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1;

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.indigoAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No expense categories recorded this month.'),
        ),
      );
    }

    final total = widget.categories.fold<double>(0, (sum, c) => sum + c.totalAmount);

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: widget.categories.asMap().entries.map((entry) {
                final idx = entry.key;
                final cat = entry.value;
                final isTouched = idx == touchedIndex;
                final fontSize = isTouched ? 14.0 : 11.0;
                final radius = isTouched ? 65.0 : 55.0;
                final percentage = total > 0 ? (cat.totalAmount / total * 100).toStringAsFixed(0) : '0';

                return PieChartSectionData(
                  color: _parseColor(cat.colorHex),
                  value: cat.totalAmount,
                  title: '$percentage%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.categories.take(6).map((cat) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _parseColor(cat.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  cat.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
