/// KP-020 + KP-022 — persistence robustness.
///
/// KP-020: `_persist` publishes a status snapshot + home-widget update after
/// every save; both are best-effort by contract, yet a platform throw escaped
/// into fire-and-forget gameplay callers (`interact()`/`purchase()`) as an
/// unhandled async error. Pinned here: a throwing snapshot sink never breaks
/// a care action, and the failure is recorded, not swallowed silently.
///
/// KP-022: `V3ToV4` unconditionally rebuilt `bond`/`nest` from already-removed
/// flat keys, so a re-applied step reset the Bond to Stranger; the runner also
/// accepted duplicate `fromVersion` registrations (silent shadowing).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/migration.dart';
import 'package:kindredpaws/data/migration_runner.dart';
import 'package:kindredpaws/data/migrations/v3_to_v4.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/controller/game_controller.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/game/model/pet_status_snapshot.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/services/crash_reporter.dart';
import 'package:kindredpaws/services/observability.dart';
import 'package:kindredpaws/services/status_snapshot_service.dart';

import '../../support/harness.dart';

/// A snapshot sink whose platform write fails (e.g. SharedPreferences I/O).
class _ThrowingSnapshots implements StatusSnapshotService {
  @override
  PetStatusSnapshot? get latest => null;
  @override
  Future<void> write(PetStatusSnapshot snapshot) async =>
      throw StateError('platform write failed');
  @override
  Future<PetStatusSnapshot?> read() async => null;
}

class _FakeMigration extends Migration {
  const _FakeMigration(this.fromVersion);
  @override
  final int fromVersion;
  @override
  int get toVersion => fromVersion + 1;
  @override
  Map<String, dynamic> migrate(Map<String, dynamic> data) => data;
}

void main() {
  group('KP-020 — snapshot/widget failures never escape gameplay', () {
    GameController build() {
      ServiceLocator.instance.reset();
      bootstrap();
      ServiceLocator.instance.registerSingleton<StatusSnapshotService>(
        _ThrowingSnapshots(),
      );
      return createGameController(
        sl: ServiceLocator.instance,
        store: InMemoryLocalSaveStore(),
        clock: () => kDay0,
        idGenerator: () => kTestPetId,
      );
    }

    test(
      'adopt + interact complete despite a throwing snapshot sink',
      () async {
        final c = build();
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        expect(c.hasPet, isTrue);

        // The audit's failure path: interact() → _persist() → publish → throw.
        await c.interact(CareInteraction.feed);
        expect(c.lastOutcome, isNotNull); // the action itself succeeded

        // The failure is observable, not silent: recorded via recordError.
        final crash =
            ServiceLocator.instance.get<ObservabilityFacade>().crash
                as InMemoryCrashReporter;
        expect(
          crash.errors.where((r) => r.context == 'publish_snapshot'),
          isNotEmpty,
        );
        c.dispose();
      },
    );
  });

  group('KP-022 — migration idempotency + runner registration guard', () {
    test('V3ToV4 applied twice is a no-op (bond/nest survive)', () {
      const step = V3ToV4();
      final v3 = {
        'petId': 'p1',
        'species': 'puppy',
        'name': 'Biscuit',
        'lifeStage': 'Young One',
        'careMeters': {
          'hunger': 70.0,
          'energy': 70.0,
          'hygiene': 70.0,
          'happiness': 70.0,
        },
        'bondValue': 42,
        'bondStage': 'Friend',
        'nestCosmeticIds': ['bow_red'],
        'careStreak': {'count': 3},
        'wallet': {'kibble': 10},
        'lastSimTimestampMs': kDay0,
      };
      final once = step.migrate(v3);
      expect((once['bond'] as Map)['value'], 42);
      expect((once['nest'] as Map)['cosmeticIds'], ['bow_red']);

      final twice = step.migrate(once);
      expect(
        (twice['bond'] as Map)['value'],
        42,
        reason: 're-applying the step must never reset the Bond',
      );
      expect((twice['bond'] as Map)['stage'], 'Friend');
      expect((twice['nest'] as Map)['cosmeticIds'], ['bow_red']);
    });

    test('runner rejects duplicate fromVersion registrations', () {
      expect(
        () => MigrationRunner(const [_FakeMigration(3), _FakeMigration(3)]),
        throwsArgumentError,
      );
    });
  });
}
