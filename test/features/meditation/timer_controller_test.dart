import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/providers.dart';
import 'package:sadhana/features/meditation/application/meditation_state.dart';
import 'package:sadhana/features/meditation/application/timer_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_audio_service.dart';

void main() {
  late AppDatabase db;
  late FakeAudioService audio;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    audio = FakeAudioService();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        audioServiceProvider.overrideWithValue(audio),
      ],
    );
    // Let the prefs FutureProvider resolve before each test starts, so
    // build() isn't still on its loading-default when a test begins.
    await container.read(prefsProvider.future);
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('setPlannedSeconds clamps to the 2 minute - 1 hour range', () {
    final notifier = container.read(timerControllerProvider.notifier);

    notifier.setPlannedSeconds(30); // below the 2 min floor
    expect(container.read(timerControllerProvider).plannedSeconds, 120);

    notifier.setPlannedSeconds(4000); // above the 1 hour ceiling
    expect(container.read(timerControllerProvider).plannedSeconds, 3600);

    notifier.setPlannedSeconds(600);
    expect(container.read(timerControllerProvider).plannedSeconds, 600);
  });

  test('a bell fires once per minute during a session, not on completion', () {
    fakeAsync((async) {
      final notifier = container.read(timerControllerProvider.notifier);
      notifier.setPlannedSeconds(180); // 3 minutes

      notifier.start();
      async.elapse(const Duration(minutes: 3));

      // Bells at minute 1 and minute 2 — not a third at the 3-minute mark,
      // since that's completion (the gong's moment instead).
      expect(audio.bellPlayCount, 2);
      expect(audio.gongPlayCount, 1);
      expect(
        container.read(timerControllerProvider).phase,
        MeditationPhase.finished,
      );
    });
  });

  test('stopping mid-session still records the session as not-completed', () {
    fakeAsync((async) {
      final notifier = container.read(timerControllerProvider.notifier);
      notifier.setPlannedSeconds(600); // 10 minutes planned
      notifier.start();

      async.elapse(const Duration(seconds: 45));
      notifier.stop();
      async.flushMicrotasks();

      final state = container.read(timerControllerProvider);
      expect(state.phase, MeditationPhase.finished);
      expect(state.elapsedSeconds, 45);
      // Stopped early — no gong, since that's reserved for natural completion.
      expect(audio.gongPlayCount, 0);
    });
  });

  // Deliberately outside fakeAsync — recordSession's write goes through
  // drift's real (synchronous-under-the-hood, but still Future-returning)
  // sqlite FFI calls, and mixing that with a virtualized time zone risks
  // the write never resolving within the fake zone's microtask flush. Real
  // wall-clock timing doesn't matter for this assertion, so it isn't needed.
  test('a stopped session is actually persisted to the database', () async {
    final notifier = container.read(timerControllerProvider.notifier);
    notifier.setPlannedSeconds(300);
    notifier.start();
    await notifier.stop();

    final sessions = await db.watchAllSessions().first;
    expect(sessions, hasLength(1));
    expect(sessions.single.practiceType, 'meditation');
    expect(sessions.single.completedNaturally, isFalse);
  });

  test('reset returns to setup with elapsed time cleared', () {
    fakeAsync((async) {
      final notifier = container.read(timerControllerProvider.notifier);
      notifier.setPlannedSeconds(120);
      notifier.start();
      async.elapse(const Duration(seconds: 30));
      notifier.stop();
      async.flushMicrotasks();

      notifier.reset();

      final state = container.read(timerControllerProvider);
      expect(state.phase, MeditationPhase.setup);
      expect(state.elapsedSeconds, 0);
    });
  });

  test('toggleMuted suppresses the bell', () {
    fakeAsync((async) {
      final notifier = container.read(timerControllerProvider.notifier);
      notifier.setPlannedSeconds(180);
      notifier.toggleMuted();
      expect(container.read(timerControllerProvider).muted, isTrue);

      notifier.start();
      async.elapse(const Duration(minutes: 3));

      expect(audio.bellPlayCount, 0);
      expect(audio.gongPlayCount, 0);
    });
  });
}
