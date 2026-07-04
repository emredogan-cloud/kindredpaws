/// Seasons of Us engine (GE-5): pure date math across hemispheres, window
/// keys that survive New Year mid-season, and seasonal kindness offers that
/// appear only in-season (and return every year — anti-FOMO).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/kindness.dart';
import 'package:kindredpaws/game/sim/kindness_engine.dart';
import 'package:kindredpaws/game/sim/season_engine.dart';

int msOf(int year, int month, [int day = 15]) =>
    DateTime.utc(year, month, day).millisecondsSinceEpoch;

void main() {
  group('seasonFor', () {
    test('the northern year turns as expected (all 12 months)', () {
      const expected = {
        1: NatureSeason.winter,
        2: NatureSeason.winter,
        3: NatureSeason.spring,
        4: NatureSeason.spring,
        5: NatureSeason.spring,
        6: NatureSeason.summer,
        7: NatureSeason.summer,
        8: NatureSeason.summer,
        9: NatureSeason.autumn,
        10: NatureSeason.autumn,
        11: NatureSeason.autumn,
        12: NatureSeason.winter,
      };
      for (final e in expected.entries) {
        expect(seasonFor(msOf(2026, e.key)), e.value, reason: 'month ${e.key}');
      }
    });

    test('the southern hemisphere flips by half a year', () {
      expect(seasonFor(msOf(2026, 1), southern: true), NatureSeason.summer);
      expect(seasonFor(msOf(2026, 4), southern: true), NatureSeason.autumn);
      expect(seasonFor(msOf(2026, 7), southern: true), NatureSeason.winter);
      expect(seasonFor(msOf(2026, 10), southern: true), NatureSeason.spring);
    });

    test('leap day is just a winter day (never a crash)', () {
      expect(seasonFor(msOf(2024, 2, 29)), NatureSeason.winter);
      expect(seasonWindowKey(msOf(2024, 2, 29)), 'winter-2024');
    });
  });

  group('seasonWindowKey', () {
    test('December belongs to the coming year\'s window (no mid-season '
        'reset at New Year)', () {
      expect(seasonWindowKey(msOf(2026, 12)), 'winter-2027');
      expect(seasonWindowKey(msOf(2027, 1)), 'winter-2027');
      expect(seasonWindowKey(msOf(2027, 2)), 'winter-2027');
      // Southern summer spans the same New Year.
      expect(seasonWindowKey(msOf(2026, 12), southern: true), 'summer-2027');
      expect(seasonWindowKey(msOf(2027, 1), southern: true), 'summer-2027');
    });

    test('non-spanning months keep their own year', () {
      expect(seasonWindowKey(msOf(2026, 7)), 'summer-2026');
      expect(seasonWindowKey(msOf(2026, 10)), 'autumn-2026');
    });
  });

  group('seasonal kindness offers', () {
    const engine = KindnessEngine();
    final seasonalIds = {
      for (final d in KindnessCatalog.all)
        if (d.season != null) d.id: d.season!,
    };

    test('eight seasonal templates, two per season, all trigger-mapped', () {
      expect(seasonalIds.length, 8);
      for (final s in NatureSeason.values) {
        expect(
          seasonalIds.values.where((v) => v == s).length,
          2,
          reason: s.name,
        );
      }
    });

    test('in-season kindnesses join the pool; out-of-season never appear', () {
      var sawSpring = false;
      for (var d = 20000; d < 20120; d++) {
        final withSpring = engine
            .offersFor(d, 'pet-x', season: NatureSeason.spring)
            .toSet();
        final without = engine.offersFor(d, 'pet-x').toSet();
        for (final id in withSpring) {
          final s = seasonalIds[id];
          if (s != null) {
            expect(s, NatureSeason.spring, reason: 'day $d offered $id');
            sawSpring = true;
          }
        }
        for (final id in without) {
          expect(
            seasonalIds.containsKey(id),
            isFalse,
            reason: 'null season must stay evergreen (day $d)',
          );
        }
      }
      expect(sawSpring, isTrue, reason: 'spring defs do get offered');
    });

    test('the pair stays two distinct adventures with seasons in the pool', () {
      for (var d = 20000; d < 20060; d++) {
        for (final s in NatureSeason.values) {
          final pair = engine.offersFor(d, 'pet-y', season: s);
          expect(pair.length, 2);
          final one = KindnessCatalog.byId(pair[0])!;
          final two = KindnessCatalog.byId(pair[1])!;
          expect(one.trigger, isNot(two.trigger));
          expect(one.room, isNot(two.room));
        }
      }
    });
  });
}
