import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/search_api.dart';
import 'search_state.dart';

// Haptic feedback failing (no platform channel under plain `flutter test`,
// same reasoning as TimerController's _safeWakelock) must never take the
// search flow down with it — best-effort only.
void _safeHapticFeedback(Future<void> Function() action) {
  action().catchError((Object error, StackTrace stackTrace) {
    developer.log(
      'HapticFeedback call failed',
      error: error,
      stackTrace: stackTrace,
      name: 'SearchController',
    );
  });
}

const _debounceDuration = Duration(milliseconds: 350);

/// Debounces free-typed queries (a plain Timer, cancelled and restarted on
/// every keystroke — no extra package needed for this) so the backend isn't
/// hit on every character.
class SearchController extends Notifier<SearchState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    _debounce = Timer(_debounceDuration, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final thisRequest = ++_requestId;
    state = state.copyWith(status: SearchStatus.loading);

    try {
      final page = await ref.read(searchApiProvider).search(query);
      // A slower earlier request landing after a newer one would otherwise
      // overwrite fresher results with stale ones.
      if (thisRequest != _requestId) return;
      state = state.copyWith(
        status: SearchStatus.success,
        results: page.results,
        page: 0,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
      // Once per search that actually reached the user — not per HTTP call
      // (loadMore/refresh continue this same search, they don't start a
      // new one), so retries/pagination don't inflate the count.
      ref.read(analyticsServiceProvider).recordSearchPerformed();
    } on SearchUnavailableException {
      if (thisRequest != _requestId) return;
      state = state.copyWith(
        status: SearchStatus.error,
        results: [],
        hasMore: false,
      );
    }
  }

  /// Called as the results list scrolls near its end. A no-op if there's
  /// nothing more to fetch or a fetch (initial or loadMore) is already in
  /// flight — the scroll listener that drives this can fire repeatedly
  /// while already past the threshold. Returns whether it succeeded so the
  /// caller (the scroll listener, see search_screen.dart) can surface a
  /// failure — a snackbar, not a full error screen, since there's already
  /// a list of results on screen worth keeping.
  Future<bool> loadMore() async {
    if (state.status != SearchStatus.success) return true;
    if (!state.hasMore || state.isLoadingMore) return true;

    // Not a new _requestId: this continues the in-flight query rather than
    // superseding it, so a concurrent fresh _runSearch (the query changed)
    // still correctly invalidates this response when it lands.
    final thisRequest = _requestId;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);

    try {
      final page = await ref
          .read(searchApiProvider)
          .search(state.query, page: nextPage);
      if (thisRequest != _requestId) return true;
      state = state.copyWith(
        results: [...state.results, ...page.results],
        page: nextPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
      if (!page.hasMore) {
        // Genuinely reached the end (not an error — this call only
        // happens while hasMore was still true, so this transition fires
        // exactly once) — a quiet tactile confirmation instead of a
        // message, since there's nothing wrong, just nothing more.
        _safeHapticFeedback(HapticFeedback.vibrate);
      }
      return true;
    } on SearchUnavailableException {
      if (thisRequest != _requestId) return true;
      // Leave the results already on screen in place — a transient failure
      // to fetch *more* shouldn't wipe out what's already showing.
      state = state.copyWith(isLoadingMore: false);
      return false;
    }
  }

  /// Re-runs the current query — the search screen wires this to
  /// pull-to-refresh. Deliberately doesn't flip [SearchState.status] to
  /// loading: unlike a fresh query, a refresh keeps whatever's already on
  /// screen visible (RefreshIndicator's own spinner is the loading cue)
  /// rather than replacing it with a skeleton. A no-op if there's no query
  /// yet — nothing to refresh. Returns whether it succeeded, same
  /// reasoning as [loadMore].
  Future<bool> refresh() async {
    final query = state.query.trim();
    if (query.isEmpty) return true;

    final thisRequest = ++_requestId;
    try {
      final page = await ref.read(searchApiProvider).search(query);
      if (thisRequest != _requestId) return true;
      state = state.copyWith(
        status: SearchStatus.success,
        results: page.results,
        page: 0,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
      return true;
    } on SearchUnavailableException {
      if (thisRequest != _requestId) return true;
      // Only fall back to the full error screen if there's nothing already
      // on screen worth keeping — otherwise leave the stale-but-real
      // results in place and let the caller show a lighter-weight message.
      if (state.results.isEmpty) {
        state = state.copyWith(status: SearchStatus.error, hasMore: false);
      }
      return false;
    }
  }

  @visibleForTesting
  Future<void> runSearchForTesting(String query) => _runSearch(query);

  @visibleForTesting
  Future<bool> loadMoreForTesting() => loadMore();
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
