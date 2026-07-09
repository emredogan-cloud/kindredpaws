/// Care Streak engine (GAMEPLAY_AND_PROGRESSION_BIBLE.md §11.1–11.2, Risk R6).
/// Forgiving by construction: a missed day is auto-protected by banked Streak
/// Warmth ("stayed warm 🔥"); only when warmth runs out does the count reset —
/// and even then NOTHING is taken from the pet or the Bond. A recently-broken
/// streak can be repaired once for Kibble.
library;

import '../model/care_streak.dart';
import 'sim_config.dart';

class CareStreakUpdate {
  const CareStreakUpdate({
    required this.streak,
    required this.isNewCareDay,
    required this.freezeUsed,
    required this.brokeFromCount,
  });

  final CareStreak streak;

  /// True if this is the first care action of a new day (worth +6 Bond).
  final bool isNewCareDay;

  /// True if banked warmth absorbed a gap (UI shows "stayed warm", not "lost").
  final bool freezeUsed;

  /// If > 0, the streak reset and this was the count before the break — offer a
  /// one-time repair back to it.
  final int brokeFromCount;
}

class CareStreakEngine {
  const CareStreakEngine(this.config);

  final SimConfig config;

  /// Registers a care action on [todayEpochDay] (days since epoch, in the
  /// player's local frame).
  CareStreakUpdate registerCareDay(CareStreak streak, int todayEpochDay) {
    final last = streak.lastCareDayEpoch;

    // Same day — or an EARLIER day (clock set back / DST underflow): no
    // change either way. A negative gap used to fall through `gap <= 0` into
    // "consecutive", incrementing the streak AND dragging the anchor
    // backwards, corrupting all later gap math (KP-019). The anchor only
    // ever moves forward.
    if (last != null && todayEpochDay <= last) {
      return CareStreakUpdate(
        streak: streak,
        isNewCareDay: false,
        freezeUsed: false,
        brokeFromCount: 0,
      );
    }

    final cap = config.streakWarmthCap;
    int newCount;
    var freezeUsed = false;
    var brokeFromCount = 0;
    var warmth = streak.warmthBanked;

    if (last == null) {
      newCount = 1; // first care day ever
    } else {
      final gap = todayEpochDay - last - 1; // missed days strictly between
      if (gap <= 0) {
        newCount = streak.count + 1; // consecutive
      } else if (warmth >= gap) {
        warmth -= gap; // Streak Warmth absorbs the gap
        freezeUsed = true;
        newCount = streak.count + 1;
      } else {
        brokeFromCount = streak.count; // broke — but never punished
        newCount = 1;
      }
    }

    // Warmth regenerates as you play (forgiving): +1 per care day, up to cap.
    final regenWarmth = warmth < cap ? warmth + 1 : cap;

    return CareStreakUpdate(
      streak: streak.copyWith(
        count: newCount,
        lastCareDayEpoch: todayEpochDay,
        warmthBanked: regenWarmth,
      ),
      isNewCareDay: true,
      freezeUsed: freezeUsed,
      brokeFromCount: brokeFromCount,
    );
  }

  /// One-time Streak Repair: restore a just-broken streak to [toCount]. The
  /// caller is responsible for charging [config.streakRepairKibbleCost] Kibble
  /// (or a rewarded ad). Framed as a welcome-back, never a penalty.
  CareStreak repair(CareStreak streak, int toCount) =>
      streak.copyWith(count: toCount);
}
