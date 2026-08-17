import 'package:flutter/material.dart';

/// Shown exactly once, on first launch — see AppPrefs.hasSeenOnboarding.
/// Deliberately plain (no animation, no swipeable pages): the app's own
/// pitch is that it's simple, so the first thing a new user sees should
/// feel calm and quick to get through, not another flashy onboarding
/// carousel.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      size: 56,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Sadhana',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Two respected studies help explain why:',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const _BenefitPoint(
                      icon: Icons.spa_outlined,
                      text:
                          'A Johns Hopkins-led review of 47 clinical trials '
                          '(3,515 people) found that about 8 weeks of daily '
                          'mindfulness meditation eased anxiety and depression '
                          'about as much as antidepressant medication does in '
                          'some studies — with no harm found.',
                      source: 'JAMA Internal Medicine, 2014',
                    ),
                    const _BenefitPoint(
                      icon: Icons.air,
                      text:
                          'A Stanford study found that just 5 minutes of daily '
                          'breathing practice — including box breathing, one '
                          'of the two techniques here — measurably lifted mood '
                          'and lowered stress within a month, with the effect '
                          'building the more consistently people practiced.',
                      source: 'Cell Reports Medicine, 2023',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'This app is intentionally simple: no complicated programs, '
                      'just two quiet practices — meditation and breathing — that '
                      'you can return to daily.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sanskrit prayers and verses are included as a bonus for '
                      'anyone curious to explore them — entirely optional, never '
                      'required.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onFinished,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Begin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitPoint extends StatelessWidget {
  const _BenefitPoint({
    required this.icon,
    required this.text,
    required this.source,
  });

  final IconData icon;
  final String text;

  /// Shown in small, muted text under the claim — real research earns real
  /// attribution, not just a confident-sounding sentence. See the
  /// OnboardingScreen's own git history for how these two were verified.
  final String source;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  source,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
