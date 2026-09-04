import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/breathing/domain/breathing_cycle_logic.dart';
import 'package:sadhana/features/breathing/domain/breathing_pattern.dart';

void main() {
  group('clampPhaseSeconds', () {
    test('clamps below the floor', () {
      expect(BreathingCycleLogic.clampPhaseSeconds(0), 2);
    });

    test('clamps above the ceiling', () {
      expect(BreathingCycleLogic.clampPhaseSeconds(99), 20);
    });

    test('leaves an in-range value untouched', () {
      expect(BreathingCycleLogic.clampPhaseSeconds(5), 5);
    });
  });

  group('clampCycles', () {
    test('clamps to at least 1', () {
      expect(BreathingCycleLogic.clampCycles(0), 1);
      expect(BreathingCycleLogic.clampCycles(-3), 1);
    });

    test('clamps to at most 30', () {
      expect(BreathingCycleLogic.clampCycles(999), 30);
    });

    test('leaves an in-range value untouched', () {
      expect(BreathingCycleLogic.clampCycles(8), 8);
    });
  });

  group('BreathingPattern.box', () {
    test('mirrors the same seconds across all four phases', () {
      final pattern = BreathingPattern.box(5, cycles: 3);
      expect(pattern.phases, hasLength(4));
      expect(pattern.phases.every((p) => p.seconds == 5), isTrue);
      expect(pattern.cycles, 3);
      expect(pattern.totalSeconds, 3 * 4 * 5);
      expect(pattern.phases.map((p) => p.type), [
        BreathingPhaseType.inhale,
        BreathingPhaseType.hold,
        BreathingPhaseType.exhale,
        BreathingPhaseType.hold,
      ]);
    });
  });

  group('BreathingPattern.alternateNostril', () {
    test('alternates nostril side and uses independent phase seconds', () {
      final pattern = BreathingPattern.alternateNostril(
        inhaleSeconds: 4,
        holdSeconds: 7,
        exhaleSeconds: 8,
        cycles: 2,
      );
      expect(pattern.phases.map((p) => p.nostril), [
        NostrilSide.left,
        NostrilSide.left,
        NostrilSide.right,
        NostrilSide.right,
        NostrilSide.right,
        NostrilSide.left,
      ]);
      expect(pattern.phases[0].seconds, 4); // inhale
      expect(pattern.phases[1].seconds, 7); // hold
      expect(pattern.phases[2].seconds, 8); // exhale
      expect(pattern.totalSeconds, 2 * (4 + 7 + 8) * 2);
    });
  });

  group('BreathingCycleLogic.tick', () {
    final pattern = BreathingPattern.box(3, cycles: 5);

    test('increments elapsed-in-phase without advancing mid-phase', () {
      final result = BreathingCycleLogic.tick(
        pattern: pattern,
        phaseIndex: 0,
        elapsedInPhaseSeconds: 1,
        completedCycles: 0,
        targetCycles: 5,
      );
      expect(result.phaseIndex, 0);
      expect(result.elapsedInPhaseSeconds, 2);
      expect(result.phaseJustChanged, isFalse);
      expect(result.sessionComplete, isFalse);
    });

    test('advances to the next phase once the current one completes', () {
      final result = BreathingCycleLogic.tick(
        pattern: pattern,
        phaseIndex: 0,
        elapsedInPhaseSeconds: 2, // about to hit 3, the phase's seconds
        completedCycles: 0,
        targetCycles: 5,
      );
      expect(result.phaseIndex, 1);
      expect(result.elapsedInPhaseSeconds, 0);
      expect(result.phaseJustChanged, isTrue);
      expect(result.completedCycles, 0);
      expect(result.sessionComplete, isFalse);
    });

    test('wraps to phase 0 and counts a cycle after the last phase', () {
      final result = BreathingCycleLogic.tick(
        pattern: pattern,
        phaseIndex: 3, // the last of 4 phases
        elapsedInPhaseSeconds: 2,
        completedCycles: 1,
        targetCycles: 5,
      );
      expect(result.phaseIndex, 0);
      expect(result.completedCycles, 2);
      expect(result.phaseJustChanged, isTrue);
      expect(result.sessionComplete, isFalse);
    });

    test('flags sessionComplete when the last configured cycle finishes', () {
      final result = BreathingCycleLogic.tick(
        pattern: pattern,
        phaseIndex: 3,
        elapsedInPhaseSeconds: 2,
        completedCycles: 4, // finishing the 5th
        targetCycles: 5,
      );
      expect(result.completedCycles, 5);
      expect(result.sessionComplete, isTrue);
    });
  });
}
