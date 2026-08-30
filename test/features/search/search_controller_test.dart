import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/providers.dart';
import 'package:sadhana/features/search/application/search_controller.dart';
import 'package:sadhana/features/search/application/search_state.dart';

import '../../fakes/fake_search_api.dart';

void main() {
  test(
    'typing debounces — only the final query after a pause reaches the API',
    () {
      final api = FakeSearchApi(
        resultsByQuery: {
          'gayatri': [sampleResult()],
        },
      );
      final container = ProviderContainer(
        overrides: [searchApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      fakeAsync((async) {
        final controller = container.read(searchControllerProvider.notifier);
        controller.onQueryChanged('g');
        async.elapse(const Duration(milliseconds: 100));
        controller.onQueryChanged('ga');
        async.elapse(const Duration(milliseconds: 100));
        controller.onQueryChanged('gayatri');
        async.elapse(const Duration(milliseconds: 400));

        expect(api.queriesReceived, ['gayatri']);
        expect(
          container.read(searchControllerProvider).status,
          SearchStatus.success,
        );
        expect(container.read(searchControllerProvider).results, hasLength(1));
      });
    },
  );

  test('clearing the query resets to idle without calling the API', () {
    final api = FakeSearchApi();
    final container = ProviderContainer(
      overrides: [searchApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    fakeAsync((async) {
      final controller = container.read(searchControllerProvider.notifier);
      controller.onQueryChanged('gayatri');
      async.elapse(const Duration(milliseconds: 400));
      controller.onQueryChanged('');
      async.elapse(const Duration(milliseconds: 400));

      expect(
        container.read(searchControllerProvider).status,
        SearchStatus.idle,
      );
      expect(container.read(searchControllerProvider).results, isEmpty);
    });
  });

  test('a failed search surfaces the error status with empty results', () {
    final api = FakeSearchApi(shouldFail: true);
    final container = ProviderContainer(
      overrides: [searchApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    fakeAsync((async) {
      container
          .read(searchControllerProvider.notifier)
          .onQueryChanged('gayatri');
      async.elapse(const Duration(milliseconds: 400));

      expect(
        container.read(searchControllerProvider).status,
        SearchStatus.error,
      );
      expect(container.read(searchControllerProvider).results, isEmpty);
    });
  });

  test(
    'loadMore appends the next page and asks for page 1, not a fresh page 0',
    () {
      final page0 = sampleResult(id: 'page-0-result');
      final page1 = sampleResult(id: 'page-1-result');
      final api = FakeSearchApi(
        resultsByQuery: {
          'gayatri': [page0],
        },
        hasMoreByQuery: {'gayatri': true},
      );
      final container = ProviderContainer(
        overrides: [searchApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      fakeAsync((async) {
        final notifier = container.read(searchControllerProvider.notifier);
        notifier.onQueryChanged('gayatri');
        async.elapse(const Duration(milliseconds: 400));

        // Swap in page-1 results for the *next* call, same query string —
        // the fake only keys by query, so this simulates what page 1 of a
        // real "gayatri" search would return.
        api.resultsByQuery['gayatri'] = [page1];
        api.hasMoreByQuery['gayatri'] = false;
        notifier.loadMoreForTesting();
        async.flushMicrotasks();

        expect(api.pagesReceived, [0, 1]);
        final state = container.read(searchControllerProvider);
        expect(state.results.map((r) => r.id), [
          'page-0-result',
          'page-1-result',
        ]);
        expect(state.hasMore, isFalse);
        expect(state.isLoadingMore, isFalse);
      });
    },
  );

  test('loadMore is a no-op once hasMore is false', () {
    final api = FakeSearchApi(
      resultsByQuery: {
        'gayatri': [sampleResult()],
      },
      hasMoreByQuery: {'gayatri': false},
    );
    final container = ProviderContainer(
      overrides: [searchApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    fakeAsync((async) {
      final notifier = container.read(searchControllerProvider.notifier);
      notifier.onQueryChanged('gayatri');
      async.elapse(const Duration(milliseconds: 400));

      notifier.loadMoreForTesting();
      async.flushMicrotasks();

      // Only the initial page-0 request — loadMore never called the API.
      expect(api.pagesReceived, [0]);
    });
  });

  test('a failed loadMore keeps the results already on screen', () {
    final api = FakeSearchApi(
      resultsByQuery: {
        'gayatri': [sampleResult()],
      },
      hasMoreByQuery: {'gayatri': true},
    );
    final container = ProviderContainer(
      overrides: [searchApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    fakeAsync((async) {
      final notifier = container.read(searchControllerProvider.notifier);
      notifier.onQueryChanged('gayatri');
      async.elapse(const Duration(milliseconds: 400));

      api.shouldFail = true;
      notifier.loadMoreForTesting();
      async.flushMicrotasks();

      final state = container.read(searchControllerProvider);
      expect(state.status, SearchStatus.success);
      expect(state.results, hasLength(1));
      expect(state.isLoadingMore, isFalse);
    });
  });
}
