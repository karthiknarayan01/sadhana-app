import '../domain/breathing_pattern.dart';

// "idle" covers both "never started" and sitting on the technique-choice /
// seconds-setup screens — that configuration lives in local widget state,
// not here (see presentation/), so the controller only has something real
// to track once a session actually starts.
enum BreathingSessionPhase { idle, running, finished }

class BreathingState {
  const BreathingState({
    required this.sessionPhase,
    required this.pattern,
    required this.phaseIndex,
    required this.elapsedInPhaseSeconds,
    required this.completedCycles,
    required this.totalElapsedSeconds,
    required this.muted,
  });

  factory BreathingState.initial({
    required BreathingPattern pattern,
    required bool muted,
  }) => BreathingState(
    sessionPhase: BreathingSessionPhase.idle,
    pattern: pattern,
    phaseIndex: 0,
    elapsedInPhaseSeconds: 0,
    completedCycles: 0,
    totalElapsedSeconds: 0,
    muted: muted,
  );

  final BreathingSessionPhase sessionPhase;
  final BreathingPattern pattern;
  final int phaseIndex;
  final int elapsedInPhaseSeconds;
  final int completedCycles;
  final int totalElapsedSeconds;
  final bool muted;

  BreathingPhase get currentPhase => pattern.phaseAt(phaseIndex);

  BreathingState copyWith({
    BreathingSessionPhase? sessionPhase,
    BreathingPattern? pattern,
    int? phaseIndex,
    int? elapsedInPhaseSeconds,
    int? completedCycles,
    int? totalElapsedSeconds,
    bool? muted,
  }) {
    return BreathingState(
      sessionPhase: sessionPhase ?? this.sessionPhase,
      pattern: pattern ?? this.pattern,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      elapsedInPhaseSeconds:
          elapsedInPhaseSeconds ?? this.elapsedInPhaseSeconds,
      completedCycles: completedCycles ?? this.completedCycles,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      muted: muted ?? this.muted,
    );
  }
}
