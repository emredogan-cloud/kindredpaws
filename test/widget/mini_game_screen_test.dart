/// The mini-game stage: launch from the Play Garden, play a moment, and both
/// endings (timer celebration / friendly early leave) wrap up warmly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/minigames/mini_game_screen.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('the garden offers both games and launches Bounce!', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'playRoom');
    expect(find.byKey(const Key('minigame-catch')), findsOneWidget);
    await tester.tap(find.byKey(const Key('minigame-bounce')));
    // The game ticker runs continuously — pump frames, never settle here.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('minigame-screen')), findsOneWidget);

    // Leave the friendly way; the wrap-up pops back to the garden.
    await tester.tap(find.byKey(const Key('minigame-leave')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('minigame-screen')), findsNothing);
  });

  testWidgets('a short session plays, celebrates, and pays the capped bonus', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(
      MaterialApp(
        home: MiniGameScreen(
          controller: c,
          kind: MiniGameKind.bounce,
          sessionSeconds: 1.5, // a tiny session keeps the test fast
        ),
      ),
    );
    await tester.pump();

    // Boop a few times while the ticker runs real frames.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('bounce-tap')));
      await tester.pump(const Duration(milliseconds: 200));
    }
    // Let the 1.5s timer finish and the celebration settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('minigame-final-score')), findsOneWidget);
    expect(c.pet!.wallet.kibble, greaterThan(0)); // verb + bonus landed
    expect(c.pet!.meters.energy, lessThan(100)); // it was REAL play

    await tester.tap(find.byKey(const Key('minigame-done')));
    await tester.pumpAndSettle();
  });

  testWidgets('leaving early is friendly: the wrap-up still counts', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    await tester.pumpWidget(
      MaterialApp(
        home: MiniGameScreen(
          controller: c,
          kind: MiniGameKind.snackCatch,
          sessionSeconds: 45,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('minigame-leave')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('minigame-screen')), findsNothing); // popped
    expect(c.pet!.meters.energy, lessThan(100)); // the play verb applied
  });
}
