import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/services/live_ops.dart';
import 'package:kindredpaws/services/local_notification_scheduler.dart';
import 'package:kindredpaws/services/notification_scheduler.dart';
import 'package:kindredpaws/services/notifications/os_notification_sink.dart';
import 'package:kindredpaws/services/remote_config_service.dart';

/// Records what the scheduler would deliver to the OS — no platform channel.
class _RecordingSink implements OsNotificationSink {
  final List<(int id, PetNotification n, String payload)> scheduled = [];
  int cancelAllCalls = 0;
  bool initialized = false;
  bool permissionRequested = false;

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async =>
      initialized = true;

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    return true;
  }

  final List<int> cancelled = [];

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.removeWhere((e) => e.$1 == id);
  }

  @override
  Future<void> schedule(
    int id,
    PetNotification notification, {
    required String payload,
  }) async => scheduled.add((id, notification, payload));

  @override
  Future<void> cancelAll() async => cancelAllCalls++;
}

LocalNotificationScheduler _make(_RecordingSink sink, {bool killed = false}) =>
    LocalNotificationScheduler(
      sink: sink,
      liveOps: LiveOps(
        DefaultRemoteConfig(
          killed ? {'killswitch.notifications': true} : const {},
        ),
      ),
    );

const int _day0 = 20000 * 86400000;

void main() {
  group('LocalNotificationScheduler — delivers the warm set to the OS', () {
    test(
      'daily presence is mirrored to the sink (replace-then-schedule)',
      () async {
        final sink = _RecordingSink();
        final s = _make(sink);
        await s.scheduleDailyPresence(
          petName: 'Biscuit',
          fromMs: _day0,
          days: 3,
        );

        // Same payloads the in-memory logic computes are forwarded to the OS.
        expect(sink.scheduled, isNotEmpty);
        expect(sink.scheduled.length, s.scheduled.length);
        // KP-017: re-arming presence never nukes the whole OS calendar —
        // it cancels exactly the previously-mirrored presence ids.
        expect(sink.cancelAllCalls, 0);
        // Personalised + carries a deep-link payload (the kind name).
        final first = sink.scheduled.first;
        expect(first.$2.body, contains('Biscuit'));
        expect(first.$3, first.$2.kind.name);

        // A second re-arm replaces the presence set id-for-id.
        final firstBatchIds = sink.scheduled.map((e) => e.$1).toSet();
        await s.scheduleDailyPresence(
          petName: 'Biscuit',
          fromMs: _day0,
          days: 3,
        );
        expect(sink.cancelled.toSet(), firstBatchIds);
        expect(sink.cancelAllCalls, 0);
      },
    );

    test(
      'KP-017: a queued celebration SURVIVES a presence re-arm (logic + OS)',
      () async {
        final sink = _RecordingSink();
        final s = _make(sink);
        await s.scheduleDailyPresence(petName: 'Mochi', fromMs: _day0);
        // A celebration queued a few hours out (e.g. a Bond-stage-up beat).
        await s.scheduleEvent(
          kind: NotificationKind.celebration,
          petName: 'Mochi',
          atMs: _day0 + 4 * 3600000,
          detail: 'becoming Friends',
        );
        final osEventIds = sink.scheduled
            .where((e) => e.$2.kind == NotificationKind.celebration)
            .map((e) => e.$1)
            .toList();
        expect(osEventIds, hasLength(1));

        // The audit's bug: this re-arm used to cancelAll() and wipe it.
        await s.scheduleDailyPresence(petName: 'Mochi', fromMs: _day0);
        expect(
          s.scheduled.where((n) => n.kind == NotificationKind.celebration),
          hasLength(1),
          reason: 'the celebration must survive in the logic layer',
        );
        expect(
          sink.scheduled.where((e) => e.$1 == osEventIds.single),
          hasLength(1),
          reason: 'the celebration must keep its OS slot',
        );
        expect(sink.cancelled, isNot(contains(osEventIds.single)));
      },
    );

    test(
      'every delivered body passes the never-guilt SSOT (Risk R6)',
      () async {
        final sink = _RecordingSink();
        final s = _make(sink);
        await s.scheduleDailyPresence(petName: 'Mochi', fromMs: _day0, days: 3);
        await s.scheduleEvent(
          kind: NotificationKind.streakWarmth,
          petName: 'Mochi',
          atMs: _day0 + 5 * 3600000,
        );
        for (final entry in sink.scheduled) {
          final body = entry.$2.body.toLowerCase();
          for (final banned in ContentValidator.forbiddenGuiltLanguage) {
            expect(
              body.contains(banned.toLowerCase()),
              isFalse,
              reason: 'guilt language "$banned" reached the OS payload',
            );
          }
        }
      },
    );

    test('an event adds exactly one OS notification', () async {
      final sink = _RecordingSink();
      final s = _make(sink);
      await s.scheduleEvent(
        kind: NotificationKind.celebration,
        petName: 'Biscuit',
        atMs: _day0 + 12 * 3600000,
        detail: 'a happy milestone',
      );
      expect(sink.scheduled.length, 1);
      expect(sink.scheduled.single.$2.kind, NotificationKind.celebration);
    });

    test('the daily cap is honored at the OS boundary too', () async {
      final sink = _RecordingSink();
      final s = _make(sink);
      // Three events on one day; the hard cap (2) drops the third.
      for (var i = 0; i < 3; i++) {
        await s.scheduleEvent(
          kind: NotificationKind.memory,
          petName: 'Biscuit',
          atMs: _day0 + (3 + i) * 3600000,
        );
      }
      expect(sink.scheduled.length, lessThanOrEqualTo(2));
    });

    test('ids are stable, positive 31-bit ints', () async {
      final sink = _RecordingSink();
      final s = _make(sink);
      await s.scheduleDailyPresence(petName: 'Biscuit', fromMs: _day0, days: 3);
      for (final e in sink.scheduled) {
        expect(e.$1, greaterThanOrEqualTo(0));
        expect(e.$1, lessThanOrEqualTo(0x7FFFFFFF));
      }
    });

    test('cancelAll clears both the logic and the OS', () async {
      final sink = _RecordingSink();
      final s = _make(sink);
      await s.scheduleDailyPresence(petName: 'Biscuit', fromMs: _day0);
      await s.cancelAll();
      expect(s.scheduled, isEmpty);
      expect(sink.cancelAllCalls, greaterThanOrEqualTo(1));
    });
  });

  group('LocalNotificationScheduler — LiveOps kill-switch', () {
    test('killed: daily presence delivers nothing + clears the OS', () async {
      final sink = _RecordingSink();
      final s = _make(sink, killed: true);
      await s.scheduleDailyPresence(petName: 'Biscuit', fromMs: _day0);
      expect(sink.scheduled, isEmpty);
      expect(s.scheduled, isEmpty);
      expect(sink.cancelAllCalls, greaterThanOrEqualTo(1)); // off-switch clears
    });

    test('killed: an event is suppressed', () async {
      final sink = _RecordingSink();
      final s = _make(sink, killed: true);
      await s.scheduleEvent(
        kind: NotificationKind.celebration,
        petName: 'Biscuit',
        atMs: _day0 + 9 * 3600000,
      );
      expect(sink.scheduled, isEmpty);
    });
  });

  group('LocalNotificationScheduler — init + permission pass-through', () {
    test('initialize + requestPermission delegate to the sink', () async {
      final sink = _RecordingSink();
      final s = _make(sink);
      await s.initialize();
      expect(await s.requestPermission(), isTrue);
      expect(sink.initialized, isTrue);
      expect(sink.permissionRequested, isTrue);
    });
  });
}
