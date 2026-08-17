import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/breathing_controller.dart';
import '../domain/breathing_pattern.dart';

/// The active-session pacer — an orb that grows on inhale, holds still on
/// hold, and shrinks on exhale, timed to the exact per-phase duration
/// (accuracy matters more than flourish here, so the core size animation is
/// a plain implicit AnimationController-driven AnimatedContainer keyed to
/// the phase's real seconds; flutter_animate only layers the label
/// fade/scale polish on top, per the project's own design notes).
class BreathingRunningView extends ConsumerWidget {
  const BreathingRunningView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(breathingControllerProvider);
    final controller = ref.read(breathingControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final phase = state.currentPhase;

    final targetScale = switch (phase.type) {
      BreathingPhaseType.inhale => 1.0,
      BreathingPhaseType.hold => phase.nostril == NostrilSide.none ? 0.85 : 1.0,
      BreathingPhaseType.exhale => 0.55,
    };
    final phaseDuration = Duration(seconds: phase.seconds);

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (phase.nostril != NostrilSide.none)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                phase.nostril == NostrilSide.left
                    ? 'Left nostril'
                    : 'Right nostril',
                style: Theme.of(context).textTheme.labelLarge,
              ).animate(key: ValueKey(phase.nostril)).fadeIn(duration: 300.ms),
            ),
          Expanded(
            child: Center(
              child: AnimatedContainer(
                duration: phaseDuration,
                curve: Curves.easeInOut,
                width: 220 * targetScale,
                height: 220 * targetScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.15),
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    phase.label,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate(key: ValueKey(phase.type)).fadeIn(duration: 250.ms),
                ),
              ),
            ),
          ),
          Text(
            '${state.completedCycles} cycle${state.completedCycles == 1 ? '' : 's'} complete',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(state.muted ? Icons.volume_off : Icons.volume_up),
            tooltip: state.muted ? 'Unmute' : 'Mute',
            onPressed: controller.toggleMuted,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: controller.stop,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 56),
              shape: const StadiumBorder(),
            ),
            child: const Text('Stop'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
