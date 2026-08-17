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
      state = state.copyWith(status: SearchStatus.idle, results: []);
      return;
    }

    _debounce = Timer(_debounceDuration, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final thisRequest = ++_requestId;
    state = state.copyWith(status: SearchStatus.loading);

    try {
      final results = await ref.read(searchApiProvider).search(query);
      // A slower earlier request landing after a newer one would otherwise
      // overwrite fresher results with stale ones.
      if (thisRequest != _requestId) return;
      state = state.copyWith(status: SearchStatus.success, results: results);
    } on SearchUnavailableException {
      if (thisRequest != _requestId) return;
      state = state.copyWith(status: SearchStatus.error, results: []);
    }
  }

  @visibleForTesting
  Future<void> runSearchForTesting(String query) => _runSearch(query);
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
