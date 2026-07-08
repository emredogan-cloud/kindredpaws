/// The persisted save (schema v10), mirroring GAME_TECHNICAL_SYSTEMS.md §3.4.
/// Holds the full runtime [PetState], the daily Bond [BondLedger], the Memory
/// Book facts, Keepsakes, the pet's evolving [PersonalityProfile], the
/// household [Inventory] (the room-based home), and the Daily Kindness slate
/// (GE-1, the Genre Evolution program).
/// Versioned + migrated forward (Risk R4: no update may orphan a pet).
/// Serialization only — the simulation lives in `lib/game`.
library;

import '../game/model/bond.dart';
import '../game/model/care_meters.dart';
import '../game/model/care_streak.dart';
import '../game/model/inventory.dart';
import '../game/model/kindness.dart';
import '../game/model/life_stage.dart';
import '../game/model/season_progress.dart';
import '../game/model/pet_state.dart';
import '../game/model/species.dart';
import '../game/model/wallet.dart';
import '../game/sim/bond_engine.dart';
import '../heartmind/memory_fact.dart';
import '../heartmind/personality.dart';
import '../keepsake/keepsake.dart';
import 'migration.dart';
import 'migrations/v1_to_v2.dart';
import 'migrations/v2_to_v3.dart';
import 'migrations/v3_to_v4.dart';
import 'migrations/v4_to_v5.dart';
import 'migrations/v5_to_v6.dart';
import 'migrations/v6_to_v7.dart';
import 'migrations/v7_to_v8.dart';
import 'migrations/v8_to_v9.dart';
import 'migrations/v9_to_v10.dart';
import 'save_envelope.dart';

class KindredSaveState {
  const KindredSaveState({
    required this.pet,
    required this.ledger,
    required this.facts,
    this.keepsakes = const [],
    this.nestCosmeticIds = const [],
    this.personality = PersonalityProfile.neutral,
    this.inventory = const Inventory(),
    this.kindness,
    this.seasonProgress,
  });

  /// Schema version this app writes. Bump + add a migration on change.
  static const int currentSchemaVersion = 10;

  /// Ordered migration chain → [currentSchemaVersion].
  static const List<Migration> migrations = [
    V1ToV2(),
    V2ToV3(),
    V3ToV4(),
    V4ToV5(),
    V5ToV6(),
    V6ToV7(),
    V7ToV8(),
    V8ToV9(),
    V9ToV10(),
  ];

  final PetState pet;
  final BondLedger ledger;
  final List<MemoryFact> facts;
  final List<Keepsake> keepsakes;
  final List<String> nestCosmeticIds;

  /// The pet's evolving personality (drifts with care; persisted from v6 so it
  /// survives app restarts — "Only MY pet" must be stable, not reset each open).
  final PersonalityProfile personality;

  /// The household inventory — pantry, toys (+affection), care supplies, and
  /// the wardrobe closet (persisted from v7, the room-based home).
  final Inventory inventory;

  /// Today's Daily Kindness slate (persisted from v8; null until the first
  /// session of the day offers a pair — the engine fills it lazily).
  final KindnessState? kindness;

  /// Seasons-of-Us active-day count for the current season-window
  /// (persisted from v10; null until the first counted day).
  final SeasonProgress? seasonProgress;

  KindredSaveState copyWith({
    PetState? pet,
    BondLedger? ledger,
    List<MemoryFact>? facts,
    List<Keepsake>? keepsakes,
    List<String>? nestCosmeticIds,
    PersonalityProfile? personality,
    Inventory? inventory,
    KindnessState? kindness,
    SeasonProgress? seasonProgress,
  }) => KindredSaveState(
    pet: pet ?? this.pet,
    ledger: ledger ?? this.ledger,
    facts: facts ?? this.facts,
    keepsakes: keepsakes ?? this.keepsakes,
    nestCosmeticIds: nestCosmeticIds ?? this.nestCosmeticIds,
    personality: personality ?? this.personality,
    inventory: inventory ?? this.inventory,
    kindness: kindness ?? this.kindness,
    seasonProgress: seasonProgress ?? this.seasonProgress,
  );

  SaveEnvelope toEnvelope() => SaveEnvelope(
    schemaVersion: currentSchemaVersion,
    data: {
      'petId': pet.petId,
      'species': pet.species.id,
      'name': pet.name,
      'lifeStage': pet.lifeStage.id,
      'careMeters': pet.meters.toMap(),
      'bond': {'value': pet.bond.value, 'stage': pet.bond.stage.displayName},
      'nest': {'cosmeticIds': nestCosmeticIds},
      'careStreak': pet.careStreak.toMap(),
      'wallet': pet.wallet.toMap(),
      'activeDays': pet.activeDays,
      'lastActiveDayEpoch': pet.lastActiveDayEpoch,
      'createdAtMs': pet.createdAtMs,
      'lastSimTimestampMs': pet.lastSimTimestampMs,
      'bondLedger': ledger.toMap(),
      'memoryFacts': facts.map((f) => f.toJson()).toList(),
      'keepsakes': keepsakes.map((k) => k.toJson()).toList(),
      'personality': personality.toMap(),
      'inventory': inventory.toMap(),
      'sleepingSinceMs': pet.sleepingSinceMs,
      'kindness': kindness?.toMap(),
      'seasonProgress': seasonProgress?.toMap(),
    },
  );

