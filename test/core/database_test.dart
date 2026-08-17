import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/persistence/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test('recordSession persists a row retrievable via sessionsOnDay', () async {
    final today = DateTime.now();

    await db.recordSession(
      practiceType: 'meditation',
      startedAt: today,
      plannedSeconds: 600,
      actualSeconds: 600,
      completedNaturally: true,
    );

    final sessions = await db.sessionsOnDay(today);
    expect(sessions, hasLength(1));
    expect(sessions.single.practiceType, 'meditation');
    expect(sessions.single.completedNaturally, isTrue);
  });

  test('sessionsOnDay excludes sessions from other days', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await db.recordSession(
      practiceType: 'box_breathing',
      startedAt: yesterday,
      plannedSeconds: 120,
      actualSeconds: 60,
      completedNaturally: false,
    );

    final todaySessions = await db.sessionsOnDay(DateTime.now());
    expect(todaySessions, isEmpty);
  });

  test(
    'a manually stopped session is still recorded (any started session counts)',
    () async {
      await db.recordSession(
        practiceType: 'meditation',
        startedAt: DateTime.now(),
        plannedSeconds: 1200,
        actualSeconds: 45,
        completedNaturally: false,
      );

      final all = await db.watchAllSessions().first;
      expect(all, hasLength(1));
      expect(all.single.completedNaturally, isFalse);
    },
  );
}
