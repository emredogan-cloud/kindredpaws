import '../migration.dart';

/// v2 → v3: introduce the forgiving Care Streak (+ Streak Warmth). Older saves
/// get a fresh, never-punitive streak record (Risk R6).
class V2ToV3 extends Migration {
  const V2ToV3();

  @override
  int get fromVersion => 2;
  @override
  int get toVersion => 3;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    // Shape must match KindredSaveState's v3 careStreak exactly (count +
    // warmthBanked); the day-tracker field arrives with the Phase-1 streak
    // logic via a future v3->v4 migration, so migration/container stay in sync.
    next['careStreak'] ??= {'count': 0, 'warmthBanked': 0};
    return next;
  }
}
