/// Daily Kindness engine + catalog (GE-1): deterministic offers, honest
/// completion detection, guilt-free copy, and a lossless state roundtrip.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/kindness.dart';
import 'package:kindredpaws/game/sim/kindness_engine.dart';

void main() {
  const engine = KindnessEngine();
  const day = 20000; // matches the harness base clock's epoch day
  const dayMs = day * 86400000;

  group('catalog', () {
    test('ids are unique and rewards stay in the canon band (10–20)', () {
      final ids = KindnessCatalog.all.map((d) => d.id).toSet();
      expect(ids.length, KindnessCatalog.all.length);
      for (final def in KindnessCatalog.all) {
        expect(def.kibble, inInclusiveRange(10, 20), reason: def.id);
      }
    });

    test('every line of copy is warm — never guilt, urgency, or loss', () {
      const banned = [
        'starving',
        'dying',
        'sick',
        'abandon',
        'guilt',
        'miss you',
        'hurry',
        'last chance',
        'expires',
        'don\'t forget',
      ];
      for (final def in KindnessCatalog.all) {
        final copy = '${def.title} ${def.invitation}'.toLowerCase();
        for (final word in banned) {
          expect(copy, isNot(contains(word)), reason: def.id);
        }
      }
    });
  });

  group('daily offers', () {
    test('same day + pet ⇒ the same pair, always', () {
      final a = engine.offersFor(day, 'pet-abc');
      final b = engine.offersFor(day, 'pet-abc');
      expect(a, b);
    });

    test('a pair is two defs with different triggers AND different rooms', () {
      for (var d = day; d < day + 50; d++) {
        for (final pet in ['pet-a', 'pet-b', 'pet-c', 'pet-longer-id-123']) {
          final offered = engine.offersFor(d, pet);
          expect(offered.length, 2, reason: 'day $d pet $pet');
          final one = KindnessCatalog.byId(offered[0])!;
          final two = KindnessCatalog.byId(offered[1])!;
          expect(one.trigger, isNot(two.trigger), reason: 'day $d pet $pet');
          expect(one.room, isNot(two.room), reason: 'day $d pet $pet');
        }
      }
    });

    test('pairs vary across days (variety, not a fixed chore)', () {
      final seen = <String>{};
      for (var d = day; d < day + 30; d++) {
        seen.add(engine.offersFor(d, 'pet-abc').join('+'));
      }
      expect(seen.length, greaterThanOrEqualTo(6));
    });

    test('today() keeps the same-day slate and refreshes on a new day', () {
      final slate = engine.today(nowMs: dayMs + 3600000, petId: 'p1');
      final withDone = slate.copyWith(completed: [slate.offered.first]);
      // Same day: untouched (completion preserved).
      final same = engine.today(
        nowMs: dayMs + 7200000,
        petId: 'p1',
        prior: withDone,
      );
      expect(same, withDone);
      // Next day: a fresh pair, completions quietly cleared.
      final next = engine.today(
        nowMs: dayMs + 86400000 + 60000,
        petId: 'p1',
        prior: withDone,
      );
      expect(next.dayEpoch, day + 1);
      expect(next.completed, isEmpty);
      expect(next.offered, engine.offersFor(day + 1, 'p1'));
    });
  });

  group('completion detection', () {
    KindnessState slate(List<KindnessDef> defs) =>
        KindnessState(dayEpoch: day, offered: defs.map((d) => d.id).toList());

    test('a matching moment completes; the wrong verb never does', () {
      final s = slate([KindnessCatalog.shareAMeal, KindnessCatalog.bubbleBath]);
      final miss = engine.record(s, KindnessTrigger.play);
      expect(miss.completed, isEmpty);
      final hit = engine.record(s, KindnessTrigger.feed);
      expect(hit.completed.single.id, KindnessCatalog.shareAMeal.id);
      expect(hit.state.isCompleted(KindnessCatalog.shareAMeal.id), isTrue);
    });

    test('item filters hold: garden-fresh needs an apple or carrot', () {
      final s = slate([
        KindnessCatalog.gardenCrunch,
        KindnessCatalog.bubbleBath,
      ]);
      expect(engine.record(s, KindnessTrigger.feed).completed, isEmpty);
      expect(
        engine
            .record(s, KindnessTrigger.feed, itemId: 'food_kibble_bowl')
            .completed,
        isEmpty,
      );
      expect(
        engine
            .record(s, KindnessTrigger.feed, itemId: 'food_apple')
            .completed
            .single
            .id,
        KindnessCatalog.gardenCrunch.id,
      );
    });

    test('requiresItem holds: the toy kindness needs a real toy', () {
      final s = slate([
        KindnessCatalog.favoriteToy,
        KindnessCatalog.bubbleBath,
      ]);
      expect(engine.record(s, KindnessTrigger.play).completed, isEmpty);
      expect(
        engine
            .record(s, KindnessTrigger.play, itemId: 'toy_bouncy_ball')
            .completed
            .single
            .id,
        KindnessCatalog.favoriteToy.id,
      );
    });

    test('completing twice never double-credits', () {
      final s = slate([KindnessCatalog.shareAMeal, KindnessCatalog.bubbleBath]);
      final once = engine.record(s, KindnessTrigger.feed);
      final twice = engine.record(once.state, KindnessTrigger.feed);
      expect(twice.completed, isEmpty);
      expect(twice.state.completed.length, 1);
    });

    test('a retired id in an old save is inert, never an error', () {
      const s = KindnessState(
        dayEpoch: day,
        offered: ['kind_retired_id', 'kind_bubble_bath'],
      );
      final res = engine.record(s, KindnessTrigger.clean);
      expect(res.completed.single.id, KindnessCatalog.bubbleBath.id);
      expect(res.state.allDone, isFalse); // the retired slot never completes
    });
  });

  test('KindnessState round-trips losslessly', () {
    const s = KindnessState(
      dayEpoch: day,
      offered: ['kind_share_a_meal', 'kind_bubble_bath'],
      completed: ['kind_bubble_bath'],
    );
    expect(KindnessState.fromMap(s.toMap()), s);
  });
}
