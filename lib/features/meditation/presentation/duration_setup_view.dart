import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../benefits/presentation/benefit_sheet.dart';
import '../application/timer_controller.dart';
import '../domain/meditation_timer_logic.dart';

const _quickPicksMinutes = [5, 10, 15, 20, 30, 45, 60];

/// The pre-start screen: pick a duration (2 min–1 hour, per spec — no
/// interval/sound customization, that's deliberately not offered), mute if
/// wanted, then Start. Preloads the bell/gong here (not lazily on first
/// play) so the first bell of the session doesn't stutter.
class DurationSetupView extends ConsumerStatefulWidget {
  const DurationSetupView({super.key});

  @override
  ConsumerState<DurationSetupView> createState() => _DurationSetupViewState();
}

class _DurationSetupViewState extends ConsumerState<DurationSetupView> {
  @override
  void initState() {
    super.initState();
    ref.read(audioServiceProvider).configure();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final minutes = (state.plannedSeconds / 60).round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Meditate', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'A quiet $minutes-minute practice.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const BenefitCard(practiceType: 'meditation'),
            const SizedBox(height: 24),
            Text(
              '$minutes min',
              style: Theme.of(context).textTheme.displayMedium
                  ?.copyWith(fontWeight: FontWeight.w300),
            ),
            Slider(
              value: minutes.toDouble(),
              min: (MeditationTimerLogic.minSeconds / 60),
              max: (MeditationTimerLogic.maxSeconds / 60),
              divisions:
                  (MeditationTimerLogic.maxSeconds -
                      MeditationTimerLogic.minSeconds) ~/
                  60,
              label: '$minutes min',
              onChanged: (value) =>
                  controller.setPlannedSeconds((value.round()) * 60),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (final preset in _quickPicksMinutes)
                  ChoiceChip(
                    label: Text('$preset'),
                    selected: minutes == preset,
                    onSelected: (_) =>
                        controller.setPlannedSeconds(preset * 60),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            IconButton(
              icon: Icon(state.muted ? Icons.volume_off : Icons.volume_up),
              tooltip: state.muted ? 'Unmute' : 'Mute',
              onPressed: controller.toggleMuted,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.start,
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 56),
                shape: const StadiumBorder(),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
