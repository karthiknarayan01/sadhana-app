import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Favorited shloka IDs, persisted via AppPrefs (a plain string set — no
/// need for a drift table, this is never queried/joined, just toggled and
/// checked for membership).
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefsAsync = ref.watch(prefsProvider);
    return prefsAsync.valueOrNull?.favoriteShlokaIds ?? {};
  }

  Future<void> toggle(String shlokaId) async {
    final prefs = await ref.read(prefsProvider.future);
    final updated = {...state};
    if (!updated.remove(shlokaId)) {
      updated.add(shlokaId);
    }
    state = updated;
    await prefs.setFavoriteShlokaIds(updated);
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);
