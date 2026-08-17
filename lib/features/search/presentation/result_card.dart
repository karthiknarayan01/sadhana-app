import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/shloka_result.dart';
import 'highlight_text.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.preferredScript,
    required this.isFavorite,
    required this.onTap,
  });

  final ShlokaResult result;
  final String preferredScript;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'shloka-${result.id}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: HighlightText(
                              nameHighlight,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              result.category,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
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
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? scheme.error : scheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
