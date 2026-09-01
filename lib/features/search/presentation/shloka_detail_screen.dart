import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/preferred_script_controller.dart';
import '../domain/shloka_result.dart';

class ShlokaDetailScreen extends ConsumerWidget {
  const ShlokaDetailScreen({super.key, required this.result});

  final ShlokaResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final preferredScript = ref.watch(preferredScriptControllerProvider);
    final meaning = result.meaningIn(preferredScript);
    final scriptText = result.contentIn(preferredScript);
    final usingDevanagari = preferredScript == 'devanagari';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Hero(
                tag: 'shloka-${result.id}',
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    result.nameIn(preferredScript),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: preferredScript == 'devanagari'
                          ? 'NotoSansDevanagari'
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _GlassCard(
                child: Text(
                  scriptText,
                  style: usingDevanagari
                      ? const TextStyle(
                          fontFamily: 'NotoSansDevanagari',
                          fontSize: 22,
                          height: 1.8,
                        )
                      : const TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 17,
                          height: 1.7,
                          fontStyle: FontStyle.italic,
                        ),
                ),
              ),
              if (meaning != null) ...[
                const SizedBox(height: 12),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meaning',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meaning,
                        style: const TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
