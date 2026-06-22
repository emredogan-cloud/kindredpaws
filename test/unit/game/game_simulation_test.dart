import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/model/mood.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/bond_engine.dart';
import 'package:kindredpaws/game/sim/game_simulation.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

const _hour = Duration.millisecondsPerHour;
const _day = Duration.millisecondsPerDay;
const _day0 = 20000 * _day; // a clean midnight-UTC epoch (day 20000)

PetState _adopt() => PetState.newlyRescued(
  petId: 'p1',
  species: Species.puppy,
  name: 'Biscuit',
  nowMs: _day0,
);

void main() {
  final sim = GameSimulation(const SimConfig());

  group('resolveOnResume', () {
    test('same-day resume: decays meters, no greeting, no new active day', () {
      final r = sim.resolveOnResume(
        state: _adopt(),
        ledger: BondLedger.empty,
        nowMs: _day0 + 2 * _hour,
      );
      expect(r.isNewDay, isFalse);
      expect(r.greetingBond, 0);
      expect(r.state.activeDays, 1);
      expect(r.state.meters.hunger, lessThan(100)); // decayed
      expect(r.state.bond.value, 0);
      expect(r.state.lastSimTimestampMs, _day0 + 2 * _hour);
    });

    test('new-day resume: warm greeting (+Bond), active day increments', () {
      final r = sim.resolveOnResume(
        state: _adopt(),
        ledger: BondLedger.empty,
        nowMs: _day0 + 1 * _day + 2 * _hour,
      );
      expect(r.isNewDay, isTrue);
      expect(r.greetingBond, greaterThanOrEqualTo(5));
      expect(r.state.bond.value, r.greetingBond);
      expect(r.state.activeDays, 2);
      // Even after a day away, the pet is "sad but safe" — never below floor.
      expect(r.state.meters.lowest, greaterThanOrEqualTo(15));
    });

    test('long neglect resolves to the floor, never past it (no guilt)', () {
      final r = sim.resolveOnResume(
        state: _adopt(),
        ledger: BondLedger.empty,
        nowMs: _day0 + 30 * _day,
      );
      expect(r.state.meters.hunger, 15);
      expect(r.state.meters.happiness, 15);
      // The Bond is untouched by absence (monotonic) beyond the warm greeting.
      expect(r.state.bond.value, greaterThanOrEqualTo(0));
    });
  });

  group('interact', () {
    test(
      'feeding a hungry pet restores hunger, grows Bond + Kibble, streaks',
      () {
        // Start a bit hungry so feeding is "needed".
        final hungry = _adopt().copyWith(
          meters: const CareMeters(
            hunger: 40,
            energy: 80,
            hygiene: 80,
            happiness: 70,
          ),
        );
        final o = sim.interact(
          state: hungry,
          interaction: CareInteraction.feed,
          session: SessionInteractions.empty,
          ledger: BondLedger.empty,
          nowMs: _day0,
        );
        expect(o.state.meters.hunger, closeTo(75, 1e-9)); // 40 + 35
        expect(o.bondAwarded, greaterThan(0));
        expect(o.state.bond.value, o.bondAwarded);
        expect(o.kibbleAwarded, 5);
        expect(o.state.wallet.kibble, 5);
        expect(o.streakIncremented, isTrue);
        expect(o.state.careStreak.count, 1);
      },
    );

    test('comfort beat: caring a Low-mood pet back up awards the +10 beat', () {
      final low = _adopt().copyWith(
        meters: const CareMeters(
          hunger: 15,
          energy: 15,
          hygiene: 15,
          happiness: 15,
        ),
      );
      expect(sim.moodOf(low.meters), Mood.low);
      final o = sim.interact(
        state: low,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0,
      );
      expect(o.comfortBeat, isTrue);
      // The award includes the interaction + streak-day + comfort (+10) beat.
      expect(o.bondAwarded, greaterThan(10));
    });
  });

  group('hard invariants (G1 / Risk R4, R6)', () {
    test('Bond NEVER decreases across a neglect → return → care cycle', () {
      var state = _adopt();
      var ledger = BondLedger.empty;
      var session = SessionInteractions.empty;

      // Day 0: a few care actions.
      for (final i in [
        CareInteraction.feed,
        CareInteraction.clean,
        CareInteraction.play,
      ]) {
        final o = sim.interact(
          state: state,
          interaction: i,
          session: session,
          ledger: ledger,
          nowMs: _day0,
        );
        state = o.state;
        ledger = o.ledger;
        session = o.session;
      }
      final bondAfterDay0 = state.bond.value;
      expect(bondAfterDay0, greaterThan(0));

      // Neglect 3 days, then return.
      final r = sim.resolveOnResume(
        state: state,
        ledger: ledger,
        nowMs: _day0 + 3 * _day,
      );
      // Bond after the absence is >= before (greeting can only add).
      expect(r.state.bond.value, greaterThanOrEqualTo(bondAfterDay0));
      // Meters decayed but safe.
      expect(r.state.meters.lowest, greaterThanOrEqualTo(15));
    });

    test('the simulation is deterministic (same inputs → identical state)', () {
      InteractionOutcome run() => sim.interact(
        state: _adopt(),
        interaction: CareInteraction.feed,
        session: SessionInteractions.empty,
        ledger: BondLedger.empty,
        nowMs: _day0,
      );
      expect(run().state, run().state);
    });
  });
}
