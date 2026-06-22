/// Analytics taxonomy + abstraction (GAME_TECHNICAL_SYSTEMS.md §10,
/// GAMEPLAY_AND_PROGRESSION_BIBLE.md §17): ~15 events mapped to funnel gates,
/// privacy-by-design, NO PII. This defines the canonical event set and a mock
/// sink; wiring Firebase/GameAnalytics is a provisioning step.
library;

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
}

abstract interface class AnalyticsService {
  /// Log an event. Implementations MUST drop any PII from [params].
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]);
}

/// In-memory sink: records events for tests/inspection; emits no PII anywhere.
class InMemoryAnalyticsService implements AnalyticsService {
  final List<(AnalyticsEvent, Map<String, Object?>)> recorded = [];

  @override
  void log(AnalyticsEvent event, [Map<String, Object?> params = const {}]) {
    recorded.add((event, Map.unmodifiable(params)));
  }

  int countOf(AnalyticsEvent event) =>
      recorded.where((e) => e.$1 == event).length;
}
