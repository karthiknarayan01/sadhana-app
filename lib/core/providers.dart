import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/search/data/search_api.dart';
import 'audio/audio_service.dart';
import 'config/app_config.dart';
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

final searchApiProvider = Provider<SearchApi>((ref) {
  return DioSearchApi(
    Dio(
      BaseOptions(
        baseUrl: searchApiBaseUrl,
        // Without these, a hung connection (dropped wifi mid-request, a
        // backend that never responds) waits indefinitely instead of
        // surfacing the error state — Dio's own default is no timeout at
        // all.
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
    ),
  );
});
