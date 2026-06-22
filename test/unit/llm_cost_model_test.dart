import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/tooling/llm_cost_model.dart';

void main() {
  group('LLM unit-economics model (G0 guard equation)', () {
    test('MVP launch: hybrid bank => zero runtime tokens, passes gate', () {
      final b = computeLlmCost(LlmCostScenarios.mvpLaunch);
      expect(b.liveChatTokensPerDauUsd, 0);
      expect(b.moderationPerDauUsd, 0);
      expect(b.passesGuardGate, isTrue);
      expect(b.ratio, lessThan(LlmCostBreakdown.guardThreshold));
    });

    test('soft-launch capped live pilot passes the gate', () {
      final b = computeLlmCost(LlmCostScenarios.softLaunchLivePilot);
      expect(b.liveChatTokensPerDauUsd, greaterThan(0));
      expect(b.passesGuardGate, isTrue);
      expect(b.ratio, lessThan(LlmCostBreakdown.guardThreshold));
    });

    test('uncapped stress FAILS the gate — the guard works', () {
      final b = computeLlmCost(LlmCostScenarios.uncappedStress);
      expect(b.passesGuardGate, isFalse);
      expect(b.ratio, greaterThan(LlmCostBreakdown.guardThreshold));
    });

    test('Haiku 4.5 cache-read is far cheaper than uncached input', () {
      expect(
        ModelPricing.haiku45.cacheReadPerMTok,
        lessThan(ModelPricing.haiku45.inputPerMTok),
      );
    });

    test('amortized pre-gen cost per DAU is structurally tiny', () {
      final b = computeLlmCost(LlmCostScenarios.mvpLaunch);
      // $40 over 50k installs = $0.0008/DAU.
      expect(b.amortizedPregenPerDauUsd, closeTo(0.0008, 1e-6));
    });
  });
}
