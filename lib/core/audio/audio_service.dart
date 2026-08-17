import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the bell/gong clips used by meditation and breathing. Preloaded via
/// [configure] so the *first* play during a session doesn't stutter waiting
/// on asset decode — call it once, early (e.g. when the setup screen
/// mounts), not lazily on first play.
///
/// Two separate players (not one reused for both clips) so a bell can be
/// re-triggered immediately without waiting on a previous play to finish —
/// relevant for breathing's shorter, more frequent cues.
class AudioService {
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _gongPlayer = AudioPlayer();
  bool _ready = false;

  // Audio failing to load/play must never take the timer down with it — the
  // countdown itself has nothing to do with whether a bell sound loaded, so
  // every platform call here is deliberately best-effort: log and move on
  // rather than let an exception propagate into the timer's own state
  // machine (this also means the app doesn't crash in an environment with
  // no real audio platform channel, e.g. plain `flutter test`).
  Future<void> configure() async {
    if (_ready) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _bellPlayer.setAsset('assets/audio/basu_bell.mp3');
      await _gongPlayer.setAsset('assets/audio/hanchi_gong.mp3');
      _ready = true;
    } catch (error, stackTrace) {
      developer.log(
        'AudioService.configure failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AudioService',
      );
    }
  }

  Future<void> playBell({required bool muted}) async {
    if (muted) return;
    await configure();
    if (!_ready) return;
    try {
      await _bellPlayer.seek(Duration.zero);
      unawaited(_bellPlayer.play());
    } catch (error, stackTrace) {
      developer.log(
        'AudioService.playBell failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AudioService',
      );
    }
  }

  Future<void> playGong({required bool muted}) async {
    if (muted) return;
    await configure();
    if (!_ready) return;
    try {
      await _gongPlayer.seek(Duration.zero);
      unawaited(_gongPlayer.play());
    } catch (error, stackTrace) {
      developer.log(
        'AudioService.playGong failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AudioService',
      );
    }
  }

  Future<void> dispose() async {
    await _bellPlayer.dispose();
    await _gongPlayer.dispose();
  }
}
