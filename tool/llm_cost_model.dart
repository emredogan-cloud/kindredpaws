// ignore_for_file: avoid_print
// LLM unit-economics model CLI (G0 deliverable).
// Run: dart run tool/llm_cost_model.dart
//
// Prints the cost/DAU and the < 35%-of-ARPDAU guard verdict for each canonical
// scenario. Exit code is non-zero only if an MVP/soft-launch scenario fails the
// gate (the uncapped-stress scenario is expected to fail by design).
import 'package:kindredpaws/tooling/llm_cost_model.dart';

void main() {
  print('KindredPaws — LLM unit-economics model v1');
  print('Runtime model: claude-haiku-4-5  |  Pre-gen model: claude-opus-4-8');
  print('Gate (G4): LLM cost/DAU < 35% of ARPDAU\n');

  var ok = true;
  for (final scenario in LlmCostScenarios.all) {
    final b = computeLlmCost(scenario);
    print(formatBreakdown(b));
    print('');
    final isControl = identical(scenario, LlmCostScenarios.uncappedStress);
    if (!isControl && !b.passesGuardGate) ok = false;
  }

  if (!ok) {
    print('ERROR: a committed scenario failed the LLM cost gate.');
    // Non-zero exit for CI; throwing keeps it dependency-free.
    throw StateError('LLM cost gate failed for a committed scenario');
  }
  print(
    'All committed scenarios pass the gate; control scenario fails as expected.',
  );
}
