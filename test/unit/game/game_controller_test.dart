import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';

import '../../support/harness.dart';

void main() {
  group('GameController', () {
    test('starts with no pet → Rescue Day, then adopt creates one', () async {
      final c = makeController();
      await c.load();
      expect(c.hasPet, isFalse);

      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(c.hasPet, isTrue);
      expect(c.pet!.name, 'Biscuit');
      expect(c.pet!.species, Species.puppy);
      // Memory Book is seeded on Rescue Day (the "it remembers" seed).
      expect(c.facts, isNotEmpty);
      expect(c.lastMessage, contains('Welcome home'));
    });

    test('empty name falls back to the canonical default', () async {
      final c = makeController();
      await c.load();
      await c.adopt(species: Species.kitten, name: '   ');
      expect(c.pet!.name, 'Mochi');
    });

    test(
      'interacting grows the Bond + Kibble and surfaces warm feedback',
      () async {
        final c = makeController(clock: () => kDay0);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');

        await c.interact(CareInteraction.play); // costs energy, awards Bond
        final bond1 = c.pet!.bond.value;
        expect(bond1, greaterThan(0));

        await c.interact(CareInteraction.feed);
        expect(c.pet!.wallet.kibble, greaterThan(0));
        expect(c.pet!.bond.value, greaterThanOrEqualTo(bond1));
        expect(c.lastMessage, isNotNull); // warm, never guilt
        c.dispose();
      },
    );

    test(
      'SAVE → REOPEN → CONTINUE: a new controller restores the pet',
      () async {
        // Persist with one controller...
        final store = InMemoryLocalSaveStore();
        final first = makeController(store: store, clock: () => kDay0);
        await first.load();
        await first.adopt(species: Species.puppy, name: 'Biscuit');
        await first.interact(CareInteraction.feed);
        final bondBefore = first.pet!.bond.value;
        final kibbleBefore = first.pet!.wallet.kibble;
        first.dispose();

        // ...reopen with a brand-new controller over the SAME local store.
        final second = makeController(store: store, clock: () => kDay0);
        await second.load();
        expect(second.hasPet, isTrue);
        expect(second.pet!.name, 'Biscuit');
        expect(second.pet!.bond.value, bondBefore); // continued, not reset
        expect(second.pet!.wallet.kibble, kibbleBefore);
        second.dispose();
      },
    );

    test('reopening a day later greets warmly (Bond never drops)', () async {
      final store = InMemoryLocalSaveStore();
      final first = makeController(store: store, clock: () => kDay0);
      await first.load();
      await first.adopt(species: Species.puppy, name: 'Biscuit');
      await first.interact(CareInteraction.feed);
      final bondBefore = first.pet!.bond.value;
      first.dispose();

      // Reopen one day later.
      final next = makeController(
        store: store,
        clock: () => kDay0 + 86400000 + 3600000,
      );
      await next.load();
      // Greeting can only add to the Bond — never subtract (Risk R6).
      expect(next.pet!.bond.value, greaterThanOrEqualTo(bondBefore));
      // Pet decayed but is safe.
      expect(next.pet!.meters.lowest, greaterThanOrEqualTo(15));
      next.dispose();
    });
  });
}
