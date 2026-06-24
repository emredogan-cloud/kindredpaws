/// Beta feedback loop (P5-5) — the complete closed-beta operations pass over one
/// piece of tester feedback. It **ingests** the rating + note, **tags** its
/// sentiment on-device, **correlates** the session's crash state + a PII-free
/// diagnostic snapshot, **triages** it into a routed/prioritized item, ships the
/// PII-free `betaFeedback` telemetry, and best-effort persists the raw feedback.
/// One call turns "how's it going?" into a worked queue item. Authority:
/// GAME_MASTER_EXECUTION_ROADMAP G3, GAME_TECHNICAL_SYSTEMS §10, brief §10.
library;

import 'analytics_service.dart';
import 'beta_diagnostics.dart';
import 'beta_triage.dart';
import 'feedback_service.dart';
import 'observability.dart';
import 'sentiment.dart';

/// One piece of beta feedback after the full pass: the raw feedback, its
/// sentiment, its triage verdict, the session's crash flag, and the PII-free
/// diagnostic snapshot it was captured with — the bundle a triager reads.
class TriagedFeedback {
  const TriagedFeedback({
    required this.feedback,
    required this.sentiment,
    required this.triage,
    required this.hadCrash,
    required this.diagnostics,
  });

  final BetaFeedback feedback;
  final Sentiment sentiment;
  final Triage triage;
  final bool hadCrash;
  final DiagnosticReport diagnostics;

  /// A complete copy-paste block for the founder's beta queue: the triage
  /// header + the note + the correlated diagnostics. (Internal triage console,
  /// not telemetry — the note text never ships off-device as analytics.)
  String exportText() =>
      'KindredPaws beta item — ${triage.severity.name.toUpperCase()} · '
      '${triage.category.name}\n'
      '  rating=${feedback.rating}★ · sentiment=${sentiment.name} · '
      'crash=$hadCrash\n'
      '  note: ${feedback.comment ?? "(none)"}\n'
      '${diagnostics.exportText()}';
}

class BetaFeedbackPipeline {
  BetaFeedbackPipeline({
    required this.feedback,
    required this.diagnostics,
    required this.observability,
  });

  final FeedbackService feedback;
  final BetaDiagnostics diagnostics;
  final ObservabilityFacade observability;

  /// Runs the full beta-ops pass for one piece of feedback and returns the
  /// triaged item. Never throws into the caller (feedback must not disrupt play).
  Future<TriagedFeedback> ingest({required int rating, String? comment}) async {
    // Ingestion — normalize/clamp/cap (BetaFeedback) so the note is a short,
    // PII-minimized signal.
    final fb = BetaFeedback(rating: rating, comment: comment);

    // Sentiment tagging — on-device, from the (capped) note + the stars. Only
    // the LABEL ever leaves the device; the note text does not ride telemetry.
    final sentiment = tagSentiment(fb.comment, rating: fb.rating);

    // Crash + diagnostic correlation — did THIS session error, and in what build?
    final hadCrash = observability.sessionHealth.hadCrash;
    final report = diagnostics.snapshot();

    // Triage — route + prioritize worst-first (crash wins).
    final triage = triageFeedback(
      rating: fb.rating,
      sentiment: sentiment,
      hadCrash: hadCrash,
      hasComment: fb.comment != null,
    );

    // Telemetry — PII-free triage tags for the founder's beta dashboard.
    observability.event(AnalyticsEvent.betaFeedback, {
      'rating': fb.rating,
      'category': triage.category.name,
      'severity': triage.severity.name,
      'sentiment': sentiment.name,
      'had_crash': hadCrash,
    });

    // Persist the raw feedback to the backend stream (best-effort).
    await feedback.submit(fb);

    return TriagedFeedback(
      feedback: fb,
      sentiment: sentiment,
      triage: triage,
      hadCrash: hadCrash,
      diagnostics: report,
    );
  }
}
