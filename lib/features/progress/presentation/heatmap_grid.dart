import 'package:flutter/material.dart';

/// A plain 7-row calendar heatmap (weekday x week), no events/scheduling —
/// just per-day practice intensity — so a full calendar package would be
/// overkill. [counts] is oldest-first, one entry per day, sized to a
/// multiple of 7 (see StreakCalculator.dailyCountsForHeatmap's default).
class HeatmapGrid extends StatelessWidget {
  const HeatmapGrid({super.key, required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = counts.isEmpty
        ? 1
        : counts.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final weeks = (counts.length / 7).ceil();

    return SizedBox(
      height: 7 * 14.0,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: weeks * 7,
        itemBuilder: (context, gridIndex) {
          // GridView with a horizontal scroll direction fills column-major
          // (down each column before moving right) — exactly week-by-week,
          // Sun-Sat top-to-bottom, which is the calendar layout wanted here.
          final index = gridIndex;
          if (index >= counts.length) return const SizedBox.shrink();
          final count = counts[index];
          final intensity = count == 0
              ? 0.0
              : (count / maxCount).clamp(0.15, 1.0);
          return Container(
            decoration: BoxDecoration(
              color: count == 0
                  ? scheme.surfaceContainerHighest
                  : scheme.primary.withValues(alpha: intensity),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}
