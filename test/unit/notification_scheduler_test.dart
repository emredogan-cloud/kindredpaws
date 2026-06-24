import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';

const _day = Duration.millisecondsPerDay;
const _day0 = 20000 * _day;
const _hour = Duration.millisecondsPerHour;

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

  group('NotificationScheduler — the 5 kinds + caps (P4-4)', () {
    test('every template across every kind passes the never-guilt SSOT', () {
      final banks = [
        InMemoryNotificationScheduler.warmTemplates,
        InMemoryNotificationScheduler.memoryTemplates,
        InMemoryNotificationScheduler.celebrationTemplates,
        InMemoryNotificationScheduler.streakWarmthTemplates,
      ];
      for (final bank in banks) {
        for (final t in bank) {
          final lower = t.toLowerCase();
          for (final w in ContentValidator.forbiddenGuiltLanguage) {
            expect(lower.contains(w), isFalse, reason: '"$t" contains "$w"');
          }
        }
      }
    });

    test('scheduleEvent adds a notification of the requested kind', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleEvent(
        kind: NotificationKind.celebration,
        petName: 'Biscuit',
        atMs: _day0 + 4 * _hour,
        detail: 'becoming Friends',
      );
      expect(s.scheduled.single.kind, NotificationKind.celebration);
      expect(s.scheduled.single.body, contains('Biscuit'));
    });

    test('streak-warmth copy is reassuring, never loss-framed', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleEvent(
        kind: NotificationKind.streakWarmth,
        petName: 'Mochi',
        atMs: _day0 + 4 * _hour,
      );
      final body = s.scheduled.single.body.toLowerCase();
      expect(body, contains('warm'));
      expect(body, isNot(contains('lost')));
      expect(body, isNot(contains("don't")));
    });

    test(
      'the hard daily cap (2) drops a third event on the same day',
      () async {
        final s = InMemoryNotificationScheduler();
        for (var i = 0; i < 3; i++) {
          await s.scheduleEvent(
            kind: NotificationKind.memory,
            petName: 'Biscuit',
            atMs: _day0 + (5 + i) * _hour, // all same calendar day
          );
        }
        expect(s.scheduled.length, 2); // 3rd dropped
        expect(s.countOnDay(_day0 + 6 * _hour), 2);
      },
    );

    test('an event on a different day is not blocked by a full day', () async {
      final s = InMemoryNotificationScheduler();
      await s.scheduleEvent(
        kind: NotificationKind.memory,
        petName: 'A',
        atMs: _day0 + 5 * _hour,
      );
      await s.scheduleEvent(
        kind: NotificationKind.memory,
        petName: 'A',
        atMs: _day0 + 5 * _hour,
      ); // day full (2)
      await s.scheduleEvent(
        kind: NotificationKind.celebration,
        petName: 'A',
        atMs: _day0 + _day + 5 * _hour,
      ); // next day
      expect(s.scheduled.length, 3);
    });
  });
}
