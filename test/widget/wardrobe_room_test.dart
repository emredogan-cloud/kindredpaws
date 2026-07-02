/// Wardrobe: buy a common look with Kibble, wear it (rendered on the pet in
/// EVERY room via DressedPet), swap within a slot, and meet premium keepsakes
/// as an invitation (paywall), never a Kibble sale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';
import '../support/room_test_utils.dart';

void main() {
  testWidgets('drawer opens the Wardrobe; premium card shows the Forever '
      'Friends invitation', (tester) async {
    phoneView(tester);
    final c = makeController();
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    // Via the side navigation (the bible's wardrobe entry, no longer "soon").
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawer-wardrobe')));
    await tester.pumpAndSettle();

    expect(find.text('Boutique'), findsOneWidget);
    expect(find.text('Forever Friends'), findsWidgets); // premium invitation
  });

  testWidgets('earn → buy → wear → the look follows the pet to other rooms', (
    tester,
  ) async {
    phoneView(tester);
    var now = kDay0;
    final c = makeController(clock: () => now);
    await c.load();
    await c.adopt(species: Species.puppy, name: 'Biscuit');

    // Earn enough Kibble for the Heart Bandana (260) with a week of real
    // care: needed verbs after decay windows.
    for (var day = 0; day < 20; day++) {
      await c.onAppBackgrounded();
      now += 12 * Duration.millisecondsPerHour;
      c.onAppForegrounded();
      await c.interact(CareInteraction.feed);
      await c.interact(CareInteraction.clean);
      await c.interact(CareInteraction.play);
    }
    expect(
      c.pet!.wallet.kibble,
      greaterThanOrEqualTo(ItemCatalog.heartBandana.kibblePrice),
    );

    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();
    await hopToRoom(tester, 'wardrobe');

    // Buy the bandana from the boutique (scroll the closet rail to it)…
    final bandanaCard = find.byKey(const Key('boutique-wear_heart_bandana'));
    for (var i = 0; i < 8 && bandanaCard.evaluate().isEmpty; i++) {
      await tester.drag(
        find.byKey(const Key('wardrobe-list')),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(bandanaCard);
    await tester.pumpAndSettle();
    await tester.tap(bandanaCard);
    await tester.pumpAndSettle();
    expect(c.inventory.ownsCosmetic(ItemCatalog.heartBandana.id), isTrue);

    // …wear it from the closet…
    await tester.tap(find.byKey(const Key('closet-wear_heart_bandana')));
    await tester.pumpAndSettle();
    expect(c.inventory.isEquipped(ItemCatalog.heartBandana.id), isTrue);
    expect(find.byKey(const Key('worn-wear_heart_bandana')), findsOneWidget);

    // …and it follows the pet into the Kitchen (same dressed friend).
    await hopToRoom(tester, 'kitchen');
    expect(find.byKey(const Key('worn-wear_heart_bandana')), findsOneWidget);
  });
}
