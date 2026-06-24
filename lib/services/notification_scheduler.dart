/// Pet-voiced local notifications (P1 + P4-4; GAMEPLAY_AND_PROGRESSION_BIBLE
/// §11.3, Risk R6). MVP is **local-scheduled** (no push cost): warm, invitational
/// lines, capped at **1–2/day**, personalised to the pet — NEVER guilt
/// ("{name} found a sunbeam ☀️", never "Your pet is starving!" / "don't lose
/// your streak!").
///
/// Five canonical kinds (P4-4): re-engagement, daypart-habit, memory-nudge,
/// celebration, streak-warmth. Every supported line is opportunity-framed; a
/// test scans them all against the same never-guilt SSOT the dialogue corpus
/// uses (`ContentValidator.forbiddenGuiltLanguage`).
///
/// This is the scheduling LOGIC + copy + caps (fully testable). The native
/// delivery binding (`flutter_local_notifications`) is a thin platform step
/// documented in REQUIRED_ENVIRONMENTS.md; until then the in-memory scheduler
/// computes exactly what would be delivered.
library;

/// The five canonical notification kinds (P4-4).
enum NotificationKind {
  /// 12–18h since last session — a soft, curious pull back.
  reEngagement,

  /// Matches the player's habitual session window (morning/evening anchors).
  daypart,

  /// The pet "remembers" something — the highest-retention lever.
  memory,

  /// A milestone happened (Bond/life-stage up, Gotcha Day) — pride + joy.
  celebration,

  /// Reassurance after a missed day — the streak stayed warm. NEVER punitive.
  streakWarmth,
}

class PetNotification {
  const PetNotification({
    required this.whenMs,
    required this.title,
    required this.body,
    this.kind = NotificationKind.reEngagement,
  });

  final int whenMs;
  final String title;
  final String body;
  final NotificationKind kind;
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

  /// Schedule a single event-driven notification of [kind] at [atMs] (e.g. a
  /// milestone celebration or a streak-warmth reassurance). Respects the
  /// per-day cap — if that day is already full, it is dropped (never spam).
  /// [detail] is an optional warm specifier (e.g. the milestone name).
  Future<void> scheduleEvent({
    required NotificationKind kind,
    required String petName,
    required int atMs,
    String? detail,
  });

  List<PetNotification> get scheduled;

  /// How many notifications are scheduled on the calendar day containing [atMs].
  int countOnDay(int atMs);

  Future<void> cancelAll();
}

/// In-memory implementation: produces the exact warm, capped payloads. The
/// real binding swaps the storage for the OS scheduler.
class InMemoryNotificationScheduler implements NotificationScheduler {
  final List<PetNotification> _scheduled = [];

  /// The hard daily ceiling — never more than this many in a calendar day.
  static const int dailyCap = 2;

  @override
  List<PetNotification> get scheduled => List.unmodifiable(_scheduled);

  /// Re-engagement / daypart presence templates — opportunity-framed, never
  /// loss-framed (Risk R6). `{name}` is the only substitution.
  static const List<String> warmTemplates = [
    '{name} found a sunbeam and thought of you ☀️',
    '{name} is curled up in a cozy spot, waiting to say hi 🐾',
    '{name} saw something fun and wanted to share it with you 💛',
    '{name} is having a calm afternoon and hopes you are too 🍃',
    '{name} did a happy little stretch and wondered how you are 🌿',
    '{name} is keeping your cozy spot warm 🏡',
  ];

  /// Memory-nudge templates (the "it remembers" lever) — warm, never demanding.
  static const List<String> memoryTemplates = [
    '{name} was just thinking about something you shared 💛',
    '{name} remembered a little something about you and smiled ✨',
    '{name} has a happy memory of your time together 🐾',
  ];

  /// Celebration templates — pride + joy. `{detail}` is the milestone (optional).
  static const List<String> celebrationTemplates = [
    '{name} and you reached a special moment together! 🎉',
    'A happy milestone with {name}! 🌟 Come celebrate together 💛',
    '{name} is doing a proud little wiggle about {detail}! ✨',
  ];

  /// Streak-warmth templates — reassurance, welcome-back energy. NEVER "you lost
  /// your streak" / "don't break it." The streak stayed warm.
  static const List<String> streakWarmthTemplates = [
    'Your care streak stayed warm with {name} 🔥 Welcome back any time 💛',
    '{name} kept the cozy going while you were busy — no worries at all 🍃',
    'All good with {name}! Your streak is safe and warm whenever you visit ☀️',
  ];

  static const int _morning =
      10; // local-ish hour anchors (hours from midnight)
  static const int _evening = 19;

  @override
  int countOnDay(int atMs) {
    final day = atMs ~/ Duration.millisecondsPerDay;
    return _scheduled
        .where((n) => n.whenMs ~/ Duration.millisecondsPerDay == day)
        .length;
  }

  @override
  Future<void> scheduleDailyPresence({
    required String petName,
    required int fromMs,
    int dailyCap = 1,
    int days = 3,
  }) async {
    _scheduled.clear();
    final cap = dailyCap.clamp(1, InMemoryNotificationScheduler.dailyCap);
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
            // The morning anchor reads as a daypart-habit nudge; evening as
            // general re-engagement.
            kind: h == _morning
                ? NotificationKind.daypart
                : NotificationKind.reEngagement,
          ),
        );
      }
    }
  }

  @override
  Future<void> scheduleEvent({
    required NotificationKind kind,
    required String petName,
    required int atMs,
    String? detail,
  }) async {
    // Respect the hard daily ceiling — an event on a full day is dropped, never
    // stacked into spam.
    if (countOnDay(atMs) >= dailyCap) return;
    final bank = switch (kind) {
      NotificationKind.memory => memoryTemplates,
      NotificationKind.celebration => celebrationTemplates,
      NotificationKind.streakWarmth => streakWarmthTemplates,
      NotificationKind.reEngagement ||
      NotificationKind.daypart => warmTemplates,
    };
    // Deterministic pick (no RNG): rotate by how many of this kind already exist.
    final i = _scheduled.where((n) => n.kind == kind).length % bank.length;
    final body = bank[i]
        .replaceAll('{name}', petName)
        .replaceAll('{detail}', detail ?? 'how far you have come together');
    _scheduled.add(
      PetNotification(whenMs: atMs, title: petName, body: body, kind: kind),
    );
  }

  @override
  Future<void> cancelAll() async => _scheduled.clear();
}
