import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/warmup_countdown_view.dart';
import '../application/breathing_controller.dart';
import '../application/breathing_state.dart';
import 'breathing_finished_view.dart';
import 'breathing_running_view.dart';
import 'technique_picker_view.dart';

/// Switches between the four phases of one breathing session — see
/// BreathingController for the state machine this renders.
class BreathingHomeScreen extends ConsumerWidget {
  const BreathingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(breathingControllerProvider);
    final controller = ref.read(breathingControllerProvider.notifier);

    return Scaffold(
      body: switch (state.sessionPhase) {
        BreathingSessionPhase.idle => const TechniquePickerView(),
        BreathingSessionPhase.warmup => WarmupCountdownView(
          secondsRemaining: state.warmupSecondsRemaining,
          onCancel: controller.cancelWarmup,
        ),
        BreathingSessionPhase.running => const BreathingRunningView(),
        BreathingSessionPhase.finished => const BreathingFinishedView(),
      },
    );
  }
}
