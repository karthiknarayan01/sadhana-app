import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/search/domain/shloka_result.dart';
import 'package:sadhana/features/search/presentation/reader_screen.dart';

ShlokaResult _result(String content, {Map<String, String> meaning = const {}}) {
  return ShlokaResult(
    id: 'x',
    category: 'stotram',
    languagesAvailable: const ['english'],
    name: const {'english': 'A Long Prayer'},
    content: {'english': content},
    meaning: meaning,
    nameHighlight: const [],
    contentHighlight: const [],
    score: 1,
  );
}

/// Opens the reader as a pushed route (as the real app does), so
/// close-button behaviour can be exercised.
Future<void> _open(WidgetTester tester, ShlokaResult result) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(result: result),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

int _pageCount(WidgetTester tester) {
  final label = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .firstWhere((s) => s != null && s.contains(' of '), orElse: () => null);
  expect(label, isNotNull, reason: 'page-position label should be shown');
  return int.parse(label!.split(' of ').last);
}

double _chromeOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  testWidgets(
    'a long verse is cut into several pages, none of them scrolling',
    (tester) async {
      await _open(
        tester,
        _result(
          List.filled(600, 'word').join(' '),
          meaning: const {'english': 'A short meaning paragraph.'},
        ),
      );

      expect(_pageCount(tester), greaterThan(1));
      // Continuous-flow pagination should never fall back to a scroll view.
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(ListView), findsNothing);
    },
  );

  testWidgets('chrome auto-hides, a tap brings it back, ✕ closes the reader', (
    tester,
  ) async {
    await _open(tester, _result('om namah shivaya'));

    expect(_chromeOpacity(tester), 1);

    await tester.pump(const Duration(seconds: 4)); // past the 3s auto-hide
    await tester.pumpAndSettle();
    expect(_chromeOpacity(tester), 0);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(_chromeOpacity(tester), 1);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(ReaderScreen), findsNothing);
  });

  testWidgets('a short prayer produces exactly one page', (tester) async {
    await _open(tester, _result('om'));
    expect(_pageCount(tester), 1);
  });
}
