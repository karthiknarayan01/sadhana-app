import 'package:flutter/material.dart';

import '../domain/benefit_content.dart';

/// A modal bottom sheet with one practice's "why bother" copy — reachable
/// both from that practice's own pre-start screen (a small "Why this
/// practice?" link) and from the progress tab's benefits section.
Future<void> showBenefitSheet(BuildContext context, String practiceType) {
  final content = benefitContent[practiceType];
  if (content == null) return Future.value();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                content.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                content.tagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              for (final point in content.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.self_improvement,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(point)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

/// The tagline is shown ambiently, right on the setup screen — no click
/// needed to see it. Tapping the card is still an option for anyone who
/// wants the full "why bother" copy, but seeing *some* benefit up front is
/// no longer gated behind a button (previously a small "Why this practice?"
/// link with an (i) icon, which read as an alert rather than an invitation).
class BenefitCard extends StatelessWidget {
  const BenefitCard({super.key, required this.practiceType});

  final String practiceType;

  @override
  Widget build(BuildContext context) {
    final content = benefitContent[practiceType];
    if (content == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showBenefitSheet(context, practiceType),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.self_improvement, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  content.tagline,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
