import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/practice_medallion.dart';
import '../application/breathing_controller.dart';

class BreathingFinishedView extends ConsumerWidget {
  const BreathingFinishedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(breathingControllerProvider);
    final controller = ref.read(breathingControllerProvider.notifier);
    final minutes = (state.totalElapsedSeconds / 60).toStringAsFixed(1);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PracticeMedallion(
                  icon: Icons.air,
                  color: Theme.of(context).colorScheme.primary,
                  size: 96,
                )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  duration: 450.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            Text(
              'Nicely done',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              '${state.completedCycles} cycle${state.completedCycles == 1 ? '' : 's'} · $minutes min',
              style: Theme.of(context).textTheme.bodyMedium,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            SizedBox(
                  width: 200,
                  child: FilledButton(
                    onPressed: controller.reset,
                    child: const Text('Done'),
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
