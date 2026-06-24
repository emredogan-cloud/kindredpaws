/// Product-health metrics derivation (P5-0). Pure functions over the recorded
/// analytics events that compute the soft-launch KPIs + leading-churn signals —
/// the exact math the founder dashboards (Firebase Analytics → BigQuery) report.
/// Keeping it as a tested module makes the dashboard definitions reviewable and
/// proves the funnels are computable from the (PII-free) event stream.
///
/// Authority: GAME_TECHNICAL_SYSTEMS.md §10, brief §10, roadmap §9 (G4).
/// See `docs/ANALYTICS_DASHBOARDS.md` for the events → KPIs → dashboards mapping.
library;

import 'analytics_service.dart';

/// Computes funnel / retention / churn-risk metrics from a list of recorded
/// `(event, params)` tuples (the [InMemoryAnalyticsService.recorded] shape; in
/// production the same definitions run server-side over the event warehouse).
class AnalyticsMetrics {
  const AnalyticsMetrics(this.events);

  final List<(AnalyticsEvent, Map<String, Object?>)> events;

  int count(AnalyticsEvent e) => events.where((r) => r.$1 == e).length;

  int _where(AnalyticsEvent e, bool Function(Map<String, Object?>) p) =>
      events.where((r) => r.$1 == e && p(r.$2)).length;

  static double _ratio(int num, int den) => den == 0 ? 0 : num / den;

  /// Onboarding activation: completed Rescue Days / onboarding starts (the first
  /// beat). The G3/§13.4 target is ≥0.80.
  double get onboardingCompletionRate => _ratio(
    count(AnalyticsEvent.rescueDayComplete),
    _where(AnalyticsEvent.onboardingStep, (m) => m['step'] == 'reach_out'),
  );

  /// Empty-session rate (`sessionQuality.empty`) — the daily-retention churn
  /// lever: a player who opened and did nothing.
  double get emptySessionRate => _ratio(
    _where(AnalyticsEvent.sessionQuality, (m) => m['empty'] == true),
    count(AnalyticsEvent.sessionQuality),
  );

  /// "It remembered me" effectiveness: callbacks that landed / callbacks shown.
  double get memoryCallbackLandedRate => _ratio(
    _where(AnalyticsEvent.memoryCallback, (m) => m['landed'] == true),
    count(AnalyticsEvent.memoryCallback),
  );

  /// Leading-churn #1 — "noticed AI repetition" flags per session.
  double get aiRepetitionRate => _ratio(
    count(AnalyticsEvent.aiRepetitionFlag),
    count(AnalyticsEvent.sessionStart),
  );

  /// Leading-churn #2 — "felt guilt-tripped" flags per session (≈0 by design).
  double get guiltRate => _ratio(
    count(AnalyticsEvent.guiltFlag),
    count(AnalyticsEvent.sessionStart),
  );

  /// Paywall conversion: purchases / paywalls shown.
  double get paywallConversionRate => _ratio(
    count(AnalyticsEvent.monetizationEvent),
    _where(AnalyticsEvent.paywallStep, (m) => m['step'] == 'shown'),
  );

  /// Notification re-engagement opens, grouped by kind.
  Map<String, int> get notificationOpensByKind {
    final out = <String, int>{};
    for (final r in events) {
      if (r.$1 == AnalyticsEvent.notificationOpened) {
        final k = '${r.$2['kind']}';
        out.update(k, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return out;
  }

  /// Retention-milestone returns, grouped by day (1/3/7/14/30).
  Map<int, int> get retentionMilestonesByDay {
    final out = <int, int>{};
    for (final r in events) {
      if (r.$1 == AnalyticsEvent.retentionMilestone) {
        final d = r.$2['day'];
        if (d is int) out.update(d, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return out;
  }

  /// A composite churn-RISK score in `0..1` (higher = more at-risk). The two
  /// mandatory leading-churn indicators predict D7/D30 collapse *before* raw
  /// retention moves (brief §10); blended with the empty-session lever. This is
  /// a dashboard alarm signal, not a player-facing value.
  double get churnRiskScore {
    final s =
        0.5 * emptySessionRate +
        0.3 * aiRepetitionRate.clamp(0.0, 1.0) +
        0.2 * guiltRate.clamp(0.0, 1.0);
    return s.clamp(0.0, 1.0);
  }
}
