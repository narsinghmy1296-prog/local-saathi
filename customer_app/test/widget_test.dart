// Basic smoke test — confirms the app boots and renders without crashing.
//
// FIX: `flutter create .` generates this file with a placeholder reference
// to a `MyApp` class, which doesn't exist in this project (our root widget
// is `LocalSaathiApp`, defined in lib/main.dart). Updated to match.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_saathi_customer/main.dart';

void main() {
  testWidgets('App builds and shows the splash screen without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalSaathiApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
