/// The Immersive Pet Experience economy foundation: item catalog integrity,
/// inventory semantics, Kibble-only purchasing, item-aware care verbs, gentle
/// supplies/comfort, and the sleep cycle — all deterministic and floor-safe.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/model/inventory.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/model/wallet.dart';
import 'package:kindredpaws/game/sim/bond_engine.dart';
import 'package:kindredpaws/game/sim/game_simulation.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/sim/shopping.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

const _hour = Duration.millisecondsPerHour;
const _day = Duration.millisecondsPerDay;
const _day0 = 20000 * _day;

PetState _adopt({int kibble = 0}) => PetState.newlyRescued(
  petId: 'p1',
  species: Species.puppy,
  name: 'Biscuit',
  nowMs: _day0,
).copyWith(wallet: Wallet(kibble: kibble));

void main() {
  final sim = GameSimulation(const SimConfig());

  group('ItemCatalog', () {
    test('ids are unique and resolvable', () {
      final ids = ItemCatalog.all.map((i) => i.id).toSet();
      expect(ids.length, ItemCatalog.all.length);
      for (final item in ItemCatalog.all) {
        expect(ItemCatalog.byId(item.id), same(item));
      }
      expect(ItemCatalog.byId('nope'), isNull);
    });

    test('prices stay in the canonical Kibble bands (§8.1)', () {
      for (final f in ItemCatalog.ofKind(ItemKind.food)) {
        expect(f.kibblePrice, inInclusiveRange(10, 30), reason: f.id);
      }
      for (final t in ItemCatalog.ofKind(ItemKind.toy)) {
        expect(t.kibblePrice, inInclusiveRange(60, 220), reason: t.id);
      }
      for (final c in ItemCatalog.ofKind(ItemKind.cosmetic)) {
        if (c.premium) continue;
        expect(c.kibblePrice, inInclusiveRange(200, 800), reason: c.id);
      }
    });

    test('premium cosmetics are never Kibble-purchasable (ethical wall)', () {
      for (final item in ItemCatalog.all.where((i) => i.premium)) {
        expect(item.purchasable, isFalse, reason: item.id);
        expect(item.kind, ItemKind.cosmetic, reason: item.id);
      }
    });

    test('the grocery shelf sells consumables + toys, never cosmetics', () {
      final shelf = ItemCatalog.groceryShelf();
      expect(shelf, isNotEmpty);
      for (final item in shelf) {
        expect(item.kind, isNot(ItemKind.cosmetic), reason: item.id);
        expect(item.purchasable, isTrue, reason: item.id);
      }
    });
  });

  group('Inventory', () {
    test('starter kit: no room greets the player empty', () {
      final inv = Inventory.starter();
      expect(inv.pantryCount(ItemCatalog.kibbleBowl.id), 2);
      expect(inv.pantryCount(ItemCatalog.apple.id), 1);
      expect(inv.ownsToy(ItemCatalog.bouncyBall.id), isTrue);
      expect(inv.supplyCount(ItemCatalog.vitaminChew.id), 1);
    });

    test('add stacks consumables and marks toys/cosmetics owned once', () {
      var inv = const Inventory();
      inv = inv.add(ItemCatalog.apple, count: 2);
      inv = inv.add(ItemCatalog.apple);
      expect(inv.pantryCount(ItemCatalog.apple.id), 3);
      inv = inv.add(ItemCatalog.bouncyBall).add(ItemCatalog.bouncyBall);
      expect(inv.toys.length, 1);
      inv = inv.add(ItemCatalog.bobbleHat);
      expect(inv.ownsCosmetic(ItemCatalog.bobbleHat.id), isTrue);
    });

    test(
      'consume decrements to empty, then returns null (warm out-of-stock)',
      () {
        final inv = const Inventory().add(ItemCatalog.apple);
        final once = inv.consume(ItemCatalog.apple);
        expect(once, isNotNull);
        expect(once!.pantryCount(ItemCatalog.apple.id), 0);
        expect(once.consume(ItemCatalog.apple), isNull);
      },
    );

    test(
      'equip fills the slot and swaps within it; unequip keeps ownership',
      () {
        var inv = const Inventory()
            .add(ItemCatalog.bobbleHat)
            .add(ItemCatalog.flowerCrown)
            .add(ItemCatalog.bellCollar);
        inv = inv.equip(ItemCatalog.bobbleHat);
        inv = inv.equip(ItemCatalog.bellCollar);
        expect(inv.isEquipped(ItemCatalog.bobbleHat.id), isTrue);
        expect(inv.isEquipped(ItemCatalog.bellCollar.id), isTrue);
        // Same-slot swap: crown replaces hat, collar untouched.
        inv = inv.equip(ItemCatalog.flowerCrown);
        expect(inv.isEquipped(ItemCatalog.flowerCrown.id), isTrue);
        expect(inv.isEquipped(ItemCatalog.bobbleHat.id), isFalse);
        expect(inv.isEquipped(ItemCatalog.bellCollar.id), isTrue);
        expect(inv.equippedIn(CosmeticSlot.hat), ItemCatalog.flowerCrown.id);
        inv = inv.unequip(ItemCatalog.flowerCrown.id);
        expect(inv.equippedIn(CosmeticSlot.hat), isNull);
        expect(inv.ownsCosmetic(ItemCatalog.flowerCrown.id), isTrue);
      },
    );

    test('equip refuses unowned cosmetics (defense in depth)', () {
      const inv = Inventory();
      expect(inv.equip(ItemCatalog.bobbleHat), inv);
    });

    test('serialization round-trips, unknown ids stay inert (R4)', () {
      final inv = Inventory.starter()
          .add(ItemCatalog.bobbleHat)
          .equip(ItemCatalog.bobbleHat)
          .bumpAffinity(ItemCatalog.bouncyBall.id);
      final back = Inventory.fromMap(
        (inv.toMap()
              ..['pantry'] = {
                ...inv.pantry,
                'food_discontinued': 3, // a future/removed catalog id
              })
            .cast<String, dynamic>(),
      );
      expect(back.pantryCount(ItemCatalog.kibbleBowl.id), 2);
      expect(back.pantryCount('food_discontinued'), 3); // preserved, inert
      expect(back.isEquipped(ItemCatalog.bobbleHat.id), isTrue);
      expect(back.affinity(ItemCatalog.bouncyBall.id), 1);
    });
  });

  group('tryPurchase (Kibble only — no real money path exists)', () {
    test('success debits Kibble and stocks the inventory', () {
      final out = tryPurchase(
        state: _adopt(kibble: 50),
        inventory: const Inventory(),
        item: ItemCatalog.apple,
      );
      expect(out.success, isTrue);
      expect(out.state!.wallet.kibble, 50 - ItemCatalog.apple.kibblePrice);
      expect(out.inventory!.pantryCount(ItemCatalog.apple.id), 1);
    });

    test('not enough Kibble blocks warmly (never negative balance)', () {
      final out = tryPurchase(
        state: _adopt(kibble: 5),
        inventory: const Inventory(),
        item: ItemCatalog.apple,
      );
      expect(out.success, isFalse);
      expect(out.block, PurchaseBlock.kibble);
    });

    test('toys and cosmetics are forever — no double purchase', () {
      final owned = const Inventory().add(ItemCatalog.bouncyBall);
      final out = tryPurchase(
        state: _adopt(kibble: 999),
        inventory: owned,
        item: ItemCatalog.bouncyBall,
      );
      expect(out.block, PurchaseBlock.alreadyOwned);
    });

    test('premium cosmetics are not sold for Kibble', () {
      final out = tryPurchase(
        state: _adopt(kibble: 99999),
        inventory: const Inventory(),
        item: ItemCatalog.sunbeamBandana,
      );
      expect(out.block, PurchaseBlock.notSoldHere);
    });
  });

  group('item-aware care verbs', () {
    test('feeding a specific food uses its satiety + joy profile', () {
      final hungry = _adopt().copyWith(
        meters: const CareMeters(
          hunger: 40,
          energy: 90,
          hygiene: 90,
          happiness: 60,
        ),
      );
      final out = sim.interact(
        state: hungry,
        interaction: CareInteraction.feed,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
        item: ItemCatalog.chickenBites,
      );
      expect(out.state.meters.hunger, 40 + ItemCatalog.chickenBites.satiety);
      expect(out.state.meters.happiness, 60 + ItemCatalog.chickenBites.joy);
      expect(out.wasNeeded, isTrue);
      expect(out.streakIncremented, isTrue); // still a real care verb
    });

    test('playing with a toy applies its energy cost + affection warmth', () {
      final rested = _adopt().copyWith(
        meters: const CareMeters(
          hunger: 90,
          energy: 80,
          hygiene: 90,
          happiness: 50,
        ),
      );
      final fresh = sim.interact(
        state: rested,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
        item: ItemCatalog.plushStar,
      );
      // plushStar: joy 40, energy -6.
      expect(fresh.state.meters.energy, 80 - 6);
      expect(fresh.state.meters.happiness, 50 + 40);

      final wellLoved = sim.interact(
        state: rested,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
        item: ItemCatalog.plushStar,
        toyAffinity: 100, // affection warmth caps at +6 joy
      );
      expect(wellLoved.state.meters.happiness, 50 + 40 + 6);
    });

    test('toy affection never touches Bond (no pay-to-win)', () {
      final base = _adopt();
      final plain = sim.interact(
        state: base,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
        item: ItemCatalog.plushStar,
      );
      final loved = sim.interact(
        state: base,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
        item: ItemCatalog.plushStar,
        toyAffinity: 100,
      );
      expect(loved.bondAwarded, plain.bondAwarded);
    });
  });

  group('care supplies & comfort (gentle, never farmable)', () {
    test('a supply lifts meters within floor..100 and skips the streak', () {
      final tired = _adopt().copyWith(
        meters: const CareMeters(
          hunger: 50,
          energy: 40,
          hygiene: 60,
          happiness: 55,
        ),
      );
      final out = sim.applySupply(
        state: tired,
        item: ItemCatalog.warmBroth,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
      );
      expect(out.state.meters.hunger, 50 + ItemCatalog.warmBroth.satiety);
      expect(out.state.meters.energy, 40 + ItemCatalog.warmBroth.energy);
      expect(out.state.meters.happiness, 55 + ItemCatalog.warmBroth.joy);
      expect(out.state.careStreak.count, tired.careStreak.count);
      expect(out.bondAwarded, 0); // no comfort beat, no bond — aids, not verbs
    });

    test('comforting a Low pet out of the Low band earns the Comfort beat', () {
      final low = _adopt().copyWith(
        meters: const CareMeters(
          hunger: 15,
          energy: 15,
          hygiene: 15,
          happiness: 15,
        ),
      );
      final out = sim.applySupply(
        state: low,
        item: ItemCatalog.warmBroth,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
      );
      expect(out.comfortBeat, isTrue);
      expect(out.bondAwarded, greaterThan(0));
    });

    test('petting bond is tiny and diminishes per session touch', () {
      final state = _adopt();
      final first = sim.comfort(
        state: state,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
      );
      expect(first.session.petting, 1);
      var session = SessionInteractions.empty;
      for (var i = 0; i < 8; i++) {
        session = session.incrementPetting();
      }
      final eighth = sim.comfort(
        state: state,
        session: session,
        ledger: BondLedger.empty,
        nowMs: _day0 + _hour,
      );
      expect(eighth.bondAwarded, lessThanOrEqualTo(first.bondAwarded));
    });
  });

  group('sleep cycle (Bedroom)', () {
    test('tuckedIn persists the nap start; wokenUp clears it', () {
      final pet = _adopt().tuckedIn(_day0 + _hour);
      expect(pet.isSleeping, isTrue);
      expect(pet.sleepingSinceMs, _day0 + _hour);
      // Tucking in again never restarts the nap clock.
      expect(pet.tuckedIn(_day0 + 5 * _hour).sleepingSinceMs, _day0 + _hour);
      expect(pet.wokenUp().isSleeping, isFalse);
    });

    test('wake credits +20 energy/hour (capped at 100) and wakes the pet', () {
      final napping = _adopt()
          .copyWith(
            meters: const CareMeters(
              hunger: 80,
              energy: 30,
              hygiene: 80,
              happiness: 70,
            ),
          )
          .tuckedIn(_day0);
      final out = sim.wake(state: napping, nowMs: _day0 + 2 * _hour);
      expect(out.sleptHours, 2);
      expect(out.state.meters.energy, 30 + 2 * 20);
      expect(out.state.isSleeping, isFalse);

      final long = sim.wake(state: napping, nowMs: _day0 + 10 * _hour);
      expect(long.state.meters.energy, 100); // capped, never over-charged
    });

    test('waking an awake pet is a no-op', () {
      final awake = _adopt();
      final out = sim.wake(state: awake, nowMs: _day0 + _hour);
      expect(out.state, awake);
      expect(out.sleptHours, 0);
    });
  });
}
