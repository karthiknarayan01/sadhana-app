import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../application/favorites_controller.dart';
import '../application/preferred_script_controller.dart';
import '../domain/shloka_result.dart';

class ShlokaDetailScreen extends ConsumerStatefulWidget {
  const ShlokaDetailScreen({super.key, required this.result});

  final ShlokaResult result;

  @override
  ConsumerState<ShlokaDetailScreen> createState() => _ShlokaDetailScreenState();
}

class _ShlokaDetailScreenState extends ConsumerState<ShlokaDetailScreen> {
  bool _showTransliteration = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final scheme = Theme.of(context).colorScheme;
    final favorites = ref.watch(favoritesControllerProvider);
    final isFavorite = favorites.contains(result.id);
    final preferredScript = ref.watch(preferredScriptControllerProvider);
    final meaning = result.meaningIn(preferredScript);

    final scriptText = _showTransliteration
        ? result.contentIn('english')
        : result.contentIn(preferredScript);
    final usingDevanagari =
        !_showTransliteration && preferredScript == 'devanagari';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => ref
                .read(favoritesControllerProvider.notifier)
                .toggle(result.id),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(result, preferredScript),
          ),
        ],
      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          result.category,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: scheme.onSecondaryContainer),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        result.nameIn(preferredScript),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _GlassCard(
                    child: Text(
                      scriptText,
                      style: usingDevanagari
                          ? GoogleFonts.notoSansDevanagari(
                              fontSize: 22,
                              height: 1.8,
                            )
                          : GoogleFonts.merriweather(
                              fontSize: 17,
                              height: 1.7,
                              fontStyle: FontStyle.italic,
                            ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _showTransliteration = !_showTransliteration,
                  ),
                  icon: const Icon(Icons.translate, size: 18),
                  label: Text(
                    _showTransliteration
                        ? 'Show original script'
                        : 'Show transliteration',
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
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meaning,
                            style: GoogleFonts.merriweather(
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 250.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _share(ShlokaResult result, String preferredScript) {
    final buffer = StringBuffer()
      ..writeln(result.nameIn(preferredScript))
      ..writeln()
      ..writeln(result.contentIn(preferredScript));
    final meaning = result.meaningIn(preferredScript);
    if (meaning != null) {
      buffer
        ..writeln()
        ..writeln(meaning);
    }
    Share.share(buffer.toString());
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
