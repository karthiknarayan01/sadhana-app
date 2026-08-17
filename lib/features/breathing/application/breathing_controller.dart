import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/breathing_cycle_logic.dart';
import '../domain/breathing_pattern.dart';
import 'breathing_state.dart';

final breathingControllerProvider =
    NotifierProvider<BreathingController, BreathingState>(
      BreathingController.new,
    );

/// Drives one breathing session: idle -> running (looping through
/// [BreathingPattern]'s phases, playing a soft cue on each phase change) ->
/// finished (recorded). Unlike meditation there's no target duration —
/// looping continues until [stop] is called; every stop is treated as a
/// complete session (there's no "gave up early" concept when there was
/// never a fixed target to fall short of).
class BreathingController extends Notifier<BreathingState> {
  Timer? _ticker;

  @override
  BreathingState build() {
    ref.onDispose(_cancelTicker);
    final prefs = ref.watch(prefsProvider).valueOrNull;
    return BreathingState.initial(
      pattern: BreathingPattern.box(4),
      muted: prefs?.soundMuted ?? false,
    );
  }

  void toggleMuted() {
    final newMuted = !state.muted;
    state = state.copyWith(muted: newMuted);
    ref.read(prefsProvider.future).then((p) => p.setSoundMuted(newMuted));
  }

  void startBoxBreathing(int seconds) => _start(
    BreathingPattern.box(BreathingCycleLogic.clampPhaseSeconds(seconds)),
  );

  void startAlternateNostril({
    required int inhaleSeconds,
    required int holdSeconds,
    required int exhaleSeconds,
  }) => _start(
    BreathingPattern.alternateNostril(
      inhaleSeconds: BreathingCycleLogic.clampPhaseSeconds(inhaleSeconds),
      holdSeconds: BreathingCycleLogic.clampPhaseSeconds(holdSeconds),
      exhaleSeconds: BreathingCycleLogic.clampPhaseSeconds(exhaleSeconds),
    ),
  );

  void _start(BreathingPattern pattern) {
    state = BreathingState.initial(
      pattern: pattern,
      muted: state.muted,
    ).copyWith(sessionPhase: BreathingSessionPhase.running);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  /// Exposed for tests that want to drive one tick directly rather than
  /// going through the real Timer.
  @visibleForTesting
  void onTickForTesting() => _onTick();

  void _onTick() {
    final result = BreathingCycleLogic.tick(
      pattern: state.pattern,
      phaseIndex: state.phaseIndex,
      elapsedInPhaseSeconds: state.elapsedInPhaseSeconds,
      completedCycles: state.completedCycles,
    );
    if (result.phaseJustChanged) {
      ref.read(audioServiceProvider).playBell(muted: state.muted);
    }
    state = state.copyWith(
      phaseIndex: result.phaseIndex,
      elapsedInPhaseSeconds: result.elapsedInPhaseSeconds,
      completedCycles: result.completedCycles,
      totalElapsedSeconds: state.totalElapsedSeconds + 1,
    );
  }

  Future<void> stop() async {
    _cancelTicker();
    await ref
        .read(databaseProvider)
        .recordSession(
          practiceType: state.pattern.practiceType,
          startedAt: clock.now().subtract(
            Duration(seconds: state.totalElapsedSeconds),
          ),
          plannedSeconds: state.totalElapsedSeconds,
          actualSeconds: state.totalElapsedSeconds,
          completedNaturally: true,
        );
    state = state.copyWith(sessionPhase: BreathingSessionPhase.finished);
  }

  void reset() {
    state = BreathingState.initial(pattern: state.pattern, muted: state.muted);
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
