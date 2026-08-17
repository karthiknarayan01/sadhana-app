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

/// Compact inline widget for a "Why this practice?" trigger — used on the
/// meditation/breathing setup screens.
class BenefitLink extends StatelessWidget {
  const BenefitLink({super.key, required this.practiceType});

  final String practiceType;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showBenefitSheet(context, practiceType),
      icon: const Icon(Icons.info_outline, size: 16),
      label: const Text('Why this practice?'),
    );
  }
}
