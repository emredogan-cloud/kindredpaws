/// GE-2 autonomous micro-behaviors: the driver stirs an idle pet only when
/// ambient motion is on, respects sleep, and always cleans up its timer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/widgets/ambient_life_driver.dart';
import 'package:kindredpaws/game/ui/widgets/ambient_scene.dart';

import '../support/harness.dart';

void main() {
  testWidgets('with motion off (tests/CI) the driver arms nothing', (
    tester,
  ) async {
    expect(AmbientScene.motionEnabled, isFalse);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(
      MaterialApp(home: AmbientLifeDriver(controller: c)),
    );
    // No timers pending — the test framework itself enforces this at exit.
    await tester.pumpAndSettle();
    c.dispose();
  });

  testWidgets('with motion on, an idle pet stirs after the idle beat', (
    tester,
  ) async {
    AmbientScene.motionEnabled = true;
    addTearDown(() => AmbientScene.motionEnabled = false);

    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    expect(c.ambientEmotion, isNull);

    await tester.pumpWidget(
      MaterialApp(home: AmbientLifeDriver(controller: c)),
    );
    await tester.pump(AmbientLifeDriver.idleBeat + const Duration(seconds: 1));
    expect(c.ambientEmotion, isNotNull, reason: 'the pet stirred on its own');

    // Unmount cancels the chain (no pending-timer failure at test end).
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('a sleeping pet is never disturbed', (tester) async {
    AmbientScene.motionEnabled = true;
    addTearDown(() => AmbientScene.motionEnabled = false);

    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await c.tuckIn();

    await tester.pumpWidget(
      MaterialApp(home: AmbientLifeDriver(controller: c)),
    );
    final before = c.ambientEmotion;
    await tester.pump(AmbientLifeDriver.idleBeat + const Duration(seconds: 1));
    expect(c.ambientEmotion, before, reason: 'sleep stays serene');

    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
