import 'package:flutter/material.dart';
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
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search a prayer or verse by name or content…',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: ref
                        .read(searchControllerProvider.notifier)
                        .onQueryChanged,
                  ),
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

class _ResultsArea extends StatelessWidget {
  const _ResultsArea({required this.state, required this.preferredScript});

  final SearchState state;
  final String preferredScript;

  @override
  Widget build(BuildContext context) {
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
        return ListView.builder(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          itemCount: state.results.length,
          itemBuilder: (context, index) {
            final result = state.results[index];
            return ResultCard(
              result: result,
              preferredScript: preferredScript,
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
            Icon(Icons.auto_stories, size: 48, color: scheme.outline),
            const SizedBox(height: 12),
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
