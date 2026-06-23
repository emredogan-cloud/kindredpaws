import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/care_meters.dart';
import 'package:kindredpaws/game/model/mood.dart';
import 'package:kindredpaws/game/model/pet_state.dart';
import 'package:kindredpaws/game/model/pet_status_snapshot.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';
import 'package:kindredpaws/game/sim/sim_config.dart';
import 'package:kindredpaws/services/status_snapshot_service.dart';

import '../../support/harness.dart';

const _day0 = 20000 * 86400000;

void main() {
  const config = SimConfig();

  PetState pet({CareMeters? meters}) => PetState.newlyRescued(
    petId: 'p1',
    species: Species.puppy,
    name: 'Biscuit',
    nowMs: _day0,
  ).copyWith(meters: meters);

  group('PetStatusSnapshot.fromPet (§6.1 shared payload)', () {
    test('derives the widget/notification fields from pet state', () {
      final s = PetStatusSnapshot.fromPet(
        pet: pet(),
        mood: Mood.joyful,
        config: config,
        nowMs: _day0,
      );
      expect(s.name, 'Biscuit');
      expect(s.species, 'puppy');
      expect(s.lifeStage, 'pupKit');
      expect(s.bondStage, 'Stranger');
      expect(s.mood, 'joyful');
      // Pre-rendered image ref the native widget shows (not a live render).
      expect(s.preRenderedMoodImageRef, 'puppy_pupKit_joyful');
    });

    test(
      'nextSuggestedCareAt is in the future and sooner when meters are low',
      () {
        final hi = PetStatusSnapshot.fromPet(
          pet: pet(meters: CareMeters.full),
          mood: Mood.content,
          config: config,
          nowMs: _day0,
        );
        final lo = PetStatusSnapshot.fromPet(
          pet: pet(
            meters: const CareMeters(
              hunger: 40,
              energy: 90,
              hygiene: 90,
              happiness: 90,
            ),
          ),
          mood: Mood.content,
          config: config,
          nowMs: _day0,
        );
        expect(hi.nextSuggestedCareAtMs, greaterThan(_day0));
        // A low hunger meter means care is suggested sooner.
        expect(lo.nextSuggestedCareAtMs, lessThan(hi.nextSuggestedCareAtMs));
      },
    );

    test(
      'toMap/fromMap round-trips losslessly (crosses the native boundary)',
      () {
        final s = PetStatusSnapshot.fromPet(
          pet: pet(),
          mood: Mood.wistful,
          config: config,
          nowMs: _day0,
        );
        expect(PetStatusSnapshot.fromMap(s.toMap()), s);
      },
    );
  });

  group('InMemoryStatusSnapshotService', () {
    test('write/read/latest round-trip', () async {
      final svc = InMemoryStatusSnapshotService();
      expect(svc.latest, isNull);
      final s = PetStatusSnapshot.fromPet(
        pet: pet(),
        mood: Mood.content,
        config: config,
        nowMs: _day0,
      );
      await svc.write(s);
      expect(svc.latest, s);
      expect(await svc.read(), s);
    });
  });

  group('GameController publishes a snapshot on every change', () {
    test('snapshot updates after adopt + interact', () async {
      final c = makeController(clock: () => _day0);
      await c.load();
      expect(c.statusSnapshot, isNull); // no pet yet

      await c.adopt(species: Species.kitten, name: 'Mochi');
      expect(c.statusSnapshot, isNotNull);
      expect(c.statusSnapshot!.name, 'Mochi');
      expect(c.statusSnapshot!.species, 'kitten');

      final before = c.statusSnapshot!.updatedAtMs;
      await c.interact(CareInteraction.feed);
      // Still published (mood/streak may change); snapshot reflects current pet.
      expect(c.statusSnapshot!.careStreakCount, c.pet!.careStreak.count);
      expect(c.statusSnapshot!.updatedAtMs, greaterThanOrEqualTo(before));
      c.dispose();
    });
  });
}
