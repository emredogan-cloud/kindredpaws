/// Issue triage (P5-5) — turns one piece of beta feedback into a routed,
/// prioritized item so the founder works the queue worst-first instead of
/// reading every note cold. Pure + deterministic over the signals the pipeline
/// already has (rating, sentiment, whether the session crashed, whether there's
/// a note), so it is fully testable and carries no PII. Authority:
/// GAME_TECHNICAL_SYSTEMS §10 (closed-beta ops), brief §10.
library;

import 'sentiment.dart';

/// Where a piece of feedback routes.
enum TriageCategory {
  /// The session crashed/errored — a stability issue, regardless of words.
  crashReport,

  /// An unhappy player (low stars / negative note) — the churn-risk queue.
  detractor,

  /// A concrete idea or report from an otherwise-neutral player.
  suggestion,

  /// Happy feedback — a promoter (testimonial / what's-working signal).
  praise,

  /// No strong signal either way.
  neutral,
}

/// How urgently it should be looked at (P1 = drop-everything).
enum TriageSeverity { p1, p2, p3 }

/// The triage verdict for one piece of feedback.
class Triage {
  const Triage({required this.category, required this.severity});

  final TriageCategory category;
  final TriageSeverity severity;
}

/// Classifies feedback worst-first. **Crash correlation wins** — a session that
/// crashed is always a P1 `crashReport` (a 5★ "loved it!" still matters if it
/// crashed). Then unhappy players (low stars or negative/mixed sentiment) are
/// P2 `detractor`s, happy players are `praise`, a neutral player with a note is
/// a `suggestion`, and the rest is `neutral`.
Triage triageFeedback({
  required int rating,
  required Sentiment sentiment,
  required bool hadCrash,
  required bool hasComment,
}) {
  if (hadCrash) {
    return const Triage(
      category: TriageCategory.crashReport,
      severity: TriageSeverity.p1,
    );
  }

  final unhappy =
      rating <= 2 ||
      sentiment == Sentiment.negative ||
      sentiment == Sentiment.mixed;
  if (unhappy) {
    // A 1★ detractor is more urgent (P2) than a 3★ grumble with a quibble (P3).
    final severity = (rating <= 2 || sentiment == Sentiment.negative)
        ? TriageSeverity.p2
        : TriageSeverity.p3;
    return Triage(category: TriageCategory.detractor, severity: severity);
  }

  if (sentiment == Sentiment.positive || rating >= 4) {
    return const Triage(
      category: TriageCategory.praise,
      severity: TriageSeverity.p3,
    );
  }

  if (hasComment) {
    return const Triage(
      category: TriageCategory.suggestion,
      severity: TriageSeverity.p3,
    );
  }

  return const Triage(
    category: TriageCategory.neutral,
    severity: TriageSeverity.p3,
  );
}
