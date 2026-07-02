/// Telemetry taxonomy (P3-1) — the production single source of truth for the
/// analytics event set. Each [AnalyticsEvent] has exactly one [EventSpec]
/// describing the closed-beta KPI / funnel gate it feeds and its exact,
/// PII-free parameter contract. [Telemetry.sanitize] is applied to every event
/// before it reaches a sink, so the contract is *enforced*, not just documented:
///
///  * PII-bearing keys ([LogRecord.blockedKeys]) are always dropped, and
///  * for an event with a declared schema, any key outside its allowed set is
///    dropped too (so a new/typo'd param can never silently ship).
///
/// The full taxonomy + KPI mapping + privacy rules live in `docs/TELEMETRY.md`.
/// See [ObservabilityFacade] for the emit path and the leading-churn helpers.
library;

import 'analytics_service.dart';
import 'logger.dart';

/// The closed-beta KPI / funnel gate an event feeds — used for dashboards and
/// the taxonomy doc. (Authority: GAME_TECHNICAL_SYSTEMS.md §10, the canonical
/// brief §10, GAME_MASTER_EXECUTION_ROADMAP.md §8/§14.)
enum TelemetryGate {
  /// Rescue Day onboarding funnel (G2/G3 activation).
  onboarding,

  /// D1/D7/D30 retention (G3 ≥40%/≥18%; G4 adds D30 ≥10%).
  retention,

  /// Core care-loop engagement (G1).
  engagement,

  /// Bond / life-stage progression payoff.
  progression,

  /// AI memory-callback reliability — hard G2 gate ≥95%.
  aiReliability,

  /// Leading-churn indicators (ai-repetition / guilt) — predict D7/D30 collapse
  /// before raw retention moves (brief §10). Guilt should be ~zero by design.
  leadingChurn,

  /// ARPDAU / subscription conversion (G4/G6).
  monetization,

  /// Keepsake shares / viral K-factor — G4 ≥1 share per DAU-week.
  virality,

  /// Donation volume + anti-fraud (Impact Pledge, G6).
  impact,

  /// LLM cost/DAU — hard gate <35% of ARPDAU (R2/G4).
  cost,

  /// A/B experiment exposure — variant assignment for soft-launch experiments
  /// (P5; LiveOps cohorts). Pairs with the per-gate outcome events.
  experiment,

  /// Closed-beta operations — triaged tester feedback (sentiment + crash
  /// correlation) that feeds the founder's beta issue queue (P5-5).
  betaOps,
}

/// The contract for one analytics event: which KPI gate it feeds plus the exact
/// parameter keys it may carry. PII keys are forbidden for *every* event and
/// enforced separately ([LogRecord.blockedKeys]).
class EventSpec {
  const EventSpec({
    required this.gate,
    required this.description,
    this.required = const {},
    this.optional = const {},
  });

  /// The KPI / funnel gate this event feeds.
  final TelemetryGate gate;

  /// One-line human description (trigger + meaning).
  final String description;

  /// Parameter keys that MUST be present (asserted in debug).
  final Set<String> required;

  /// Additional parameter keys that MAY be present.
  final Set<String> optional;

  /// Every key this event is allowed to carry. When empty, the event accepts a
  /// free-form (but still PII-stripped) context map — used by the leading-churn
  /// flags whose context is intentionally open-ended.
  Set<String> get allowedKeys => {...required, ...optional};
}

/// The canonical registry: exactly one [EventSpec] per [AnalyticsEvent].
/// [debugAssertComplete] guarantees totality (a test pins it).
abstract final class Telemetry {
  const Telemetry._();

