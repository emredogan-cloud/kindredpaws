/// Cozy Corners model (GE-3): slots, catalog integrity, sets, inventory
/// placement rules, wishlist semantics, and the purchase path.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/decor.dart';
import 'package:kindredpaws/game/model/inventory.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/rooms/room_id.dart';
import 'package:kindredpaws/game/sim/shopping.dart';

void main() {
  group('slots', () {
    test('12 launch slots, unique ids, the roadmap room split', () {
      expect(DecorSlots.all.length, 12);
      expect(DecorSlots.all.map((s) => s.id).toSet().length, 12);
      int inRoom(RoomId r) => DecorSlots.forRoom(r).length;
      expect(inRoom(RoomId.home), 3);
      expect(inRoom(RoomId.bedroom), 3);
      expect(inRoom(RoomId.playRoom), 3);
      expect(inRoom(RoomId.kitchen), 2);
      expect(inRoom(RoomId.bathroom), 1);
    });

    test('a retired slot id is inert, never an error', () {
      expect(DecorSlots.byId('slot_gone_forever'), isNull);
    });
  });

  group('catalog', () {
    final decorItems = ItemCatalog.ofKind(ItemKind.decor);

    test('14 pieces, every one pointing at a real slot, canon price band', () {
      expect(decorItems.length, 14);
      for (final item in decorItems) {
        expect(item.decorSlotId, isNotNull, reason: item.id);
        expect(DecorSlots.byId(item.decorSlotId!), isNotNull, reason: item.id);
        expect(item.kibblePrice, inInclusiveRange(40, 260), reason: item.id);
        expect(item.purchasable, isTrue, reason: item.id);
      }
    });

    test('every slot has at least one piece to find', () {
      final coveredSlots = decorItems.map((i) => i.decorSlotId).toSet();
      for (final slot in DecorSlots.all) {
        expect(coveredSlots, contains(slot.id), reason: slot.id);
      }
    });

    test('sets reference real catalog pieces and complete on ownership', () {
      for (final set in DecorSets.all) {
        for (final id in set.itemIds) {
          expect(ItemCatalog.byId(id)?.kind, ItemKind.decor, reason: set.id);
        }
        expect(set.completedBy(const {}), isFalse);
        expect(set.completedBy(set.itemIds), isTrue);
        expect(
          set.completedBy({set.itemIds.first}),
          isFalse,
          reason: 'a partial set never completes',
        );
      }
      expect(
        DecorSets.containing('decor_star_lamp').single.id,
        DecorSets.starryNight.id,
      );
      expect(DecorSets.containing('decor_duck_parade'), isEmpty);
    });
  });

  group('inventory placement', () {
    const inv = Inventory(decor: {'decor_star_lamp'});

    test('placing an owned piece fills the slot; unowned is a no-op', () {
      final placed = inv.place('slot_bedroom_bedside', 'decor_star_lamp');
      expect(placed.placedIn('slot_bedroom_bedside'), 'decor_star_lamp');
      final noop = inv.place('slot_bedroom_bedside', 'decor_moon_tapestry');
      expect(noop, inv, reason: 'not owned ⇒ nothing changes');
    });

    test('a new piece replaces; clearing keeps ownership', () {
      final both = inv.add(ItemCatalog.cloudNightlight);
      final a = both.place('slot_bedroom_bedside', 'decor_star_lamp');
      final b = a.place('slot_bedroom_bedside', 'decor_cloud_nightlight');
      expect(b.placedIn('slot_bedroom_bedside'), 'decor_cloud_nightlight');
      final cleared = b.clearSlot('slot_bedroom_bedside');
      expect(cleared.placedIn('slot_bedroom_bedside'), isNull);
      expect(cleared.ownsDecor('decor_cloud_nightlight'), isTrue);
      expect(cleared.ownsDecor('decor_star_lamp'), isTrue);
    });

    test('wishlist sets, survives copyWith, and clears explicitly', () {
      final wished = inv.copyWith(wishlistId: 'decor_snuggle_rug');
      expect(wished.wishlistId, 'decor_snuggle_rug');
      expect(wished.copyWith(pantry: const {}).wishlistId, 'decor_snuggle_rug');
      expect(wished.copyWith(clearWishlist: true).wishlistId, isNull);
    });

    test('décor + placements + wishlist round-trip the save map', () {
      final full = inv
          .add(ItemCatalog.moonTapestry)
          .place('slot_bedroom_wall', 'decor_moon_tapestry')
          .copyWith(wishlistId: 'decor_bee_house');
      expect(Inventory.fromMap(full.toMap().cast<String, dynamic>()), full);
    });
  });

  test('décor purchase: buy once, forever yours, never re-sold', () {
    final pet = PetState.newlyRescued(
      petId: 'p1',
      species: Species.puppy,
      name: 'Biscuit',
      nowMs: 0,
    );
    final rich = pet.copyWith(wallet: pet.wallet.addKibble(500));
    final first = tryPurchase(
      state: rich,
      inventory: const Inventory(),
      item: ItemCatalog.duckParade,
    );
    expect(first.success, isTrue);
    expect(first.inventory!.ownsDecor('decor_duck_parade'), isTrue);
    expect(
      first.state!.wallet.kibble,
      500 - ItemCatalog.duckParade.kibblePrice,
    );
    final again = tryPurchase(
      state: first.state!,
      inventory: first.inventory!,
      item: ItemCatalog.duckParade,
    );
    expect(again.block, PurchaseBlock.alreadyOwned);
  });
}
