import '../migration.dart';

/// v4 → v5: introduce the Keepsake scrapbook (P2-5). Older saves get an empty
/// collection — the upgrade never orphans a pet (Risk R4).
class V4ToV5 extends Migration {
  const V4ToV5();

  @override
  int get fromVersion => 4;
  @override
  int get toVersion => 5;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    next['keepsakes'] ??= <Map<String, dynamic>>[];
    return next;
  }
}
