import 'dart:math' as math;

/// A general, illustrative model of how consistent practice tends to
/// compound over the first few months — NOT a personalized measurement of
/// the user's actual mood. This app collects no mood/journaling data, so
/// there is nothing to measure per-user; this curve exists to make a
/// research-general point visible ("consistency compounds") without
/// overclaiming a clinical readout.
///
/// Shaped as a saturating curve — fast, noticeable movement in the first
/// couple of weeks, continuing but slowing gains after that — since that's
/// the commonly-described honest pattern in mindfulness research, not
/// unbounded/literal exponential growth.
class WellbeingCurve {
  const WellbeingCurve._();

  static const int horizonDays = 90;

  /// A day-scale constant controlling how quickly the curve approaches its
  /// ceiling — chosen so the curve is visibly past its steepest climb by
  /// ~3 weeks (the "it takes about 3 weeks to feel it" framing many
  /// mindfulness programs use), then keeps rising gently toward 90 days.
  static const double _riseRateDays = 21;

  /// 0-100 illustrative index for [day] of consistent practice (day 0 = just
  /// started, 0). Clamped to [horizonDays] — the curve is nearly flat well
  /// before that, so extrapolating further wouldn't show anything new.
  static double indexForDay(int day) {
    final clamped = day.clamp(0, horizonDays);
    return 100 * (1 - math.exp(-clamped / _riseRateDays));
  }
}
