import '../domain/shloka_result.dart';

enum SearchStatus { idle, loading, success, error }

class SearchState {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.idle,
    this.results = const [],
  });

  final String query;
  final SearchStatus status;
  final List<ShlokaResult> results;

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<ShlokaResult>? results,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
    );
  }
}
