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

  /// OS ids currently mirrored, per domain (KP-017). Presence re-arms cancel
  /// exactly [_presenceIds]; queued event notifications keep their slots.
  final Set<int> _presenceIds = {};
  final Set<int> _eventIds = {};

  /// Monotonic salt so event ids stay unique + stable across presence
  /// re-arms (a list index would shift when the presence set is replaced).
  int _eventSalt = 0;

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
    List<int>? preferredHours,
  }) async {
    // Kill-switch: clear the calendar + deliver nothing.
    if (_killed) {
      await cancelAll();
      return;
    }
    // Recompute the warm presence set (the logic layer preserves queued
    // events), then mirror it to the OS — replacing ONLY the presence domain.
    // `cancelAll()` here used to wipe pending celebration/streak
    // notifications before they could fire (KP-017).
    await _logic.scheduleDailyPresence(
      petName: petName,
      fromMs: fromMs,
      dailyCap: dailyCap,
      days: days,
      preferredHours: preferredHours,
    );
    for (final id in _presenceIds) {
      await _sink.cancel(id);
    }
    _presenceIds.clear();
    var i = 0;
    for (final n in _logic.scheduled.where(
      (n) => kPresenceKinds.contains(n.kind),
    )) {
      final id = _idFor(n, i++);
      _presenceIds.add(id);
      await _sink.schedule(id, n, payload: _payloadFor(n));
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
    // The logic appends (or drops on a full day). Mirror only the new one,
    // with a monotonic salt so its id survives presence re-arms (KP-017).
    final after = _logic.scheduled;
    if (after.length > before) {
      final n = after.last;
      final id = _idFor(n, _eventSalt++) | 0x40000000; // disjoint event range
      _eventIds.add(id);
      await _sink.schedule(id, n, payload: _payloadFor(n));
    }
  }

  @override
  Future<void> cancelAll() async {
    await _logic.cancelAll();
    _presenceIds.clear();
    _eventIds.clear();
    await _sink.cancelAll();
  }

  /// A stable 30-bit notification id (truncated to the minute so re-scheduling
  /// the same slot replaces it). [salt] decorrelates same-minute slots; the
  /// event domain sets bit 30 so the two id spaces can never collide.
  int _idFor(PetNotification n, int salt) =>
      ((n.whenMs ~/ Duration.millisecondsPerMinute) + salt * 1000003) &
      0x3FFFFFFF;

  /// The deep-link payload: the kind name. The app's tap handler maps it to a
  /// destination (memory → Memory Book, celebration → home, …) + emits the
  /// `notificationOpened` analytics event.
  String _payloadFor(PetNotification n) => n.kind.name;
}
