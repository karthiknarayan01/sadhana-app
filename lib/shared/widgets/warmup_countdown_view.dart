import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The settle-in screen shown between Start and the gong that marks
/// practice actually beginning — identical need for meditation and
/// breathing, so shared rather than duplicated per feature.
class WarmupCountdownView extends StatelessWidget {
  const WarmupCountdownView({
    super.key,
    required this.secondsRemaining,
    required this.onCancel,
  });

  final int secondsRemaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get ready…',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                        '$secondsRemaining',
                        key: ValueKey(secondsRemaining),
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontFamily: 'Merriweather',
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      )
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        duration: 250.ms,
                      ),
                ],
              ),
            ),
          ),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 56),
              shape: const StadiumBorder(),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
