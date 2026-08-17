import 'dart:async';
import 'dart:developer' as developer;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/providers.dart';
import '../domain/meditation_timer_logic.dart';
import 'meditation_state.dart';

// Keeping the screen on is a nice-to-have, not core timer correctness — a
// platform without a wakelock implementation (e.g. plain `flutter test`)
// must never take the session down with it.
void _safeWakelock(Future<void> Function() action) {
  action().catchError((Object error, StackTrace stackTrace) {
    developer.log(
      'wakelock_plus call failed',
      error: error,
      stackTrace: stackTrace,
      name: 'TimerController',
    );
  });
}

final timerControllerProvider =
    NotifierProvider<TimerController, MeditationState>(TimerController.new);

/// Drives one meditation session: setup (picking a duration) -> running
/// (ticking, firing the bell every minute) -> finished (gong + recorded).
/// Uses clock.now() rather than DateTime.now() directly so tests can
/// virtualize time via fake_async instead of waiting on real seconds — see
/// test/features/meditation/timer_controller_test.dart.
class TimerController extends Notifier<MeditationState> {
  Timer? _ticker;
  DateTime? _startedAt;
  int _lastElapsedSeconds = 0;

  @override
  MeditationState build() {
    ref.onDispose(_cancelTicker);
    final prefsAsync = ref.watch(prefsProvider);
    final prefs = prefsAsync.valueOrNull;
    return MeditationState.initial(
      plannedSeconds: prefs?.lastMeditationSeconds ?? 600,
      muted: prefs?.soundMuted ?? false,
    );
  }

  void setPlannedSeconds(int seconds) {
    if (state.phase != MeditationPhase.setup) return;
    state = state.copyWith(
      plannedSeconds: MeditationTimerLogic.clampDuration(seconds),
    );
  }

  void toggleMuted() {
    final newMuted = !state.muted;
    state = state.copyWith(muted: newMuted);
    ref.read(prefsProvider.future).then((p) => p.setSoundMuted(newMuted));
  }

  void start() {
    _startedAt = clock.now();
    _lastElapsedSeconds = 0;
    state = state.copyWith(phase: MeditationPhase.running, elapsedSeconds: 0);
    ref
        .read(prefsProvider.future)
        .then((p) => p.setLastMeditationSeconds(state.plannedSeconds));
    _safeWakelock(WakelockPlus.enable);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  /// Exposed for tests that want to drive one tick directly rather than
  /// going through the real Timer — production code never calls this
  /// itself, [start] wires _onTick to a real Timer.periodic instead.
  @visibleForTesting
  Future<void> onTickForTesting() => _onTick();

  Future<void> _onTick() async {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    final elapsed = clock.now().difference(startedAt).inSeconds;

    if (MeditationTimerLogic.crossedAMinuteBoundary(
      previousElapsedSeconds: _lastElapsedSeconds,
      elapsedSeconds: elapsed,
      plannedSeconds: state.plannedSeconds,
    )) {
      ref.read(audioServiceProvider).playBell(muted: state.muted);
    }
    _lastElapsedSeconds = elapsed;

    if (MeditationTimerLogic.isComplete(
      elapsedSeconds: elapsed,
      plannedSeconds: state.plannedSeconds,
    )) {
      await _finish(
        completedNaturally: true,
        actualSeconds: state.plannedSeconds,
      );
      return;
    }
    state = state.copyWith(elapsedSeconds: elapsed);
  }

  /// Any started session counts toward the practice total, even one stopped
  /// well before its planned duration — this is what records that.
  Future<void> stop() async {
    final startedAt = _startedAt;
    final elapsed = startedAt == null
        ? 0
        : clock.now().difference(startedAt).inSeconds;
    await _finish(completedNaturally: false, actualSeconds: elapsed);
  }

  Future<void> _finish({
    required bool completedNaturally,
    required int actualSeconds,
  }) async {
    _cancelTicker();
    _safeWakelock(WakelockPlus.disable);
    if (completedNaturally) {
      await ref.read(audioServiceProvider).playGong(muted: state.muted);
    }
    await ref
        .read(databaseProvider)
        .recordSession(
          practiceType: 'meditation',
          startedAt: _startedAt ?? clock.now(),
          plannedSeconds: state.plannedSeconds,
          actualSeconds: actualSeconds,
          completedNaturally: completedNaturally,
        );
    state = state.copyWith(
      phase: MeditationPhase.finished,
      elapsedSeconds: actualSeconds,
    );
  }

  void reset() {
    _startedAt = null;
    _lastElapsedSeconds = 0;
    state = state.copyWith(phase: MeditationPhase.setup, elapsedSeconds: 0);
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
