/// The persisted save (schema v4), mirroring GAME_TECHNICAL_SYSTEMS.md §3.4.
/// Holds the full runtime [PetState] plus the daily Bond [BondLedger] and the
/// Memory Book facts. Versioned + migrated forward (Risk R4: no update may
/// orphan a pet). Serialization only — the simulation lives in `lib/game`.
library;

import '../game/model/bond.dart';
import '../game/model/care_meters.dart';
import '../game/model/care_streak.dart';
import '../game/model/life_stage.dart';
import '../game/model/pet_state.dart';
import '../game/model/species.dart';
import '../game/model/wallet.dart';
import '../game/sim/bond_engine.dart';
import '../heartmind/memory_fact.dart';
import 'migration.dart';
import 'migrations/v1_to_v2.dart';
import 'migrations/v2_to_v3.dart';
import 'migrations/v3_to_v4.dart';
import 'save_envelope.dart';

class KindredSaveState {
  const KindredSaveState({
    required this.pet,
    required this.ledger,
    required this.facts,
    this.nestCosmeticIds = const [],
  });

  /// Schema version this app writes. Bump + add a migration on change.
  static const int currentSchemaVersion = 4;

  /// Ordered migration chain → [currentSchemaVersion].
  static const List<Migration> migrations = [V1ToV2(), V2ToV3(), V3ToV4()];

  final PetState pet;
  final BondLedger ledger;
  final List<MemoryFact> facts;
  final List<String> nestCosmeticIds;

  KindredSaveState copyWith({
    PetState? pet,
    BondLedger? ledger,
    List<MemoryFact>? facts,
    List<String>? nestCosmeticIds,
  }) => KindredSaveState(
    pet: pet ?? this.pet,
    ledger: ledger ?? this.ledger,
    facts: facts ?? this.facts,
    nestCosmeticIds: nestCosmeticIds ?? this.nestCosmeticIds,
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
    },
  );

  /// Reads a v4 envelope. Upgrade older envelopes with [MigrationRunner] first.
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
    );

    return KindredSaveState(
      pet: pet,
      ledger: BondLedger.fromMap(
        (d['bondLedger'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      facts: factsList,
      nestCosmeticIds: (nest['cosmeticIds'] as List? ?? const [])
          .map((e) => e as String)
          .toList(),
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
