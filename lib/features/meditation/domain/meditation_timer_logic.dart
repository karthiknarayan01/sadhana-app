/// Pure timer math — no Flutter/IO dependencies, so it's testable without a
/// real Timer or wall clock. The controller (see
/// application/timer_controller.dart) is a thin shell around this that
/// supplies the real DateTime.now()/Timer/audio/persistence side effects.
class MeditationTimerLogic {
  MeditationTimerLogic._();

  static const int minSeconds = 2 * 60;
  static const int maxSeconds = 60 * 60;

  static int clampDuration(int seconds) =>
      seconds.clamp(minSeconds, maxSeconds);

  /// True if a bell should fire now that elapsed time has moved from
  /// [previousElapsedSeconds] to [elapsedSeconds] — checks for crossing a
  /// new whole-minute boundary rather than an exact `elapsed % 60 == 0`, so
  /// a delayed tick (elapsed jumping from 58s to 61s, say) still fires
  /// exactly once instead of silently skipping the boundary. Never fires
  /// once the session's already complete — that's the gong's moment, not
  /// the bell's.
  static bool crossedAMinuteBoundary({
    required int previousElapsedSeconds,
    required int elapsedSeconds,
    required int plannedSeconds,
  }) {
    if (elapsedSeconds >= plannedSeconds) return false;
    return (elapsedSeconds ~/ 60) > (previousElapsedSeconds ~/ 60);
  }

  static bool isComplete({
    required int elapsedSeconds,
    required int plannedSeconds,
  }) => elapsedSeconds >= plannedSeconds;
}
