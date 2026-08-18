import 'package:flutter/material.dart';

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
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$secondsRemaining',
                    style: Theme.of(context).textTheme.displayLarge
                        ?.copyWith(fontWeight: FontWeight.w200),
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
