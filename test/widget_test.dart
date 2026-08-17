import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadhana/app.dart';
import 'package:sadhana/core/persistence/database.dart';
import 'package:sadhana/core/providers.dart';

void main() {
  testWidgets('root shell shows all four destinations and switches tabs', (
    WidgetTester tester,
  ) async {
    // The Progress tab watches the database as soon as it's built (all four
    // tabs are built eagerly by RootShell's IndexedStack). The real
    // AppDatabase opens a background isolate via path_provider, which has no
    // platform channel handler under `flutter test` and never resolves —
    // so, like the feature-level provider tests, swap in an in-memory one.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
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
    expect(find.text('Shloka search — coming soon'), findsOneWidget);
  });
}
