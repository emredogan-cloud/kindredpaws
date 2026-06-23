/// Pet-voiced local notifications (P1 deliverable; GAMEPLAY_AND_PROGRESSION_BIBLE
/// §11.3, Risk R6). MVP is **local-scheduled** (no push cost): warm, invitational
/// lines, capped at 1–2/day, personalised to the pet — NEVER guilt
/// ("Mochi found a sunbeam ☀️", never "Your pet is starving!").
///
/// This is the scheduling LOGIC + copy + caps (fully testable). The native
/// delivery binding (`flutter_local_notifications`) is a thin platform step
/// documented in REQUIRED_ENVIRONMENTS.md; until then the in-memory scheduler
/// computes exactly what would be delivered.
library;

class PetNotification {
  const PetNotification({
    required this.whenMs,
    required this.title,
    required this.body,
  });

  final int whenMs;
  final String title;
  final String body;
}

abstract interface class NotificationScheduler {
  /// Schedule the next [days] of warm presence notifications for [petName],
  /// honouring the [dailyCap] (1–2). Replaces any previously-scheduled set.
  Future<void> scheduleDailyPresence({
    required String petName,
    required int fromMs,
    int dailyCap = 1,
    int days = 3,
  });

  List<PetNotification> get scheduled;
  Future<void> cancelAll();
}

/// In-memory implementation: produces the exact warm, capped payloads. The
/// real binding swaps the storage for the OS scheduler.
class InMemoryNotificationScheduler implements NotificationScheduler {
  final List<PetNotification> _scheduled = [];

  @override
  List<PetNotification> get scheduled => List.unmodifiable(_scheduled);

  /// Warm, invitational templates — every one is opportunity-framed, never
  /// loss-framed (Risk R6). `{name}` is the only substitution.
  static const List<String> warmTemplates = [
    '{name} found a sunbeam and thought of you ☀️',
    '{name} is curled up in a cozy spot, waiting to say hi 🐾',
    '{name} saw something fun and wanted to share it with you 💛',
    '{name} is having a calm afternoon and hopes you are too 🍃',
  ];

  static const int _morning =
      10; // local-ish hour anchors (hours from midnight)
  static const int _evening = 19;

  @override
  Future<void> scheduleDailyPresence({
    required String petName,
    required int fromMs,
    int dailyCap = 1,
    int days = 3,
  }) async {
    _scheduled.clear();
    final cap = dailyCap.clamp(1, 2);
    final startDay = fromMs ~/ Duration.millisecondsPerDay;
    var templateIndex = 0;

    for (var d = 0; d < days; d++) {
      final dayStartMs = (startDay + d + 1) * Duration.millisecondsPerDay;
      final hours = cap == 1 ? const [_evening] : const [_morning, _evening];
      for (final h in hours) {
        final body = warmTemplates[templateIndex % warmTemplates.length]
            .replaceAll('{name}', petName);
        templateIndex++;
        _scheduled.add(
          PetNotification(
            whenMs: dayStartMs + h * Duration.millisecondsPerHour,
            title: petName,
            body: body,
          ),
        );
      }
    }
  }

  @override
  Future<void> cancelAll() async => _scheduled.clear();
}
