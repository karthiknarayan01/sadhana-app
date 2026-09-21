import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/features/search/domain/reader_pagination.dart';

void main() {
  group('splitIntoChunks', () {
    test('splits on blank lines when present', () {
      expect(
        splitIntoChunks('stanza one\nline two\n\nstanza two\n\n\nstanza three'),
        ['stanza one\nline two', 'stanza two', 'stanza three'],
      );
    });

    test('falls back to single newlines when there are no blank lines', () {
      expect(splitIntoChunks('line a\nline b\nline c'), [
        'line a',
        'line b',
        'line c',
      ]);
    });

    test('breaks an unbroken verse after danda / double danda', () {
      expect(splitIntoChunks('oṃ bhūr bhuvaḥ svaḥ । tat savitur vareṇyaṃ ॥'), [
        'oṃ bhūr bhuvaḥ svaḥ ।',
        'tat savitur vareṇyaṃ ॥',
      ]);
    });

    test('breaks an unbroken transliteration after "||"', () {
      expect(splitIntoChunks('om namah shivaya || hara hara mahadev ||'), [
        'om namah shivaya ||',
        'hara hara mahadev ||',
      ]);
    });

    test('trims and drops empty fragments; empty input yields nothing', () {
      expect(splitIntoChunks('  \n\n  hello  \n\n  '), ['hello']);
      expect(splitIntoChunks('   \n  '), isEmpty);
    });
  });

  group('buildReaderRuns / flattenRuns', () {
    test('title, then gap-separated verse stanzas, then meaning section', () {
      final runs = buildReaderRuns(
        title: 'Gayatri Mantra',
        verse: 'om bhur bhuvah svah\n\ntat savitur varenyam',
        meaning: 'We meditate on the glory.\n\nMay it inspire our minds.',
      );

      expect(runs.map((r) => r.kind), [
        ReaderRunKind.title,
        ReaderRunKind.gap,
        ReaderRunKind.verse,
        ReaderRunKind.gap,
        ReaderRunKind.verse,
        ReaderRunKind.gap,
        ReaderRunKind.meaningHeading,
        ReaderRunKind.gap,
        ReaderRunKind.meaning,
        ReaderRunKind.gap,
        ReaderRunKind.meaning,
      ]);
      expect(runs.first.text, 'Gayatri Mantra');
      expect(
        flattenRuns(runs).startsWith('Gayatri Mantra\n\nom bhur bhuvah svah'),
        isTrue,
      );
    });

    test('no meaning section when meaning is null or blank', () {
      final runs = buildReaderRuns(title: 'T', verse: 'a\n\nb', meaning: '  ');
      expect(runs.any((r) => r.kind == ReaderRunKind.meaningHeading), isFalse);
      expect(runs.any((r) => r.kind == ReaderRunKind.meaning), isFalse);
    });
  });

  group('paginateLines', () {
    // Six lines, each 20 tall (tops 0,20,40,...); a page holds 50 -> 2 lines.
    List<double> tops(int n, double h) => [for (var i = 0; i < n; i++) i * h];
    List<int> starts(int n, int step) => [for (var i = 0; i < n; i++) i * step];

    test('packs as many whole lines as fit, then starts a new page', () {
      final pages = paginateLines(
        lineTops: tops(6, 20),
        lineStarts: starts(6, 10), // 10 chars per line
        totalHeight: 120,
        textLength: 60,
        maxHeight: 50,
      );

      expect(pages, [
        const PageSlice(0, 20),
        const PageSlice(20, 40),
        const PageSlice(40, 60),
      ]);
    });

    test('a single line taller than the page still gets its own page', () {
      final pages = paginateLines(
        lineTops: [0, 200, 220],
        lineStarts: [0, 5, 9],
        totalHeight: 240,
        textLength: 12,
        maxHeight: 50,
      );

      expect(pages, [
        const PageSlice(0, 5), // oversized line alone
        const PageSlice(5, 12), // the remaining two short lines
      ]);
    });

    test('empty input yields a single empty page', () {
      expect(
        paginateLines(
          lineTops: const [],
          lineStarts: const [],
          totalHeight: 0,
          textLength: 0,
          maxHeight: 50,
        ),
        [const PageSlice(0, 0)],
      );
    });
  });

  group('runSlicesFor', () {
    final runs = [
      const ReaderRun(ReaderRunKind.title, 'Title'), // 0..5
      const ReaderRun(ReaderRunKind.gap, '\n\n'), // 5..7
      const ReaderRun(ReaderRunKind.verse, 'verse body'), // 7..17
    ];
    final text = flattenRuns(runs);

    test('clips every run to the page range, in order', () {
      final slices = runSlicesFor(runs, text, const PageSlice(3, 12)).toList();
      expect(slices.map((s) => s.kind), [
        ReaderRunKind.title,
        ReaderRunKind.gap,
        ReaderRunKind.verse,
      ]);
      expect(slices[0].text, 'le'); // 'Title'[3..5]
      expect(slices[2].text, 'verse'); // 'verse body'[0..5]
    });

    test('drops runs entirely outside the range', () {
      final slices = runSlicesFor(runs, text, const PageSlice(7, 17)).toList();
      expect(slices.map((s) => s.kind), [ReaderRunKind.verse]);
      expect(slices.single.text, 'verse body');
    });
  });
}
