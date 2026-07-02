import '../migration.dart';

/// v5 → v6: persist the pet's evolving [PersonalityProfile] (P3-4). Older saves
/// had personality only in-memory (reset to neutral every launch); they upgrade
/// to an explicit neutral profile so the pet starts from where the design
/// expects and drifts forward from there — the upgrade never orphans a pet
/// (Risk R4).
class V5ToV6 extends Migration {
  const V5ToV6();

  @override
  int get fromVersion => 5;
  @override
  int get toVersion => 6;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    next['personality'] ??= const {
      'playfulness': 2,
      'cuddliness': 2,
      'chattiness': 2,
      'bravery': 2,
    };
    return next;
  }
}
