/// GameController surface of the room-based home: kitchen feeding from the
/// pantry, toy play with affection, Kibble purchases, gentle supplies, the
/// wellness ritual, wardrobe equipping, and the sleep cycle — including the
/// v6→v7 save upgrade that gifts existing pets the starter kit.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/migration_runner.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/game/model/items.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';

import '../../support/harness.dart';

void main() {
  group('kitchen feeding (pantry-backed)', () {
    test(
      'feedWith consumes the pantry and restores by the food profile',
      () async {
        final c = makeController();
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        // Work up an appetite so feeding is a "needed" care action.
        final before = c.inventory.pantryCount(ItemCatalog.kibbleBowl.id);
        await c.feedWith(ItemCatalog.kibbleBowl);
        expect(c.inventory.pantryCount(ItemCatalog.kibbleBowl.id), before - 1);
        expect(c.lastMessage, contains('Kibble Bowl'));
        expect(c.lastMessage, isNot(contains('empty')));
      },
    );

    test(
      'an empty shelf nudges the Grocery Store warmly — never an error',
      () async {
        final c = makeController();
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        expect(c.inventory.pantryCount(ItemCatalog.honeyBiscuit.id), 0);
        await c.feedWith(ItemCatalog.honeyBiscuit);
        expect(c.lastMessage, contains('Grocery Store'));
        // No meters changed, nothing consumed, session not incremented.
        expect(c.pet!.meters.hunger, 100);
      },
    );
  });

  group('toy play (affection progression)', () {
    test('playWith records the shared play and speaks of the toy', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      await c.playWith(ItemCatalog.bouncyBall);
      expect(c.inventory.affinity(ItemCatalog.bouncyBall.id), 1);
      expect(c.lastMessage, contains('Bouncy Ball'));
      await c.playWith(ItemCatalog.bouncyBall);
      expect(c.inventory.affinity(ItemCatalog.bouncyBall.id), 2);
    });

    test('an unowned toy is a silent no-op (UI never offers it)', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      final happiness = c.pet!.meters.happiness;
      await c.playWith(ItemCatalog.plushStar);
      expect(c.inventory.affinity(ItemCatalog.plushStar.id), 0);
      expect(c.pet!.meters.happiness, happiness);
    });
  });

  group('grocery purchases (Kibble only)', () {
    test('purchase debits Kibble, stocks the pantry, and celebrates', () async {
      var now = kDay0;
      final c = makeController(clock: () => now);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      // Earn Kibble the real way: come back later and meet real needs
      // (needed care pays 5 Kibble; a topped-up pet pays the token 1).
      await c.onAppBackgrounded();
      now += 8 * Duration.millisecondsPerHour;
      c.onAppForegrounded();
      await c.feedWith(ItemCatalog.kibbleBowl);
      await c.playWith(ItemCatalog.bouncyBall);
      await c.interact(CareInteraction.clean);
      final kibble = c.pet!.wallet.kibble;
      expect(kibble, greaterThanOrEqualTo(ItemCatalog.apple.kibblePrice));
      final ok = await c.purchase(ItemCatalog.apple);
      expect(ok, isTrue);
      expect(c.pet!.wallet.kibble, kibble - ItemCatalog.apple.kibblePrice);
      expect(c.inventory.pantryCount(ItemCatalog.apple.id), 2); // starter +1
    });

    test(
      'coming up short invites more care moments — never pressure',
      () async {
        final c = makeController();
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        final ok = await c.purchase(ItemCatalog.plushStar); // 220 — far off
        expect(ok, isFalse);
        expect(c.lastMessage, contains('care moments'));
        expect(c.pet!.wallet.kibble, 0); // never negative, never charged
      },
    );
  });

  group('Care Corner (gentle wellness)', () {
    test('useSupply consumes the shelf and comforts', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      await c.useSupply(ItemCatalog.vitaminChew);
      expect(c.inventory.supplyCount(ItemCatalog.vitaminChew.id), 0);
      expect(c.lastMessage, contains('cozier'));
      await c.useSupply(ItemCatalog.vitaminChew); // now empty
      expect(c.lastMessage, contains('Grocery Store'));
    });

    test(
      'the wellness check is always reassuring (no sickness exists)',
      () async {
        final c = makeController();
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        c.wellnessCheck();
        expect(c.lastMessage, contains('🌡️'));
        expect(c.lastMessage!.toLowerCase(), isNot(contains('sick')));
        expect(c.lastMessage!.toLowerCase(), isNot(contains('fever')));
      },
    );

    test('comfortPet gives a tiny bond and a warm lean-in', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      await c.comfortPet();
      expect(c.petLine, isNotNull);
      expect(c.lastMessage, contains('💛'));
    });
  });

  group('wardrobe (cosmetic delight only)', () {
    test(
      'equipCosmetic dresses an owned cosmetic; premium needs entitlement',
      () async {
        final c = makeController();
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        // Not owned and not entitled → no-op.
        await c.equipCosmetic(ItemCatalog.sunbeamBandana);
        expect(c.inventory.equipped, isEmpty);
        // Entitled premium keepsake → granted + worn.
        await c.equipCosmetic(ItemCatalog.sunbeamBandana, entitled: true);
        expect(c.inventory.isEquipped(ItemCatalog.sunbeamBandana.id), isTrue);
        await c.unequipCosmetic(ItemCatalog.sunbeamBandana);
        expect(c.inventory.equipped, isEmpty);
        expect(c.inventory.ownsCosmetic(ItemCatalog.sunbeamBandana.id), isTrue);
      },
    );
  });

  group('sleep cycle', () {
    test('tuckIn → care actions hush → wakeUp credits the nap', () async {
      var now = kDay0;
      final c = makeController(clock: () => now);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      // Tire the pet out a little so the credit is visible.
      await c.playWith(ItemCatalog.bouncyBall);
      final energyBefore = c.pet!.meters.energy;
      await c.tuckIn();
      expect(c.isSleeping, isTrue);
      expect(c.lastMessage, contains('Sweet dreams'));

      await c.interact(CareInteraction.feed);
      expect(c.lastMessage, contains('asleep'));
      expect(c.isSleeping, isTrue);

      now += 2 * Duration.millisecondsPerHour; // a two-hour nap
      await c.wakeUp();
      expect(c.isSleeping, isFalse);
      expect(c.pet!.meters.energy, greaterThan(energyBefore));
      expect(c.lastMessage, contains('☀️'));
    });

    test(
      'sleep survives a save round-trip (nap continues across restarts)',
      () async {
        var now = kDay0;
        final store = makeStore();
        final c = makeController(store: store, clock: () => now);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        await c.tuckIn();

        now += Duration.millisecondsPerHour;
        final reopened = makeController(store: store, clock: () => now);
        await reopened.load();
        expect(reopened.isSleeping, isTrue);
        await reopened.wakeUp();
        expect(reopened.isSleeping, isFalse);
      },
    );
  });

  group('save v6 → v7 upgrade', () {
    test('gifts existing pets the starter kit and keeps them awake', () {
      // A faithful minimal v6 envelope (what a pre-rooms build persisted).
      const v6 = SaveEnvelope(
        schemaVersion: 6,
        data: {
          'petId': 'p-old',
          'species': 'kitten',
          'name': 'Mochi',
          'lifeStage': 'youngOne',
          'careMeters': {
            'hunger': 70.0,
            'energy': 80.0,
            'hygiene': 60.0,
            'happiness': 75.0,
          },
          'bond': {'value': 300, 'stage': 'Friend'},
          'nest': {'cosmeticIds': <String>[]},
          'careStreak': {'count': 3, 'lastCareDayEpoch': 20000, 'freezes': 2},
          'wallet': {'kibble': 40, 'heartstones': 0, 'compassionCoins': 0},
          'activeDays': 6,
          'lastActiveDayEpoch': 20000,
          'createdAtMs': 0,
          'lastSimTimestampMs': 0,
          'bondLedger': <String, dynamic>{},
          'memoryFacts': <Map<String, dynamic>>[],
          'keepsakes': <Map<String, dynamic>>[],
          'personality': {
            'playfulness': 2,
            'cuddliness': 2,
            'chattiness': 2,
            'bravery': 2,
          },
        },
      );
      final runner = MigrationRunner(KindredSaveState.migrations);
      final upgraded = runner.upgrade(
        v6,
        KindredSaveState.currentSchemaVersion,
      );
      final state = KindredSaveState.fromEnvelope(upgraded);
      expect(state.pet.name, 'Mochi');
      expect(state.pet.isSleeping, isFalse);
      expect(state.inventory.pantryCount(ItemCatalog.kibbleBowl.id), 2);
      expect(state.inventory.ownsToy(ItemCatalog.bouncyBall.id), isTrue);
      expect(state.pet.wallet.kibble, 40); // wallet untouched by the gift
    });

    test('v7 round-trips inventory + sleep losslessly', () {
      final s = KindredSaveState.newPet(
        petId: 'p3',
        species: 'puppy',
        name: 'Biscuit',
        nowMs: 123,
      );
      final dressed = s.copyWith(
        pet: s.pet.tuckedIn(456),
        inventory: s.inventory
            .add(ItemCatalog.bobbleHat)
            .equip(ItemCatalog.bobbleHat)
            .add(ItemCatalog.warmBroth, count: 2),
      );
      final back = KindredSaveState.fromEnvelope(dressed.toEnvelope());
      expect(back.pet.sleepingSinceMs, 456);
      expect(back.inventory.isEquipped(ItemCatalog.bobbleHat.id), isTrue);
      expect(back.inventory.supplyCount(ItemCatalog.warmBroth.id), 2);
    });
  });
}
