import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/warmup_countdown_view.dart';
import '../application/meditation_state.dart';
import '../application/timer_controller.dart';
import 'duration_setup_view.dart';
import 'session_finished_view.dart';
import 'timer_running_view.dart';

/// Switches between the four phases of one meditation session — see
/// TimerController for the state machine this renders.
class MeditationHomeScreen extends ConsumerWidget {
  const MeditationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerControllerProvider);
    final controller = ref.read(timerControllerProvider.notifier);

    return Scaffold(
      body: switch (state.phase) {
        MeditationPhase.setup => const DurationSetupView(),
        MeditationPhase.warmup => WarmupCountdownView(
          secondsRemaining: state.warmupSecondsRemaining,
          onCancel: controller.cancelWarmup,
        ),
        MeditationPhase.running => const TimerRunningView(),
        MeditationPhase.finished => const SessionFinishedView(),
      },
    );
  }
}
