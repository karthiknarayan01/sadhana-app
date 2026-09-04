import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      notifier.startBoxBreathing(4);

      expect(
        container.read(breathingControllerProvider).sessionPhase,
        BreathingSessionPhase.warmup,
      );
      expect(audio.bellPlayCount, 0);

      async.elapse(_warmup);
      // The bell (kangse) marks warmup ending and practice actually
      // starting; the gong is held for the close.
      expect(audio.bellPlayCount, 1);
      expect(audio.gongPlayCount, 0);
      final state = container.read(breathingControllerProvider);
      expect(state.sessionPhase, BreathingSessionPhase.running);
      expect(state.pattern.practiceType, BreathingPattern.boxBreathingType);
    });
  });

  test('cancelWarmup returns to idle without recording anything', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(4);

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
      notifier.startBoxBreathing(2); // 4 phases * 2s = 8s per cycle
      async.elapse(_warmup); // through warmup, into running
      expect(audio.bellPlayCount, 1); // the opening bell

      async.elapse(const Duration(seconds: 16)); // exactly 2 full cycles

      final state = container.read(breathingControllerProvider);
      expect(state.completedCycles, 2);
      // Opening bell + a bell on every phase boundary (4 phases/cycle * 2
      // cycles = 8). Box breathing keeps the bell; only alternate nostril
      // swaps in the soft phase cue.
      expect(audio.bellPlayCount, 9);
      expect(audio.phaseCuePlayCount, 0);
    });
  });

  test('alternate nostril uses the soft phase cue, not the bell', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startAlternateNostril(
        inhaleSeconds: 2,
        holdSeconds: 2,
        exhaleSeconds: 2,
      ); // 6 phases * 2s = 12s per cycle
      async.elapse(_warmup);
      expect(audio.bellPlayCount, 1); // kangse still opens the practice
      expect(audio.phaseCuePlayCount, 0);

      async.elapse(const Duration(seconds: 24)); // 2 full cycles

      expect(audio.phaseCuePlayCount, 12); // soft cue on all 12 phase changes
      expect(audio.bellPlayCount, 1); // no further bells
    });
  });

  test('alternate nostril tracks which side is active', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startAlternateNostril(
        inhaleSeconds: 2,
        holdSeconds: 2,
        exhaleSeconds: 2,
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

  test(
    'stopping during warmup records a session but plays no closing gong',
    () async {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(4);
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
    notifier.startBoxBreathing(4);
    for (var i = 0; i < practiceWarmupSeconds; i++) {
      await notifier.onWarmupTickForTesting();
    }
    await notifier.stop();

    expect(audio.gongPlayCount, 1);
    final sessions = await db.watchAllSessions().first;
    expect(sessions, hasLength(1));
  });

  test('reset returns to idle', () async {
    final notifier = container.read(breathingControllerProvider.notifier);
    notifier.startBoxBreathing(4);
    await notifier.stop();

    notifier.reset();

    expect(
      container.read(breathingControllerProvider).sessionPhase,
      BreathingSessionPhase.idle,
    );
  });

  test('toggleMuted suppresses the opening bell and the phase-change cues', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.toggleMuted();
      notifier.startBoxBreathing(2);
      async.elapse(_warmup);

      async.elapse(const Duration(seconds: 8));

      expect(audio.bellPlayCount, 0);
      expect(audio.gongPlayCount, 0);
      expect(audio.phaseCuePlayCount, 0);
    });
  });
}
