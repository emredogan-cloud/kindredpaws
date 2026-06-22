/// Heartmind service seam + safety constants + model identifiers.
///
/// MVP is hybrid: lines come from the on-device pre-generated bank ($0 tokens).
/// The only metered path — live free-form chat (#6b) — is Deferred, age-gated,
/// subscriber-only, and capped (Risk R1, R2). This file provides the service
/// interface, the locked model ids, and the fixed safety strings. The runtime
/// bank-selection + memory-injection + moderation pipeline is Phase 2.
library;

/// LLM model identifiers (Open Decision #3, resolved at G0).
class HeartmindModels {
  HeartmindModels._();

  /// Runtime / live-chat model (founder decision: "Claude Haiku 4").
  /// Cost-sensitive path; cheap + fast; only used by the Deferred live chat.
  static const String runtimeModel = 'claude-haiku-4-5';

  /// Offline pre-generation model (quality, paid ONCE, amortized to ~$0/DAU).
  static const String pregenModel = 'claude-opus-4-8';
}

/// Pre-written, human-reviewed safe strings — NEVER generated (Risk R1/R10).
class SafetyConstants {
  SafetyConstants._();

  /// Served whenever generation is blocked, moderation trips, or the proxy is
  /// down (fail-closed). In-character, warm, never an error dialog.
  static const String safeFallbackLine = "Let's just cuddle for now. 🐾";

  /// Self-harm / crisis input → this static message; no model output, ever.
  static const String selfHarmStaticMessage =
      "I care about you. If you're going through something hard, please talk to "
      'a grown-up you trust or a local support line.';
}

/// What the UI/sim asks Heartmind for (Phase 2 fills the real selection).
class HeartmindRequest {
  const HeartmindRequest({
    required this.intent,
    required this.lifeStage,
    required this.mood,
    required this.bondStage,
    this.personalityDial = 'calm',
  });

  final String intent;
  final String lifeStage;
  final String mood;
  final String bondStage;
  final String personalityDial;
}

abstract interface class HeartmindService {
  /// Returns a line for the given pet-state. MVP implementations select from
  /// the on-device bank with NO network call (spinner-free; gate G2).
  Future<String> lineFor(HeartmindRequest request);
}

/// Phase-0 provisioning placeholder: always returns the reviewed safe line.
/// It proves the seam compiles and is wired; the real on-device bank selector
/// + structured-memory injection lands in Phase 2 (the vertical slice).
class StubHeartmind implements HeartmindService {
  const StubHeartmind();

  @override
  Future<String> lineFor(HeartmindRequest request) async =>
      SafetyConstants.safeFallbackLine;
}
