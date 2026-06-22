/// LLM unit-economics model v1 — Phase-0 / G0 pass criterion #3:
/// "LLM cost/DAU model shows < ARPDAU at projected mix."
///
/// Implements the guard equation from GAME_TECHNICAL_SYSTEMS.md §12.3:
///
///   LLM_cost_per_DAU = amortized_pregen_per_DAU
///                    + live_chat_share × avg_turns × per_turn_token_cost
///                    + live_chat_share × avg_turns × moderation_per_turn
///   REQUIRE: LLM_cost_per_DAU < 0.35 × ARPDAU         (hard gate G4)
///
/// Pricing is the verified Anthropic list price (claude-api skill, 2026):
///   Haiku 4.5 (runtime/live): $1.00 in / $5.00 out per MTok;
///     prompt-cache read ~0.1× ($0.10/MTok), write 1.25× 5-min ($1.25/MTok).
///   Opus 4.8 (offline pre-gen, paid once): $5.00 in / $25.00 out per MTok.
///
/// Key structural result: the MVP hybrid path uses **zero runtime tokens** (the
/// bank is selected on-device), so MVP LLM cost/DAU ≈ the amortized pre-gen
/// pass, which is structurally tiny. The metered live-chat path is Deferred and
/// subscriber-funded; this model proves it stays within the gate when capped.
library;

class ModelPricing {
  const ModelPricing({
    required this.inputPerMTok,
    required this.outputPerMTok,
    required this.cacheReadPerMTok,
    required this.cacheWritePerMTok,
  });

  final double inputPerMTok;
  final double outputPerMTok;
  final double cacheReadPerMTok;
  final double cacheWritePerMTok;

  /// Founder-locked runtime model ("Claude Haiku 4" → claude-haiku-4-5).
  static const ModelPricing haiku45 = ModelPricing(
    inputPerMTok: 1.0,
    outputPerMTok: 5.0,
    cacheReadPerMTok: 0.10, // ~0.1× input
    cacheWritePerMTok: 1.25, // 1.25× input (5-minute TTL)
  );

  /// Offline pre-generation model (quality, paid once).
  static const ModelPricing opus48 = ModelPricing(
    inputPerMTok: 5.0,
    outputPerMTok: 25.0,
    cacheReadPerMTok: 0.50,
    cacheWritePerMTok: 6.25,
  );
}

class LlmCostScenario {
  const LlmCostScenario({
    required this.name,
    required this.arpdauUsd,
    required this.pregenOneTimeUsd,
    required this.amortizationInstalls,
    required this.liveChatDauShare,
    required this.avgLiveTurnsPerActiveDau,
    required this.personaPromptTokens,
    required this.perTurnInputTokens,
    required this.perTurnOutputTokens,
    required this.moderationCostPerTurnUsd,
    this.personaCached = true,
    this.runtime = ModelPricing.haiku45,
  });

  final String name;
  final double arpdauUsd;

  /// One-time Opus pre-generation spend for the reviewed dialogue bank.
  final double pregenOneTimeUsd;

  /// Install base the one-time pre-gen cost is amortized across.
  final int amortizationInstalls;

  /// Fraction of DAU who use the Deferred live chat (subscribers only).
  final double liveChatDauShare;
  final double avgLiveTurnsPerActiveDau;

  /// Cached persona prefix (read each live turn at cacheReadPerMTok).
  final int personaPromptTokens;

  /// Uncached per-turn input (user message + injected memory facts).
  final int perTurnInputTokens;

  /// Capped per-turn output (~60–100 tokens).
  final int perTurnOutputTokens;

  /// Two-sided moderation cost per live turn.
  final double moderationCostPerTurnUsd;

  final bool personaCached;
  final ModelPricing runtime;
}

class LlmCostBreakdown {
  const LlmCostBreakdown({
    required this.scenarioName,
    required this.amortizedPregenPerDauUsd,
    required this.liveChatTokensPerDauUsd,
    required this.moderationPerDauUsd,
    required this.costPerDauUsd,
    required this.arpdauUsd,
  });

  final String scenarioName;
  final double amortizedPregenPerDauUsd;
  final double liveChatTokensPerDauUsd;
  final double moderationPerDauUsd;
  final double costPerDauUsd;
  final double arpdauUsd;

  /// LLM cost as a fraction of ARPDAU.
  double get ratio =>
      arpdauUsd > 0 ? costPerDauUsd / arpdauUsd : double.infinity;

  /// The hard G4 gate: LLM cost/DAU must be < 35% of ARPDAU.
  bool get passesGuardGate => costPerDauUsd < guardThreshold * arpdauUsd;

