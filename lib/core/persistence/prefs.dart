import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around simple scalar settings that don't warrant a database
/// table — mute state, last-used durations. Session/practice history lives
/// in [AppDatabase] instead (see database.dart), since that needs real
/// per-row queries this key-value store isn't suited for.
class AppPrefs {
  AppPrefs(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> load() async {
    return AppPrefs(await SharedPreferences.getInstance());
  }

  static const _keySoundMuted = 'sound_muted';
  static const _keyLastMeditationSeconds = 'last_meditation_seconds';

  bool get soundMuted => _prefs.getBool(_keySoundMuted) ?? false;
  Future<void> setSoundMuted(bool value) =>
      _prefs.setBool(_keySoundMuted, value);

  // Defaults to 10 minutes — a reasonable first-run starting point, not a
  // product requirement.
  int get lastMeditationSeconds =>
      _prefs.getInt(_keyLastMeditationSeconds) ?? 600;
  Future<void> setLastMeditationSeconds(int seconds) =>
      _prefs.setInt(_keyLastMeditationSeconds, seconds);
}
