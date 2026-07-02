import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/bond.dart';
import 'package:kindredpaws/game/model/mood.dart';
import 'package:kindredpaws/game/sim/bond_engine.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

void main() {
  group('BondStage thresholds (§7.1)', () {
    test('canonical thresholds', () {
      expect(BondStage.stranger.threshold, 0);
      expect(BondStage.friend.threshold, 250);
      expect(BondStage.companion.threshold, 1200);
      expect(BondStage.kindred.threshold, 4000);
      expect(BondStage.soulmate.threshold, 10000);
    });

    test('stageFor resolves the right stage at and around boundaries', () {
      expect(Bond.stageFor(0), BondStage.stranger);
      expect(Bond.stageFor(249), BondStage.stranger);
      expect(Bond.stageFor(250), BondStage.friend);
      expect(Bond.stageFor(1199), BondStage.friend);
      expect(Bond.stageFor(1200), BondStage.companion);
      expect(Bond.stageFor(4000), BondStage.kindred);
      expect(Bond.stageFor(10000), BondStage.soulmate);
      expect(Bond.stageFor(999999), BondStage.soulmate);
    });
  });

  group('Bond is monotonic non-decreasing (Risk R6)', () {
    test('add positive raises value + re-resolves stage', () {
      final b = Bond.initial.add(250);
      expect(b.value, 250);
      expect(b.stage, BondStage.friend);
    });

    test('add negative is ignored — the Bond never falls', () {
      final b = Bond.initial.add(300).add(-1000);
      expect(b.value, 300);
      expect(b.stage, BondStage.friend);
    });
  });

  group('BondEngine.award', () {
    const engine = BondEngine(SimConfig());
    const today = 20000;

    test('applies the Joyful ×1.15 modifier', () {
      final a = engine.award(
        bond: Bond.initial,
        rawPoints: 10,
        mood: Mood.joyful,
        ledger: BondLedger.empty,
        todayEpochDay: today,
      );
      expect(a.awarded, 12); // round(10 * 1.15)
      expect(a.bond.value, 12);
    });

    test('clamps to the daily soft cap (≈55) and tracks the ledger', () {
      final a = engine.award(
        bond: Bond.initial,
        rawPoints: 100,
        mood: Mood.content,
        ledger: BondLedger.empty,
        todayEpochDay: today,
      );
      expect(a.awarded, 55); // capped
      // Further same-day awards get nothing.
      final b = engine.award(
        bond: a.bond,
        rawPoints: 100,
        mood: Mood.content,
        ledger: a.ledger,
        todayEpochDay: today,
      );
      expect(b.awarded, 0);
      expect(b.bond.value, 55);
    });

    test('ledger rolls over on a new day', () {
      final day1 = engine.award(
        bond: Bond.initial,
        rawPoints: 100,
        mood: Mood.content,
        ledger: BondLedger.empty,
        todayEpochDay: today,
      );
      final day2 = engine.award(
        bond: day1.bond,
        rawPoints: 30,
        mood: Mood.content,
        ledger: day1.ledger,
        todayEpochDay: today + 1,
      );
      expect(day2.awarded, 30); // fresh cap budget the next day
      expect(day2.ledger.earnedToday, 30);
    });

    test('ignoreDailyCap lets macro milestones exceed the cap', () {
      final a = engine.award(
        bond: Bond.initial,
        rawPoints: 50,
        mood: Mood.content,
        ledger: const BondLedger(dayEpoch: today, earnedToday: 55),
        todayEpochDay: today,
        ignoreDailyCap: true,
      );
      expect(a.awarded, 50);
    });
  });

  group('BondLedger (daily soft-cap accounting)', () {
    const today = 20000;

    test('forDay returns self on the same day', () {
      const l = BondLedger(dayEpoch: today, earnedToday: 40);
      expect(identical(l.forDay(today), l), isTrue);
    });

    test('forDay resets earnedToday when the day rolls over', () {
      const l = BondLedger(dayEpoch: today, earnedToday: 40);
      final next = l.forDay(today + 1);
      expect(next.dayEpoch, today + 1);
      expect(next.earnedToday, 0);
    });

    test('toMap/fromMap round-trips losslessly', () {
      const l = BondLedger(dayEpoch: today, earnedToday: 33);
      final back = BondLedger.fromMap(l.toMap());
      expect(back.dayEpoch, today);
      expect(back.earnedToday, 33);
    });

    test('fromMap tolerates a null day (a fresh ledger)', () {
      final l = BondLedger.fromMap(const {'dayEpoch': null, 'earnedToday': 0});
      expect(l.dayEpoch, isNull);
      expect(l.earnedToday, 0);
    });
  });
}
