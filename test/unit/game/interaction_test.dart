import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

void main() {
  const engine = InteractionEngine(SimConfig());

  group('feed', () {
    test('restores hunger (+35) + happiness (+10) when hungry', () {
      const m = CareMeters(hunger: 50, energy: 80, hygiene: 80, happiness: 70);
      final e = engine.apply(
        m,
        CareInteraction.feed,
        SessionInteractions.empty,
      );
      expect(e.meters.hunger, closeTo(85, 1e-9));
      expect(e.meters.happiness, closeTo(80, 1e-9));
      expect(e.wasNeeded, isTrue);
      expect(e.rawBondPoints, closeTo(2, 1e-9)); // feedWhenHungry
      expect(e.kibble, 5);
      expect(e.session.feed, 1);
    });

    test('diminishing returns: 2nd feed this session = ×0.6', () {
      const m = CareMeters(hunger: 0, energy: 80, hygiene: 80, happiness: 50);
      const session = SessionInteractions(feed: 1); // already fed once
      final e = engine.apply(m, CareInteraction.feed, session);
      expect(e.meters.hunger, closeTo(21, 1e-9)); // 0 + 35*0.6
      expect(e.rawBondPoints, closeTo(1.2, 1e-9)); // 2 * 0.6
    });

    test('feeding a full pet is "petting-equivalent" only', () {
      const m = CareMeters(hunger: 100, energy: 80, hygiene: 80, happiness: 80);
      final e = engine.apply(
        m,
        CareInteraction.feed,
        SessionInteractions.empty,
      );
      expect(e.wasNeeded, isFalse);
      expect(e.rawBondPoints, closeTo(0.5, 1e-9)); // pettingTouch
      expect(e.kibble, 1);
      expect(e.meters.hunger, 100); // clamped
    });
  });

  group('clean', () {
    test('restores hygiene (+40) when dirty', () {
      const m = CareMeters(hunger: 80, energy: 80, hygiene: 30, happiness: 80);
      final e = engine.apply(
        m,
        CareInteraction.clean,
        SessionInteractions.empty,
      );
      expect(e.meters.hygiene, closeTo(70, 1e-9));
      expect(e.rawBondPoints, closeTo(2, 1e-9));
    });
  });

  group('play', () {
    test('boosts happiness (+30) but costs energy (−10)', () {
      const m = CareMeters(hunger: 80, energy: 50, hygiene: 80, happiness: 40);
      final e = engine.apply(
        m,
        CareInteraction.play,
        SessionInteractions.empty,
      );
      expect(e.meters.happiness, closeTo(70, 1e-9));
      expect(e.meters.energy, closeTo(40, 1e-9));
      expect(e.rawBondPoints, closeTo(3, 1e-9)); // playWhenWilling
    });

    test('energy cost respects the no-death floor', () {
      const m = CareMeters(hunger: 80, energy: 20, hygiene: 80, happiness: 80);
      final e = engine.apply(
        m,
        CareInteraction.play,
        SessionInteractions.empty,
      );
      expect(e.meters.energy, 15); // 20 - 10 = 10 → clamped up to floor 15
    });
  });
}
