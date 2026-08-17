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
}
