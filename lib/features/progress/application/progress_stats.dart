import '../domain/milestones.dart';

class ProgressStats {
  const ProgressStats({
    required this.totalSessions,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalMinutes,
    required this.heatmapCounts,
    required this.weeklyMinutes,
    required this.unlockedMilestoneIds,
    required this.newlyUnlockedMilestoneIds,
  });

  final int totalSessions;
  final int currentStreak;
  final int longestStreak;
  final int totalMinutes;

  /// One entry per day, oldest first — see StreakCalculator.dailyCountsForHeatmap.
  final List<int> heatmapCounts;

  /// One entry per day for the last 7 days, oldest first — minutes
  /// practiced that day (fl_chart bar per day).
  final List<double> weeklyMinutes;

  final Set<String> unlockedMilestoneIds;

  /// Milestones that became newly unlocked on *this* computation — drives
  /// the confetti celebration exactly once, not on every rebuild.
  final Set<String> newlyUnlockedMilestoneIds;

  MilestoneStats get asMilestoneStats => MilestoneStats(
    totalSessions: totalSessions,
    currentStreak: currentStreak,
    totalMinutes: totalMinutes,
  );
}
