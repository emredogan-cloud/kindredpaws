/// Grocery Store room: Kibble-only shelves, warm success + warm "not yet",
/// owned-forever goods marked yours, and the Kitchen shortcut hop.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';

void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  testWidgets('kitchen shortcut hops to the store; shelves show prices', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('room-dock-kitchen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kitchen-grocery-shortcut')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('grocery-kibble')), findsOneWidget);
    expect(find.byKey(const Key('shelf-food_apple')), findsOneWidget);
  });

  testWidgets('buying stocks the pantry; short on Kibble stays warm; owned '
      'toys read "yours"', (tester) async {
    phoneView(tester);
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('room-dock-groceryStore')));
    await tester.pumpAndSettle();

    // Starter ball is owned forever — its card reads "yours 💛", disabled.
    expect(find.text('yours 💛'), findsOneWidget);

    // No Kibble yet → warm invitation, wallet untouched, nothing added.
    final apples = c.inventory.pantryCount(ItemCatalog.apple.id);
    await tester.tap(find.byKey(const Key('shelf-food_apple')));
    await tester.pumpAndSettle();
    expect(c.pet!.wallet.kibble, 0);
    expect(c.inventory.pantryCount(ItemCatalog.apple.id), apples);
    expect(find.textContaining('care moments'), findsOneWidget);

    // Earn Kibble the real way: return after a while and meet real needs
    // (needed care pays 5 each; three needed verbs cover the apple).
    await c.onAppBackgrounded();
    now += 8 * Duration.millisecondsPerHour;
    c.onAppForegrounded();
    await c.interact(CareInteraction.feed);
    await c.interact(CareInteraction.clean);
    await c.interact(CareInteraction.play);
    await tester.pumpAndSettle();
    final kibble = c.pet!.wallet.kibble;
    expect(kibble, greaterThanOrEqualTo(ItemCatalog.apple.kibblePrice));

    await tester.tap(find.byKey(const Key('shelf-food_apple')));
    await tester.pumpAndSettle();
    expect(c.inventory.pantryCount(ItemCatalog.apple.id), apples + 1);
    expect(c.pet!.wallet.kibble, kibble - ItemCatalog.apple.kibblePrice);
  });
}
