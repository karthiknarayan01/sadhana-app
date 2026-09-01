import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/preferred_script_controller.dart';
import '../application/search_controller.dart';
import '../application/search_state.dart';
import 'language_selector.dart';
import 'result_card.dart';
import 'results_skeleton.dart';
import 'shloka_detail_screen.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchControllerProvider);
    final preferredScript = ref.watch(preferredScriptControllerProvider);

    final availableLanguages = {
      for (final result in state.results) ...result.languagesAvailable,
      'devanagari',
      'english',
    }.toList()..sort();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sanskrit Prayers',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    '1,300+ prayers, verses, and hymns to explore',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 12),
                  TextField(
                        decoration: const InputDecoration(
                          hintText:
                              'Search a prayer or verse by name or content…',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: ref
                            .read(searchControllerProvider.notifier)
                            .onQueryChanged,
                      )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
            const SizedBox(height: 4),
            LanguageSelector(
              languages: availableLanguages,
              selected: preferredScript,
              onSelected: ref
                  .read(preferredScriptControllerProvider.notifier)
                  .select,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _ResultsArea(
                state: state,
                preferredScript: preferredScript,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsArea extends ConsumerStatefulWidget {
  const _ResultsArea({required this.state, required this.preferredScript});

  final SearchState state;
  final String preferredScript;

  @override
  ConsumerState<_ResultsArea> createState() => _ResultsAreaState();
}

class _ResultsAreaState extends ConsumerState<_ResultsArea> {
  final _scrollController = ScrollController();

  // Fetch the next page a bit before the user actually hits the bottom, so
  // it's ready by the time they get there instead of after.
  static const _loadMoreThreshold = 400.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    switch (state.status) {
      case SearchStatus.idle:
        return state.query.trim().isEmpty
            ? const _EmptyPrompt()
            : const SizedBox.shrink();
      case SearchStatus.loading:
        return const ResultsSkeleton();
      case SearchStatus.error:
        return const _ErrorState();
      case SearchStatus.success:
        if (state.results.isEmpty) {
          return const _NoMatches();
        }
        final itemCount = state.results.length + (state.isLoadingMore ? 1 : 0);
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index >= state.results.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            final result = state.results[index];
            return ResultCard(
              result: result,
              preferredScript: widget.preferredScript,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShlokaDetailScreen(result: result),
                ),
              ),
            );
          },
        );
    }
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories, size: 40, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'A bonus collection of Sanskrit prayers, verses, and hymns — '
              'search by name or content',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No matches found',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(
              "Couldn't reach search right now — try again in a moment.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
