import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio/audio_service.dart';
import 'persistence/database.dart';
import 'persistence/prefs.dart';

/// A single AppDatabase instance for the app's lifetime. Safe to construct
/// eagerly/synchronously — drift's LazyDatabase defers actually opening the
/// sqlite file until the first query, so this doesn't block startup.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// AppPrefs wraps SharedPreferences, whose own factory is async — screens
/// that need it (the meditation/breathing settings) watch this as an
/// AsyncValue rather than the app gating its entire startup on it.
final prefsProvider = FutureProvider<AppPrefs>((ref) => AppPrefs.load());

/// One AudioService for the app's lifetime — shared by meditation and
/// breathing, both of which play the same bell cue.
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
