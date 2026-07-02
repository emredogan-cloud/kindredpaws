/// The REAL OS notification binding (Task 1) — the single file that imports
/// `flutter_local_notifications` + `timezone`. Wired only in `main()` on a real
/// build (a production swap, like `PrefsHomeWidgetService`); CI / host tests use
/// [NoopOsNotificationSink], so the plugin's platform channels are never loaded
/// off-device. Never throws into the caller.
///
/// Design choices that keep notifications gentle (Risk R6): one **low-importance**
/// channel per kind (silent, non-intrusive, user-tunable in OS settings),
/// **inexact** scheduling (battery-friendly, no exact-alarm permission), and a
/// timezone-safe absolute instant via `tz.TZDateTime` (no naive `DateTime` — the
/// classic DST bug is avoided). Reboot restore is handled natively by the
/// plugin's `ScheduledNotificationBootReceiver` (declared in AndroidManifest).
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../notification_scheduler.dart';
import 'os_notification_sink.dart';

class FlutterLocalNotificationsSink implements OsNotificationSink {
  FlutterLocalNotificationsSink({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// The shared iOS category for all warm pet notifications.
  static const String _iosCategory = 'kp_warm';

  /// One gentle, low-importance channel per kind so the player can tune each in
  /// OS settings. (id, name, description).
  static const Map<NotificationKind, (String, String, String)> _channels = {
    NotificationKind.reEngagement: (
      'kp_presence',
      'Gentle hellos',
      'Soft, invitational nudges from your companion. Never pushy.',
    ),
    NotificationKind.daypart: (
      'kp_daypart',
      'Daily rhythm',
      'A warm hello around your usual visiting time.',
    ),
    NotificationKind.memory: (
      'kp_memory',
      'Little memories',
      'When your companion remembers something you shared.',
    ),
    NotificationKind.celebration: (
      'kp_celebration',
      'Happy moments',
      'Milestones and joyful moments to celebrate together.',
    ),
    NotificationKind.streakWarmth: (
      'kp_warmth',
      'Warm reassurance',
      'Gentle, no-pressure welcome-backs. Your streak stays warm.',
    ),
  };

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    try {
      tzdata.initializeTimeZones();
      // tz.local defaults to UTC; notifications fire at the correct ABSOLUTE
      // instant regardless. (Mapping anchors to the device's local wall-clock is
      // a documented enhancement — see NOTIFICATION_SYSTEM_REMEDIATION_REPORT.md.)

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        // Permission is requested explicitly later (a warm in-context prompt),
        // not at init — so we don't pop a system dialog on first launch.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [DarwinNotificationCategory(_iosCategory)],
      );

      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
        onDidReceiveNotificationResponse: (resp) => onTap?.call(resp.payload),
      );

      final android0 = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      for (final ch in _channels.values) {
        await android0?.createNotificationChannel(
          AndroidNotificationChannel(
            ch.$1,
            ch.$2,
            description: ch.$3,
            importance: Importance.low, // gentle: no sound/heads-up
          ),
        );
      }
    } catch (_) {
      // Never let notification setup break boot.
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final a = await android?.requestNotificationsPermission() ?? false;
      final i =
          await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return a || i;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> schedule(
    int id,
    PetNotification notification, {
    required String payload,
  }) async {
    try {
      final when = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.local,
        notification.whenMs,
      );
      // Never deliver in the past.
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;

      final ch = _channels[notification.kind]!;
      await _plugin.zonedSchedule(
        id: id,
        title: notification.title,
        body: notification.body,
        scheduledDate: when,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            ch.$1,
            ch.$2,
            channelDescription: ch.$3,
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: _iosCategory,
            presentBadge: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      // A single failed schedule must never disrupt play.
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
