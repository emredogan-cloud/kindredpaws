import '../migration.dart';

/// v7 → v8: Daily Kindnesses (GE-1, the Genre Evolution program). Adds the
/// persisted kindness slate. Existing pets upgrade with no slate at all —
/// the engine quietly offers today's pair on the next session start, so the
/// upgrade is invisible and never orphans a pet (Risk R4).
class V7ToV8 extends Migration {
  const V7ToV8();

  @override
  int get fromVersion => 7;
  @override
  int get toVersion => 8;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    next.putIfAbsent('kindness', () => null);
    return next;
  }
}
