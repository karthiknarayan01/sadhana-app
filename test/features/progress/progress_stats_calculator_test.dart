import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/features/progress/application/progress_stats_calculator.dart';

Session _session({
  required DateTime startedAt,
  int actualSeconds = 600,
  String practiceType = 'meditation',
}) {
  return Session(
    id: 0,
    practiceType: practiceType,
    startedAt: startedAt,
    plannedSeconds: actualSeconds,
    actualSeconds: actualSeconds,
    completedNaturally: true,
  );
}

void main() {
  final today = DateTime(2026, 3, 15);

  test('totals sessions and minutes across all practice types', () {
    final sessions = [
      _session(startedAt: today, actualSeconds: 600), // 10 min
      _session(
        startedAt: today,
        actualSeconds: 300,
        practiceType: 'box_breathing',
      ), // 5 min
    ];

    final stats = ProgressStatsCalculator.compute(
      sessions: sessions,
      alreadyUnlockedMilestoneIds: {},
      now: today,
    );

    expect(stats.totalSessions, 2);
    expect(stats.totalMinutes, 15);
  });

  test('computes the current streak from session dates', () {
    final sessions = [
      _session(startedAt: today),
      _session(startedAt: today.subtract(const Duration(days: 1))),
    ];

    final stats = ProgressStatsCalculator.compute(
      sessions: sessions,
      alreadyUnlockedMilestoneIds: {},
      now: today,
    );

    expect(stats.currentStreak, 2);
  });

  test('newly meeting a milestone is reported once, not repeatedly', () {
    final sessions = [_session(startedAt: today)]; // meets first_session

    final firstRun = ProgressStatsCalculator.compute(
      sessions: sessions,
      alreadyUnlockedMilestoneIds: {},
      now: today,
    );
    expect(firstRun.newlyUnlockedMilestoneIds, contains('first_session'));
    expect(firstRun.unlockedMilestoneIds, contains('first_session'));

    // Same session data, but this time first_session is already unlocked —
    // matches what the provider passes on the next stream emission after
    // persisting it.
    final secondRun = ProgressStatsCalculator.compute(
      sessions: sessions,
      alreadyUnlockedMilestoneIds: {'first_session'},
      now: today,
    );
    expect(secondRun.newlyUnlockedMilestoneIds, isEmpty);
    expect(secondRun.unlockedMilestoneIds, contains('first_session'));
  });

  test('weeklyMinutes has exactly 7 entries, most recent last', () {
    final sessions = [_session(startedAt: today, actualSeconds: 120)];

    final stats = ProgressStatsCalculator.compute(
      sessions: sessions,
      alreadyUnlockedMilestoneIds: {},
      now: today,
    );

    expect(stats.weeklyMinutes, hasLength(7));
    expect(stats.weeklyMinutes.last, 2.0); // 120s = 2 min, on `today`
  });

  test('an empty history produces zeroed, not-crashing stats', () {
    final stats = ProgressStatsCalculator.compute(
      sessions: [],
      alreadyUnlockedMilestoneIds: {},
      now: today,
    );

    expect(stats.totalSessions, 0);
    expect(stats.currentStreak, 0);
    expect(stats.newlyUnlockedMilestoneIds, isEmpty);
  });
}