  static const double guardThreshold = 0.35;
}

LlmCostBreakdown computeLlmCost(LlmCostScenario s) {
  final amortizedPregen = s.amortizationInstalls > 0
      ? s.pregenOneTimeUsd / s.amortizationInstalls
      : 0.0;

  final personaPerTurn = s.personaCached
      ? s.personaPromptTokens * s.runtime.cacheReadPerMTok / 1e6
      : s.personaPromptTokens * s.runtime.inputPerMTok / 1e6;
  final inputPerTurn = s.perTurnInputTokens * s.runtime.inputPerMTok / 1e6;
  final outputPerTurn = s.perTurnOutputTokens * s.runtime.outputPerMTok / 1e6;
  final perTurnTokenCost = personaPerTurn + inputPerTurn + outputPerTurn;

  final liveTurnsPerDau = s.liveChatDauShare * s.avgLiveTurnsPerActiveDau;
  final liveChatTokensPerDau = liveTurnsPerDau * perTurnTokenCost;
  final moderationPerDau = liveTurnsPerDau * s.moderationCostPerTurnUsd;

  final costPerDau = amortizedPregen + liveChatTokensPerDau + moderationPerDau;

  return LlmCostBreakdown(
    scenarioName: s.name,
    amortizedPregenPerDauUsd: amortizedPregen,
    liveChatTokensPerDauUsd: liveChatTokensPerDau,
    moderationPerDauUsd: moderationPerDau,
    costPerDauUsd: costPerDau,
    arpdauUsd: s.arpdauUsd,
  );
}

/// Canonical scenarios used by the G0 sign-off + the unit tests.
class LlmCostScenarios {
  LlmCostScenarios._();

  /// MVP launch: hybrid bank only, NO live chat → ~$0 runtime tokens.
  static const LlmCostScenario mvpLaunch = LlmCostScenario(
    name: 'MVP launch (hybrid bank, no live chat)',
    arpdauUsd: 0.03,
    pregenOneTimeUsd: 40,
    amortizationInstalls: 50000,
    liveChatDauShare: 0,
    avgLiveTurnsPerActiveDau: 0,
    personaPromptTokens: 1500,
    perTurnInputTokens: 120,
    perTurnOutputTokens: 90,
    moderationCostPerTurnUsd: 0.0002,
  );

  /// Soft-launch live-chat pilot: capped, subscriber-only, persona cached.
  static const LlmCostScenario softLaunchLivePilot = LlmCostScenario(
    name: 'Soft-launch live pilot (5% DAU, capped, cached persona)',
    arpdauUsd: 0.03,
    pregenOneTimeUsd: 40,
    amortizationInstalls: 50000,
    liveChatDauShare: 0.05,
    avgLiveTurnsPerActiveDau: 8,
    personaPromptTokens: 1500,
    perTurnInputTokens: 120,
    perTurnOutputTokens: 90,
    moderationCostPerTurnUsd: 0.0002,
  );

  /// Anti-pattern control: uncapped, uncached, mass live chat. This SHOULD
  /// fail the gate — it demonstrates the guard catches the unbounded-OPEX trap
  /// (Risk R2) that the hybrid architecture exists to avoid.
  static const LlmCostScenario uncappedStress = LlmCostScenario(
    name: 'Uncapped stress (50% DAU, 40 turns, uncached) — must FAIL gate',
    arpdauUsd: 0.03,
    pregenOneTimeUsd: 40,
    amortizationInstalls: 50000,
    liveChatDauShare: 0.5,
    avgLiveTurnsPerActiveDau: 40,
    personaPromptTokens: 1500,
    perTurnInputTokens: 400,
    perTurnOutputTokens: 300,
    moderationCostPerTurnUsd: 0.001,
    personaCached: false,
  );

  static const List<LlmCostScenario> all = [
    mvpLaunch,
    softLaunchLivePilot,
    uncappedStress,
  ];
}

/// Human-readable one-liner for a breakdown.
String formatBreakdown(LlmCostBreakdown b) {
  String d(double v) => '\$${v.toStringAsFixed(6)}';
  final pct = (b.ratio * 100).toStringAsFixed(1);
  final verdict = b.passesGuardGate ? 'PASS' : 'FAIL';
  return '${b.scenarioName}\n'
      '  cost/DAU=${d(b.costPerDauUsd)}  ARPDAU=${d(b.arpdauUsd)}  '
      'ratio=$pct% (gate <35%)  [$verdict]\n'
      '    pregen=${d(b.amortizedPregenPerDauUsd)}  '
      'live=${d(b.liveChatTokensPerDauUsd)}  '
      'moderation=${d(b.moderationPerDauUsd)}';
}
