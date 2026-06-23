import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/result.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/migration.dart';
import 'package:kindredpaws/data/migration_runner.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/model/bond.dart';
import 'package:kindredpaws/game/model/life_stage.dart';
import 'package:kindredpaws/game/model/species.dart';

SaveEnvelope _v1() => const SaveEnvelope(
  schemaVersion: 1,
  data: {
    'petId': 'p1',
    'species': 'puppy',
    'name': 'Biscuit',
    'lifeStage': 'Pup/Kit',
    'careMeters': {
      'hunger': 100.0,
      'energy': 100.0,
      'hygiene': 100.0,
      'happiness': 100.0,
    },
    'bondValue': 0,
    'bondStage': 'Stranger',
    'nestCosmeticIds': <String>[],
    'lastSimTimestampMs': 0,
  },
);

void main() {
  final runner = MigrationRunner(KindredSaveState.migrations);

  group('versioned save + migration (Risk R4)', () {
    test(
      'upgrades v1 -> current (v5), adding wallet/careStreak/bond/ledger/keepsakes',
      () {
        final up = runner.upgrade(_v1(), KindredSaveState.currentSchemaVersion);
        expect(up.schemaVersion, KindredSaveState.currentSchemaVersion);
        expect(up.data['wallet'], isNotNull);
        expect(up.data['careStreak'], isNotNull);
        expect(up.data['bond'], isNotNull); // nested in v4
        expect(up.data['bondLedger'], isNotNull); // new in v4
        expect(up.data['memoryFacts'], isNotNull);
        expect(up.data['keepsakes'], isNotNull); // new in v5

        final state = KindredSaveState.fromEnvelope(up);
        expect(state.pet.name, 'Biscuit');
        expect(state.pet.wallet.kibble, 0);
        expect(state.pet.careStreak.count, 0);
        expect(state.pet.activeDays, 1);
        expect(state.facts, isEmpty);
        expect(state.keepsakes, isEmpty);
      },
    );

    test('current-schema save round-trips losslessly', () {
      final s = KindredSaveState.newPet(
        petId: 'p2',
        species: 'kitten',
        name: 'Mochi',
        nowMs: 123,
      );
      final back = KindredSaveState.fromEnvelope(s.toEnvelope());
      expect(back.pet.species, Species.kitten);
      expect(back.pet.name, 'Mochi');
      expect(back.pet.lifeStage, LifeStage.pupKit);
      expect(back.pet.bond.stage, BondStage.stranger);
    });

    test('refuses to downgrade a newer save (no orphaned pet)', () {
      expect(
        () =>
            runner.upgrade(const SaveEnvelope(schemaVersion: 99, data: {}), 3),
        throwsStateError,
      );
    });

    test('rejects a non-incrementing (skipping) migration', () {
      expect(
        () => MigrationRunner(const [_SkipMigration()]),
        throwsArgumentError,
      );
    });

    test('SaveRepository loads + migrates an old local blob', () async {
      final store = InMemoryLocalSaveStore()..write(_v1().toJsonString());
      final repo = SaveRepository(local: store);
      final res = await repo.load();
      expect(res, isA<Ok<KindredSaveState?>>());
      final state = (res as Ok<KindredSaveState?>).value!;
      expect(state.pet.name, 'Biscuit');
      expect(state.pet.wallet.compassionCoins, 0);
    });

    test('SaveRepository.load returns null when no save exists', () async {
      final repo = SaveRepository(local: InMemoryLocalSaveStore());
      final res = await repo.load();
      expect((res as Ok<KindredSaveState?>).value, isNull);
    });
  });
}

/// A deliberately invalid migration that skips v2 — used to prove the runner
/// rejects non-incrementing steps.
class _SkipMigration extends Migration {
  const _SkipMigration();
  @override
  int get fromVersion => 1;
  @override
  int get toVersion => 3;
  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) => data;
}
