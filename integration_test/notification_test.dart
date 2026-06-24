import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kindredpaws/services/local_notification_scheduler.dart';
import 'package:kindredpaws/services/notifications/flutter_local_notifications_sink.dart';

/// On-device validation of the REAL production notification path (Task 1): the
/// FlutterLocalNotificationsSink actually initialises channels, requests
/// permission, and schedules the warm, capped, never-guilt set against the OS —
/// then we read them back from the OS via `pendingNotificationRequests`. Runs on
/// a device/emulator via `flutter test integration_test/notification_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real plugin: schedule → OS holds them → cancel clears', (
    tester,
  ) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final scheduler = LocalNotificationScheduler(
      sink: FlutterLocalNotificationsSink(plugin: plugin),
    );

    await scheduler.initialize();
    await scheduler.requestPermission();
    await scheduler.cancelAll();

    final now = DateTime.now().millisecondsSinceEpoch;
    await scheduler.scheduleDailyPresence(
      petName: 'Biscuit',
      fromMs: now,
      dailyCap: 2,
      days: 3,
    );

    // The OS now holds the scheduled, warm notifications.
    final pending = await plugin.pendingNotificationRequests();
    expect(pending, isNotEmpty, reason: 'OS should hold the scheduled set');
    expect(
      pending.any((p) => (p.body ?? '').contains('Biscuit')),
      isTrue,
      reason: 'payloads are personalised + warm',
    );
    expect(
      pending.every((p) => (p.payload ?? '').isNotEmpty),
      isTrue,
      reason: 'every notification carries a deep-link payload',
    );

    // Cancelling clears the OS calendar.
    await scheduler.cancelAll();
    expect(await plugin.pendingNotificationRequests(), isEmpty);
  });
}
