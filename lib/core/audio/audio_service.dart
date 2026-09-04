import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the bell/gong clips used by meditation and breathing. Preloaded via
/// [configure] so the *first* play during a session doesn't stutter waiting
/// on asset decode — call it once, early (e.g. when the setup screen
/// mounts), not lazily on first play.
///
/// One player per clip (not one reused across clips) so a cue can be
/// re-triggered immediately without waiting on a previous play to finish —
/// relevant for breathing's shorter, more frequent cues.
///
/// Three clips:
///  - bell (`kangse_bell.mp3`) — starts a practice and marks each minute /
///    box-breathing phase.
///  - gong (`hanchi_gong.mp3`) — closes a practice.
///  - phase cue (`phase_cue.mp3`) — a soft, short tone for alternate-nostril
///    phase changes, where a full bell rung 2–3 times around a short hold
///    sounds cluttered.
class AudioService {
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _gongPlayer = AudioPlayer();
  final AudioPlayer _phaseCuePlayer = AudioPlayer();
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
      await _bellPlayer.setAsset('assets/audio/kangse_bell.mp3');
      await _gongPlayer.setAsset('assets/audio/hanchi_gong.mp3');
      await _phaseCuePlayer.setAsset('assets/audio/phase_cue.mp3');
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
      await _restartFromZero(_bellPlayer);
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
      await _restartFromZero(_gongPlayer);
    } catch (error, stackTrace) {
      developer.log(
        'AudioService.playGong failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AudioService',
      );
    }
  }

  /// The soft, short cue for alternate-nostril phase changes — see the
  /// class doc for why breathing doesn't just ring the bell here.
  Future<void> playPhaseCue({required bool muted}) async {
    if (muted) return;
    await configure();
    if (!_ready) return;
    try {
      await _restartFromZero(_phaseCuePlayer);
    } catch (error, stackTrace) {
      developer.log(
        'AudioService.playPhaseCue failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AudioService',
      );
    }
  }

  /// just_audio's play() is a no-op — silently, no exception — if the
  /// player is already `playing` (see AudioPlayer.play()'s `if (playing)
  /// return;`), and seek() alone doesn't stop playback. So re-triggering a
  /// cue before the previous play finished (routine for breathing, whose
  /// phases can be as short as 2s while basu_bell.mp3 runs longer than
  /// that) would otherwise silently fail to restart, sounding like the
  /// bell "stopped working" after the first ring or two. pause() (not
  /// stop(), which tears down decoders) forces playing back to false first
  /// — a no-op itself if already stopped — so the play() after it actually
  /// takes effect every time.
  Future<void> _restartFromZero(AudioPlayer player) async {
    await player.pause();
    await player.seek(Duration.zero);
    unawaited(player.play());
  }

  Future<void> dispose() async {
    await _bellPlayer.dispose();
    await _gongPlayer.dispose();
    await _phaseCuePlayer.dispose();
  }
}
