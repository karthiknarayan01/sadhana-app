import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/providers.dart';
import 'package:sadhana/features/progress/application/progress_providers.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test(
    'a newly-met milestone is persisted as unlocked in the database',
    () async {
      await db.recordSession(
        practiceType: 'meditation',
        startedAt: DateTime.now(),
        plannedSeconds: 600,
        actualSeconds: 600,
        completedNaturally: true,
      );

      final stats = await container.read(progressStatsProvider.future);

      expect(stats.newlyUnlockedMilestoneIds, contains('first_session'));

      final persisted = await db.unlockedMilestoneIds();
      expect(persisted, contains('first_session'));
    },
  );

  test(
    'an already-unlocked milestone is never reported as newly unlocked again',
    () async {
      await db.unlockMilestone('first_session', DateTime.now());
      await db.recordSession(
        practiceType: 'meditation',
        startedAt: DateTime.now(),
        plannedSeconds: 600,
        actualSeconds: 600,
        completedNaturally: true,
      );

      final stats = await container.read(progressStatsProvider.future);

      expect(stats.newlyUnlockedMilestoneIds, isNot(contains('first_session')));
      expect(stats.unlockedMilestoneIds, contains('first_session'));
    },
  );
}
