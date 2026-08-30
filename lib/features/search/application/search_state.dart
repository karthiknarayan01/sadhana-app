import '../domain/shloka_result.dart';

enum SearchStatus { idle, loading, success, error }

class SearchState {
  const SearchState({
    this.query = '',
    this.status = SearchStatus.idle,
    this.results = const [],
    this.page = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final String query;
  final SearchStatus status;
  final List<ShlokaResult> results;

  /// The last page successfully fetched for [results] — loadMore() asks
  /// for page + 1 next.
  final int page;

  /// Whether the backend says more results exist beyond the current page.
  final bool hasMore;

  /// True while a loadMore() request is in flight — distinct from
  /// [SearchStatus.loading], which is for the initial full-screen fetch,
  /// so scrolling to load more doesn't blank out the results already shown.
  final bool isLoadingMore;

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<ShlokaResult>? results,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
