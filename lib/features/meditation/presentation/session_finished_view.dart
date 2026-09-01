import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/format.dart';
import '../../../shared/widgets/practice_medallion.dart';
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
            PracticeMedallion(
                  icon: completedFully
                      ? Icons.self_improvement
                      : Icons.pause_circle_outline,
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
              completedFully ? 'Session complete' : 'Session ended early',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'You sat for ${formatMmSs(Duration(seconds: state.elapsedSeconds))}.'
              '${completedFully ? '' : ' Every practice counts — this one\'s recorded too.'}',
              textAlign: TextAlign.center,
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
