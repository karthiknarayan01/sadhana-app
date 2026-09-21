import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

/// Minutes practiced per day, last 7 days — [minutes] is oldest-first,
/// exactly 7 entries (see ProgressStats.weeklyMinutes).
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.minutes});

  final List<double> minutes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMinutes = minutes.isEmpty
        ? 1.0
        : minutes.reduce((a, b) => a > b ? a : b);
    final chartMax = maxMinutes <= 0 ? 10.0 : maxMinutes * 1.2;
    final today = DateTime.now();

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final dayOffset = 6 - value.toInt();
                  final day = today.subtract(Duration(days: dayOffset));
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekdayLabels[day.weekday % 7],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < minutes.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: minutes[i],
                    color: scheme.primary,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
