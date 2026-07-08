/// KP-015 / KP-016 / KP-018 / KP-019 — the local-time + monotonic-clock
/// cluster. Day boundaries, notification anchors, streak days, and kindness
/// rollovers live on the PLAYER's local clock and only ever move forward:
/// no device-clock change may mint bonuses, Bond, growth days, or fresh
/// kindness slates, and no anchor may land at 2am because it was computed
/// in UTC.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/local_day.dart';
import 'package:kindredpaws/game/model/care_streak.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/bond_engine.dart';
import 'package:kindredpaws/game/sim/care_streak_engine.dart';
import 'package:kindredpaws/game/sim/game_simulation.dart';
import 'package:kindredpaws/game/sim/kindness_engine.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';

import '../../support/harness.dart';

const int _hour = Duration.millisecondsPerHour;
const int _day = Duration.millisecondsPerDay;

/// Fixed offsets modelling real zones (UTC+13 Tonga, UTC-8 California).
Duration plus13(int _) => const Duration(hours: 13);
Duration minus8(int _) => const Duration(hours: -8);

/// A fake DST zone: +1h before [dstFlipMs], +2h at/after it.
Duration Function(int) dstAt(int dstFlipMs) =>
    (ms) => Duration(hours: ms >= dstFlipMs ? 2 : 1);

