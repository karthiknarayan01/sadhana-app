import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/format.dart';
import '../application/timer_controller.dart';

/// Shown once a session ends, however it ended — naturally (the gong
/// played) or stopped early. Both still count toward the practice total
/// (already recorded by the controller by the time this renders); this
/// screen is purely the wind-down/acknowledgement, not where that decision
/// is made.
class SessionFinishedView extends ConsumerWidget {
  const SessionFinishedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final completedFully = state.elapsedSeconds >= state.plannedSeconds;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              completedFully
                  ? Icons.self_improvement
                  : Icons.pause_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              completedFully ? 'Session complete' : 'Session ended early',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You sat for ${formatMmSs(Duration(seconds: state.elapsedSeconds))}.'
              '${completedFully ? '' : ' Every practice counts — this one\'s recorded too.'}',
              textAlign: TextAlign.center,
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
