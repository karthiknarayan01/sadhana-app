import 'package:drift/drift.dart';

import 'connection/connection.dart' as connection;

part 'database.g.dart';

/// One row per practice session — meditation or either breathing technique.
/// Both a natural completion and a manual mid-session stop insert a row
/// here; `completedNaturally` is what distinguishes them. This is the
/// source of truth the progress/motivation screens (streaks, heatmap,
/// charts) read from — not a single running counter — since those need
/// per-day, per-session detail, not just a total.
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'meditation' | 'box_breathing' | 'alt_nostril_breathing'
  TextColumn get practiceType => text()();

  DateTimeColumn get startedAt => dateTime()();
  IntColumn get plannedSeconds => integer()();
  IntColumn get actualSeconds => integer()();
  BoolColumn get completedNaturally => boolean()();
}

/// One row per milestone the user has unlocked (see features/progress) —
/// tracked separately from the session history itself so an unlock only
/// ever celebrates once, no matter how many times the underlying criteria
/// re-evaluates true.
class UnlockedMilestones extends Table {
  TextColumn get milestoneId => text()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {milestoneId};
}

@DriftDatabase(tables: [Sessions, UnlockedMilestones])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  /// All sessions started on [day] (local time), most recent first — the
  /// query the meditation/breathing screens' "today" state and the streak
  /// calculation both build on.
  Future<List<Session>> sessionsOnDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(sessions)
          ..where((s) => s.startedAt.isBetweenValues(start, end))
          ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
        .get();
  }

  /// Live view of every session, oldest first — the progress screen watches
  /// this to recompute streaks/charts/milestones as soon as a session is
  /// recorded, with no manual cache invalidation.
  Stream<List<Session>> watchAllSessions() {
    return (select(
      sessions,
    )..orderBy([(s) => OrderingTerm.asc(s.startedAt)])).watch();
  }

  Future<int> recordSession({
    required String practiceType,
    required DateTime startedAt,
    required int plannedSeconds,
    required int actualSeconds,
    required bool completedNaturally,
  }) {
    return into(sessions).insert(
      SessionsCompanion.insert(
        practiceType: practiceType,
        startedAt: startedAt,
        plannedSeconds: plannedSeconds,
        actualSeconds: actualSeconds,
        completedNaturally: completedNaturally,
      ),
    );
  }

  Future<Set<String>> unlockedMilestoneIds() async {
    final rows = await select(unlockedMilestones).get();
    return rows.map((r) => r.milestoneId).toSet();
  }

  /// Upsert rather than a plain insert — an unlock is idempotent by design
  /// (see UnlockedMilestones' own docstring), so a caller that somehow
  /// evaluates the same not-yet-unlocked milestone twice in quick
  /// succession doesn't throw on the primary-key collision.
  Future<void> unlockMilestone(String milestoneId, DateTime unlockedAt) {
    return into(unlockedMilestones).insertOnConflictUpdate(
      UnlockedMilestonesCompanion.insert(
        milestoneId: milestoneId,
        unlockedAt: unlockedAt,
      ),
    );
  }
}
