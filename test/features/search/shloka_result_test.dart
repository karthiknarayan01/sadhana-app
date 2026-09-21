import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/search/domain/shloka_result.dart';

void main() {
  test('fromJson parses a full backend response document', () {
    final result = ShlokaResult.fromJson({
      'id': 'gayatri-mantra',
      'category': 'mantra',
      'languages_available': ['english', 'devanagari'],
      'name': {'english': 'Gayatri Mantra', 'devanagari': 'गायत्री मन्त्र'},
      'content': {
        'english': 'om bhur bhuvah svah',
        'devanagari': 'ॐ भूर्भुवः स्वः',
      },
      'meaning': {'english': 'A prayer to the sun for wisdom.'},
      'highlight': {
        'name': ['<em>Gayatri</em> Mantra'],
        'content': [],
      },
      'score': 6.78,
    });

    expect(result.id, 'gayatri-mantra');
    expect(result.nameIn('devanagari'), 'गायत्री मन्त्र');
    expect(result.contentIn('english'), 'om bhur bhuvah svah');
    expect(result.meaningIn('english'), 'A prayer to the sun for wisdom.');
  });

  test('nameIn/contentIn fall back to english when the requested language is missing', () {
    final result = ShlokaResult.fromJson({
      'id': 'x',
      'category': 'mantra',
      'languages_available': ['english'],
      'name': {'english': 'Only English'},
      'content': {'english': 'only english content'},
      'meaning': {},
      'highlight': {'name': [], 'content': []},
      'score': 1.0,
    });

    expect(result.nameIn('devanagari'), 'Only English');
    expect(result.contentIn('telugu'), 'only english content');
    expect(result.meaningIn('devanagari'), isNull);
  });

  test('meaning defaults to an empty map when absent from the response', () {
    final result = ShlokaResult.fromJson({
      'id': 'x',
      'category': 'mantra',
      'languages_available': ['english'],
      'name': {'english': 'X'},
      'content': {'english': 'x'},
      'highlight': {'name': [], 'content': []},
      'score': 1.0,
    });

    expect(result.meaning, isEmpty);
  });
}
