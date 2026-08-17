import '../../../core/persistence/database.dart';
import '../domain/milestones.dart';
import '../domain/streak_calculator.dart';
import 'progress_stats.dart';

/// Combines the pure streak/milestone math (domain/) with real session rows
/// from the database — kept out of the provider itself so the arithmetic is
/// testable without a real drift instance (see
/// test/features/progress/progress_stats_calculator_test.dart).
class ProgressStatsCalculator {
  ProgressStatsCalculator._();

  static ProgressStats compute({
    required List<Session> sessions,
    required Set<String> alreadyUnlockedMilestoneIds,
    required DateTime now,
  }) {
    final startDates = sessions.map((s) => s.startedAt).toList();
    final totalSessions = sessions.length;
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + (s.actualSeconds ~/ 60),
    );
    final currentStreak = StreakCalculator.currentStreak(
      startDates,
      today: now,
    );
    final longestStreak = StreakCalculator.longestStreak(startDates);
    final heatmapCounts = StreakCalculator.dailyCountsForHeatmap(
      startDates,
      today: now,
    );

    final weeklyMinutes = List<double>.generate(7, (i) {
      final day = StreakCalculator.dateOnly(now)
          .subtract(Duration(days: 6 - i));
      final nextDay = day.add(const Duration(days: 1));
      final minutesThatDay = sessions
          .where(
            (s) => !s.startedAt.isBefore(day) && s.startedAt.isBefore(nextDay),
          )
          .fold<int>(0, (sum, s) => sum + s.actualSeconds);
      return minutesThatDay / 60;
    });

    final stats = MilestoneStats(
      totalSessions: totalSessions,
      currentStreak: currentStreak,
      totalMinutes: totalMinutes,
    );
    final newlyUnlocked = <String>{};
    for (final def in milestoneDefinitions) {
      if (def.isMet(stats) && !alreadyUnlockedMilestoneIds.contains(def.id)) {
        newlyUnlocked.add(def.id);
      }
    }

    return ProgressStats(
      totalSessions: totalSessions,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalMinutes: totalMinutes,
      heatmapCounts: heatmapCounts,
      weeklyMinutes: weeklyMinutes,
      unlockedMilestoneIds: {...alreadyUnlockedMilestoneIds, ...newlyUnlocked},
      newlyUnlockedMilestoneIds: newlyUnlocked,
    );
  }
}
