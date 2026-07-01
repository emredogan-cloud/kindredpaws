import '../migration.dart';

/// v6 → v7: the room-based home (Immersive Pet Experience). Adds the household
/// inventory — pantry, toys with affection progression, care supplies, and the
/// wardrobe closet — plus the persisted sleep state. Existing pets upgrade
/// with the same warm rescue starter kit a new pet receives (a couple of
/// meals, the bouncy ball, a vitamin chew), so no room ever greets a returning
/// player empty; the upgrade never orphans a pet (Risk R4).
class V6ToV7 extends Migration {
  const V6ToV7();

  @override
  int get fromVersion => 6;
  @override
  int get toVersion => 7;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    // Mirrors Inventory.starter() — literal here so the migration is frozen
    // in time even if the starter kit changes later.
    next['inventory'] ??= const {
      'pantry': {'food_kibble_bowl': 2, 'food_apple': 1},
      'toys': ['toy_bouncy_ball'],
      'toyAffinity': <String, int>{},
      'supplies': {'care_vitamin_chew': 1},
      'closet': <String>[],
      'equipped': <String>[],
    };
    next.putIfAbsent('sleepingSinceMs', () => null); // migrated pets are awake
    return next;
  }
}
