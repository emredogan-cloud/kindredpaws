@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/settings_screen.dart';

import '../support/harness.dart';

/// Pins the Product Evolution surfaces: Settings (toggles + privacy) and the
/// Our-story Profile (facts + Milestone Book). Linux-rendered to match CI.
/// Regenerate: `just goldens-update`.
void main() {
  Future<void> pumpAt(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(400, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(debugShowCheckedModeBanner: false, home: home),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Settings matches golden', (tester) async {
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await pumpAt(tester, SettingsScreen(controller: c));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/settings.png'),
    );
  });

  testWidgets('Profile (Our story) matches golden', (tester) async {
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await pumpAt(tester, ProfileScreen(controller: c));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile.png'),
    );
  });
}
