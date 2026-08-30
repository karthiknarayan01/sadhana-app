import 'package:sadhana/features/search/data/search_api.dart';
import 'package:sadhana/features/search/domain/shloka_result.dart';

class FakeSearchApi implements SearchApi {
  FakeSearchApi({
    this.resultsByQuery = const {},
    this.hasMoreByQuery = const {},
    this.shouldFail = false,
  });

  final Map<String, List<ShlokaResult>> resultsByQuery;

  /// Which queries should report more pages available — defaults to false
  /// (no more) for any query not listed here.
  final Map<String, bool> hasMoreByQuery;

  /// Mutable (not final) so a test can flip it mid-scenario — e.g. to make
  /// a loadMore() call fail after the initial search already succeeded.
  bool shouldFail;
  final List<String> queriesReceived = [];
  final List<int> pagesReceived = [];

  @override
  Future<SearchPage> search(String query, {int page = 0}) async {
    queriesReceived.add(query);
    pagesReceived.add(page);
    if (shouldFail) throw const SearchUnavailableException();
    return SearchPage(
      results: resultsByQuery[query] ?? [],
      hasMore: hasMoreByQuery[query] ?? false,
    );
  }
}

ShlokaResult sampleResult({
  String id = 'gayatri-mantra',
  String category = 'mantra',
}) {
  return ShlokaResult(
    id: id,
    category: category,
    languagesAvailable: const ['english', 'devanagari'],
    name: const {'english': 'Gayatri Mantra', 'devanagari': 'गायत्री मन्त्र'},
    content: const {
      'english': 'om bhur bhuvah svah',
      'devanagari': 'ॐ भूर्भुवः स्वः',
    },
    meaning: const {'english': 'A prayer to the sun for wisdom.'},
    nameHighlight: const ['<em>Gayatri</em> Mantra'],
    contentHighlight: const [],
    score: 5.0,
  );
}
