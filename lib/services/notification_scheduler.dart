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

import '../core/local_day.dart';

/// The presence kinds — the set [NotificationScheduler.scheduleDailyPresence]
/// owns and replaces on every re-arm. Event kinds (memory, celebration,
/// streak-warmth) live in their own domain and SURVIVE a presence re-arm
/// (KP-017: re-arming used to wipe a queued celebration before it fired).
const Set<NotificationKind> kPresenceKinds = {
  NotificationKind.reEngagement,
  NotificationKind.daypart,
};

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

/// Rhythm-aware anchor hours (GE-6). Given a 24-bucket histogram of when the
/// household actually opens the app, returns the [cap] best hours to say
/// hello — the peaks of their real rhythm, nudged toward morning/evening and
/// kept apart so two-a-day never bunch up. Falls back to the gentle default
/// anchors when there isn't enough signal yet. Pure + deterministic; the
/// histogram never leaves the device (privacy-first).
List<int> preferredNotificationHours(List<int> histogram, int cap) {
  const morning = 10, evening = 19; // the safe defaults
  final safeCap = cap.clamp(1, 2);
  final total = histogram.fold<int>(0, (a, b) => a + b);
  // Need a little evidence before personalizing (≥ 3 opens); else defaults.
  if (histogram.length != 24 || total < 3) {
    return safeCap == 1 ? const [evening] : const [morning, evening];
  }
  // Rank hours by frequency (ties → earlier hour, for stability).
  final order = List<int>.generate(24, (i) => i)
    ..sort((a, b) {
      final d = histogram[b].compareTo(histogram[a]);
      return d != 0 ? d : a.compareTo(b);
    });
  final best = order.first;
  if (safeCap == 1) return [best];
  // A second, well-separated peak (≥ 4 h from the first) so a pair feels
  // like morning + evening, not two pings in one hour.
  for (final h in order.skip(1)) {
    if ((h - best).abs() >= 4) {
      final pair = [best, h]..sort();
      return pair;
    }
  }
  // No separated second peak → pair the best with the far default anchor.
  final partner = (best - morning).abs() >= (best - evening).abs()
      ? morning
      : evening;
  return ([best, partner]..sort()).toSet().toList();
}

abstract interface class NotificationScheduler {
  /// Ask the OS for notification permission. Called ONLY from the warm
  /// post-adoption priming moment (KP-023) — never at cold boot: the one
  /// system prompt must land after the player is invested, not over the
  /// rainy cold-open's first beat.
  Future<bool> requestPermission();

  /// Schedule the next [days] of warm presence notifications for [petName],
  /// honouring the [dailyCap] (1–2). Replaces any previously-scheduled set.
  /// [preferredHours] (GE-6) overrides the default anchor hours with the
  /// household's real rhythm; when null the gentle 10/19 anchors stand.
  Future<void> scheduleDailyPresence({
    required String petName,
    required int fromMs,
    int dailyCap = 1,
    int days = 3,
    List<int>? preferredHours,
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
  /// [utcOffsetAt] fixes KP-016: anchors are computed on the PLAYER's local
  /// wall clock (10am means 10am here, not 10:00 UTC = 2am California).
  /// Tests keep the deterministic UTC default; production injects the device
  /// offset.
  InMemoryNotificationScheduler({UtcOffsetAt utcOffsetAt = utcOffsetNone})
    : _utcOffsetAt = utcOffsetAt;

  final UtcOffsetAt _utcOffsetAt;
  final List<PetNotification> _scheduled = [];

  /// How many times permission was requested (tests pin the KP-023 timing:
  /// zero at boot, one after the priming card is accepted).
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

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
    // The daily cap is a promise about the player's experienced day — count
    // in the local frame (KP-016/KP-018).
    final day = localDayOf(atMs, _utcOffsetAt);
    return _scheduled
        .where((n) => localDayOf(n.whenMs, _utcOffsetAt) == day)
        .length;
  }

  @override
  Future<void> scheduleDailyPresence({
    required String petName,
    required int fromMs,
    int dailyCap = 1,
    int days = 3,
    List<int>? preferredHours,
  }) async {
    // Replace ONLY the presence set. Queued events (a celebration four hours
    // out, a streak-warmth reassurance) must survive a re-arm — clearing
    // everything silently dropped exactly the delightful moments (KP-017).
    _scheduled.removeWhere((n) => kPresenceKinds.contains(n.kind));
    final cap = dailyCap.clamp(1, InMemoryNotificationScheduler.dailyCap);
    final startDay = localDayOf(fromMs, _utcOffsetAt);
    var templateIndex = 0;
    // The household's real rhythm (GE-6) if provided, else the gentle anchors.
    final anchors = preferredHours != null && preferredHours.isNotEmpty
        ? (preferredHours.take(cap).toList()..sort())
        : (cap == 1 ? const [_evening] : const [_morning, _evening]);

    for (var d = 0; d < days; d++) {
      for (final h in anchors) {
        // The anchor lands on the player's local wall clock (KP-016), DST
        // evaluated at the target instant.
        final whenMs = msAtLocalHour(startDay + d + 1, h, _utcOffsetAt);
        // Presence never stacks a local day past the hard cap — queued
        // events already on that day count against it.
        if (countOnDay(whenMs) >= InMemoryNotificationScheduler.dailyCap) {
          continue;
        }
        final body = warmTemplates[templateIndex % warmTemplates.length]
            .replaceAll('{name}', petName);
        templateIndex++;
        _scheduled.add(
          PetNotification(
            whenMs: whenMs,
            title: petName,
            body: body,
            // On a two-a-day, the earlier anchor reads as a daypart-habit
            // nudge and the later as general re-engagement.
            kind: (anchors.length > 1 && h == anchors.first)
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