  /// Reads a current-schema envelope. Upgrade older ones with
  /// [MigrationRunner] first.
  ///
  /// Deserialization is TOTAL for everything except `petId` (KP-010): a
  /// missing or malformed field falls back to a safe default instead of
  /// throwing, because one bad field must never cost a player the whole pet.
  /// `petId` stays strict — it is the identity anchor: without it the save
  /// cannot be keyed for cloud restore, so the caller's recovery path (which
  /// quarantines the blob and never overwrites it) is the honest outcome.
  factory KindredSaveState.fromEnvelope(SaveEnvelope env) {
    if (env.schemaVersion != currentSchemaVersion) {
      throw StateError(
        'Expected schema v$currentSchemaVersion, got v${env.schemaVersion}; '
        'run MigrationRunner.upgrade() before deserializing.',
      );
    }
    final d = env.data;

    final petId = d['petId'];
    if (petId is! String || petId.isEmpty) {
      throw const FormatException('save has no petId — identity unrecoverable');
    }

    final bondMap = _mapOrEmpty(d['bond']);
    final bondValue = _intOr(bondMap['value']) ?? 0;
    final nest = _mapOrEmpty(d['nest']);
    final species = Species.fromId(_stringOr(d['species'], ''));
    final createdAtMs = _intOr(d['createdAtMs']) ?? 0;

    final pet = PetState(
      petId: petId,
      species: species,
      name: _stringOr(d['name'], species.defaultName),
      lifeStage: LifeStage.fromId(_stringOr(d['lifeStage'], '')),
      meters: CareMeters.fromMap(_mapOrEmpty(d['careMeters'])),
      // Stage is recomputed from the authoritative value on load.
      bond: Bond(value: bondValue, stage: Bond.stageFor(bondValue)),
      careStreak: CareStreak.fromMap(_mapOrEmpty(d['careStreak'])),
      wallet: Wallet.fromMap(_mapOrEmpty(d['wallet'])),
      activeDays: _intOr(d['activeDays']) ?? 1,
      lastActiveDayEpoch: _intOr(d['lastActiveDayEpoch']),
      createdAtMs: createdAtMs,
      // A lost sim timestamp resumes from creation: the offline catch-up cap
      // (7 days) bounds the elapsed decay, so this is always gentle.
      lastSimTimestampMs: _intOr(d['lastSimTimestampMs']) ?? createdAtMs,
      sleepingSinceMs: _intOr(d['sleepingSinceMs']),
    );

    return KindredSaveState(
      pet: pet,
      ledger: _section(
        () => BondLedger.fromMap(_mapOrEmpty(d['bondLedger'])),
        BondLedger.empty,
      ),
      // One corrupt scrapbook entry must not take the pet down with it: parse
      // per-item, skip what cannot be read, keep the rest.
      facts: _lenientList(d['memoryFacts'], MemoryFact.fromJson),
      keepsakes: _lenientList(d['keepsakes'], Keepsake.fromJson),
      nestCosmeticIds: (nest['cosmeticIds'] as List? ?? const [])
          .whereType<String>()
          .toList(),
      personality: _section(
        () => PersonalityProfile.fromMap(_mapOrEmpty(d['personality'])),
        PersonalityProfile.neutral,
      ),
      inventory: _section(
        () => Inventory.fromMap(_mapOrEmpty(d['inventory'])),
        const Inventory(),
      ),
      // Daily/seasonal slates regenerate on their own — corrupt ones drop.
      kindness: d['kindness'] == null
          ? null
          : _section(
              () => KindnessState.fromMap(_mapOrEmpty(d['kindness'])),
              null,
            ),
      seasonProgress: d['seasonProgress'] == null
          ? null
          : _section(
              () => SeasonProgress.fromMap(_mapOrEmpty(d['seasonProgress'])),
              null,
            ),
    );
  }

  static Map<String, dynamic> _mapOrEmpty(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const <String, dynamic>{};

  static String _stringOr(Object? v, String fallback) =>
      v is String && v.isNotEmpty ? v : fallback;

  static int? _intOr(Object? v) => v is num ? v.toInt() : null;

  /// Parse a subsystem section, falling back to [fallback] if its inner shape
  /// is corrupt — the pet survives; the subsystem state resets.
  static T _section<T>(T Function() parse, T fallback) {
    try {
      return parse();
    } catch (_) {
      return fallback;
    }
  }

  /// Parse a list of records item-by-item, skipping unreadable entries.
  static List<T> _lenientList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    final out = <T>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(fromJson(e.cast<String, dynamic>()));
      } catch (_) {
        // Skip the one bad record; keep every readable one.
      }
    }
    return out;
  }

  /// A fresh save for a newly rescued pet.
  factory KindredSaveState.newPet({
    required String petId,
    required String species,
    required String name,
    required int nowMs,
  }) => KindredSaveState(
    pet: PetState.newlyRescued(
      petId: petId,
      species: Species.fromId(species),
      name: name,
      nowMs: nowMs,
    ),
    ledger: BondLedger.empty,
    facts: const [],
  );
}
