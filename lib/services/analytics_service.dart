/// Analytics taxonomy + abstraction (GAME_TECHNICAL_SYSTEMS.md §10,
/// GAMEPLAY_AND_PROGRESSION_BIBLE.md §17): ~15 events mapped to funnel gates,
/// privacy-by-design, NO PII. This defines the canonical event set and a mock
/// sink; the per-event parameter contract + KPI mapping live in `Telemetry`
/// (`telemetry.dart`) and `docs/TELEMETRY.md`. Wiring Firebase is a
/// provisioning step.
library;

import 'logger.dart' show LogRecord;

/// The canonical ~15-event set. The two mandatory leading-churn indicators
/// (`aiRepetitionFlag`, `guiltFlag`) are non-optional (brief §10).
enum AnalyticsEvent {
  rescueDayComplete,
  sessionStart,
  sessionQuality,
  careAction,
  bondChange,
  bondStageUp,
  lifeStageUp,
  memoryCallback,
  aiRepetitionFlag, // leading churn indicator (mandatory)
  guiltFlag, // leading churn indicator (mandatory)
  streakEvent,
  monetizationEvent,
  compassionCoinMint,
  keepsakeShare,
  llmCostEvent, // R2 / G4: LLM cost/DAU < 35% ARPDAU
  // ---- Phase 5 (soft-launch readiness) ----
  onboardingStep, // Rescue Day funnel step (beat/species/name)
  retentionMilestone, // returned on a D1/D3/D7/D14/D30 boundary since adopt
  notificationOpened, // re-engagement effectiveness (app opened from a notification)
  paywallStep, // monetization funnel step (shown/dismissed/start)
  experimentExposure, // A/B experiment assignment (LiveOps cohorts)
  betaFeedback, // triaged closed-beta feedback (sentiment + crash correlation)
}

abstract interface class AnalyticsService {
  /// Log an event. Implementations MUST drop any PII from [params].
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]);

  /// Reset the analytics identifiers (app-instance / advertising id) so no
  /// future event can be linked back to a deleted account. Part of the
  /// right-to-be-forgotten path (§8.3, §11.2) — called by
  /// `SaveRepository.deleteAccount`.
  void resetIdentifiers();
}

/// In-memory sink: records events for tests/inspection; emits no PII anywhere.
/// Strips [LogRecord.blockedKeys] on write as a defense-in-depth backstop, so
/// even a direct `log()` (bypassing the [ObservabilityFacade] sanitizer) can
/// never rest PII in the buffer.
class InMemoryAnalyticsService implements AnalyticsService {
  final List<(AnalyticsEvent, Map<String, Object?>)> recorded = [];

  /// How many times [resetIdentifiers] has run (test/inspection hook).
  int resetCount = 0;

  @override
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]) {
    final clean = {
      for (final e in params.entries)
        if (!LogRecord.blockedKeys.contains(e.key)) e.key: e.value,
    };
    recorded.add((event, Map.unmodifiable(clean)));
  }

  @override
  void resetIdentifiers() {
    resetCount++;
    // Mirror the real reset: drop buffered events tied to the old identity.
    recorded.clear();
  }

  int countOf(AnalyticsEvent event) =>
      recorded.where((e) => e.$1 == event).length;
}
