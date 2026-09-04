import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/audio/audio_service.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/providers.dart';
import 'package:sadhana/features/breathing/application/breathing_controller.dart';
import 'package:sadhana/features/breathing/application/breathing_state.dart';
import 'package:sadhana/features/breathing/domain/breathing_pattern.dart';
import 'package:sadhana/shared/practice_warmup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_audio_service.dart';

const _warmup = Duration(seconds: practiceWarmupSeconds);

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
    await container.read(prefsProvider.future);
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('starting box breathing enters a 10s warmup before running', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(4, cycles: 20);

      expect(
        container.read(breathingControllerProvider).sessionPhase,
        BreathingSessionPhase.warmup,
      );
      expect(audio.bellPlayCount, 0);

      async.elapse(_warmup);
      // A short bell (not the long meditation one) opens the practice; the
      // gong is held for the close.
      expect(audio.bellPlayCount, 1);
      expect(audio.lastBellLong, isFalse);
      expect(audio.gongPlayCount, 0);
      final state = container.read(breathingControllerProvider);
      expect(state.sessionPhase, BreathingSessionPhase.running);
      expect(state.pattern.practiceType, BreathingPattern.boxBreathingType);
    });
  });

  test('cancelWarmup returns to idle without recording anything', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(4, cycles: 20);

      async.elapse(const Duration(seconds: 3));
      notifier.cancelWarmup();
      async.elapse(_warmup);

      expect(audio.bellPlayCount, 0);
      expect(audio.gongPlayCount, 0);
      expect(
        container.read(breathingControllerProvider).sessionPhase,
        BreathingSessionPhase.idle,
      );
    });
  });

  test('box breathing rings the bell on every phase change', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(2, cycles: 20); // 4 phases * 2s = 8s per cycle
      async.elapse(_warmup);
      expect(audio.bellPlayCount, 1); // the opening bell

      async.elapse(const Duration(seconds: 16)); // 2 full cycles

      final state = container.read(breathingControllerProvider);
      expect(state.completedCycles, 2);
      // Opening bell + a bell on every phase boundary (4/cycle * 2 = 8).
      expect(audio.bellPlayCount, 9);
      expect(audio.breathCuePlayCount, 0);
    });
  });

  test('alternate nostril is guided by rising / steady / falling cues', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startAlternateNostril(
        inhaleSeconds: 2,
        holdSeconds: 2,
        exhaleSeconds: 2,
        cycles: 20,
      ); // 6 phases * 2s = 12s per cycle
      async.elapse(_warmup);
      // No bell for alternate nostril — it opens on the inhale cue itself.
      expect(audio.bellPlayCount, 0);
      expect(audio.breathCuePlayCount, 1);

      async.elapse(const Duration(seconds: 11)); // through the first cycle

      expect(audio.bellPlayCount, 0);
      // opening inhale + a cue entering each of the next 5 phases
      expect(audio.breathCues, [
        BreathCue.inhale, // inhale left (opening)
        BreathCue.hold,
        BreathCue.exhale, // exhale right
        BreathCue.inhale, // inhale right
        BreathCue.hold,
        BreathCue.exhale, // exhale left
      ]);
    });
  });

  test('alternate nostril tracks which side is active', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startAlternateNostril(
        inhaleSeconds: 2,
        holdSeconds: 2,
        exhaleSeconds: 2,
        cycles: 20,
      );
      async.elapse(_warmup);

      expect(
        container.read(breathingControllerProvider).currentPhase.nostril,
        NostrilSide.left,
      );

      async.elapse(
        const Duration(seconds: 6),
      ); // inhale+hold+exhale (left half)

      expect(
        container.read(breathingControllerProvider).currentPhase.nostril,
        NostrilSide.right,
      );
    });
  });

  test('the session stops itself once the configured cycles are done', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(2, cycles: 2); // 8s per cycle, 2 cycles = 16s
      async.elapse(_warmup);

      async.elapse(const Duration(seconds: 16));

      expect(container.read(breathingControllerProvider).completedCycles, 2);
      expect(audio.gongPlayCount, 1); // closing gong on natural finish
      // opening bell + 7 phase-change bells; the 8th boundary is the
      // completing one, which gongs instead of ringing.
      final bellsAtFinish = audio.bellPlayCount;
      expect(bellsAtFinish, 8);

      // and nothing keeps firing after — the ticker really stopped
      async.elapse(const Duration(seconds: 20));
      expect(audio.bellPlayCount, bellsAtFinish);
      expect(audio.gongPlayCount, 1);
    });
  });

  test('a natural finish records the session and moves to finished', () async {
    final notifier = container.read(breathingControllerProvider.notifier);
    notifier.startBoxBreathing(2, cycles: 1); // one 8s cycle
    for (var i = 0; i < practiceWarmupSeconds; i++) {
      await notifier.onWarmupTickForTesting();
    }
    for (var i = 0; i < 8; i++) {
      notifier.onTickForTesting();
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final state = container.read(breathingControllerProvider);
    expect(state.sessionPhase, BreathingSessionPhase.finished);
    expect(state.completedCycles, 1);
    expect(audio.gongPlayCount, 1);

    final sessions = await db.watchAllSessions().first;
    expect(sessions, hasLength(1));
    expect(sessions.single.completedNaturally, isTrue);
  });

  test(
    'stopping during warmup records a session but plays no closing gong',
    () async {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(4, cycles: 20);
      await notifier.stop();

      final state = container.read(breathingControllerProvider);
      expect(state.sessionPhase, BreathingSessionPhase.finished);
      expect(audio.gongPlayCount, 0); // practice never actually started

      final sessions = await db.watchAllSessions().first;
      expect(sessions, hasLength(1));
      expect(sessions.single.practiceType, BreathingPattern.boxBreathingType);
      expect(sessions.single.completedNaturally, isTrue);
    },
  );

  test('stopping a running practice closes with the gong', () async {
    final notifier = container.read(breathingControllerProvider.notifier);
    notifier.startBoxBreathing(4, cycles: 20);
    for (var i = 0; i < practiceWarmupSeconds; i++) {
      await notifier.onWarmupTickForTesting();
    }
    await notifier.stop();

    expect(audio.gongPlayCount, 1);
    final sessions = await db.watchAllSessions().first;
    expect(sessions, hasLength(1));
  });

  test('abandon (tab switch) stops the practice without a gong', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(3, cycles: 20);
      async.elapse(_warmup);
      async.elapse(const Duration(seconds: 20));
      final bells = audio.bellPlayCount;

      notifier.abandon();

      expect(audio.gongPlayCount, 0);
      async.elapse(const Duration(seconds: 40));
      expect(audio.bellPlayCount, bells); // ticker really stopped
      expect(audio.gongPlayCount, 0);
    });
  });

  test(
    'abandoning a running practice records the session and returns to idle',
    () async {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(3, cycles: 20);
      for (var i = 0; i < practiceWarmupSeconds; i++) {
        await notifier.onWarmupTickForTesting();
      }
      notifier.onTickForTesting();
      notifier.onTickForTesting();
      await notifier.abandon();

      expect(
        container.read(breathingControllerProvider).sessionPhase,
        BreathingSessionPhase.idle,
      );
      final sessions = await db.watchAllSessions().first;
      expect(sessions, hasLength(1));
    },
  );

  test('reset returns to idle', () async {
    final notifier = container.read(breathingControllerProvider.notifier);
    notifier.startBoxBreathing(4, cycles: 20);
    await notifier.stop();

    notifier.reset();

    expect(
      container.read(breathingControllerProvider).sessionPhase,
      BreathingSessionPhase.idle,
    );
  });

  test('toggleMuted suppresses the opening bell and the phase cues', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.toggleMuted();
      notifier.startBoxBreathing(2, cycles: 20);
      async.elapse(_warmup);

      async.elapse(const Duration(seconds: 8));

      expect(audio.bellPlayCount, 0);
      expect(audio.gongPlayCount, 0);
      expect(audio.breathCuePlayCount, 0);
    });
  });
}
