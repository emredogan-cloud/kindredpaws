/// Seasons of Us UI (GE-5): the hemisphere toggle lives in Settings, every
/// season's accent layer renders statically in tests (never blocking
/// settle), and rooms dress for the controller's season.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/season_engine.dart';
import 'package:kindredpaws/game/ui/settings_screen.dart';
import 'package:kindredpaws/game/ui/widgets/ambient_scene.dart';
import 'package:kindredpaws/services/prefs_service.dart';

import '../support/harness.dart';

void main() {
  testWidgets('every season accent renders still and settles in tests', (
    tester,
  ) async {
    expect(AmbientScene.motionEnabled, isFalse);
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            SeasonAccentScene(season: NatureSeason.spring),
            SeasonAccentScene(season: NatureSeason.summer),
            SeasonAccentScene(season: NatureSeason.autumn),
            SeasonAccentScene(season: NatureSeason.winter),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SeasonAccentScene), findsNWidgets(4));
  });

  testWidgets('the Settings toggle flips the hemisphere preference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: c)));
    await tester.pumpAndSettle();

    final prefs = ServiceLocator.instance.get<PrefsService>();
    expect(prefs.southernHemisphere, isFalse);
    expect(c.season, NatureSeason.autumn); // kDay0 = October, northern

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-southern')),
      200,
    );
    await tester.tap(find.byKey(const Key('settings-southern')));
    await tester.pumpAndSettle();

    expect(prefs.southernHemisphere, isTrue);
    expect(c.season, NatureSeason.spring, reason: 'October, southern');
    c.dispose();
  });
}
