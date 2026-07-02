/// Cozy Corners UI (GE-3): placed décor shows in the scene, the decorate
/// sheet places in two taps, and the grocery wish-jar fills and clears.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/decor.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/ui/rooms/room_host.dart';

import '../support/harness.dart';

void phoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<LocalSaveStore> storeOwning(
  List<ItemDef> items, {
  int kibble = 0,
}) async {
  final store = makeStore();
  final base = KindredSaveState.newPet(
    petId: kTestPetId,
    species: 'puppy',
    name: 'Biscuit',
    nowMs: kDay0,
  );
  var inv = base.inventory;
  for (final item in items) {
    inv = inv.add(item);
  }
  final state = base.copyWith(
    pet: base.pet.copyWith(wallet: base.pet.wallet.addKibble(kibble)),
    inventory: inv,
  );
  await store.write(state.toEnvelope().toJsonString());
  return store;
}

void main() {
  testWidgets('two taps decorate the bedroom and the piece appears in scene', (
    tester,
  ) async {
    phoneView(tester);
    final store = await storeOwning([ItemCatalog.starLamp]);
    final c = makeController(store: store, clock: () => kDay0 + 3600000);
    await c.load();
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('room-dock-bedroom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('decorate-button-bedroom')), findsOneWidget);
    expect(
      find.byKey(const Key('decor-placed-slot_bedroom_bedside')),
      findsNothing,
    );

    // Tap 1: open the sheet. Tap 2: choose the piece.
    await tester.tap(find.byKey(const Key('decorate-button-bedroom')));
    await tester.pumpAndSettle();
    expect(find.text('On the bedside table'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const Key('decor-choice-slot_bedroom_bedside-decor_star_lamp'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      c.inventory.placedIn(DecorSlots.bedroomBedside.id),
      ItemCatalog.starLamp.id,
    );

    // Close the sheet — the star lamp now lives in the scene.
    await tester.tapAt(const Offset(200, 80));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('decor-placed-slot_bedroom_bedside')),
      findsOneWidget,
    );
  });

  testWidgets('long-pressing a décor piece sets the wish-jar; it fills and '
      'clears', (tester) async {
    // A tall viewport renders the whole shelf (no lazy-build/scroll dance
    // against the live room PageView).
    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final store = await storeOwning(const [], kibble: 20);
    final c = makeController(store: store, clock: () => kDay0 + 3600000);
    await c.load();
    await tester.pumpWidget(MaterialApp(home: RoomHost(controller: c)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('room-dock-groceryStore')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wish-jar')), findsNothing);

    // Long-press the duck parade (40 Kibble) → the jar appears, half full.
    await tester.longPress(find.byKey(const Key('shelf-decor_duck_parade')));
    await tester.pumpAndSettle();
    expect(c.inventory.wishlistId, ItemCatalog.duckParade.id);

    expect(find.byKey(const Key('wish-jar')), findsOneWidget);
    expect(find.textContaining('20/40'), findsOneWidget);

    // Letting the wish go clears the jar (nothing lost, nothing said twice).
    await tester.tap(find.byKey(const Key('wish-jar-clear')));
    await tester.pumpAndSettle();
    expect(c.inventory.wishlistId, isNull);
    expect(find.byKey(const Key('wish-jar')), findsNothing);
  });
}
