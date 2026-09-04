import 'package:flutter/material.dart';

/// A collapsed-by-default "How to practice" card for a practice's setup
/// screen: what the cues mean, and the actual steps. Meditation and
/// breathing both use bell / gong / soft-tone cues that mean nothing
/// without a one-line explanation.
class PracticeGuide extends StatelessWidget {
  const PracticeGuide({super.key, required this.practiceType});

  final String practiceType;

  static const _guides = <String, ({String title, List<String> lines})>{
    'meditation': (
      title: 'How to practice',
      lines: [
        'A bell opens the session and sounds once a minute — just a marker '
            'that time is passing, nothing to do.',
        'A deep gong closes the session.',
        'Sit comfortably, eyes closed or lowered. Rest your attention on the '
            'breath; when the mind wanders, notice and come back. That is the '
            'whole practice.',
      ],
    ),
    'box_breathing': (
      title: 'How to practice',
      lines: [
        'Follow the count on screen. A bell marks each change — inhale, hold, '
            'exhale, hold, all the same length.',
        'Breathe through the nose, smoothly; never strain the holds.',
        'A gong closes the session when you stop.',
      ],
    ),
    'alt_nostril_breathing': (
      title: 'How to practice',
      lines: [
        'A soft tone marks each step. The screen shows which nostril is '
            'active.',
        'With your right hand: close the right nostril, inhale through the '
            'left. Close the left, exhale through the right. Inhale right, '
            'then switch and exhale left — that is one round.',
        'Keep the breath gentle. A gong closes the session when you stop.',
      ],
    ),
  };

  @override
  Widget build(BuildContext context) {
    final guide = _guides[practiceType];
    if (guide == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    // Material (not a plain DecoratedBox) so ExpansionTile's internal
    // ListTile has a Material ancestor to paint its background/splash on.
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.spa_outlined, size: 20, color: scheme.primary),
          title: Text(
            guide.title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in guide.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 10),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
