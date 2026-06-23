/// Closed-beta feedback hook (P3-7). A tiny seam the in-app "how's it going?"
/// affordance calls so beta testers can rate the experience + leave an optional
/// note. The Noop default keeps dev/CI offline; the backend-backed impl appends
/// to an internal `beta_feedback` stream (never shown to other players, so it is
/// not a UGC surface). Authority: GAME_MASTER_EXECUTION_ROADMAP G3 (closed beta),
/// GAME_TECHNICAL_SYSTEMS.md §10.
library;

import 'backend_service.dart';

/// One structured piece of beta feedback. PII-minimized by construction: a
/// 1–5 [rating] + an optional, length-capped [comment]. No identifiers.
class BetaFeedback {
  const BetaFeedback._({required this.rating, this.comment});

  /// Builds normalized feedback: [rating] clamped to 1–5, [comment] trimmed,
  /// nulled when blank, and capped to [maxCommentLength] so it stays a short
  /// note rather than a data sink.
  factory BetaFeedback({required int rating, String? comment}) {
    final trimmed = comment?.trim() ?? '';
    return BetaFeedback._(
      rating: rating.clamp(1, 5),
      comment: trimmed.isEmpty
          ? null
          : trimmed.substring(
              0,
              trimmed.length > maxCommentLength
                  ? maxCommentLength
                  : trimmed.length,
            ),
    );
  }

  /// Star rating, clamped to 1–5.
  final int rating;

  /// Optional short note (trimmed + capped), or null.
  final String? comment;

  static const int maxCommentLength = 280;

  /// The PII-free payload appended to the feedback stream.
  Map<String, dynamic> toJson() => {
    'rating': rating,
    if (comment != null) 'comment': comment,
  };
}

abstract interface class FeedbackService {
  /// Submit beta feedback. Best-effort; implementations must never throw into
  /// the caller (feedback failing must not disrupt play).
  Future<void> submit(BetaFeedback feedback);
}

/// Offline default — accepts feedback and drops it (dev / CI / pre-provisioning).
class NoopFeedbackService implements FeedbackService {
  const NoopFeedbackService();

  @override
  Future<void> submit(BetaFeedback feedback) async {}
}

/// Appends feedback to the authoritative backend's `beta_feedback` stream.
/// Best-effort: a backend error is swallowed (logged by the caller if needed).
class BackendFeedbackService implements FeedbackService {
  const BackendFeedbackService(this._backend);

  final BackendService _backend;

  /// The append-only stream collecting closed-beta feedback.
  static const String stream = 'beta_feedback';

  @override
  Future<void> submit(BetaFeedback feedback) async {
    try {
      await _backend.append(stream, feedback.toJson());
    } catch (_) {
      // Best-effort: never let feedback submission disrupt the session.
    }
  }
}
