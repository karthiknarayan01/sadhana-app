import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            Icon(
              Icons.air,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nicely done',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${state.completedCycles} cycle${state.completedCycles == 1 ? '' : 's'} · $minutes min',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: controller.reset,
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 56),
                shape: const StadiumBorder(),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
