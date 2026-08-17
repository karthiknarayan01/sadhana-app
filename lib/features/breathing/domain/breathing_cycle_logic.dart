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
  });

  final int phaseIndex;
  final int elapsedInPhaseSeconds;
  final int completedCycles;
  final bool phaseJustChanged;
}

class BreathingCycleLogic {
  BreathingCycleLogic._();

  /// Clamp helper shared by both setup screens' seconds inputs — kept
  /// deliberately generous (2–20s) since box breathing and alternate
  /// nostril both just need "a comfortable few seconds," not a hard
  /// physiological limit.
  static int clampPhaseSeconds(int seconds) => seconds.clamp(2, 20);

  /// Advances one second within [pattern], given the current phase index,
  /// how many seconds have elapsed in that phase, and how many full cycles
  /// have completed so far. Wraps back to phase 0 (incrementing
  /// completedCycles) once the last phase finishes — there's no end state,
  /// unlike the meditation timer: breathing loops until the user stops.
  static BreathingTickResult tick({
    required BreathingPattern pattern,
    required int phaseIndex,
    required int elapsedInPhaseSeconds,
    required int completedCycles,
  }) {
    final newElapsed = elapsedInPhaseSeconds + 1;
    final currentPhaseSeconds = pattern.phaseAt(phaseIndex).seconds;

    if (newElapsed < currentPhaseSeconds) {
      return BreathingTickResult(
        phaseIndex: phaseIndex,
        elapsedInPhaseSeconds: newElapsed,
        completedCycles: completedCycles,
        phaseJustChanged: false,
      );
    }

    final nextPhaseIndex = (phaseIndex + 1) % pattern.phases.length;
    final wrapped = nextPhaseIndex == 0;
    return BreathingTickResult(
      phaseIndex: nextPhaseIndex,
      elapsedInPhaseSeconds: 0,
      completedCycles: wrapped ? completedCycles + 1 : completedCycles,
      phaseJustChanged: true,
    );
  }
}
