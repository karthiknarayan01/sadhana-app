import 'dart:async';
import 'dart:developer' as developer;

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the two cues meditation and breathing use — a bell and a gong.
///
///  - `kangse_bell.mp3`  — the long bell (~10s, slow fade): opens a
///    meditation and marks each minute.
///  - `kangse_short.mp3` — a short strike (~2s): opens a breathing practice
///    and marks each phase change (inhale / hold / exhale).
///  - `hanchi_gong.mp3`  — the closing gong for every practice.
///
/// One [AudioPlayer] per clip so a cue can re-trigger immediately without
/// waiting on a previous play. Preloaded via [configure] so the first cue
/// of a session doesn't stutter on asset decode — call it once, early
/// (when a setup screen mounts).
class AudioService {
  final AudioPlayer _meditationBell = AudioPlayer();
  final AudioPlayer _breathBell = AudioPlayer();
  final AudioPlayer _gong = AudioPlayer();
  bool _ready = false;

  // Audio failing to load/play must never take a timer down with it — every
  // platform call here is best-effort: log and move on rather than let an
  // exception into a controller's state machine (this also keeps things
  // working in an environment with no audio platform channel, e.g. plain
  // `flutter test`).
  Future<void> configure() async {
    if (_ready) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _meditationBell.setAsset('assets/audio/kangse_bell.mp3');
      await _breathBell.setAsset('assets/audio/kangse_short.mp3');
      await _gong.setAsset('assets/audio/hanchi_gong.mp3');
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

  /// The kangse bell. [long] picks the ~10s meditation bell; the default is
  /// the short strike used for breathing phase changes.
  Future<void> playBell({required bool muted, bool long = false}) =>
      _play(long ? _meditationBell : _breathBell, 'playBell', muted);

  Future<void> playGong({required bool muted}) =>
      _play(_gong, 'playGong', muted);

  Future<void> _play(AudioPlayer player, String label, bool muted) async {
    if (muted) return;
    await configure();
    if (!_ready) return;
    try {
      await _restartFromZero(player);
    } catch (error, stackTrace) {
      developer.log(
        'AudioService.$label failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AudioService',
      );
    }
  }

  /// just_audio's play() is a silent no-op if the player is already
  /// `playing`, and seek() alone doesn't stop playback — so re-triggering a
  /// cue before the previous play finished (routine for breathing's short
  /// phases) would otherwise sound like the cue "stopped working". pause()
  /// (not stop(), which tears down decoders) forces `playing` back to false
  /// first, so the play() after it takes effect every time.
  Future<void> _restartFromZero(AudioPlayer player) async {
    await player.pause();
    await player.seek(Duration.zero);
    unawaited(player.play());
  }

  Future<void> dispose() async {
    await _meditationBell.dispose();
    await _breathBell.dispose();
    await _gong.dispose();
  }
}
