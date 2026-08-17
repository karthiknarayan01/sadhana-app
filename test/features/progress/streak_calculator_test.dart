import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/progress/domain/streak_calculator.dart';

void main() {
  final today = DateTime(2026, 3, 15);

  group('currentStreak', () {
    test('is zero with no sessions at all', () {
      expect(StreakCalculator.currentStreak([], today: today), 0);
    });

    test('counts a session today as a streak of 1', () {
      expect(StreakCalculator.currentStreak([today], today: today), 1);
    });

    test(
      'a session only yesterday still counts — today just hasn\'t happened yet',
      () {
        final yesterday = today.subtract(const Duration(days: 1));
        expect(StreakCalculator.currentStreak([yesterday], today: today), 1);
      },
    );

    test('a gap of a full day breaks the streak', () {
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      expect(StreakCalculator.currentStreak([twoDaysAgo], today: today), 0);
    });

    test('counts consecutive days correctly', () {
      final dates = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
      ];
      expect(StreakCalculator.currentStreak(dates, today: today), 3);
    });

    test('multiple sessions on the same day only count once', () {
      final dates = [
        today,
        today.add(const Duration(hours: 3)),
        today.subtract(const Duration(days: 1)),
      ];
      expect(StreakCalculator.currentStreak(dates, today: today), 2);
    });

    test('an old streak with a gap before today does not count', () {
      final dates = [
        today.subtract(const Duration(days: 10)),
        today.subtract(const Duration(days: 11)),
        today.subtract(const Duration(days: 12)),
      ];
      expect(StreakCalculator.currentStreak(dates, today: today), 0);
    });
  });

  group('longestStreak', () {
    test('is zero with no sessions', () {
      expect(StreakCalculator.longestStreak([]), 0);
    });

    test(
      'finds the longest run anywhere in history, not just the current one',
      () {
        final dates = [
          // A 4-day streak, long ago.
          DateTime(2026, 1, 1),
          DateTime(2026, 1, 2),
          DateTime(2026, 1, 3),
          DateTime(2026, 1, 4),
          // A gap, then a shorter, more recent 2-day streak.
          DateTime(2026, 3, 14),
          DateTime(2026, 3, 15),
        ];
        expect(StreakCalculator.longestStreak(dates), 4);
      },
    );
  });

  group('dailyCountsForHeatmap', () {
    test(
      'returns exactly `days` entries, zero-filled where there is no session',
      () {
        final counts = StreakCalculator.dailyCountsForHeatmap(
          [today],
          today: today,
          days: 7,
        );
        expect(counts, hasLength(7));
        expect(counts.last, 1); // today is the last (most recent) entry
        expect(counts.sublist(0, 6).every((c) => c == 0), isTrue);
      },
    );

    test(
      'multiple sessions on the same day accumulate in that day\'s count',
      () {
        final counts = StreakCalculator.dailyCountsForHeatmap(
          [today, today.add(const Duration(hours: 2))],
          today: today,
          days: 3,
        );
        expect(counts.last, 2);
      },
    );
  });
}
