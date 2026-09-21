/// Pure layout logic for the Books-style prayer reader.
///
/// The reader lays a whole prayer out as one continuous styled document,
/// then cuts it into screen-sized pages at line boundaries so every page is
/// full and nothing has to scroll. This file owns the two pure pieces:
/// turning the prayer's fields into styled runs, and packing measured lines
/// into pages. The measuring itself (TextPainter) lives in the widget.
library;

import 'dart:math' as math;

enum ReaderRunKind { title, gap, verse, meaningHeading, meaning }

/// A stretch of the flattened prayer text that shares one text style.
class ReaderRun {
  const ReaderRun(this.kind, this.text);

  final ReaderRunKind kind;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is ReaderRun && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'ReaderRun(${kind.name}, ${text.length} chars)';
}

/// A page is just a half-open character range [start, end) into the
/// flattened prayer text.
class PageSlice {
  const PageSlice(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is PageSlice && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'PageSlice($start, $end)';
}

/// Splits a raw text field into paragraph/stanza chunks so the reader has
/// natural break points. In order of preference: blank-line separated
/// blocks, then single newlines, then — for verses that arrive as one
/// unbroken string — after a danda (।), double danda (॥), or their "||"/"|"
/// transliteration, keeping the mark on the line it closes. Anything still
/// too tall for a page is broken line-by-line when the page is measured.
List<String> splitIntoChunks(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];

  var parts = trimmed.split(RegExp(r'\n[ \t]*\n+'));
  if (parts.length == 1) parts = trimmed.split('\n');
  if (parts.length == 1) {
    parts = trimmed.split(RegExp(r'(?<=॥)\s*|(?<=।)\s*|(?<=\|\|)\s*'));
  }

  return [
    for (final p in parts)
      if (p.trim().isNotEmpty) p.trim(),
  ];
}

/// Flattens a prayer into the run list the reader concatenates and lays
/// out: the title, a blank line, each verse stanza separated by blank
/// lines, then (if present) a "Meaning" heading and the meaning paragraphs.
List<ReaderRun> buildReaderRuns({
  required String title,
  required String verse,
  String? meaning,
}) {
  final runs = <ReaderRun>[ReaderRun(ReaderRunKind.title, title.trim())];

  final stanzas = splitIntoChunks(verse);
  for (var i = 0; i < stanzas.length; i++) {
    runs.add(const ReaderRun(ReaderRunKind.gap, '\n\n'));
    runs.add(ReaderRun(ReaderRunKind.verse, stanzas[i]));
  }

  final paras = meaning == null ? const <String>[] : splitIntoChunks(meaning);
  if (paras.isNotEmpty) {
    runs.add(const ReaderRun(ReaderRunKind.gap, '\n\n'));
    runs.add(const ReaderRun(ReaderRunKind.meaningHeading, 'Meaning'));
    for (final p in paras) {
      runs.add(const ReaderRun(ReaderRunKind.gap, '\n\n'));
      runs.add(ReaderRun(ReaderRunKind.meaning, p));
    }
  }

  return runs;
}

/// The plain string the runs concatenate to — what gets laid out and
/// sliced. Kept in one place so run offsets and page offsets agree.
String flattenRuns(List<ReaderRun> runs) => runs.map((r) => r.text).join();

/// Packs measured lines into pages. [lineTops] holds the y offset of each
/// line's top, [lineStarts] the character offset where each line begins
/// (both in visual order), [totalHeight] the full laid-out height and
/// [textLength] the flattened text length. A page takes as many whole
/// lines as fit in [maxHeight]; a single line taller than the page still
/// gets its own page rather than looping forever.
List<PageSlice> paginateLines({
  required List<double> lineTops,
  required List<int> lineStarts,
  required double totalHeight,
  required int textLength,
  required double maxHeight,
}) {
  assert(lineTops.length == lineStarts.length);
  if (lineStarts.isEmpty) return const [PageSlice(0, 0)];

  double lineHeight(int i) => (i + 1 < lineTops.length)
      ? lineTops[i + 1] - lineTops[i]
      : totalHeight - lineTops[i];

  int lineCharEnd(int i) =>
      (i + 1 < lineStarts.length) ? lineStarts[i + 1] : textLength;

  final pages = <PageSlice>[];
  var i = 0;
  while (i < lineStarts.length) {
    final startLine = i;
    var used = 0.0;
    while (i < lineStarts.length &&
        (i == startLine || used + lineHeight(i) <= maxHeight)) {
      used += lineHeight(i);
      i++;
    }
    pages.add(PageSlice(lineStarts[startLine], lineCharEnd(i - 1)));
  }
  return pages;
}

/// Builds the `TextSpan` children for one page: every run clipped to the
/// page's character range, in order. [text] is [flattenRuns] of [runs].
Iterable<({ReaderRunKind kind, String text})> runSlicesFor(
  List<ReaderRun> runs,
  String text,
  PageSlice slice,
) sync* {
  var offset = 0;
  for (final run in runs) {
    final runStart = offset;
    final runEnd = offset + run.text.length;
    offset = runEnd;
    final from = math.max(runStart, slice.start);
    final to = math.min(runEnd, slice.end);
    if (from < to) {
      yield (kind: run.kind, text: text.substring(from, to));
    }
  }
}
