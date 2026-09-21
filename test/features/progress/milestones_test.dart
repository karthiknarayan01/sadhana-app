import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/progress/domain/milestones.dart';

MilestoneDefinition _find(String id) =>
    milestoneDefinitions.firstWhere((m) => m.id == id);

void main() {
  test('milestone ids are unique', () {
    final ids = milestoneDefinitions.map((m) => m.id).toSet();
    expect(ids, hasLength(milestoneDefinitions.length));
  });

  test('first_session is met by a single session', () {
    const stats = MilestoneStats(
      totalSessions: 1,
      currentStreak: 1,
      totalMinutes: 5,
    );
    expect(_find('first_session').isMet(stats), isTrue);
  });

  test('first_session is not met with zero sessions', () {
    const stats = MilestoneStats(
      totalSessions: 0,
      currentStreak: 0,
      totalMinutes: 0,
    );
    expect(_find('first_session').isMet(stats), isFalse);
  });

  test('streak milestones respect their exact thresholds', () {
    const justUnder = MilestoneStats(
      totalSessions: 10,
      currentStreak: 6,
      totalMinutes: 60,
    );
    const exactly = MilestoneStats(
      totalSessions: 10,
      currentStreak: 7,
      totalMinutes: 60,
    );

    expect(_find('streak_7').isMet(justUnder), isFalse);
    expect(_find('streak_7').isMet(exactly), isTrue);
  });

  test('minutes milestones respect their exact thresholds', () {
    const justUnder = MilestoneStats(
      totalSessions: 1,
      currentStreak: 1,
      totalMinutes: 59,
    );
    const exactly = MilestoneStats(
      totalSessions: 1,
      currentStreak: 1,
      totalMinutes: 60,
    );

    expect(_find('minutes_60').isMet(justUnder), isFalse);
    expect(_find('minutes_60').isMet(exactly), isTrue);
  });
}
