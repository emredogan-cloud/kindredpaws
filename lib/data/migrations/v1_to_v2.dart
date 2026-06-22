import '../migration.dart';

/// v1 → v2: introduce the currency wallet (Kibble / Heartstones / Compassion
/// Coins). Older saves predate the economy; default a zeroed wallet so the
/// upgrade never loses a pet.
class V1ToV2 extends Migration {
  const V1ToV2();

  @override
  int get fromVersion => 1;
  @override
  int get toVersion => 2;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);
    next['wallet'] ??= {'kibble': 0, 'heartstones': 0, 'compassionCoins': 0};
    return next;
  }
}
