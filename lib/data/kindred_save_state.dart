/// The current persisted save shape (schema v3), mirroring the illustrative
/// snapshot in GAME_TECHNICAL_SYSTEMS.md §3.4. This is a **data container with
/// serialization only** — it holds the pet's persisted state but contains no
/// simulation/decay/interaction logic (that is Phase 1).
library;

import 'migration.dart';
import 'migrations/v1_to_v2.dart';
import 'migrations/v2_to_v3.dart';
import 'save_envelope.dart';

class KindredSaveState {
  const KindredSaveState({
    required this.petId,
    required this.species,
    required this.name,
    required this.lifeStage,
    required this.careMeters,
    required this.bondValue,
    required this.bondStage,
    required this.nestCosmeticIds,
    required this.careStreakCount,
    required this.warmthBanked,
    required this.wallet,
    required this.lastSimTimestampMs,
  });

  /// The save schema version this app writes. Bump + add a migration on change.
  static const int currentSchemaVersion = 3;

  /// The migration chain (registered with a MigrationRunner) for upgrading
  /// older blobs forward to [currentSchemaVersion].
  static const List<Migration> migrations = [V1ToV2(), V2ToV3()];

  final String petId;
  final String species; // 'puppy' | 'kitten'
  final String name;
  final String lifeStage; // 'Pup/Kit' | 'Young One' | 'Grown'
  final Map<String, double> careMeters; // hunger/energy/hygiene/happiness
  final int bondValue;
  final String bondStage; // Stranger..Soulmate
  final List<String> nestCosmeticIds;
  final int careStreakCount;
  final int warmthBanked;
  final Map<String, int> wallet; // kibble/heartstones/compassionCoins
  final int lastSimTimestampMs;

  SaveEnvelope toEnvelope() => SaveEnvelope(
    schemaVersion: currentSchemaVersion,
    data: {
      'petId': petId,
      'species': species,
      'name': name,
      'lifeStage': lifeStage,
      'careMeters': careMeters,
      'bondValue': bondValue,
      'bondStage': bondStage,
      'nestCosmeticIds': nestCosmeticIds,
      'careStreak': {'count': careStreakCount, 'warmthBanked': warmthBanked},
      'wallet': wallet,
      'lastSimTimestampMs': lastSimTimestampMs,
    },
  );

  /// Reads a v3 envelope. Upgrade older envelopes with [MigrationRunner] first.
  factory KindredSaveState.fromEnvelope(SaveEnvelope env) {
    if (env.schemaVersion != currentSchemaVersion) {
      throw StateError(
        'Expected schema v$currentSchemaVersion, got v${env.schemaVersion}; '
        'run MigrationRunner.upgrade() before deserializing.',
      );
    }
    final d = env.data;
    final streak = (d['careStreak'] as Map?) ?? const {};
    return KindredSaveState(
      petId: d['petId'] as String,
      species: d['species'] as String,
      name: d['name'] as String,
      lifeStage: d['lifeStage'] as String,
      careMeters: (d['careMeters'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      bondValue: (d['bondValue'] as num).toInt(),
      bondStage: d['bondStage'] as String,
      nestCosmeticIds: (d['nestCosmeticIds'] as List)
          .map((e) => e as String)
          .toList(),
      careStreakCount: (streak['count'] as num?)?.toInt() ?? 0,
      warmthBanked: (streak['warmthBanked'] as num?)?.toInt() ?? 0,
      wallet: (d['wallet'] as Map).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
      lastSimTimestampMs: (d['lastSimTimestampMs'] as num).toInt(),
    );
  }

  /// A fresh save for a newly rescued pet (used by tests; the real Rescue Day
  /// flow that creates this is Phase 1).
  factory KindredSaveState.newPet({
    required String petId,
    required String species,
    required String name,
    required int nowMs,
  }) => KindredSaveState(
    petId: petId,
    species: species,
    name: name,
    lifeStage: 'Pup/Kit',
    careMeters: const {
      'hunger': 100,
      'energy': 100,
      'hygiene': 100,
      'happiness': 100,
    },
    bondValue: 0,
    bondStage: 'Stranger',
    nestCosmeticIds: const [],
    careStreakCount: 0,
    warmthBanked: 0,
    wallet: const {'kibble': 0, 'heartstones': 0, 'compassionCoins': 0},
    lastSimTimestampMs: nowMs,
  );
}
