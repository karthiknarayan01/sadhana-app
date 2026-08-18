import '../../../shared/practice_warmup.dart';
import '../domain/meditation_timer_logic.dart';

enum MeditationPhase { setup, warmup, running, finished }

class MeditationState {
  const MeditationState({
    required this.phase,
    required this.plannedSeconds,
    required this.elapsedSeconds,
    required this.muted,
    required this.warmupSecondsRemaining,
  });

  factory MeditationState.initial({
    required int plannedSeconds,
    required bool muted,
  }) => MeditationState(
    phase: MeditationPhase.setup,
    plannedSeconds: MeditationTimerLogic.clampDuration(plannedSeconds),
    elapsedSeconds: 0,
    muted: muted,
    warmupSecondsRemaining: practiceWarmupSeconds,
  );

  final MeditationPhase phase;
  final int plannedSeconds;
  final int elapsedSeconds;
  final bool muted;
  final int warmupSecondsRemaining;

  Duration get remaining => Duration(
    seconds: (plannedSeconds - elapsedSeconds).clamp(0, plannedSeconds),
  );

  double get progress =>
      plannedSeconds == 0 ? 0 : (elapsedSeconds / plannedSeconds).clamp(0, 1);

  MeditationState copyWith({
    MeditationPhase? phase,
    int? plannedSeconds,
    int? elapsedSeconds,
    bool? muted,
    int? warmupSecondsRemaining,
  }) {
    return MeditationState(
      phase: phase ?? this.phase,
      plannedSeconds: plannedSeconds ?? this.plannedSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      muted: muted ?? this.muted,
      warmupSecondsRemaining:
          warmupSecondsRemaining ?? this.warmupSecondsRemaining,
    );
  }
}
