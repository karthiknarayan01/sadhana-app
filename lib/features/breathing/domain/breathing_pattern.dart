enum BreathingPhaseType { inhale, hold, exhale }

enum NostrilSide { none, left, right }

class BreathingPhase {
  const BreathingPhase({
    required this.type,
    required this.seconds,
    this.nostril = NostrilSide.none,
  });

  final BreathingPhaseType type;
  final int seconds;
  final NostrilSide nostril;

  String get label => switch (type) {
    BreathingPhaseType.inhale => 'Inhale',
    BreathingPhaseType.hold => 'Hold',
    BreathingPhaseType.exhale => 'Exhale',
  };
}

/// A repeating sequence of phases — box breathing's four equal phases, or
/// alternate nostril's six-phase, side-switching cycle — practised for a
/// chosen number of [cycles] (one cycle = one full pass through [phases]).
/// The session ends itself once that many cycles complete; the user can
/// still stop early.
class BreathingPattern {
  const BreathingPattern({
    required this.practiceType,
    required this.phases,
    required this.cycles,
  });

  final String practiceType; // matches Sessions.practiceType in the database
  final List<BreathingPhase> phases;
  final int cycles;

  static const boxBreathingType = 'box_breathing';
  static const alternateNostrilType = 'alt_nostril_breathing';

  /// Seconds to complete every configured cycle — shown on the setup
  /// screen so the user knows what they're committing to.
  int get totalSeconds =>
      cycles * phases.fold<int>(0, (sum, p) => sum + p.seconds);

  factory BreathingPattern.box(int seconds, {required int cycles}) {
    return BreathingPattern(
      practiceType: boxBreathingType,
      cycles: cycles,
      phases: [
        BreathingPhase(type: BreathingPhaseType.inhale, seconds: seconds),
        BreathingPhase(type: BreathingPhaseType.hold, seconds: seconds),
        BreathingPhase(type: BreathingPhaseType.exhale, seconds: seconds),
        BreathingPhase(type: BreathingPhaseType.hold, seconds: seconds),
      ],
    );
  }

  /// Traditional Nadi Shodhana alternates sides each half-cycle: inhale
  /// left -> hold -> exhale right -> inhale right -> hold -> exhale left ->
  /// repeat. [nostril] on each phase drives the running screen's left/right
  /// indicator.
  factory BreathingPattern.alternateNostril({
    required int inhaleSeconds,
    required int holdSeconds,
    required int exhaleSeconds,
    required int cycles,
  }) {
    return BreathingPattern(
      practiceType: alternateNostrilType,
      cycles: cycles,
      phases: [
        BreathingPhase(
          type: BreathingPhaseType.inhale,
          seconds: inhaleSeconds,
          nostril: NostrilSide.left,
        ),
        BreathingPhase(
          type: BreathingPhaseType.hold,
          seconds: holdSeconds,
          nostril: NostrilSide.left,
        ),
        BreathingPhase(
          type: BreathingPhaseType.exhale,
          seconds: exhaleSeconds,
          nostril: NostrilSide.right,
        ),
        BreathingPhase(
          type: BreathingPhaseType.inhale,
          seconds: inhaleSeconds,
          nostril: NostrilSide.right,
        ),
        BreathingPhase(
          type: BreathingPhaseType.hold,
          seconds: holdSeconds,
          nostril: NostrilSide.right,
        ),
        BreathingPhase(
          type: BreathingPhaseType.exhale,
          seconds: exhaleSeconds,
          nostril: NostrilSide.left,
        ),
      ],
    );
  }

  BreathingPhase phaseAt(int index) => phases[index % phases.length];
}