  static const Map<AnalyticsEvent, EventSpec> specs = {
    AnalyticsEvent.rescueDayComplete: EventSpec(
      gate: TelemetryGate.onboarding,
      description: 'Rescue Day onboarding completed (pet adopted + named).',
      required: {'species'},
    ),
    AnalyticsEvent.sessionStart: EventSpec(
      gate: TelemetryGate.retention,
      description: 'A play session began (after offline catch-up resolved).',
      required: {'offline_hours'},
    ),
    AnalyticsEvent.sessionQuality: EventSpec(
      gate: TelemetryGate.retention,
      description:
          'Session-quality summary at session end. `empty=false` means the '
          'session had ≥1 meaningful beat (greeting/callback/need/tick).',
      required: {'empty', 'interactions_n', 'duration_s'},
    ),
    AnalyticsEvent.careAction: EventSpec(
      gate: TelemetryGate.engagement,
      description: 'A feed/clean/play care interaction.',
      required: {'verb', 'bond_awarded', 'needed'},
    ),
    AnalyticsEvent.bondChange: EventSpec(
      gate: TelemetryGate.progression,
      description: 'Bond total changed (carries the new total).',
      required: {'value'},
    ),
    AnalyticsEvent.bondStageUp: EventSpec(
      gate: TelemetryGate.progression,
      description:
          'Bond crossed into a new stage (milestone, distinct from '
          'continuous bondChange).',
      required: {'stage'},
    ),
    AnalyticsEvent.lifeStageUp: EventSpec(
      gate: TelemetryGate.progression,
      description: 'Pet grew into a new life stage.',
      required: {'stage'},
    ),
    AnalyticsEvent.memoryCallback: EventSpec(
      gate: TelemetryGate.aiReliability,
      description:
          'The pet surfaced a real memory ("it remembered me"). Feeds the hard '
          'G2 ≥95% callback-reliability gate.',
      required: {'facts'},
      optional: {'landed'},
    ),
    AnalyticsEvent.aiRepetitionFlag: EventSpec(
      gate: TelemetryGate.leadingChurn,
      description:
          'LEADING CHURN #1: the player noticed AI repetition. Open context '
          '(PII-stripped). Trend predicts D7/D30 collapse (brief §10).',
    ),
    AnalyticsEvent.guiltFlag: EventSpec(
      gate: TelemetryGate.leadingChurn,
      description:
          'LEADING CHURN #2: the player felt guilt-tripped. Should be ~zero by '
          'construction in a cozy game; any hit is a red flag.',
    ),
    AnalyticsEvent.streakEvent: EventSpec(
      gate: TelemetryGate.engagement,
      description: 'Care-streak advanced (habit loop).',
      required: {'count'},
    ),
    AnalyticsEvent.monetizationEvent: EventSpec(
      gate: TelemetryGate.monetization,
      description:
          'A monetization event (purchase/restore/subscription). '
          'Emitted by the monetization subsystem (P3-5).',
      required: {'stream', 'sku', 'value'},
    ),
    AnalyticsEvent.compassionCoinMint: EventSpec(
      gate: TelemetryGate.impact,
      description:
          'Compassion Coins minted (donation/impact). `validated` is '
          'the anti-fraud flag. Emitted by the impact-ledger subsystem.',
      required: {'source', 'amount', 'validated'},
    ),
    AnalyticsEvent.keepsakeShare: EventSpec(
      gate: TelemetryGate.virality,
      description:
          'A Keepsake card was shared (K-factor). Emitted by the share '
          'flow (Content OS, P3-3).',
      required: {'moment_type', 'platform'},
    ),
    AnalyticsEvent.llmCostEvent: EventSpec(
      gate: TelemetryGate.cost,
      description:
          'LLM token/cost for a metered turn. Pre-gen bank reads are \$0 by '
          'design; the live-chat path (P4, Deferred) meters this. Feeds the '
          'hard cost/DAU <35% ARPDAU gate (R2).',
      required: {'tokens', 'cost', 'model'},
    ),
    // ---- Phase 5 (soft-launch readiness) ----
    AnalyticsEvent.onboardingStep: EventSpec(
      gate: TelemetryGate.onboarding,
      description:
          'A Rescue Day onboarding funnel step was reached (the cold-open beats, '
          'species choice, name field). Feeds the activation funnel + drop-off '
          'analysis (≥80% complete Rescue Day, §13.4).',
      required: {'step'},
      optional: {'ms_since_start'},
    ),
    AnalyticsEvent.retentionMilestone: EventSpec(
      gate: TelemetryGate.retention,
      description:
          'The player returned on a D1/D3/D7/D14/D30 boundary since adopting. '
          'Feeds the D1≥42% / D7≥20% / D30≥10% retention gates (G4).',
      required: {'day'},
    ),
    AnalyticsEvent.kindnessComplete: EventSpec(
      gate: TelemetryGate.retention,
      description:
          'A Daily Kindness completed through a real care moment (GE-1). '
          'Kept separate from careAction so the care funnel stays pure; '
          'measures whether the daily-variety loop lands (Genre Evolution).',
      required: {'kindness', 'kibble'},
      optional: {'all_done'},
    ),
    AnalyticsEvent.notificationOpened: EventSpec(
      gate: TelemetryGate.retention,
      description:
          'The app was opened from a notification — re-engagement effectiveness '
          'per notification kind (G3/G4).',
      required: {'kind'},
    ),
    AnalyticsEvent.paywallStep: EventSpec(
      gate: TelemetryGate.monetization,
      description:
          'A monetization funnel step (paywall shown/dismissed, purchase/restore '
          'started). Feeds ARPDAU + sub-conversion analysis (G4/G6).',
      required: {'step'},
      optional: {'surface'},
    ),
    AnalyticsEvent.experimentExposure: EventSpec(
      gate: TelemetryGate.experiment,
      description:
          'An A/B experiment assigned a variant to this user (LiveOps cohort). '
          'Joins to the per-gate outcome events for lift analysis.',
      required: {'experiment', 'variant'},
    ),
    AnalyticsEvent.betaFeedback: EventSpec(
      gate: TelemetryGate.betaOps,
      description:
          'A piece of closed-beta feedback after triage: the star rating, the '
          'routed category + severity, the note sentiment, and whether the '
          'session crashed (crash correlation). PII-free — no note text ships.',
      required: {'rating', 'category', 'severity', 'sentiment', 'had_crash'},
    ),
  };

