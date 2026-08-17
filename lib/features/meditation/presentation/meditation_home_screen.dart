import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/meditation_state.dart';
import '../application/timer_controller.dart';
import 'duration_setup_view.dart';
import 'session_finished_view.dart';
import 'timer_running_view.dart';

/// Switches between the three phases of one meditation session — see
/// TimerController for the state machine this renders.
class MeditationHomeScreen extends ConsumerWidget {
  const MeditationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(timerControllerProvider.select((s) => s.phase));

    return Scaffold(
      body: switch (phase) {
        MeditationPhase.setup => const DurationSetupView(),
        MeditationPhase.running => const TimerRunningView(),
        MeditationPhase.finished => const SessionFinishedView(),
      },
    );
  }
}
