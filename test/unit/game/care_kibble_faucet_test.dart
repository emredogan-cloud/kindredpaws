/// KP-014 — the care-action Kibble faucet is bounded.
///
/// The audit: `willing = energy > playEnergyCost(10)` was permanently true
/// (the no-death floor is 15), so "play" minted 5 Kibble per tap forever —
/// no diminishing, no daily cap; the whole shop was trivially farmable.
/// Now: full value to ⅔ of the daily cap, a 1-Kibble trickle to the cap,
/// zero after — resetting at the (local, forward-only) day rollover.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/bond.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/mood.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/bond_engine.dart';
import 'package:kindredpaws/game/sim/game_simulation.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

import '../../support/harness.dart';

const int _hour = Duration.millisecondsPerHour;
const int _day = Duration.millisecondsPerDay;

void main() {
  const config = SimConfig();
  final sim = GameSimulation(config);

  PetState fresh() => PetState.newlyRescued(
    petId: kTestPetId,
    species: Species.puppy,
    name: 'Biscuit',
    nowMs: kDay0,
  );

  group('KP-014 — bounded daily care-Kibble', () {
    test('tap-farming play all day yields exactly the daily cap', () {
      var state = fresh();
      var ledger = BondLedger.empty;
      var session = SessionInteractions.empty;
      var totalMinted = 0;

      // 200 greedy taps within one day.
      for (var i = 0; i < 200; i++) {
        final r = sim.interact(
          state: state,
          interaction: CareInteraction.play,
          session: session,
          ledger: ledger,
          nowMs: kDay0 + i * 60000, // a tap a minute
        );
        totalMinted += r.kibbleAwarded;
        state = r.state;
        ledger = r.ledger;
        session = r.session;
      }
      expect(totalMinted, config.careKibbleDailyCap);
      expect(state.wallet.kibble, config.careKibbleDailyCap);
    });

    test('the taper: full mints, then a 1-Kibble trickle, then zero', () {
      var state = fresh();
      var ledger = BondLedger.empty;
      var session = SessionInteractions.empty;
      final mints = <int>[];
      for (var i = 0; i < 40; i++) {
        final r = sim.interact(
          state: state,
          interaction: CareInteraction.play,
          session: session,
          ledger: ledger,
          nowMs: kDay0 + i * 60000,
        );
        mints.add(r.kibbleAwarded);
        state = r.state;
        ledger = r.ledger;
        session = r.session;
      }
      // Softcap = 20 → four full 5s; trickle of 1s to 30; zeros after.
      expect(mints.takeWhile((m) => m == 5).length, 4);
      expect(mints.where((m) => m == 1).length, 10);
      expect(mints.skip(14).every((m) => m == 0), isTrue);
    });

    test('the faucet refills on a genuine new day — not on a restart', () {
      var state = fresh();
      var ledger = BondLedger.empty;
      // Exhaust today.
      var session = SessionInteractions.empty;
      for (var i = 0; i < 40; i++) {
        final r = sim.interact(
          state: state,
          interaction: CareInteraction.play,
          session: session,
          ledger: ledger,
          nowMs: kDay0 + i * 60000,
        );
        state = r.state;
        ledger = r.ledger;
        session = r.session;
      }
      // A "restart" (fresh session object, same day): still dry — the tally
      // is persisted on the ledger, not the session.
      final sameDay = sim.interact(
        state: state,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: ledger,
        nowMs: kDay0 + 5 * _hour,
      );
      expect(sameDay.kibbleAwarded, 0);

      // The next (forward) day starts a fresh budget.
      final nextDay = sim.interact(
        state: sameDay.state,
        interaction: CareInteraction.play,
        session: SessionInteractions.empty,
        ledger: sameDay.ledger,
        nowMs: kDay0 + _day + _hour,
      );
      expect(nextDay.kibbleAwarded, greaterThan(0));
    });

    test('a tired pet is not "willing" — play pays the token, not the full '
        'mint', () {
      // Energy at 24: the cost (10) would land below the floor+cost line.
      final tired = fresh().copyWith(
        meters: const CareMeters(
          hunger: 80,
          energy: 24,
          hygiene: 80,
          happiness: 80,
        ),
      );
      const engine = InteractionEngine(SimConfig());
      final effect = engine.apply(
        tired.meters,
        CareInteraction.play,
        SessionInteractions.empty,
      );
      expect(effect.kibble, 1, reason: 'no headroom above the floor');

      final rested = engine.apply(
        const CareMeters(hunger: 80, energy: 80, hygiene: 80, happiness: 80),
        CareInteraction.play,
        SessionInteractions.empty,
      );
      expect(rested.kibble, 5);
    });

    test('a Bond award never resets the day\'s Kibble tally', () {
      const engine = BondEngine(SimConfig());
      const ledger = BondLedger(
        dayEpoch: 100,
        earnedToday: 10,
        careKibbleToday: 25,
      );
      final award = engine.award(
        bond: Bond.initial,
        rawPoints: 5,
        mood: Mood.content,
        ledger: ledger,
        todayEpochDay: 100,
      );
      expect(award.ledger.careKibbleToday, 25);
    });

    test('ledger round-trips the tally; old saves default to zero', () {
      const ledger = BondLedger(
        dayEpoch: 7,
        earnedToday: 3,
        careKibbleToday: 12,
      );
      expect(BondLedger.fromMap(ledger.toMap()).careKibbleToday, 12);
      expect(
        BondLedger.fromMap(const {
          'dayEpoch': 7,
          'earnedToday': 3,
        }).careKibbleToday,
        0,
      );
    });
  });
}
