import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sadhana/app.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/providers.dart';

import 'fakes/fake_analytics_service.dart';
import 'fakes/fake_search_api.dart';

void main() {
  testWidgets('root shell shows all four destinations and switches tabs', (
    WidgetTester tester,
  ) async {
    // Onboarding is a separate, dedicated test (see onboarding_test.dart) —
    // this test is about tab navigation, so skip straight past it.
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

    // The Progress tab watches the database as soon as it's built (all four
    // tabs are built eagerly by RootShell's IndexedStack). The real
    // AppDatabase opens a background isolate via path_provider, which has no
    // platform channel handler under `flutter test` and never resolves —
    // so, like the feature-level provider tests, swap in an in-memory one.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final analytics = FakeAnalyticsService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // The Search tab is also built eagerly — swap in a fake so this
          // smoke test never attempts a real network call.
          searchApiProvider.overrideWithValue(FakeSearchApi()),
          // RootShell fires a real, fire-and-forget HTTP call per tab
          // switch otherwise — flutter_test's strict "no pending timers"
          // check at the end of the test doesn't tolerate that.
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: const SadhanaApp(),
      ),
    );
    // AppPrefs.load() and AudioService.configure() both kick off async work
    // from initState — let it settle before asserting on rendered content.
    await tester.pumpAndSettle();

    // "Meditate" legitimately appears twice: the bottom-nav label and the
    // duration setup screen's own heading.
    expect(find.text('Meditate'), findsWidgets);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.air));
    await tester.pumpAndSettle();
    // "Breathe" also appears twice — nav label + this screen's own heading.
    expect(find.text('Breathe'), findsWidgets);

    await tester.tap(find.byIcon(Icons.insights));
    await tester.pumpAndSettle();
    // "Progress" also appears twice — nav label + this screen's own heading.
    expect(find.text('Progress'), findsWidgets);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    // "Sanskrit Prayers" is the screen's own heading — "Prayers" (the nav
    // label) is a different, shorter string, so this stays findsOneWidget.
    expect(find.text('Sanskrit Prayers'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Three switches happened (meditate->breathe->progress->prayers) —
    // each should have flushed the *previous* tab's time-in-feature.
    expect(analytics.featureTimesRecorded.map((e) => e.$1), [
      'meditate',
      'breathe',
      'progress',
    ]);
  });
}
