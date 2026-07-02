import '../migration.dart';

/// v8 → v9: Cozy Corners décor (GE-3, the Genre Evolution program). The
/// household inventory gains décor ownership, slot placements, and the one
/// wished-for item. Existing pets upgrade with empty corners and no wish —
/// the shop simply starts offering homeware; the upgrade never orphans a
/// pet (Risk R4).
class V8ToV9 extends Migration {
  const V8ToV9();

  @override
  int get fromVersion => 8;
  @override
  int get toVersion => 9;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    final inventory = Map<String, dynamic>.from(
      (next['inventory'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    inventory.putIfAbsent('decor', () => <String>[]);
    inventory.putIfAbsent('placements', () => <String, String>{});
    inventory.putIfAbsent('wishlistId', () => null);
    next['inventory'] = inventory;
    return next;
  }
}
