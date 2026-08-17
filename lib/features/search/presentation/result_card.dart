import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/shloka_result.dart';
import 'highlight_text.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.preferredScript,
    required this.onTap,
  });

  final ShlokaResult result;
  final String preferredScript;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nameHighlight = result.nameHighlight.isNotEmpty
        ? result.nameHighlight.first
        : result.nameIn('english');
    final contentHighlight = result.contentHighlight.isNotEmpty
        ? result.contentHighlight.first
        : result.contentIn(preferredScript);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Hero(
            tag: 'shloka-${result.id}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HighlightText(
                  nameHighlight,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                HighlightText(
                  contentHighlight,
                  style: preferredScript == 'devanagari'
                      ? GoogleFonts.notoSansDevanagari(fontSize: 15)
                      : Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
