/// E3 retention surfaces: the daily first-open Kibble welcome (§8.1), the
/// one-time Streak Repair (§11.2 — warm, optional, never nagged), and the
/// streak-break passthrough that powers the offer.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/game/model/species.dart';
import 'package:kindredpaws/game/sim/interaction.dart';

import '../../support/harness.dart';

const _day = Duration.millisecondsPerDay;
const _hour = Duration.millisecondsPerHour;

void main() {
  group('daily first-open Kibble (§8.1)', () {
    test('a new day grants +50 once; the same day never repeats it', () async {
      var now = kDay0;
      final store = makeStore();
      final c = makeController(store: store, clock: () => now);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      expect(c.pet!.wallet.kibble, 0); // adoption day = day 0, no bonus yet

      // Next morning: the welcome bonus lands with a warm message.
      await c.onAppBackgrounded();
      now += _day;
      c.onAppForegrounded();
      expect(c.pet!.wallet.kibble, 50);
      expect(c.lastMessage, contains('+50'));

      // A second open the same day: no double-dip.
      await c.onAppBackgrounded();
      now += 2 * _hour;
      c.onAppForegrounded();
      expect(c.pet!.wallet.kibble, 50);
    });
  });

  group('Streak Repair (§11.2)', () {
    /// Runs enough warm days to build a streak, then lapses past the banked
    /// warmth so the streak truly breaks on the next care action.
    Future<void> breakAStreak(dynamic c, void Function(int) advance) async {
      for (var day = 0; day < 4; day++) {
        await c.interact(CareInteraction.feed);
        await c.onAppBackgrounded();
        advance(1);
        c.onAppForegrounded();
      }
      // 4-day gap: beyond the warmth cap (2) — the streak will break.
      await c.onAppBackgrounded();
      advance(4);
      c.onAppForegrounded();
      await c.interact(CareInteraction.feed);
    }

    test('a broken streak surfaces the offer; repairing spends 100 Kibble '
        'and rekindles', () async {
      var now = kDay0;
      final c = makeController(clock: () => now);
      await c.load();
      await c.adopt(species: Species.puppy, name: 'Biscuit');
      await breakAStreak(c, (d) => now += d * _day);

      expect(c.streakRepairOffer, isNotNull);
      final broke = c.streakRepairOffer!;
      expect(broke, greaterThanOrEqualTo(3));
      // Daily bonuses funded the wallet well past the repair cost.
      expect(c.pet!.wallet.kibble, greaterThanOrEqualTo(100));

      final kibble = c.pet!.wallet.kibble;
      final ok = await c.repairStreak();
      expect(ok, isTrue);
      expect(c.pet!.wallet.kibble, kibble - 100);
      expect(c.pet!.careStreak.count, broke + 1); // continuing, not reset
      expect(c.streakRepairOffer, isNull);
      expect(c.lastMessage, contains('glowing'));
    });

    test(
      'the offer clears itself on the next fresh care day (no nagging)',
      () async {
        var now = kDay0;
        final c = makeController(clock: () => now);
        await c.load();
        await c.adopt(species: Species.puppy, name: 'Biscuit');
        await breakAStreak(c, (d) => now += d * _day);
        expect(c.streakRepairOffer, isNotNull);

        // Simply caring again tomorrow moves on — the offer melts away.
        await c.onAppBackgrounded();
        now += _day;
        c.onAppForegrounded();
        await c.interact(CareInteraction.feed);
        expect(c.streakRepairOffer, isNull);
        expect(c.pet!.careStreak.count, 2); // yesterday + today, fresh and fine
      },
    );
  });
}
