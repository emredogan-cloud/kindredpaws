import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';

import '../../support/harness.dart';

void main() {
  // The controller — not just the Rescue Day widget — must keep PII/profanity
  // out of the persisted name (P3-8 audit: defense in depth at the persistence
  // boundary, §11.1).
  group('GameController.adopt re-validates the name', () {
    test('a profane name falls back to the species default', () async {
      final c = makeController(clock: () => kDay0);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'shithead');
      expect(c.pet!.name, Species.puppy.defaultName); // 'Biscuit', not the slur
      c.dispose();
    });

    test('a PII-shaped name falls back to the species default', () async {
      final c = makeController(clock: () => kDay0);
      await c.load();
      await c.adopt(species: Species.kitten, name: 'a@b.com');
      expect(c.pet!.name, Species.kitten.defaultName); // 'Mochi'
      c.dispose();
    });

    test('a clean name is persisted (sanitized) as-is', () async {
      final c = makeController(clock: () => kDay0);
      await c.load();
      await c.adopt(species: Species.puppy, name: '  Noodle  ');
      expect(c.pet!.name, 'Noodle'); // trimmed/collapsed by the validator
      c.dispose();
    });
  });
}
