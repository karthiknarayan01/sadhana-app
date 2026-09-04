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
  Timer? _warmupTicker;

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

  void startBoxBreathing(int seconds) => _startWarmup(
    BreathingPattern.box(BreathingCycleLogic.clampPhaseSeconds(seconds)),
  );

  void startAlternateNostril({
    required int inhaleSeconds,
    required int holdSeconds,
    required int exhaleSeconds,
  }) => _startWarmup(
    BreathingPattern.alternateNostril(
      inhaleSeconds: BreathingCycleLogic.clampPhaseSeconds(inhaleSeconds),
      holdSeconds: BreathingCycleLogic.clampPhaseSeconds(holdSeconds),
      exhaleSeconds: BreathingCycleLogic.clampPhaseSeconds(exhaleSeconds),
    ),
  );

  /// Starts the warmup countdown, not the practice itself — the bell at
  /// the end of warmup (see _onWarmupTick) is what actually marks practice
  /// beginning, matching the same cue used by meditation's warmup.
  void _startWarmup(BreathingPattern pattern) {
    state = BreathingState.initial(
      pattern: pattern,
      muted: state.muted,
    ).copyWith(sessionPhase: BreathingSessionPhase.warmup);
    _warmupTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onWarmupTick(),
    );
  }

  @visibleForTesting
  Future<void> onWarmupTickForTesting() => _onWarmupTick();

  Future<void> _onWarmupTick() async {
    final remaining = state.warmupSecondsRemaining - 1;
    if (remaining <= 0) {
      _warmupTicker?.cancel();
      _warmupTicker = null;
      // Bell (kangse) opens every practice; the gong closes it (see stop).
      await ref.read(audioServiceProvider).playBell(muted: state.muted);
      _beginPractice();
      return;
    }
    state = state.copyWith(warmupSecondsRemaining: remaining);
  }

  /// Cancelling during warmup returns to idle without recording anything —
  /// practice hasn't actually begun yet, unlike [stop] once it has.
  void cancelWarmup() {
    _warmupTicker?.cancel();
    _warmupTicker = null;
    state = BreathingState.initial(pattern: state.pattern, muted: state.muted);
  }

  void _beginPractice() {
    state = state.copyWith(sessionPhase: BreathingSessionPhase.running);
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
      final audio = ref.read(audioServiceProvider);
      // Alternate nostril steps through six phases per cycle, some of them
      // very short (a 2s hold) — a full bell rung that often sounds
      // cluttered, so it gets the soft phase cue instead. Box breathing's
      // four equal phases are spaced enough for the bell.
      if (state.pattern.practiceType == BreathingPattern.alternateNostrilType) {
        audio.playPhaseCue(muted: state.muted);
      } else {
        audio.playBell(muted: state.muted);
      }
    }
    state = state.copyWith(
      phaseIndex: result.phaseIndex,
      elapsedInPhaseSeconds: result.elapsedInPhaseSeconds,
      completedCycles: result.completedCycles,
      totalElapsedSeconds: state.totalElapsedSeconds + 1,
    );
  }

  Future<void> stop() async {
    final wasRunning = state.sessionPhase == BreathingSessionPhase.running;
    _cancelTicker();
    // Close with the gong — but only if practice actually started (a stop
    // during the warmup countdown isn't a session to round off).
    if (wasRunning) {
      await ref.read(audioServiceProvider).playGong(muted: state.muted);
    }
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
    _warmupTicker?.cancel();
    _warmupTicker = null;
  }
}
