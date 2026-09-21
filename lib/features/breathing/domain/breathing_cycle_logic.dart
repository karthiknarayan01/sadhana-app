import 'breathing_pattern.dart';

/// The result of advancing one tick (1 second) through a [BreathingPattern]
/// — pure data, no Flutter/IO dependencies, so it's directly testable. The
/// controller (see application/breathing_controller.dart) is a thin shell
/// that supplies the real Timer/clock/audio/persistence side effects.
class BreathingTickResult {
  const BreathingTickResult({
    required this.phaseIndex,
    required this.elapsedInPhaseSeconds,
    required this.completedCycles,
    required this.phaseJustChanged,
    required this.sessionComplete,
  });

  final int phaseIndex;
  final int elapsedInPhaseSeconds;
  final int completedCycles;
  final bool phaseJustChanged;

  /// True on the tick that finishes the last configured cycle — the
  /// controller closes the session (gong, record, finished) instead of
  /// looping back to phase 0.
  final bool sessionComplete;
}

class BreathingCycleLogic {
  BreathingCycleLogic._();

  /// Clamp helper shared by both setup screens' seconds inputs — kept
  /// deliberately generous (2–20s) since box breathing and alternate
  /// nostril both just need "a comfortable few seconds," not a hard
  /// physiological limit.
  static int clampPhaseSeconds(int seconds) => seconds.clamp(2, 20);

  /// Alternate nostril's hold has its own floor of 3s: every phase rings
  /// the bell, and a 2s hold would put three bells almost on top of each
  /// other.
  static int clampHoldSeconds(int seconds) => seconds.clamp(3, 20);

  /// How many full cycles the user may ask for — 1 to 30, enough range for
  /// a one-minute reset or a long session without an unbounded input.
  static int clampCycles(int cycles) => cycles.clamp(1, 30);

  /// Advances one second within [pattern]. Wraps back to phase 0
  /// (incrementing completedCycles) once the last phase finishes; sets
  /// [BreathingTickResult.sessionComplete] on the tick that finishes the
  /// [targetCycles]th cycle.
  static BreathingTickResult tick({
    required BreathingPattern pattern,
    required int phaseIndex,
    required int elapsedInPhaseSeconds,
    required int completedCycles,
    required int targetCycles,
  }) {
    final newElapsed = elapsedInPhaseSeconds + 1;
    final currentPhaseSeconds = pattern.phaseAt(phaseIndex).seconds;

    if (newElapsed < currentPhaseSeconds) {
      return BreathingTickResult(
        phaseIndex: phaseIndex,
        elapsedInPhaseSeconds: newElapsed,
        completedCycles: completedCycles,
        phaseJustChanged: false,
        sessionComplete: false,
      );
    }

    final nextPhaseIndex = (phaseIndex + 1) % pattern.phases.length;
    final wrapped = nextPhaseIndex == 0;
    final newCompleted = wrapped ? completedCycles + 1 : completedCycles;
    return BreathingTickResult(
      phaseIndex: nextPhaseIndex,
      elapsedInPhaseSeconds: 0,
      completedCycles: newCompleted,
      phaseJustChanged: true,
      sessionComplete: wrapped && newCompleted >= targetCycles,
    );
  }
}
