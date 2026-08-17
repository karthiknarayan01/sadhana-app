import 'package:sadhana/features/search/data/search_api.dart';
import 'package:sadhana/features/search/domain/shloka_result.dart';

class FakeSearchApi implements SearchApi {
  FakeSearchApi({this.resultsByQuery = const {}, this.shouldFail = false});

  final Map<String, List<ShlokaResult>> resultsByQuery;
  final bool shouldFail;
  final List<String> queriesReceived = [];

  @override
  Future<List<ShlokaResult>> search(String query) async {
    queriesReceived.add(query);
    if (shouldFail) throw const SearchUnavailableException();
    return resultsByQuery[query] ?? [];
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
