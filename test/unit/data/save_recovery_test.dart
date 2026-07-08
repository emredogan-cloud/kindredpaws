/// KP-010 — silent pet-loss remediation.
///
/// The audit traced three data-loss paths: (1) corrupt/partial saves dropped
/// the player into Rescue Day and the next persist overwrote the recoverable
/// blob, (2) newer-schema saves (downgrade) were treated as unrecoverable,
/// (3) one missing field killed the whole deserialization. These tests pin the
/// remediation: typed load outcomes, blob quarantine, total deserialization,
/// the adopt guard, and the cloud-restore path.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/bootstrap.dart';
import 'package:kindredpaws/core/service_locator.dart';
import 'package:kindredpaws/data/kindred_save_state.dart';
import 'package:kindredpaws/data/save_envelope.dart';
import 'package:kindredpaws/data/save_repository.dart';
import 'package:kindredpaws/game/controller/game_controller.dart';
import 'package:kindredpaws/game/game_wiring.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/services/backend_service.dart';

import '../../support/harness.dart';

/// A healthy current-schema blob to corrupt in various ways.
String healthyBlob({String petId = kTestPetId, String name = 'Biscuit'}) =>
    KindredSaveState.newPet(
      petId: petId,
      species: 'puppy',
      name: name,
      nowMs: kDay0,
    ).toEnvelope().toJsonString();

