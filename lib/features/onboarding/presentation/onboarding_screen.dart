import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

/// Shown exactly once, on first launch — see AppPrefs.hasSeenOnboarding.
///
/// Leads with the feeling, not the footnote: a first-time visitor decides
/// whether to care in the first few seconds. So the hook questions and a
/// plain description of the practice come first, big and unhurried — no
/// outcome promises, no clinical claims, just what the app is and an
/// invitation to try it.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark ? AppTheme.heroGradientDark : AppTheme.heroGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      _BreathingIcon(color: scheme.primary),
                      const SizedBox(height: 28),
                      Text(
                            'Feeling anxious?\nOverwhelmed? Tired?',
                            style: textTheme.headlineMedium,
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 12),
                      Text(
                            "You're in the right place.",
                            style: textTheme.headlineSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          )
                          .animate(delay: 150.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 20),
                      Text(
                            'A few quiet minutes a day of meditation and '
                            'pranayama — a small, steady practice to slow down '
                            'and give your attention somewhere to rest.',
                            style: textTheme.bodyLarge?.copyWith(height: 1.5),
                          )
                          .animate(delay: 300.ms)
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.15, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'Practiced and refined by people for thousands of years. '
                        'Now it\'s your turn.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ).animate(delay: 450.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _BenefitChip(
                            icon: Icons.self_improvement,
                            label: 'Calm',
                          ),
                          _BenefitChip(
                            icon: Icons.center_focus_strong_outlined,
                            label: 'Focus',
                          ),
                          _BenefitChip(
                            icon: Icons.spa_outlined,
                            label: 'Stillness',
                          ),
                          _BenefitChip(
                            icon: Icons.bedtime_outlined,
                            label: 'Rest',
                          ),
                        ],
                      ).animate(delay: 550.ms).fadeIn(duration: 500.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onFinished,
                        child: const Text('Begin Your Practice'),
                      ),
                    )
                    .animate(delay: 750.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingIcon extends StatelessWidget {
  const _BreathingIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.self_improvement, size: 44, color: color),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.08,
                duration: 2200.ms,
                curve: Curves.easeInOut,
              ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
