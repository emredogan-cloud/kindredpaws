import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_streak.dart';
import 'package:kindredpaws/game/sim/care_streak_engine.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';

void main() {
  const engine = CareStreakEngine(SimConfig()); // warmthCap = 2
  const dayD = 20000;

  test('first care ever starts a 1-day streak + banks warmth', () {
    final u = engine.registerCareDay(CareStreak.initial, dayD);
    expect(u.streak.count, 1);
    expect(u.streak.lastCareDayEpoch, dayD);
    expect(u.streak.warmthBanked, 1); // regen +1
    expect(u.isNewCareDay, isTrue);
  });

  test('caring again the same day does not re-increment', () {
    const s = CareStreak(count: 3, lastCareDayEpoch: dayD, warmthBanked: 2);
    final u = engine.registerCareDay(s, dayD);
    expect(u.isNewCareDay, isFalse);
    expect(u.streak.count, 3);
  });

  test('consecutive days increment + cap warmth at 2', () {
    const s = CareStreak(count: 1, lastCareDayEpoch: dayD, warmthBanked: 1);
    final u = engine.registerCareDay(s, dayD + 1);
    expect(u.streak.count, 2);
    expect(u.streak.warmthBanked, 2); // regen to cap
  });

  test('Streak Warmth auto-protects a missed day (stays warm 🔥)', () {
    const s = CareStreak(count: 3, lastCareDayEpoch: dayD, warmthBanked: 2);
    final u = engine.registerCareDay(s, dayD + 2); // gap of 1 missed day
    expect(u.freezeUsed, isTrue);
    expect(u.streak.count, 4); // streak continues
    expect(u.brokeFromCount, 0);
  });

  test('a gap beyond banked warmth resets the streak — but NEVER punishes', () {
    const s = CareStreak(count: 5, lastCareDayEpoch: dayD, warmthBanked: 0);
    final u = engine.registerCareDay(s, dayD + 3); // gap of 2, no warmth
    expect(u.streak.count, 1); // reset, not negative
    expect(u.brokeFromCount, 5); // remembered for an optional repair
    expect(u.freezeUsed, isFalse);
    // The engine touches NOTHING about the Bond — breaking is never punitive.
  });

  test('repair restores a just-broken streak to its prior count', () {
    const broken = CareStreak(
      count: 1,
      lastCareDayEpoch: dayD,
      warmthBanked: 1,
    );
    final repaired = engine.repair(broken, 5);
    expect(repaired.count, 5);
  });
}
