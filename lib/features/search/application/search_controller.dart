import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/search_api.dart';
import 'search_state.dart';

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
  /// while already past the threshold.
  Future<void> loadMore() async {
    if (state.status != SearchStatus.success) return;
    if (!state.hasMore || state.isLoadingMore) return;

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
      if (thisRequest != _requestId) return;
      state = state.copyWith(
        results: [...state.results, ...page.results],
        page: nextPage,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } on SearchUnavailableException {
      if (thisRequest != _requestId) return;
      // Leave the results already on screen in place — a transient failure
      // to fetch *more* shouldn't wipe out what's already showing.
      state = state.copyWith(isLoadingMore: false);
    }
  }

  @visibleForTesting
  Future<void> runSearchForTesting(String query) => _runSearch(query);

  @visibleForTesting
  Future<void> loadMoreForTesting() => loadMore();
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
