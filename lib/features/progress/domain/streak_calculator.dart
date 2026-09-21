/// Pure streak/heatmap math over a list of session dates — no Flutter/IO
/// dependencies, so it's directly testable. [ProgressStatsNotifier] (see
/// application/) is the thin shell that supplies real session data from
/// the database.
class StreakCalculator {
  StreakCalculator._();

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// The current streak in days: consecutive days with >=1 session, counted
  /// backwards from whichever of today/yesterday most recently has one. Not
  /// yet having practiced *today* doesn't break a streak that was alive as
  /// of yesterday — it only breaks once a full day is skipped entirely.
  static int currentStreak(
    List<DateTime> sessionDates, {
    required DateTime today,
  }) {
    final days = sessionDates.map(dateOnly).toSet();
    final todayOnly = dateOnly(today);

    var cursor = todayOnly;
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest streak anywhere in the history, same day-gap rule as
  /// [currentStreak] but scanning the whole timeline rather than just the
  /// tail ending today/yesterday.
  static int longestStreak(List<DateTime> sessionDates) {
    final days = sessionDates.map(dateOnly).toSet().toList()..sort();
    if (days.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > longest) longest = current;
    }
    return longest;
  }

  /// Session counts per day for the [days]-day window ending at [today]
  /// (inclusive) — the data a calendar heatmap renders directly. Always
  /// returns exactly [days] entries, oldest first, zero-filled for days
  /// with no practice.
  static List<int> dailyCountsForHeatmap(
    List<DateTime> sessionDates, {
    required DateTime today,
    int days = 84, // 12 weeks
  }) {
    final counts = <DateTime, int>{};
    for (final date in sessionDates.map(dateOnly)) {
      counts[date] = (counts[date] ?? 0) + 1;
    }
    final todayOnly = dateOnly(today);
    return List.generate(days, (i) {
      final day = todayOnly.subtract(Duration(days: days - 1 - i));
      return counts[day] ?? 0;
    });
  }
}