  /// The single [EventSpec] for [e] (every event is registered).
  static EventSpec specOf(AnalyticsEvent e) => specs[e]!;

  /// The set of params actually safe to ship for [e]: PII keys are always
  /// dropped, and — when [e] declares a schema — any key outside its allowed set
  /// is dropped too. An empty-schema event (the open-ended leading-churn flags)
  /// accepts any non-PII key but only **coarse** (non-String) values: a free-text
  /// String value is the one way PII could ride an un-declared key, so it is
  /// dropped (P3-8 audit). Declared-schema events keep their String values (the
  /// keys are explicitly contracted as coarse).
  static Map<String, Object?> sanitize(
    AnalyticsEvent e,
    Map<String, Object?> params,
  ) {
    final allowed = specs[e]?.allowedKeys ?? const <String>{};
    final strict = allowed.isNotEmpty;
    return {
      for (final entry in params.entries)
        if (!LogRecord.blockedKeys.contains(entry.key) &&
            (strict ? allowed.contains(entry.key) : entry.value is! String))
          entry.key: entry.value,
    };
  }

  /// Required param keys missing from [params] (debug-time contract check).
  static Set<String> missingRequired(
    AnalyticsEvent e,
    Map<String, Object?> params,
  ) {
    final req = specs[e]?.required ?? const <String>{};
    return req.difference(params.keys.toSet());
  }

  /// Asserts every [AnalyticsEvent] has a spec — pinned by a unit test so the
  /// registry can never drift out of totality.
  static bool debugAssertComplete() {
    for (final e in AnalyticsEvent.values) {
      assert(specs.containsKey(e), 'Telemetry: no EventSpec for $e');
    }
    return specs.length == AnalyticsEvent.values.length;
  }
}
