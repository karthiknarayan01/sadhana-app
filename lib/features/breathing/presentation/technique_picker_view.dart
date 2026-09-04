import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/practice_guide.dart';
import '../../../shared/widgets/practice_medallion.dart';
import '../../benefits/presentation/benefit_sheet.dart';
import '../application/breathing_controller.dart';
import '../domain/breathing_cycle_logic.dart';
import '../domain/breathing_pattern.dart';

enum _Technique { box, alternateNostril }

/// The idle-state screen: pick box breathing or alternate nostril, then
/// (inline, not a separate route) the seconds inputs for whichever was
/// picked. Purely local widget state — nothing here is persisted or part
/// of BreathingController until Start is actually pressed.
class TechniquePickerView extends ConsumerStatefulWidget {
  const TechniquePickerView({super.key});

  @override
  ConsumerState<TechniquePickerView> createState() =>
      _TechniquePickerViewState();
}

class _TechniquePickerViewState extends ConsumerState<TechniquePickerView> {
  _Technique? _technique;
  int _boxSeconds = 4;
  int _boxCycles = 4;
  int _inhaleSeconds = 4;
  int _holdSeconds = 4;
  int _exhaleSeconds = 6;
  int _altCycles = 4;

  static String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  @override
  void initState() {
    super.initState();
    ref.read(audioServiceProvider).configure();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PracticeMedallion(icon: Icons.air, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Breathe',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              'Two simple techniques — pick one.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            SegmentedButton<_Technique>(
              segments: const [
                ButtonSegment(value: _Technique.box, label: Text('Box')),
                ButtonSegment(
                  value: _Technique.alternateNostril,
                  label: Text('Alternate Nostril'),
                ),
              ],
              selected: {?_technique},
              emptySelectionAllowed: true,
              onSelectionChanged: (selection) => setState(
                () => _technique = selection.isEmpty ? null : selection.first,
              ),
            ),
            const SizedBox(height: 32),
            if (_technique == _Technique.box) _buildBoxSetup(context),
            if (_technique == _Technique.alternateNostril)
              _buildAltNostrilSetup(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxSetup(BuildContext context) {
    final controller = ref.read(breathingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Equal inhale, hold, exhale, hold — a true box.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const BenefitCard(practiceType: BreathingPattern.boxBreathingType),
        const SizedBox(height: 12),
        const PracticeGuide(practiceType: BreathingPattern.boxBreathingType),
        const SizedBox(height: 12),
        _Stepper(
          label: 'Seconds per side',
          value: _boxSeconds,
          suffix: 's',
          onChanged: (v) => setState(() => _boxSeconds = v),
          clamp: BreathingCycleLogic.clampPhaseSeconds,
        ),
        _Stepper(
          label: 'Cycles',
          value: _boxCycles,
          onChanged: (v) => setState(() => _boxCycles = v),
          clamp: BreathingCycleLogic.clampCycles,
        ),
        const SizedBox(height: 8),
        _DurationLine(seconds: _boxCycles * 4 * _boxSeconds),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () =>
              controller.startBoxBreathing(_boxSeconds, cycles: _boxCycles),
          child: const Text('Start'),
        ),
      ],
    );
  }

  Widget _buildAltNostrilSetup(BuildContext context) {
    final controller = ref.read(breathingControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Adjust to your comfort — defaults are a gentle starting point.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const BenefitCard(practiceType: BreathingPattern.alternateNostrilType),
        const SizedBox(height: 12),
        const PracticeGuide(
          practiceType: BreathingPattern.alternateNostrilType,
        ),
        const SizedBox(height: 12),
        _Stepper(
          label: 'Inhale',
          value: _inhaleSeconds,
          suffix: 's',
          onChanged: (v) => setState(() => _inhaleSeconds = v),
          clamp: BreathingCycleLogic.clampPhaseSeconds,
        ),
        _Stepper(
          label: 'Hold',
          value: _holdSeconds,
          suffix: 's',
          onChanged: (v) => setState(() => _holdSeconds = v),
          clamp: BreathingCycleLogic.clampPhaseSeconds,
        ),
        _Stepper(
          label: 'Exhale',
          value: _exhaleSeconds,
          suffix: 's',
          onChanged: (v) => setState(() => _exhaleSeconds = v),
          clamp: BreathingCycleLogic.clampPhaseSeconds,
        ),
        _Stepper(
          label: 'Cycles',
          value: _altCycles,
          onChanged: (v) => setState(() => _altCycles = v),
          clamp: BreathingCycleLogic.clampCycles,
        ),
        const SizedBox(height: 8),
        _DurationLine(
          seconds:
              _altCycles *
              (2 * _inhaleSeconds + 2 * _holdSeconds + 2 * _exhaleSeconds),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => controller.startAlternateNostril(
            inhaleSeconds: _inhaleSeconds,
            holdSeconds: _holdSeconds,
            exhaleSeconds: _exhaleSeconds,
            cycles: _altCycles,
          ),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.clamp,
    this.suffix = '',
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int Function(int) clamp;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => onChanged(clamp(value - 1)),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value$suffix',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(clamp(value + 1)),
          ),
        ],
      ),
    );
  }
}

/// The "≈ 3m 20s" line under the cycles stepper — so the user knows how
/// long the session they've configured will take.
class _DurationLine extends StatelessWidget {
  const _DurationLine({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.schedule, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          'About ${_TechniquePickerViewState._formatDuration(seconds)}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
