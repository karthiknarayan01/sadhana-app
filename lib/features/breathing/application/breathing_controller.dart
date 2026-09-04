import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/providers.dart';
import '../domain/breathing_cycle_logic.dart';
import '../domain/breathing_pattern.dart';
import 'breathing_state.dart';

final breathingControllerProvider =
    NotifierProvider<BreathingController, BreathingState>(
      BreathingController.new,
    );

/// Drives one breathing session: idle -> running (looping through
/// [BreathingPattern]'s phases, cueing each change) -> finished. The
/// session ends itself once the configured number of cycles complete; the
/// user can also stop early. Either way it's recorded as a complete
/// session — there was no fixed target to fall short of.
class BreathingController extends Notifier<BreathingState> {
  Timer? _ticker;
  Timer? _warmupTicker;

  @override
  BreathingState build() {
    ref.onDispose(_cancelTicker);
    final prefs = ref.watch(prefsProvider).valueOrNull;
    return BreathingState.initial(
      pattern: BreathingPattern.box(4, cycles: 4),
      muted: prefs?.soundMuted ?? false,
    );
  }

  void toggleMuted() {
    final newMuted = !state.muted;
    state = state.copyWith(muted: newMuted);
    ref.read(prefsProvider.future).then((p) => p.setSoundMuted(newMuted));
  }

  void startBoxBreathing(int seconds, {required int cycles}) => _startWarmup(
    BreathingPattern.box(
      BreathingCycleLogic.clampPhaseSeconds(seconds),
      cycles: BreathingCycleLogic.clampCycles(cycles),
    ),
  );

  void startAlternateNostril({
    required int inhaleSeconds,
    required int holdSeconds,
    required int exhaleSeconds,
    required int cycles,
  }) => _startWarmup(
    BreathingPattern.alternateNostril(
      inhaleSeconds: BreathingCycleLogic.clampPhaseSeconds(inhaleSeconds),
      holdSeconds: BreathingCycleLogic.clampPhaseSeconds(holdSeconds),
      exhaleSeconds: BreathingCycleLogic.clampPhaseSeconds(exhaleSeconds),
      cycles: BreathingCycleLogic.clampCycles(cycles),
    ),
  );

  /// Starts the warmup countdown, not the practice itself — the short bell
  /// at the end of warmup (see _onWarmupTick) is what actually marks
  /// practice beginning, matching meditation's warmup.
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
      // Box breathing opens on the short bell. Alternate nostril opens on
      // its inhale cue instead — the first phase is always an inhale, and
      // the eyes-closed practitioner needs that cue as much as any later
      // one. The gong closes either practice.
      final audio = ref.read(audioServiceProvider);
      if (state.pattern.practiceType == BreathingPattern.alternateNostrilType) {
        await audio.playBreathCue(BreathCue.inhale, muted: state.muted);
      } else {
        await audio.playBell(muted: state.muted);
      }
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
      targetCycles: state.pattern.cycles,
    );

    state = state.copyWith(
      phaseIndex: result.phaseIndex,
      elapsedInPhaseSeconds: result.elapsedInPhaseSeconds,
      completedCycles: result.completedCycles,
      totalElapsedSeconds: state.totalElapsedSeconds + 1,
    );

    if (result.sessionComplete) {
      _finishNaturally();
      return;
    }
    if (result.phaseJustChanged) {
      _cuePhaseChange(state.currentPhase.type);
    }
  }

  void _cuePhaseChange(BreathingPhaseType type) {
    final audio = ref.read(audioServiceProvider);
    // Box breathing's four equal phases get the short bell. Alternate
    // nostril is practised with the eyes closed and its six phases can be
    // very short, so it's guided by ear instead: a rising tone to breathe
    // in, a steady one to hold, a falling one to breathe out.
    if (state.pattern.practiceType == BreathingPattern.alternateNostrilType) {
      audio.playBreathCue(switch (type) {
        BreathingPhaseType.inhale => BreathCue.inhale,
        BreathingPhaseType.hold => BreathCue.hold,
        BreathingPhaseType.exhale => BreathCue.exhale,
      }, muted: state.muted);
    } else {
      audio.playBell(muted: state.muted);
    }
  }

  /// The configured cycles are done — close the session (gong, record,
  /// finished). Shares the recording path with [stop].
  Future<void> _finishNaturally() async {
    _cancelTicker();
    await ref.read(audioServiceProvider).playGong(muted: state.muted);
    await _record();
    state = state.copyWith(sessionPhase: BreathingSessionPhase.finished);
  }

  Future<void> stop() async {
    final wasRunning = state.sessionPhase == BreathingSessionPhase.running;
    _cancelTicker();
    // Close with the gong — but only if practice actually started (a stop
    // during the warmup countdown isn't a session to round off).
    if (wasRunning) {
      await ref.read(audioServiceProvider).playGong(muted: state.muted);
    }
    await _record();
    state = state.copyWith(sessionPhase: BreathingSessionPhase.finished);
  }

  /// The user navigated away mid-practice (switched tabs). Drop it quietly:
  /// no gong, no finished screen — stop the timers, count what was done,
  /// and return to idle so the setup screen is fresh next time.
  Future<void> abandon() async {
    final wasRunning = state.sessionPhase == BreathingSessionPhase.running;
    final wasWarmup = state.sessionPhase == BreathingSessionPhase.warmup;
    if (!wasRunning && !wasWarmup) return;
    _cancelTicker();
    if (wasRunning) await _record();
    state = BreathingState.initial(pattern: state.pattern, muted: state.muted);
  }

  Future<void> _record() {
    return ref
        .read(databaseProvider)
        .recordSession(
          practiceType: state.pattern.practiceType,
          startedAt: clock.now().subtract(
            Duration(seconds: state.totalElapsedSeconds),
          ),
          plannedSeconds: state.pattern.totalSeconds,
          actualSeconds: state.totalElapsedSeconds,
          completedNaturally: true,
        );
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
