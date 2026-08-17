import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/app.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/persistence/prefs.dart';
import 'package:sadhana/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_search_api.dart';

void main() {
  testWidgets(
    'a fresh install sees onboarding first, then Begin reveals the app',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            searchApiProvider.overrideWithValue(FakeSearchApi()),
          ],
          child: const SadhanaApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Sadhana'), findsOneWidget);
      expect(find.text('Meditate'), findsNothing);

      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Sadhana'), findsNothing);
      expect(find.text('Meditate'), findsWidgets);

      final prefs = await AppPrefs.load();
      expect(prefs.hasSeenOnboarding, isTrue);
    },
  );

  testWidgets('a returning user skips onboarding entirely', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          searchApiProvider.overrideWithValue(FakeSearchApi()),
        ],
        child: const SadhanaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Sadhana'), findsNothing);
    expect(find.text('Meditate'), findsWidgets);
  });
}
