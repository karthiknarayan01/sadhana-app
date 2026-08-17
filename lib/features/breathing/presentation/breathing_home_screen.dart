import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/breathing_controller.dart';
import '../application/breathing_state.dart';
import 'breathing_finished_view.dart';
import 'breathing_running_view.dart';
import 'technique_picker_view.dart';

/// Switches between the three phases of one breathing session — see
/// BreathingController for the state machine this renders.
class BreathingHomeScreen extends ConsumerWidget {
  const BreathingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionPhase = ref.watch(
      breathingControllerProvider.select((s) => s.sessionPhase),
    );

    return Scaffold(
      body: switch (sessionPhase) {
        BreathingSessionPhase.idle => const TechniquePickerView(),
        BreathingSessionPhase.running => const BreathingRunningView(),
        BreathingSessionPhase.finished => const BreathingFinishedView(),
      },
    );
  }
}
