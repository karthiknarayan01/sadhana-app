import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/practice_medallion.dart';
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

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            PracticeMedallion(
              icon: Icons.self_improvement,
              color: scheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Meditate',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 6),
            Text(
              'A quiet $minutes-minute practice.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            const BenefitCard(practiceType: 'meditation')
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            Text(
              '$minutes',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontFamily: 'Merriweather',
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            Text(
              'minutes',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
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
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 20),
            IconButton(
              icon: Icon(state.muted ? Icons.volume_off : Icons.volume_up),
              tooltip: state.muted ? 'Unmute' : 'Mute',
              onPressed: controller.toggleMuted,
            ),
            const SizedBox(height: 12),
            SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.start,
                    child: const Text('Start'),
                  ),
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.15, end: 0),
          ],
        ),
      ),
    );
  }
}
