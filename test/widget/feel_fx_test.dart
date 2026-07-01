/// The joy layer: bursts pop once per care outcome, celebrations fire exactly
/// once per milestone, controller cues route through the gated Feel service —
/// and everything settles (one-shot animations only).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';
import 'package:kindredpaws/game/ui/widgets/feel_fx.dart';
import 'package:kindredpaws/services/feel_service.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('a care verb pops one burst and plays one gated cue', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    final feel = ServiceLocator.instance.get<FeelService>();
    final cuesBefore = feel.playedCount;

    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pump(const Duration(milliseconds: 120)); // burst mid-flight
    expect(find.byType(ParticleBurst), findsOneWidget);
    await tester.pumpAndSettle(); // one-shot → settles
    expect(feel.playedCount, greaterThan(cuesBefore));
  });

  testWidgets('sound toggle silences controller cues', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    final feel = ServiceLocator.instance.get<FeelService>();
    await feel.prefs.setSoundEnabled(false);
    final before = feel.playedCount;

    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('play-button')));
    await tester.pumpAndSettle();

    expect(feel.playedCount, before); // gated silent
  });

  testWidgets('a bond-stage milestone celebrates exactly once', (tester) async {
    phoneView(tester);
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    // Grind warm days until the Bond crosses into Friend (threshold 250).
    var guard = 0;
    while (c.pet!.bond.stage.rank < 1 && guard < 80) {
      await c.onAppBackgrounded();
      now += 12 * Duration.millisecondsPerHour;
      c.onAppForegrounded();
      await c.interact(CareInteraction.feed);
      await c.interact(CareInteraction.clean);
      await c.interact(CareInteraction.play);
      await c.comfortPet();
      guard++;
    }
    expect(c.pet!.bond.stage.rank, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('celebration-banner')), findsOneWidget);
    expect(find.textContaining('Friend'), findsWidgets);
    await tester.pumpAndSettle(); // celebration is one-shot
    expect(find.byKey(const Key('celebration-banner')), findsNothing);
  });
}
