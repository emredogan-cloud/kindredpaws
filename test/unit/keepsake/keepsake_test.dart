import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/bond.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/keepsake/keepsake.dart';
import 'package:kindredpaws/keepsake/keepsake_factory.dart';

import '../../support/harness.dart';

const _day = 86400000;
const _day0 = 20000 * _day;

PetState _pet() => PetState.newlyRescued(
  petId: 'p1',
  species: Species.puppy,
  name: 'Biscuit',
  nowMs: _day0,
);

void main() {
  const factory = KeepsakeFactory();

  group('KeepsakeFactory', () {
    test('builds warm, correctly-kinded cards', () {
      final r = factory.rescueDay(_pet(), _day0);
      expect(r.kind, KeepsakeKind.rescueDay);
      expect(r.caption, contains('Biscuit'));
      expect(r.petName, 'Biscuit');

      final b = factory.bondMilestone(_pet(), BondStage.friend, _day0);
      expect(b.kind, KeepsakeKind.bondMilestone);
      expect(b.caption, contains('Friend'));

      final s = factory.streakMilestone(_pet(), 7, _day0);
      expect(s.caption, contains('7'));
    });

    test('ids are stable per milestone (so a card is captured once)', () {
      expect(
        factory.bondMilestone(_pet(), BondStage.friend, _day0).id,
        factory.bondMilestone(_pet(), BondStage.friend, _day0 + 999).id,
      );
      // Different milestones get different ids.
      expect(
        factory.bondMilestone(_pet(), BondStage.friend, _day0).id,
        isNot(factory.bondMilestone(_pet(), BondStage.companion, _day0).id),
      );
    });

    test('growth + memoryCallback cards are well-formed', () {
      final g = factory.growth(_pet(), _day0);
      expect(g.kind, KeepsakeKind.beforeAfterGrowth);
      expect(g.caption, contains('grew'));
      // Stable per life stage (a given growth is captured once).
      expect(g.id, factory.growth(_pet(), _day0 + 999).id);

      final m = factory.memoryCallback(_pet(), 'you like rainy days', _day0);
      expect(m.kind, KeepsakeKind.longMemoryCallback);
      expect(m.caption, contains('remembered'));
      // The card never leaks the raw remembered text (privacy-safe).
      expect(m.caption, isNot(contains('rainy days')));
    });

    test('serializes losslessly', () {
      final k = factory.rescueDay(_pet(), _day0);
      expect(Keepsake.fromJson(k.toJson()), k);
    });
  });

  group('GameController keepsake collection', () {
    test('adopt captures the Rescue Day card', () async {
      final c = makeController(clock: () => _day0);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(c.keepsakes, hasLength(1));
      expect(c.keepsakes.first.kind, KeepsakeKind.rescueDay);
      c.dispose();
    });

    test('keepsakes persist across save → reopen', () async {
      final store = makeStore();
      final first = makeController(store: store, clock: () => _day0);
      await first.load();
      await first.adopt(species: Species.kitten, name: 'Mochi');
      first.dispose();

      final second = makeController(store: store, clock: () => _day0);
      await second.load();
      expect(second.keepsakes, isNotEmpty);
      // The Rescue Day card persisted (it may not be first — newest-first order).
      expect(
        second.keepsakes.any((k) => k.kind == KeepsakeKind.rescueDay),
        isTrue,
      );
      second.dispose();
    });

    test('a memory callback (on return) earns an It-Remembered card', () async {
      final store = makeStore();
      final first = makeController(store: store, clock: () => _day0);
      await first.load();
      // Adoption seeds memory facts (likesActivity), so a callback can fire.
      await first.adopt(species: Species.puppy, name: 'Biscuit');
      first.dispose();

      // Reopen after a real absence → the "returning" beat tries a callback.
      final next = makeController(store: store, clock: () => _day0 + 2 * _day);
      await next.load();
      expect(
        next.keepsakes.any((k) => k.kind == KeepsakeKind.longMemoryCallback),
        isTrue,
      );
      next.dispose();
    });

    test('a Comfort beat earns an Unprompted-Comfort card', () async {
      final store = makeStore();
      final first = makeController(store: store, clock: () => _day0);
      await first.load();
      await first.adopt(species: Species.puppy, name: 'Biscuit');
      first.dispose();

      // Reopen after a long absence → pet decays to the Low band.
      final next = makeController(store: store, clock: () => _day0 + 30 * _day);
      await next.load();
      await next.interact(CareInteraction.play); // caring it back up = comfort
      expect(
        next.keepsakes.any((k) => k.kind == KeepsakeKind.unpromptedComfort),
        isTrue,
      );
      next.dispose();
    });
  });
}
