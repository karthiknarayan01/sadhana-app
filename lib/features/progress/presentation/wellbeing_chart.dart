import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/wellbeing_curve.dart';

/// Plots WellbeingCurve — an illustrative, general research-pattern curve,
/// not a personal measurement — and marks where the user's own current
/// streak sits on it. The caption below the chart is load-bearing, not
/// decoration: without it this could easily read as "the app measured your
/// happiness," which it never does.
class WellbeingChart extends StatelessWidget {
  const WellbeingChart({super.key, required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final youAreHereDay = currentStreak.clamp(0, WellbeingCurve.horizonDays);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: WellbeingCurve.horizonDays.toDouble(),
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
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
                interval: 30,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${value.toInt()}d',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var day = 0; day <= WellbeingCurve.horizonDays; day++)
                  FlSpot(day.toDouble(), WellbeingCurve.indexForDay(day)),
              ],
              isCurved: true,
              barWidth: 3,
              color: scheme.primary,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            verticalLines: [
              VerticalLine(
                x: youAreHereDay.toDouble(),
                color: scheme.secondary,
                strokeWidth: 2,
                dashArray: [4, 4],
                label: VerticalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.secondary),
                  labelResolver: (_) => 'You: day $youAreHereDay',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
