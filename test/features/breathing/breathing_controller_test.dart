import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/providers.dart';
import 'package:sadhana/features/breathing/application/breathing_controller.dart';
import 'package:sadhana/features/breathing/application/breathing_state.dart';
import 'package:sadhana/features/breathing/domain/breathing_pattern.dart';
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
    await container.read(prefsProvider.future);
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('starting box breathing enters the running phase', () {
    final notifier = container.read(breathingControllerProvider.notifier);
    notifier.startBoxBreathing(4);

    final state = container.read(breathingControllerProvider);
    expect(state.sessionPhase, BreathingSessionPhase.running);
    expect(state.pattern.practiceType, BreathingPattern.boxBreathingType);
  });

  test('a cue plays on every phase change, and cycles are counted', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.startBoxBreathing(2); // 4 phases * 2s = 8s per cycle

      async.elapse(const Duration(seconds: 16)); // exactly 2 full cycles

      final state = container.read(breathingControllerProvider);
      expect(state.completedCycles, 2);
      // A cue on every phase boundary: 4 phases/cycle * 2 cycles = 8.
      expect(audio.bellPlayCount, 8);
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

  test('stopping records a session and moves to finished', () async {
    final notifier = container.read(breathingControllerProvider.notifier);
    notifier.startBoxBreathing(4);
    await notifier.stop();

    final state = container.read(breathingControllerProvider);
    expect(state.sessionPhase, BreathingSessionPhase.finished);

    final sessions = await db.watchAllSessions().first;
    expect(sessions, hasLength(1));
    expect(sessions.single.practiceType, BreathingPattern.boxBreathingType);
    expect(sessions.single.completedNaturally, isTrue);
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

  test('toggleMuted suppresses the phase-change cue', () {
    fakeAsync((async) {
      final notifier = container.read(breathingControllerProvider.notifier);
      notifier.toggleMuted();
      notifier.startBoxBreathing(2);

      async.elapse(const Duration(seconds: 8));

      expect(audio.bellPlayCount, 0);
    });
  });
}
