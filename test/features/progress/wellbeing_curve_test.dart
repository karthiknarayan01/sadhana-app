import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/progress/domain/wellbeing_curve.dart';

void main() {
  test('day 0 starts at zero', () {
    expect(WellbeingCurve.indexForDay(0), 0);
  });

  test('the curve rises monotonically toward the horizon', () {
    var previous = WellbeingCurve.indexForDay(0);
    for (var day = 1; day <= WellbeingCurve.horizonDays; day++) {
      final value = WellbeingCurve.indexForDay(day);
      expect(value, greaterThan(previous));
      previous = value;
    }
  });

  test(
    'gains slow down over time (concave, not literal exponential growth)',
    () {
      final earlyGain =
          WellbeingCurve.indexForDay(14) - WellbeingCurve.indexForDay(7);
      final lateGain =
          WellbeingCurve.indexForDay(84) - WellbeingCurve.indexForDay(77);
      expect(earlyGain, greaterThan(lateGain));
    },
  );

  test('stays within the 0-100 index range, even past the horizon', () {
    expect(
      WellbeingCurve.indexForDay(WellbeingCurve.horizonDays),
      lessThanOrEqualTo(100),
    );
    expect(WellbeingCurve.indexForDay(1000), lessThanOrEqualTo(100));
    expect(WellbeingCurve.indexForDay(-5), 0);
  });
}
