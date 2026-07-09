/// The thin, testable seam over the OS notification API (Task 1 — production
/// notification system). The real binding
/// ([FlutterLocalNotificationsSink]) is the ONLY place
/// `flutter_local_notifications` + `timezone` are touched — everything else (the
/// scheduler, all tests, CI) depends on this interface, so the host test suite
/// never loads a platform channel. Same gated-seam pattern as billing/firebase.
library;

import '../notification_scheduler.dart';

/// A device-side notification binding. Implementations must never throw into the
/// caller (a failed schedule must not disrupt play).
abstract interface class OsNotificationSink {
  /// Initialise channels/categories + the timezone database + the tap handler.
  /// [onTap] receives the tapped notification's payload (the deep-link string).
  Future<void> initialize({void Function(String? payload)? onTap});

  /// Ask the OS for permission to post notifications (Android 13+, iOS). Returns
  /// whether it was granted. Safe to call repeatedly.
  Future<bool> requestPermission();

  /// Schedule [notification] at its absolute instant with a stable [id], its
  /// per-kind channel, and a tap [payload] (the deep-link). A past instant is a
  /// no-op (never deliver late).
  Future<void> schedule(
    int id,
    PetNotification notification, {
    required String payload,
  });

  /// Cancel one scheduled notification by [id] (the per-domain primitive —
  /// re-arming daily presence must not wipe pending celebrations, KP-017).
  Future<void> cancel(int id);

  /// Cancel every scheduled notification (kill-switch / notifications-off).
  Future<void> cancelAll();
}

/// Offline default — does nothing (dev / CI / host tests). The scheduler still
/// computes the warm, capped payloads; this simply doesn't reach the OS. Keeps
/// the app fully functional with zero platform dependencies, exactly like the
/// in-memory observability/billing seams.
class NoopOsNotificationSink implements OsNotificationSink {
  const NoopOsNotificationSink();

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(
    int id,
    PetNotification notification, {
    required String payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}
}
