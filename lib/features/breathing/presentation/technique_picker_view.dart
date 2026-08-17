import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
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
  int _inhaleSeconds = 4;
  int _holdSeconds = 4;
  int _exhaleSeconds = 6;

  @override
  void initState() {
    super.initState();
    ref.read(audioServiceProvider).configure();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Breathe', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Two simple techniques — pick one.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
        const BenefitLink(practiceType: BreathingPattern.boxBreathingType),
        _SecondsStepper(
          label: 'Seconds per side',
          value: _boxSeconds,
          onChanged: (v) => setState(() => _boxSeconds = v),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => controller.startBoxBreathing(_boxSeconds),
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
        const BenefitLink(practiceType: BreathingPattern.alternateNostrilType),
        _SecondsStepper(
          label: 'Inhale',
          value: _inhaleSeconds,
          onChanged: (v) => setState(() => _inhaleSeconds = v),
        ),
        _SecondsStepper(
          label: 'Hold',
          value: _holdSeconds,
          onChanged: (v) => setState(() => _holdSeconds = v),
        ),
        _SecondsStepper(
          label: 'Exhale',
          value: _exhaleSeconds,
          onChanged: (v) => setState(() => _exhaleSeconds = v),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => controller.startAlternateNostril(
            inhaleSeconds: _inhaleSeconds,
            holdSeconds: _holdSeconds,
            exhaleSeconds: _exhaleSeconds,
          ),
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _SecondsStepper extends StatelessWidget {
  const _SecondsStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () =>
                onChanged(BreathingCycleLogic.clampPhaseSeconds(value - 1)),
          ),
          SizedBox(
            width: 32,
            child: Text('${value}s', textAlign: TextAlign.center),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                onChanged(BreathingCycleLogic.clampPhaseSeconds(value + 1)),
          ),
        ],
      ),
    );
  }
}
