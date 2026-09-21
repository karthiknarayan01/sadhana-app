import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'progress_stats.dart';
import 'progress_stats_calculator.dart';

/// Recomputes on every change to the session history (drift's watch query
/// pushes a new list the moment a session is recorded — no manual
/// invalidation needed) and persists any newly-met milestone as unlocked,
/// exactly once, before yielding the stats that reflect it.
final progressStatsProvider = StreamProvider<ProgressStats>((ref) async* {
  final db = ref.watch(databaseProvider);
  await for (final sessions in db.watchAllSessions()) {
    final alreadyUnlocked = await db.unlockedMilestoneIds();
    final now = DateTime.now();
    final stats = ProgressStatsCalculator.compute(
      sessions: sessions,
      alreadyUnlockedMilestoneIds: alreadyUnlocked,
      now: now,
    );
    for (final id in stats.newlyUnlockedMilestoneIds) {
      await db.unlockMilestone(id, now);
    }
    yield stats;
  }
});
