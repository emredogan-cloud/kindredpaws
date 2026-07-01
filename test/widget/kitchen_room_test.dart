/// Kitchen room + room-dock navigation: the pantry feeds through the real
/// verb, empty shelves invite the Grocery Store, and the dock hops rooms with
/// the SAME controller state everywhere (no reset on navigation).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';

/// A realistic phone-portrait surface so room layouts match the shipped
/// experience (the default 800×600 test view squeezes portrait rooms).
void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  testWidgets('the room dock appears and hops Home ↔ Kitchen instantly', (
    tester,
  ) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    // Starts at Home (the hearth), dock visible with both rooms.
    expect(find.byKey(const Key('room-dock')), findsOneWidget);
    expect(find.byKey(const Key('feed-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('room-dock-kitchen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pantry-food_kibble_bowl')), findsOneWidget);

    await tester.tap(find.byKey(const Key('room-dock-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feed-button')), findsOneWidget);
  });

  testWidgets('feeding from the pantry consumes stock and keeps state across '
      'rooms (simulation never resets)', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('room-dock-kitchen')));
    await tester.pumpAndSettle();

    final kibbleBefore = c.pet!.wallet.kibble;
    await tester.tap(find.byKey(const Key('pantry-food_kibble_bowl')));
    await tester.pumpAndSettle();

    // Pantry ×2 → ×1, Kibble earned, warm feedback shown in-room.
    expect(c.inventory.pantryCount(ItemCatalog.kibbleBowl.id), 1);
    expect(c.pet!.wallet.kibble, greaterThan(kibbleBefore));
    expect(find.byKey(const Key('room-feedback')), findsOneWidget);

    // Walk home — the same pet, the same wallet, nothing reset.
    await tester.tap(find.byKey(const Key('room-dock-home')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kibble-count')), findsOneWidget);
    expect(c.inventory.pantryCount(ItemCatalog.kibbleBowl.id), 1);
  });

  testWidgets('the grocery shortcut is offered from the kitchen', (
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
    // The Grocery Store page isn't open yet, but the invitation is there
    // (tapping is a safe no-op until the room ships).
    expect(find.byKey(const Key('kitchen-grocery-shortcut')), findsOneWidget);
  });
}
