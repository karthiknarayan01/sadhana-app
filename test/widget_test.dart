import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sadhana/app.dart';

void main() {
  testWidgets('root shell shows all four destinations and switches tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SadhanaApp()));

    expect(find.text('Meditation timer — coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.air));
    await tester.pumpAndSettle();
    expect(find.text('Breathing practices — coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights));
    await tester.pumpAndSettle();
    expect(find.text('Your progress — coming soon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    expect(find.text('Shloka search — coming soon'), findsOneWidget);
  });
}
