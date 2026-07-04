/// Cozy Corners × GameController (GE-3): set completion mints its keepsake
/// exactly once, placement persists across reopen, the wish-jar sets and
/// self-clears, and the v8→v9 upgrade is invisible.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/migration_runner.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/decor.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/keepsake/keepsake.dart';

import '../../support/harness.dart';

/// A store seeded with a rich wallet (décor windows shopping without grind).
Future<LocalSaveStore> richStore({int kibble = 1000}) async {
  final store = makeStore();
  final base = KindredSaveState.newPet(
    petId: kTestPetId,
    species: 'puppy',
    name: 'Biscuit',
    nowMs: kDay0,
  );
  final state = base.copyWith(
    pet: base.pet.copyWith(wallet: base.pet.wallet.addKibble(kibble)),
  );
  await store.write(state.toEnvelope().toJsonString());
  return store;
}

void main() {
  test(
    'completing the Starry Night set mints its keepsake exactly once',
    () async {
      final c = makeController(
        store: await richStore(),
        clock: () => kDay0 + 3600000,
      );
      await c.load();

      expect(await c.purchase(ItemCatalog.starLamp), isTrue);
      expect(await c.purchase(ItemCatalog.moonTapestry), isTrue);
      expect(
        c.keepsakes.where((k) => k.kind == KeepsakeKind.decorSet),
        isEmpty,
        reason: 'two of three pieces — not yet',
      );

      expect(await c.purchase(ItemCatalog.dreamMobile), isTrue);
      final minted = c.keepsakes
          .where((k) => k.kind == KeepsakeKind.decorSet)
          .toList();
      expect(minted.length, 1);
      expect(minted.single.caption, contains('Starry Night'));
      expect(c.lastMessage, contains('Starry Night'));

      // More décor later never re-mints the same set.
      expect(await c.purchase(ItemCatalog.duckParade), isTrue);
      expect(
        c.keepsakes.where((k) => k.kind == KeepsakeKind.decorSet).length,
        1,
      );
      c.dispose();
    },
  );

  test('placement persists across a reopen (the corner stays cozy)', () async {
    final store = await richStore();
    final first = makeController(store: store, clock: () => kDay0 + 3600000);
    await first.load();
    await first.purchase(ItemCatalog.starLamp);
    await first.placeDecor(DecorSlots.bedroomBedside, ItemCatalog.starLamp);
    expect(
      first.inventory.placedIn(DecorSlots.bedroomBedside.id),
      ItemCatalog.starLamp.id,
    );
    first.dispose();

    final second = makeController(store: store, clock: () => kDay0 + 7200000);
    await second.load();
    expect(
      second.inventory.placedIn(DecorSlots.bedroomBedside.id),
      ItemCatalog.starLamp.id,
    );
    // Back to the box: the slot empties, the piece stays owned.
    await second.clearDecor(DecorSlots.bedroomBedside);
    expect(second.inventory.placedIn(DecorSlots.bedroomBedside.id), isNull);
    expect(second.inventory.ownsDecor(ItemCatalog.starLamp.id), isTrue);
    second.dispose();
  });

  test('the wish-jar sets, and coming home clears it quietly', () async {
    final c = makeController(
      store: await richStore(kibble: 200),
      clock: () => kDay0 + 3600000,
    );
    await c.load();

    await c.setWishlist(ItemCatalog.snuggleRug);
    expect(c.inventory.wishlistId, ItemCatalog.snuggleRug.id);
    expect(c.lastMessage, contains('Snuggle Rug'));

    expect(await c.purchase(ItemCatalog.snuggleRug), isTrue);
    expect(c.inventory.wishlistId, isNull, reason: 'wish fulfilled ⇒ jar away');
    c.dispose();
  });

  test('a v8 save upgrades to v9 with empty corners (never orphaned)', () {
    final v9 = KindredSaveState.newPet(
      petId: 'p-v8',
      species: 'kitten',
      name: 'Mochi',
      nowMs: 1,
    ).toEnvelope();
    final inv =
        Map<String, dynamic>.from(
          (v9.data['inventory'] as Map).cast<String, dynamic>(),
        )..removeWhere(
          (k, _) => k == 'decor' || k == 'placements' || k == 'wishlistId',
        );
    final v8 = SaveEnvelope(
      schemaVersion: 8,
      data: Map<String, dynamic>.from(v9.data)..['inventory'] = inv,
    );

    final runner = MigrationRunner(KindredSaveState.migrations);
    final up = runner.upgrade(v8, KindredSaveState.currentSchemaVersion);
    expect(up.schemaVersion, KindredSaveState.currentSchemaVersion);
    // The v8→v9 step is what this test proves: décor fields materialize.
    expect(up.data['inventory'], isA<Map<String, dynamic>>());
    final state = KindredSaveState.fromEnvelope(up);
    expect(state.pet.name, 'Mochi');
    expect(state.inventory.decor, isEmpty);
    expect(state.inventory.placements, isEmpty);
    expect(state.inventory.wishlistId, isNull);
  });
}
