import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';

const _day = Duration.millisecondsPerDay;
const _day0 = 20000 * _day;

void main() {
  group('InMemoryNotificationScheduler (warm, capped, never guilt)', () {
    test('respects the daily cap (1/day default)', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleDailyPresence(petName: 'Biscuit', fromMs: _day0, days: 3);
      expect(s.scheduled.length, 3); // 1/day × 3 days
    });

    test('cap of 2 schedules a morning + evening', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleDailyPresence(
        petName: 'Mochi',
        fromMs: _day0,
        dailyCap: 2,
        days: 2,
      );
      expect(s.scheduled.length, 4); // 2/day × 2 days
    });

    test('caps are clamped to 1..2 (never spammy)', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleDailyPresence(
        petName: 'Biscuit',
        fromMs: _day0,
        dailyCap: 9,
        days: 1,
      );
      expect(s.scheduled.length, 2); // clamped to 2
    });

    test(
      'every line is personalised + warm — never guilt-framed (Risk R6)',
      () async {
        final s = InMemoryNotificationScheduler();
        await s.scheduleDailyPresence(
          petName: 'Biscuit',
          fromMs: _day0,
          days: 2,
        );
        for (final n in s.scheduled) {
          expect(n.body, contains('Biscuit'));
          expect(n.body.toLowerCase(), isNot(contains('starving')));
          expect(n.body.toLowerCase(), isNot(contains('miss')));
          expect(n.whenMs, greaterThan(_day0)); // all in the future
        }
      },
    );

    test('rescheduling replaces the prior set', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleDailyPresence(petName: 'A', fromMs: _day0, days: 3);
      await s.scheduleDailyPresence(petName: 'B', fromMs: _day0, days: 1);
      expect(s.scheduled.length, 1);
      expect(s.scheduled.single.body, contains('B'));
    });

    test('cancelAll clears the schedule', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleDailyPresence(petName: 'A', fromMs: _day0);
      await s.cancelAll();
      expect(s.scheduled, isEmpty);
    });
  });
}
