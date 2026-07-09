import '../migration.dart';

/// v9 → v10: Seasons of Us (GE-5, the Genre Evolution program). Adds the
/// per-season active-day count. Existing pets upgrade with no window — the
/// next session starts counting the current season quietly; the upgrade
/// never orphans a pet (Risk R4).
class V9ToV10 extends Migration {
  const V9ToV10();

  @override
  int get fromVersion => 9;
  @override
  int get toVersion => 10;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    next.putIfAbsent('seasonProgress', () => null);
    return next;
  }
}
