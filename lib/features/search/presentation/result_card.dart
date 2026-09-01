import 'package:flutter/material.dart';

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
    // Only Elasticsearch's name.english/content.english are ever indexed
    // (see sadhana-backend/app/mapping.py), so the highlighted <em> match
    // only ever exists in English — using it while displaying any other
    // script would silently show English text under a Devanagari selection.
    // Bolded-match emphasis is an English-search nicety, not something to
    // chase across scripts.
    final showEnglish = preferredScript == 'english';
    final nameHighlight = showEnglish && result.nameHighlight.isNotEmpty
        ? result.nameHighlight.first
        : result.nameIn(preferredScript);
    final contentHighlight = showEnglish && result.contentHighlight.isNotEmpty
        ? result.contentHighlight.first
        : result.contentIn(preferredScript);

    final scheme = Theme.of(context).colorScheme;
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories,
                  size: 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'shloka-${result.id}',
                      child: HighlightText(
                        nameHighlight,
                        style: preferredScript == 'devanagari'
                            ? Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontFamily: 'NotoSansDevanagari')
                            : Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    HighlightText(
                      contentHighlight,
                      style: preferredScript == 'devanagari'
                          ? const TextStyle(
                              fontFamily: 'NotoSansDevanagari',
                              fontSize: 15,
                            )
                          : Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