void main() {
  group('SaveRepository.loadOutcome (typed outcomes + quarantine)', () {
    test('no blob → SaveAbsent (genuinely fresh install)', () async {
      final repo = SaveRepository(local: InMemoryLocalSaveStore());
      expect(await repo.loadOutcome(), isA<SaveAbsent>());
    });

    test('healthy blob → SaveLoaded', () async {
      final store = InMemoryLocalSaveStore();
      await store.write(healthyBlob());
      final repo = SaveRepository(local: store);
      final outcome = await repo.loadOutcome();
      expect(outcome, isA<SaveLoaded>());
      expect((outcome as SaveLoaded).state.pet.name, 'Biscuit');
    });

    test(
      'truncated blob → SaveUnreadable, quarantined, petId salvaged',
      () async {
        final store = InMemoryLocalSaveStore();
        final blob = healthyBlob();
        final truncated = blob.substring(0, blob.length ~/ 2);
        await store.write(truncated);
        final repo = SaveRepository(local: store);

        final outcome = await repo.loadOutcome();
        expect(outcome, isA<SaveUnreadable>());
        final u = outcome as SaveUnreadable;
        expect(u.isNewerSchema, isFalse);
        // petId is written near the head of the envelope → salvageable by scan.
        expect(u.salvagedPetId, kTestPetId);
        // The blob is quarantined AND still in the main slot — nothing wrote
        // over it.
        expect(await store.readBackup(), truncated);
        expect(await store.read(), truncated);
      },
    );

    test('garbage blob → SaveUnreadable, quarantined', () async {
      final store = InMemoryLocalSaveStore();
      await store.write('not json at all');
      final repo = SaveRepository(local: store);
      final outcome = await repo.loadOutcome();
      expect(outcome, isA<SaveUnreadable>());
      expect(await store.readBackup(), 'not json at all');
    });

    test(
      'newer-schema blob (downgrade) → isNewerSchema, never a wipe',
      () async {
        final store = InMemoryLocalSaveStore();
        final newer = const SaveEnvelope(
          schemaVersion: KindredSaveState.currentSchemaVersion + 1,
          data: {'petId': 'pet-from-the-future', 'name': 'Nova'},
        ).toJsonString();
        await store.write(newer);
        final repo = SaveRepository(local: store);

        final outcome = await repo.loadOutcome();
        expect(outcome, isA<SaveUnreadable>());
        final u = outcome as SaveUnreadable;
        expect(u.isNewerSchema, isTrue);
        expect(u.salvagedPetId, 'pet-from-the-future');
        expect(await store.read(), newer); // untouched
      },
    );

    test('legacy load() still maps outcomes (compat)', () async {
      final store = InMemoryLocalSaveStore();
      final repo = SaveRepository(local: store);
      expect((await repo.load()).valueOrNull, isNull); // absent → Ok(null)
      await store.write('garbage');
      expect((await repo.load()).isErr, isTrue); // unreadable → Err
    });
  });

  group('KindredSaveState.fromEnvelope is total (one bad field ≠ lost pet)', () {
    Map<String, dynamic> healthyData() =>
        SaveEnvelope.fromJsonString(healthyBlob()).data;

    KindredSaveState parse(Map<String, dynamic> data) =>
        KindredSaveState.fromEnvelope(
          SaveEnvelope(
            schemaVersion: KindredSaveState.currentSchemaVersion,
            data: data,
          ),
        );

    test(
      'missing lastSimTimestampMs (the audit case) → falls back to createdAtMs',
      () {
        final d = healthyData()..remove('lastSimTimestampMs');
        final s = parse(d);
        expect(s.pet.lastSimTimestampMs, s.pet.createdAtMs);
        expect(s.pet.name, 'Biscuit');
      },
    );

    test('missing careMeters / single meter key → comfortable defaults', () {
      final d = healthyData()..remove('careMeters');
      expect(parse(d).pet.meters.hunger, 80);
      final d2 = healthyData();
      (d2['careMeters'] as Map).remove('energy');
      expect(parse(d2).pet.meters.energy, 80);
      expect(parse(d2).pet.meters.hunger, 100); // untouched keys keep values
    });

    test(
      'missing bond / careStreak / wallet / name / lifeStage → defaults',
      () {
        final d = healthyData()
          ..remove('bond')
          ..remove('careStreak')
          ..remove('wallet')
          ..remove('name')
          ..remove('lifeStage');
        final s = parse(d);
        expect(s.pet.bond.value, 0);
        expect(s.pet.careStreak.count, 0);
        expect(s.pet.wallet.kibble, 0);
        expect(s.pet.name, Species.puppy.defaultName);
      },
    );

    test('wrong-typed fields → defaults, not crashes', () {
      final d = healthyData();
      d['name'] = 42;
      d['careMeters'] = 'oops';
      d['activeDays'] = 'many';
      final s = parse(d);
      expect(s.pet.name, Species.puppy.defaultName);
      expect(s.pet.meters.hygiene, 80);
      expect(s.pet.activeDays, 1);
    });

    test('one corrupt keepsake/fact is skipped; the rest survive', () {
      final d = healthyData();
      d['memoryFacts'] = [
        {'bad': 'record'},
        // A real fact shape (mirrors MemoryFact.toJson).
        {
          'key': 'importantDate',
          'value': 'rescue-day',
          'source': 'onboarding',
          'confidence': 1.0,
          'createdAtMs': kDay0,
        },
      ];
      d['keepsakes'] = [
        {'also': 'bad'},
      ];
      final s = parse(d);
      expect(s.facts, hasLength(1));
      expect(s.keepsakes, isEmpty);
    });

    test('corrupt inventory section resets; the pet survives', () {
      final d = healthyData();
      d['inventory'] = {
        'pantry': {'kibble_basic': 'NaN'},
      };
      final s = parse(d);
      expect(s.pet.name, 'Biscuit');
    });

    test('missing petId is the one strict field → throws into recovery', () {
      final d = healthyData()..remove('petId');
      expect(() => parse(d), throwsA(isA<FormatException>()));
    });
  });

  group('GameController recovery invariants (never overwrite)', () {
    test('corrupt save → recovery, adopt refused, blob intact', () async {
      final store = InMemoryLocalSaveStore();
      final blob = healthyBlob();
      final corrupt = blob.substring(0, blob.length - 25);
      await store.write(corrupt);
      final c = makeController(store: store);

      await c.load();
      expect(c.recovery, RecoveryKind.corruptSave);
      expect(c.hasPet, isFalse);
      expect(c.loading, isFalse);

      // The KP-010 disaster path: adopting must be refused while recovering.
      await c.adopt(species: Species.kitten, name: 'Usurper');
      expect(c.hasPet, isFalse);
      expect(await store.read(), corrupt); // nothing overwrote the blob
      expect(await store.readBackup(), corrupt); // and it is quarantined
      c.dispose();
    });

    test(
      'newer-schema save → appTooOld recovery, no fresh-start escape',
      () async {
        final store = InMemoryLocalSaveStore();
        final newer = const SaveEnvelope(
          schemaVersion: KindredSaveState.currentSchemaVersion + 1,
          data: {'petId': 'p1'},
        ).toJsonString();
        await store.write(newer);
        final c = makeController(store: store);

        await c.load();
        expect(c.recovery, RecoveryKind.appTooOld);

        // beginFreshStart only applies to corrupt saves — a healthy newer save
        // must never be startable-over (updating the app preserves the pet).
        c.beginFreshStart();
        expect(c.recovery, RecoveryKind.appTooOld);
        await c.adopt(species: Species.puppy, name: 'Nope');
        expect(await store.read(), newer);
        c.dispose();
      },
    );

    test(
      'explicit fresh start: backup preserved, adoption re-opened',
      () async {
        final store = InMemoryLocalSaveStore();
        await store.write('{"broken":');
        final c = makeController(store: store);

        await c.load();
        expect(c.recovery, RecoveryKind.corruptSave);

        c.beginFreshStart();
        expect(c.recovery, isNull);
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        expect(c.hasPet, isTrue);
        // New save written, but the quarantined blob is still readable.
        expect(await store.read(), isNot('{"broken":'));
        expect(await store.readBackup(), '{"broken":');
        c.dispose();
      },
    );

    test('retryLoad heals a transiently-corrupt store', () async {
      final store = InMemoryLocalSaveStore();
      await store.write('garbage');
      final c = makeController(store: store);
      await c.load();
      expect(c.recovery, RecoveryKind.corruptSave);

      await store.write(healthyBlob());
      await c.retryLoad();
      expect(c.recovery, isNull);
      expect(c.hasPet, isTrue);
      expect(c.pet!.name, 'Biscuit');
      c.dispose();
    });

    test(
      'right-to-be-forgotten erases the quarantined blob too (§8.3)',
      () async {
        final store = InMemoryLocalSaveStore();
        await store.write('corrupt personal data');
        final repo = SaveRepository(local: store);
        await repo.loadOutcome(); // quarantines
        expect(await store.readBackup(), isNotNull);

        await repo.deleteAccount();
        expect(await store.read(), isNull);
        expect(await store.readBackup(), isNull);
      },
    );

    test(
      'cloud restore rescues a corrupt local save (KP-010 + KP-001 seam)',
      () async {
        ServiceLocator.instance.reset();
        bootstrap();
        // The authoritative cloud copy exists (mirrored on an earlier persist).
        final backend =
            ServiceLocator.instance.get<BackendService>()
                as InMemoryBackendService;
        final cloudState = KindredSaveState.newPet(
          petId: kTestPetId,
          species: 'kitten',
          name: 'Mochi',
          nowMs: kDay0,
        );
        await backend.writeDocument(
          'saves',
          kTestPetId,
          cloudState.toEnvelope().toJsonMap(),
        );

        // The local blob is corrupt but the petId is salvageable.
        final store = InMemoryLocalSaveStore();
        final blob = healthyBlob(name: 'Mochi');
        await store.write(blob.substring(0, blob.length - 30));

        final c = createGameController(
          sl: ServiceLocator.instance,
          store: store,
          clock: () => kDay0,
          idGenerator: () => kTestPetId,
        );
        await c.load();

        // Restored from cloud: no recovery screen, the pet is back, and the
        // repaired blob replaced the corrupt one locally.
        expect(c.recovery, isNull);
        expect(c.hasPet, isTrue);
        expect(c.pet!.name, 'Mochi');
        final healed = await store.read();
        expect(healed, isNotNull);
        expect(
          SaveEnvelope.fromJsonString(healed!).schemaVersion,
          KindredSaveState.currentSchemaVersion,
        );
        c.dispose();
      },
    );
  });
}
