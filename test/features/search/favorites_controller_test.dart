import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/core/persistence/prefs.dart';
import 'package:sadhana/core/providers.dart';
import 'package:sadhana/features/search/application/favorites_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [prefsProvider.overrideWith((ref) => AppPrefs.load())],
    );
  });

  tearDown(() => container.dispose());

  test('toggling favorites persists across a fresh AppPrefs load', () async {
    await container.read(prefsProvider.future);
    await container
        .read(favoritesControllerProvider.notifier)
        .toggle('gayatri-mantra');

    expect(
      container.read(favoritesControllerProvider),
      contains('gayatri-mantra'),
    );

    final reloaded = await AppPrefs.load();
    expect(reloaded.favoriteShlokaIds, contains('gayatri-mantra'));
  });

  test('toggling twice removes the favorite', () async {
    await container.read(prefsProvider.future);
    final controller = container.read(favoritesControllerProvider.notifier);

    await controller.toggle('gayatri-mantra');
    await controller.toggle('gayatri-mantra');

    expect(container.read(favoritesControllerProvider), isEmpty);
  });
}
