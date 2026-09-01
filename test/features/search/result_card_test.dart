import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/search/domain/shloka_result.dart';
import 'package:sadhana/features/search/presentation/result_card.dart';

void main() {
  // A result with a query match — nameHighlight/contentHighlight populated,
  // same as a real backend response for a matching search. Elasticsearch
  // only ever highlights name.english/content.english (see
  // sadhana-backend/app/mapping.py), so these are always English text.
  final result = const ShlokaResult(
    id: 'gayatri-mantra',
    category: 'mantra',
    languagesAvailable: ['english', 'devanagari'],
    name: {'english': 'Gayatri Mantra', 'devanagari': 'गायत्री मन्त्र'},
    content: {
      'english': 'om bhur bhuvah svah',
      'devanagari': 'ॐ भूर्भुवः स्वः',
    },
    meaning: {},
    nameHighlight: ['<em>Gayatri</em> Mantra'],
    contentHighlight: ['om <em>bhur</em> bhuvah svah'],
    score: 5.0,
  );

  Future<void> pumpCard(WidgetTester tester, String preferredScript) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultCard(
          result: result,
          preferredScript: preferredScript,
          onTap: () {},
        ),
      ),
    );
  }

  testWidgets(
    'devanagari selection shows Devanagari title and content, not the English highlight',
    (tester) async {
      await pumpCard(tester, 'devanagari');

      expect(find.text('गायत्री मन्त्र'), findsOneWidget);
      expect(find.text('ॐ भूर्भुवः स्वः'), findsOneWidget);
      expect(find.textContaining('Gayatri Mantra'), findsNothing);
      expect(find.textContaining('bhur bhuvah'), findsNothing);
    },
  );

  testWidgets('english selection still shows the highlighted match', (
    tester,
  ) async {
    await pumpCard(tester, 'english');

    // HighlightText splits "<em>Gayatri</em> Mantra" into separate spans
    // ("Gayatri" bolded, " Mantra" plain), so it isn't one findable string
    // — check the underlying rich text's plain content instead. Scoped to
    // the title's Hero (not just "the first RichText in the card"): the
    // leading icon medallion's Icon is itself implemented via RichText, so
    // an unscoped `.first` picks up the icon's glyph instead of the title.
    final richText = tester.widget<RichText>(
      find
          .descendant(of: find.byType(Hero), matching: find.byType(RichText))
          .first,
    );
    expect(richText.text.toPlainText(), 'Gayatri Mantra');
  });
}
