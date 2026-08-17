import 'package:flutter/material.dart';

/// Renders Elasticsearch's default `<em>...</em>` highlight markup as bolded
/// spans — the only tag the backend's highlight config ever produces (see
/// sadhana-backend/app/es_client.py), so a tiny hand-rolled parser is enough,
/// no HTML package needed.
class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final emphasisStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    final spans = <TextSpan>[];
    final pattern = RegExp('<em>(.*?)</em>');
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: emphasisStyle));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
