import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/sim/care_meter_simulator.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

const _h = Duration.millisecondsPerHour;
const _d = Duration.millisecondsPerDay;

void main() {
  const config = SimConfig();
  const sim = CareMeterSimulator(config);

  group('effectiveDecayHours (grace + MAX_CATCHUP)', () {
    test('zero / negative elapsed → no decay', () {
      expect(sim.effectiveDecayHours(0), 0);
      expect(sim.effectiveDecayHours(-5 * _h), 0);
    });

    test('first 8h decay at 50% (the pet napped)', () {
      expect(sim.effectiveDecayHours(1 * _h), closeTo(0.5, 1e-9));
      expect(sim.effectiveDecayHours(8 * _h), closeTo(4.0, 1e-9));
    });

    test('beyond grace, full rate applies to the remainder', () {
      // 10h = 8h grace (×0.5 → 4) + 2h full = 6.0 effective hours.
      expect(sim.effectiveDecayHours(10 * _h), closeTo(6.0, 1e-9));
    });

    test('MAX_CATCHUP caps total decay at 7 days', () {
      final sevenDays = sim.effectiveDecayHours(7 * _d);
      expect(sim.effectiveDecayHours(100 * _d), sevenDays);
    });
  });

  group('applyDecay', () {
    test('1h within grace decays at half rate, others stay high', () {
      final m = sim.applyDecay(CareMeters.full, 1 * _h);
      expect(m.hunger, closeTo(97.5, 1e-9)); // 100 - 5.0*0.5
      expect(m.energy, closeTo(98.25, 1e-9)); // 100 - 3.5*0.5
      expect(m.hygiene, closeTo(98.75, 1e-9)); // 100 - 2.5*0.5
      // happiness: -4*0.5 then +1*0.5 passive (others > 60) = 98.5
      expect(m.happiness, closeTo(98.5, 1e-9));
    });

    test('HARD no-death floor: long neglect never drops below 15', () {
      final m = sim.applyDecay(CareMeters.full, 100 * _d);
      expect(m.hunger, 15);
      expect(m.energy, 15);
      expect(m.hygiene, 15);
      expect(m.happiness, 15);
      expect(m.lowest, greaterThanOrEqualTo(config.floor));
    });

    test('decay is clamped to the MAX_CATCHUP window', () {
      final capped = sim.applyDecay(CareMeters.full, 7 * _d);
      final beyond = sim.applyDecay(CareMeters.full, 30 * _d);
      expect(beyond, capped); // identical — no extra decay past the cap
    });

    test('is deterministic — identical inputs yield identical output', () {
      final a = sim.applyDecay(CareMeters.full, 9 * _h);
      final b = sim.applyDecay(CareMeters.full, 9 * _h);
      expect(a, b);
    });

    test('negative elapsed (clock skew) leaves meters unchanged', () {
      expect(sim.applyDecay(CareMeters.full, -3 * _h), CareMeters.full);
    });

    test(
      'passive happiness recovery stops once another meter dips below 60',
      () {
        // Start with a low-ish hygiene so it crosses below 60 → no passive.
        const m0 = CareMeters(
          hunger: 100,
          energy: 100,
          hygiene: 50,
          happiness: 80,
        );
        final m = sim.applyDecay(m0, 2 * _h); // effective 1.0h
        // hygiene 50 - 2.5 = 47.5 (<60) → happiness gets NO passive, only decay.
        expect(m.happiness, closeTo(76.0, 1e-9)); // 80 - 4*1.0
      },
    );
  });
}
