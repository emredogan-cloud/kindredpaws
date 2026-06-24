/// Production notification scheduler (Task 1) — the [NotificationScheduler] that
/// actually delivers to the OS. It REUSES the warm, capped, never-guilt payload
/// logic of [InMemoryNotificationScheduler] (so the copy + 1–2/day caps + the
/// five canonical kinds are unchanged + still test-pinned) and adds the device
/// binding via an [OsNotificationSink], plus the LiveOps kill-switch.
///
/// Ethical wall, preserved end-to-end: every payload is opportunity-framed —
/// never guilt, never shame, never "your pet is starving" / "don't lose your
/// streak". The scheduler cannot invent copy; it only forwards the reviewed
/// templates. Authority: GAMEPLAY_AND_PROGRESSION_BIBLE §11.3, Risk R6.
library;

import 'live_ops.dart';
import 'notification_scheduler.dart';
import 'notifications/os_notification_sink.dart';

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({
    required OsNotificationSink sink,
    NotificationScheduler? logic,
    LiveOps? liveOps,
  }) : _sink = sink,
       _logic = logic ?? InMemoryNotificationScheduler(),
       _liveOps = liveOps;

  final OsNotificationSink _sink;

  /// Pure payload computation (warm copy + caps + kinds). Never reaches the OS.
  final NotificationScheduler _logic;

  /// LiveOps control plane (P4-3). When `notifications` is killed, nothing is
  /// delivered and the calendar is cleared — the founder's incident off-switch.
  final LiveOps? _liveOps;

  bool get _killed => _liveOps?.isKilled(LiveFeature.notifications) ?? false;

  /// Initialise the device binding (channels/categories/tz/tap handler). Call
  /// once at startup, before scheduling.
  Future<void> initialize({void Function(String? payload)? onTap}) =>
      _sink.initialize(onTap: onTap);

  /// Request OS permission (Android 13+ / iOS). Returns whether granted.
  Future<bool> requestPermission() => _sink.requestPermission();

  @override
  List<PetNotification> get scheduled => _logic.scheduled;

  @override
  int countOnDay(int atMs) => _logic.countOnDay(atMs);

  @override
  Future<void> scheduleDailyPresence({
    required String petName,
    required int fromMs,
    int dailyCap = 1,
    int days = 3,
  }) async {
    // Kill-switch: clear the calendar + deliver nothing.
    if (_killed) {
      await cancelAll();
      return;
    }
    // Recompute the warm set, then mirror it to the OS (replace the prior set).
    await _logic.scheduleDailyPresence(
      petName: petName,
      fromMs: fromMs,
      dailyCap: dailyCap,
      days: days,
    );
    await _sink.cancelAll();
    var i = 0;
    for (final n in _logic.scheduled) {
      await _sink.schedule(_idFor(n, i++), n, payload: _payloadFor(n));
    }
  }

  @override
  Future<void> scheduleEvent({
    required NotificationKind kind,
    required String petName,
    required int atMs,
    String? detail,
  }) async {
    if (_killed) return;
    final before = _logic.scheduled.length;
    await _logic.scheduleEvent(
      kind: kind,
      petName: petName,
      atMs: atMs,
      detail: detail,
    );
    // The logic appends (or drops on a full day). Mirror only the new one.
    final after = _logic.scheduled;
    if (after.length > before) {
      final n = after.last;
      await _sink.schedule(_idFor(n, after.length), n, payload: _payloadFor(n));
    }
  }

  @override
  Future<void> cancelAll() async {
    await _logic.cancelAll();
    await _sink.cancelAll();
  }

  /// A stable 31-bit notification id (truncated to the minute so re-scheduling
  /// the same slot replaces it). [salt] decorrelates same-minute slots.
  int _idFor(PetNotification n, int salt) =>
      ((n.whenMs ~/ Duration.millisecondsPerMinute) + salt * 1000003) &
      0x7FFFFFFF;

  /// The deep-link payload: the kind name. The app's tap handler maps it to a
  /// destination (memory → Memory Book, celebration → home, …) + emits the
  /// `notificationOpened` analytics event.
  String _payloadFor(PetNotification n) => n.kind.name;
}
