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
                      'A few minutes a day, consistently, is what research keeps '
                      'pointing to:',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const _BenefitPoint(
                      icon: Icons.spa_outlined,
                      text:
                          'Regular meditation practice has been linked to lower '
                          'stress, better focus, and a greater sense of calm.',
                    ),
                    const _BenefitPoint(
                      icon: Icons.air,
                      text:
                          'Slow, conscious breathing can activate the body\'s '
                          'relaxation response within minutes.',
                    ),
                    const _BenefitPoint(
                      icon: Icons.calendar_today_outlined,
                      text:
                          'Consistency matters more than duration — a few honest '
                          'minutes each day, kept up over time, is what compounds.',
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
  const _BenefitPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