void main() {
  group('local_day primitives (KP-018)', () {
    test('localDayOf flips at the LOCAL midnight, not UTC', () {
      // 13:00 UTC on epoch-day N is already "tomorrow" at UTC+13 (02:00),
      // and still "yesterday evening" at UTC-8 (05:00 same day).
      const ms = kDay0 + 13 * _hour;
      expect(localDayOf(ms, utcOffsetNone), kDay0 ~/ _day);
      expect(localDayOf(ms, plus13), kDay0 ~/ _day + 1);
      expect(localDayOf(ms, minus8), kDay0 ~/ _day);
    });

    test('msAtLocalHour lands on the local wall-clock hour (KP-016)', () {
      const day = kDay0 ~/ _day;
      // 10am at UTC+13 is 21:00 UTC the previous day.
      final at = msAtLocalHour(day, 10, plus13);
      expect(at, day * _day + 10 * _hour - 13 * _hour);
      // 10am at UTC-8 is 18:00 UTC the same day.
      expect(msAtLocalHour(day, 10, minus8), day * _day + 18 * _hour);
    });

    test('msAtLocalHour evaluates DST at the TARGET instant', () {
      const day = kDay0 ~/ _day;
      // The flip to +2h happens well before the target hour.
      final dst = dstAt(kDay0 - 30 * _day);
      expect(msAtLocalHour(day, 10, dst), day * _day + 8 * _hour);
      // A zone still at +1h at the target keeps the +1h conversion.
      final preDst = dstAt(kDay0 + 30 * _day);
      expect(msAtLocalHour(day, 10, preDst), day * _day + 9 * _hour);
    });
  });

  group('resolveOnResume — clock attacks mint nothing (KP-015)', () {
    GameSimulation sim([UtcOffsetAt offset = utcOffsetNone]) =>
        GameSimulation(const SimConfig(), utcOffsetAt: offset);

    PetState fresh() => PetState.newlyRescued(
      petId: kTestPetId,
      species: Species.puppy,
      name: 'Biscuit',
      nowMs: kDay0,
    );

    test('a genuine forward day grants exactly one daily set', () {
      final s = sim();
      final r1 = s.resolveOnResume(
        state: fresh(),
        ledger: BondLedger.empty,
        nowMs: kDay0 + _day + _hour,
      );
      expect(r1.isNewDay, isTrue);
      expect(r1.dailyKibble, greaterThan(0));
    });

    test(
      'setting the clock BACK a day re-grants nothing and moves nothing',
      () {
        final s = sim();
        final afterDay1 = s.resolveOnResume(
          state: fresh(),
          ledger: BondLedger.empty,
          nowMs: kDay0 + _day + _hour,
        );
        final kibbleAfter = afterDay1.state.wallet.kibble;
        final bondAfter = afterDay1.state.bond.value;

        // The attack: clock back 24h, cold-start again (resolveOnResume runs
        // on every foreground). `!=` used to treat this as a NEW day.
        final attacked = s.resolveOnResume(
          state: afterDay1.state,
          ledger: afterDay1.ledger,
          nowMs: kDay0 + _hour,
        );
        expect(attacked.isNewDay, isFalse);
        expect(attacked.dailyKibble, 0);
        expect(attacked.greetingBond, 0);
        expect(attacked.state.wallet.kibble, kibbleAfter);
        expect(attacked.state.bond.value, bondAfter);
        expect(attacked.state.activeDays, afterDay1.state.activeDays);
        // Anchors never move backward (no corrupted later gap math).
        expect(
          attacked.state.lastActiveDayEpoch,
          afterDay1.state.lastActiveDayEpoch,
        );
        expect(
          attacked.state.lastSimTimestampMs,
          afterDay1.state.lastSimTimestampMs,
        );
      },
    );

    test('back-and-forth flapping grants the day exactly once', () {
      final s = sim();
      var state = fresh();
      var ledger = BondLedger.empty;
      var grants = 0;
      // Flap the clock across the same midnight ten times.
      for (var i = 0; i < 10; i++) {
        final ms = (i % 2 == 0) ? kDay0 + _day + _hour : kDay0 + _hour;
        final r = s.resolveOnResume(state: state, ledger: ledger, nowMs: ms);
        if (r.dailyKibble > 0) grants++;
        state = r.state;
        ledger = r.ledger;
      }
      expect(grants, 1);
    });

    test('day boundaries follow the local frame (KP-018)', () {
      // 13:00 UTC: a UTC+13 player has crossed local midnight; a UTC sim
      // has not. Same instant, different (correct) local answers.
      final utcSim = sim();
      final tongaSim = sim(plus13);
      const at = kDay0 + 13 * _hour;
      expect(
        utcSim
            .resolveOnResume(
              state: fresh(),
              ledger: BondLedger.empty,
              nowMs: at,
            )
            .isNewDay,
        isFalse,
      );
      final tongaPet = PetState.newlyRescued(
        petId: kTestPetId,
        species: Species.puppy,
        name: 'Biscuit',
        nowMs: kDay0,
        utcOffsetAt: plus13,
      );
      expect(
        tongaSim
            .resolveOnResume(
              state: tongaPet,
              ledger: BondLedger.empty,
              nowMs: at,
            )
            .isNewDay,
        isTrue,
      );
    });
  });

  group('CareStreakEngine — backward days never count (KP-019)', () {
    const engine = CareStreakEngine(SimConfig());

    test('a backward day is a no-op (no increment, anchor unmoved)', () {
      const streak = CareStreak(
        count: 5,
        lastCareDayEpoch: 100,
        warmthBanked: 2,
      );
      final update = engine.registerCareDay(streak, 99);
      expect(update.isNewCareDay, isFalse);
      expect(update.streak.count, 5);
      expect(update.streak.lastCareDayEpoch, 100);
      expect(update.streak.warmthBanked, 2);
    });

    test('forward adjacent day still increments normally', () {
      const streak = CareStreak(
        count: 5,
        lastCareDayEpoch: 100,
        warmthBanked: 2,
      );
      final update = engine.registerCareDay(streak, 101);
      expect(update.isNewCareDay, isTrue);
      expect(update.streak.count, 6);
      expect(update.streak.lastCareDayEpoch, 101);
    });
  });

  group('KindnessEngine — slate is local + monotonic (KP-015/KP-018)', () {
    const engine = KindnessEngine();

    test('a backward day keeps today\'s slate (no re-farmable pair)', () {
      final slate = engine.today(nowMs: kDay0 + _day, petId: kTestPetId);
      final attacked = engine.today(
        nowMs: kDay0, // clock set back a day
        petId: kTestPetId,
        prior: slate,
      );
      expect(identical(attacked, slate), isTrue);
    });

    test('the kindness day flips at local midnight', () {
      final utcSlate = engine.today(
        nowMs: kDay0 + 13 * _hour,
        petId: kTestPetId,
      );
      final tongaSlate = engine.today(
        nowMs: kDay0 + 13 * _hour,
        petId: kTestPetId,
        utcOffsetAt: plus13,
      );
      expect(tongaSlate.dayEpoch, utcSlate.dayEpoch + 1);
    });
  });

  group('notification anchors are local (KP-016)', () {
    test('the 10am/19pm anchors land on local wall-clock hours', () async {
      final utc = InMemoryNotificationScheduler();
      final tonga = InMemoryNotificationScheduler(utcOffsetAt: plus13);
      final california = InMemoryNotificationScheduler(utcOffsetAt: minus8);
      for (final s in [utc, tonga, california]) {
        await s.scheduleDailyPresence(
          petName: 'Biscuit',
          fromMs: kDay0 + _hour,
          dailyCap: 2,
          days: 1,
        );
      }
      int localHourOf(int whenMs, UtcOffsetAt offset) =>
          ((whenMs + offset(whenMs).inMilliseconds) % _day) ~/ _hour;

      for (final n in utc.scheduled) {
        expect([10, 19], contains(localHourOf(n.whenMs, utcOffsetNone)));
      }
      for (final n in tonga.scheduled) {
        expect([10, 19], contains(localHourOf(n.whenMs, plus13)));
      }
      for (final n in california.scheduled) {
        expect([10, 19], contains(localHourOf(n.whenMs, minus8)));
      }
      // And the absolute instants genuinely differ across zones.
      expect(
        tonga.scheduled.first.whenMs,
        isNot(california.scheduled.first.whenMs),
      );
    });
  });
}
