import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadhana/app.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/persistence/prefs.dart';
import 'package:sadhana/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_analytics_service.dart';
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
            analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          ],
          child: const SadhanaApp(),
        ),
      );
      // Not pumpAndSettle: the onboarding screen's icon medallion pulses
      // continuously (see PracticeMedallion's repeat(reverse: true)), so
      // animations never settle — pump a bounded number of frames instead,
      // enough for the staggered entrance fades (last one starts at 750ms)
      // to finish.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(
        find.text('Feeling anxious?\nOverwhelmed? Tired?'),
        findsOneWidget,
      );
      expect(find.text('Meditate'), findsNothing);

      await tester.tap(find.text('Begin Your Practice'));
      // Safe to pumpAndSettle from here: the onboarding screen (and its
      // perpetually-repeating icon animation) has been unmounted in favor
      // of RootShell, so animations can actually settle now.
      await tester.pumpAndSettle();

      expect(find.text('Feeling anxious?\nOverwhelmed? Tired?'), findsNothing);
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
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
        ],
        child: const SadhanaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Feeling anxious?\nOverwhelmed? Tired?'), findsNothing);
    expect(find.text('Meditate'), findsWidgets);
  });
}
