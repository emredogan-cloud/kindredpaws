import '../migration.dart';

/// v3 → v4: the Phase-1 core-loop save. Restructures the flat v3 shape into the
/// nested GAME_TECHNICAL_SYSTEMS.md §3.4 shape and adds the fields the live
/// simulation needs — the streak day-tracker (`lastCareDay`), `activeDays` +
/// `lastActiveDayEpoch` (the life-stage dual gate), `createdAtMs` (Gotcha Day),
/// the daily Bond ledger, and the Memory Book facts. Every addition defaults
/// safely so the upgrade never orphans a pet (Risk R4).
class V3ToV4 extends Migration {
  const V3ToV4();

  @override
  int get fromVersion => 3;
  @override
  int get toVersion => 4;

  static const Map<String, String> _lifeStageIds = {
    'Pup/Kit': 'pupKit',
    'Young One': 'youngOne',
    'Grown': 'grown',
  };

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) {
    final next = Map<String, dynamic>.from(data);

    // lifeStage: display name → stable id (idempotent if already an id).
    final ls = next['lifeStage'] as String?;
    next['lifeStage'] = _lifeStageIds[ls] ?? ls ?? 'pupKit';

    // bond: flat → nested {value, stage}. Skip when already nested — a
    // re-applied step must be a no-op, never a bond reset (KP-022).
    if (next['bond'] is! Map) {
      next['bond'] = {
        'value': (next.remove('bondValue') as num?)?.toInt() ?? 0,
        'stage': next.remove('bondStage') ?? 'Stranger',
      };
    }

    // nest: cosmetic id list → nested (same idempotency guard).
    if (next['nest'] is! Map) {
      next['nest'] = {
        'cosmeticIds': next.remove('nestCosmeticIds') ?? <String>[],
      };
    }

    // careStreak: ensure the day-tracker field exists.
    final cs = Map<String, dynamic>.from(
      (next['careStreak'] as Map?) ?? const {},
    );
    cs['count'] ??= 0;
    cs['warmthBanked'] ??= 0;
    cs.putIfAbsent('lastCareDay', () => null);
    next['careStreak'] = cs;

    // New v4 fields.
    next['activeDays'] ??= 1;
    next.putIfAbsent('lastActiveDayEpoch', () => null);
    next['createdAtMs'] ??= next['lastSimTimestampMs'] ?? 0;
    next['bondLedger'] ??= {'dayEpoch': null, 'earnedToday': 0};
    next['memoryFacts'] ??= <Map<String, dynamic>>[];

    return next;
  }
}
