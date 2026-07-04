/// Care meters → tangible cues (GE-2): exact thresholds, boundaries, and the
/// "full pet carries nothing" guarantee.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/ui/care_cues.dart';
import 'package:kindredpaws/render/pet_renderer.dart';

CareMeters _meters({
  double hunger = 100,
  double energy = 100,
  double hygiene = 100,
  double happiness = 100,
}) => CareMeters(
  hunger: hunger,
  energy: energy,
  hygiene: hygiene,
  happiness: happiness,
);

void main() {
  test('a well-cared pet carries no cues at all', () {
    expect(cuesFor(CareMeters.full), PetCareCues.none);
    expect(cuesFor(CareMeters.full).any, isFalse);
  });

  test('each cue trips exactly below its own threshold', () {
    // At the threshold: still clean/awake/full (strictly below trips).
    expect(cuesFor(_meters(hygiene: kMussedBelowHygiene)).mussed, isFalse);
    expect(cuesFor(_meters(energy: kDrowsyBelowEnergy)).drowsy, isFalse);
    expect(cuesFor(_meters(hunger: kPeckishBelowHunger)).peckish, isFalse);
    // Just below: the cue shows.
    expect(cuesFor(_meters(hygiene: kMussedBelowHygiene - 0.1)).mussed, isTrue);
    expect(cuesFor(_meters(energy: kDrowsyBelowEnergy - 0.1)).drowsy, isTrue);
    expect(cuesFor(_meters(hunger: kPeckishBelowHunger - 0.1)).peckish, isTrue);
  });

  test('cues are independent — one low meter never drags the others', () {
    final c = cuesFor(_meters(hygiene: 20));
    expect(c.mussed, isTrue);
    expect(c.drowsy, isFalse);
    expect(c.peckish, isFalse);
  });

  test('thresholds sit at/below the no-death floor story: even the lowest '
      'meters produce cues, never a scary state', () {
    final c = cuesFor(_meters(hunger: 15, energy: 15, hygiene: 15));
    expect(c.mussed && c.drowsy && c.peckish, isTrue);
    expect(c.any, isTrue);
  });
}
