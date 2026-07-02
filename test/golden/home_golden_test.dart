@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/ui/rescue_day_screen.dart';

import '../support/harness.dart';

/// Golden / snapshot test for the Rescue Day cold-open (the deterministic first
/// screen — no clock, no pet). Reference images live in `test/golden/goldens/`
/// and are Linux-rendered to match CI.
/// Regenerate with: flutter test --update-goldens --tags golden
void main() {
  testWidgets('Rescue Day cold-open matches golden', (tester) async {
    final controller = makeController();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RescueDayScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}
