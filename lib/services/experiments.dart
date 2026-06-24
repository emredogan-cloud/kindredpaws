/// Experiments coordinator (P5-3) — the safe way to run a soft-launch A/B test.
/// Wraps [LiveOps] variant assignment + the `experimentExposure` telemetry so a
/// consumer just asks "what variant for this user?" and the exposure is logged
/// (once per user, deduped) for lift analysis. Experiments are OFF by default
/// (everyone `control`); the founder enables one via Remote Config — and can
/// emergency-rollback to control instantly, no app update. Authority:
/// GAME_TECHNICAL_SYSTEMS.md §9, brief §11 R8.
library;

import 'analytics_service.dart';
import 'live_ops.dart';
import 'observability.dart';

class Experiments {
  Experiments({required this.liveOps, required this.observability});

  final LiveOps liveOps;
  final ObservabilityFacade observability;

  /// Exposure is logged once per `(experiment, unit)` in a process lifetime.
  final Set<String> _exposed = {};

  /// Returns the sticky variant for [exp] + [unitId] and emits
  /// `experimentExposure {experiment, variant}` the first time (joins to the
  /// outcome events for lift analysis). [treatments] is the number of treatment
  /// arms beyond control (1 ⇒ A/B, 2 ⇒ A/B/C).
  ExperimentVariant expose(
    Experiment exp, {
    required String unitId,
    int treatments = 1,
  }) {
    final variant = liveOps.assignVariant(
      exp,
      unitId: unitId,
      treatments: treatments,
    );
    if (_exposed.add('${exp.key}:$unitId')) {
      observability.event(AnalyticsEvent.experimentExposure, {
        'experiment': exp.key,
        'variant': variant.name,
      });
    }
    return variant;
  }
}
