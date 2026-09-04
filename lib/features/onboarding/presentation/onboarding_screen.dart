import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';

/// Shown exactly once, on first launch — see AppPrefs.hasSeenOnboarding.
///
/// Leads with the feeling, not the footnote: a first-time visitor decides
/// whether to care in the first few seconds, and nobody reads two
/// paragraphs of citations to make that call — they decide from the
/// promise, then (maybe) look for evidence it's credible. So the hook
/// questions and the benefit come first, big and unhurried; the research
/// backing them is still here (dishonest marketing is worse than none),
/// just folded into a single quiet, tappable line instead of two dense
/// paragraphs up front.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _showResearch = false;

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
                            '10 quiet minutes a day of meditation and pranayama '
                            'can bring more calm, less anxiety, and real happiness.',
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
                            icon: Icons.favorite_outline,
                            label: 'Happiness',
                          ),
                          _BenefitChip(
                            icon: Icons.spa_outlined,
                            label: 'Less anxiety',
                          ),
                          _BenefitChip(
                            icon: Icons.bedtime_outlined,
                            label: 'Better sleep',
                          ),
                        ],
                      ).animate(delay: 550.ms).fadeIn(duration: 500.ms),
                      const SizedBox(height: 28),
                      _ResearchDisclosure(
                        expanded: _showResearch,
                        onToggle: () =>
                            setState(() => _showResearch = !_showResearch),
                      ).animate(delay: 650.ms).fadeIn(duration: 500.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onFinished,
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

/// The two citations that used to open the screen — kept, just no longer
/// the first thing anyone has to get past. See git history for how these
/// were verified.
class _ResearchDisclosure extends StatelessWidget {
  const _ResearchDisclosure({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  expanded ? 'Hide the research' : 'Backed by real research',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A Johns Hopkins-led review of 47 clinical trials (3,515 '
                            'people) found that about 8 weeks of daily mindfulness '
                            'meditation eased anxiety and depression about as much as '
                            'antidepressant medication does in some studies — with no '
                            'harm found.',
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            'JAMA Internal Medicine, 2014',
                            style: textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'A Stanford study found that just 5 minutes of daily '
                            'breathing practice — including box breathing, one of the '
                            'two techniques here — measurably lifted mood and lowered '
                            'stress within a month, building the more consistently '
                            'people practiced.',
                            style: textTheme.bodySmall,
                          ),
                          Text(
                            'Cell Reports Medicine, 2023',
                            style: textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sanskrit prayers and verses are included as a bonus for '
                            'anyone interested to explore.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
