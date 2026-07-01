/// The persisted save (schema v7), mirroring GAME_TECHNICAL_SYSTEMS.md §3.4.
/// Holds the full runtime [PetState], the daily Bond [BondLedger], the Memory
/// Book facts, Keepsakes, the pet's evolving [PersonalityProfile], and the
/// household [Inventory] (the room-based home).
/// Versioned + migrated forward (Risk R4: no update may orphan a pet).
/// Serialization only — the simulation lives in `lib/game`.
library;

import '../game/model/bond.dart';
import '../game/model/care_meters.dart';
import '../game/model/care_streak.dart';
import '../game/model/inventory.dart';
import '../game/model/life_stage.dart';
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
  });

  /// Schema version this app writes. Bump + add a migration on change.
  static const int currentSchemaVersion = 7;

  /// Ordered migration chain → [currentSchemaVersion].
  static const List<Migration> migrations = [
    V1ToV2(),
    V2ToV3(),
    V3ToV4(),
    V4ToV5(),
    V5ToV6(),
    V6ToV7(),
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

  KindredSaveState copyWith({
    PetState? pet,
    BondLedger? ledger,
    List<MemoryFact>? facts,
    List<Keepsake>? keepsakes,
    List<String>? nestCosmeticIds,
    PersonalityProfile? personality,
    Inventory? inventory,
  }) => KindredSaveState(
    pet: pet ?? this.pet,
    ledger: ledger ?? this.ledger,
    facts: facts ?? this.facts,
    keepsakes: keepsakes ?? this.keepsakes,
    nestCosmeticIds: nestCosmeticIds ?? this.nestCosmeticIds,
    personality: personality ?? this.personality,
    inventory: inventory ?? this.inventory,
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
    },
  );

  /// Reads a v7 envelope. Upgrade older envelopes with [MigrationRunner] first.
  factory KindredSaveState.fromEnvelope(SaveEnvelope env) {
    if (env.schemaVersion != currentSchemaVersion) {
      throw StateError(
        'Expected schema v$currentSchemaVersion, got v${env.schemaVersion}; '
        'run MigrationRunner.upgrade() before deserializing.',
      );
    }
    final d = env.data;
    final bondMap = (d['bond'] as Map).cast<String, dynamic>();
    final bondValue = (bondMap['value'] as num).toInt();
    final nest = (d['nest'] as Map?)?.cast<String, dynamic>() ?? const {};
    final factsList = (d['memoryFacts'] as List? ?? const [])
        .map((e) => MemoryFact.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final pet = PetState(
      petId: d['petId'] as String,
      species: Species.fromId(d['species'] as String),
      name: d['name'] as String,
      lifeStage: LifeStage.fromId(d['lifeStage'] as String),
      meters: CareMeters.fromMap(
        (d['careMeters'] as Map).cast<String, dynamic>(),
      ),
      // Stage is recomputed from the authoritative value on load.
      bond: Bond(value: bondValue, stage: Bond.stageFor(bondValue)),
      careStreak: CareStreak.fromMap(
        (d['careStreak'] as Map).cast<String, dynamic>(),
      ),
      wallet: Wallet.fromMap((d['wallet'] as Map).cast<String, dynamic>()),
      activeDays: (d['activeDays'] as num?)?.toInt() ?? 1,
      lastActiveDayEpoch: (d['lastActiveDayEpoch'] as num?)?.toInt(),
      createdAtMs: (d['createdAtMs'] as num?)?.toInt() ?? 0,
      lastSimTimestampMs: (d['lastSimTimestampMs'] as num).toInt(),
      sleepingSinceMs: (d['sleepingSinceMs'] as num?)?.toInt(),
    );

    return KindredSaveState(
      pet: pet,
      ledger: BondLedger.fromMap(
        (d['bondLedger'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      facts: factsList,
      keepsakes: (d['keepsakes'] as List? ?? const [])
          .map((e) => Keepsake.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      nestCosmeticIds: (nest['cosmeticIds'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
      personality: PersonalityProfile.fromMap(
        (d['personality'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      inventory: Inventory.fromMap(
        (d['inventory'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
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
