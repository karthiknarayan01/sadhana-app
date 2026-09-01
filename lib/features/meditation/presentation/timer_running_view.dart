import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/format.dart';
import '../../../shared/widgets/timer_ring_painter.dart';
import '../application/timer_controller.dart';

/// The active-session screen — deliberately minimal (thin ring, centered
/// countdown, mute + stop), matching Insight Timer's own timer screen
/// rather than surfacing any of the customization the spec says this app
/// doesn't offer (interval choice, sound choice).
class TimerRunningView extends ConsumerWidget {
  const TimerRunningView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(alpha: 0.08),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(
                          begin: 0.94,
                          end: 1.04,
                          duration: 3000.ms,
                          curve: Curves.easeInOut,
                        ),
                    CustomPaint(
                      size: const Size(260, 260),
                      painter: TimerRingPainter(
                        progress: state.progress,
                        trackColor: scheme.surfaceContainerHighest,
                        progressColor: scheme.primary,
                      ),
                    ),
                    Text(
                      formatMmSs(state.remaining),
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(fontWeight: FontWeight.w200),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(state.muted ? Icons.volume_off : Icons.volume_up),
            tooltip: state.muted ? 'Unmute' : 'Mute',
            onPressed: controller.toggleMuted,
          ),
          const SizedBox(height: 16),
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
