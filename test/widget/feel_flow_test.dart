/// Feel & Flow UI (GE-6): first-visit hints pulse once then retire, the
/// camera gently pushes in on a care beat, and both respect reduced-motion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';
import 'package:kindredpaws/game/ui/rooms/room_scaffold.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('the kitchen shows its first-visit hint once, then never again', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'kitchen');
    final hint = find.byKey(const Key('hint-hint_kitchen'));
    expect(hint, findsOneWidget);
    expect(c.shouldShowHint('hint_kitchen'), isTrue);

    // Tapping the hint sends it on its way and marks it seen forever.
    await tester.tap(hint);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hint-hint_kitchen')), findsNothing);
    expect(c.shouldShowHint('hint_kitchen'), isFalse);

    // Leaving and returning never shows it again.
    await hopToRoom(tester, 'home');
    await hopToRoom(tester, 'kitchen');
    expect(find.byKey(const Key('hint-hint_kitchen')), findsNothing);
  });

  testWidgets('a care beat pushes the pet in, then it settles back', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'kitchen');
    // Dismiss the hint so it doesn't cover the shelf.
    await tester.tap(find.byKey(const Key('hint-hint_kitchen')));
    await tester.pumpAndSettle();

    // Feed from the pantry — a care beat.
    await tester.tap(find.byKey(const Key('pantry-food_kibble_bowl')));
    await tester.pump(); // beat detected → push-in this frame
    AnimatedScale petScale() => tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PetStage),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(petScale().scale, greaterThan(1.0)); // pushed in
    // The push-in must DWELL, not blink: still pushed in a couple of frames
    // later (guards the reviewed no-op where a post-frame reset killed it).
    await tester.pump(const Duration(milliseconds: 120));
    expect(petScale().scale, greaterThan(1.0));
    await tester.pumpAndSettle(); // then settles back to rest
    expect(petScale().scale, 1.0);
  });

  testWidgets('reduced motion keeps the pet perfectly still on a care beat', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RoomHost(controller: c),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await hopToRoom(tester, 'kitchen');
    await tester.tap(find.byKey(const Key('pantry-food_kibble_bowl')));
    await tester.pump();
    final scaleWidget = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PetStage),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scaleWidget.scale, 1.0, reason: 'reduced motion ⇒ no push-in');
  });
}
