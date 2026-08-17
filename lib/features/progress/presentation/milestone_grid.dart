import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../domain/milestones.dart';

class MilestoneGrid extends StatelessWidget {
  const MilestoneGrid({super.key, required this.unlockedIds});

  final Set<String> unlockedIds;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: milestoneDefinitions.length,
      itemBuilder: (context, index) {
        final milestone = milestoneDefinitions[index];
        final unlocked = unlockedIds.contains(milestone.id);
        return Tooltip(
          message: unlocked
              ? milestone.description
              : 'Locked — ${milestone.description}',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: unlocked
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                child: Icon(
                  milestone.icon,
                  color: unlocked
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                milestone.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: unlocked
                      ? null
                      : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ).animate(target: unlocked ? 1 : 0).scaleXY(begin: 0.94, end: 1.0);
      },
    );
  }
}
