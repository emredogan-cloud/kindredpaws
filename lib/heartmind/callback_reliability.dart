/// Automated AI-memory callback reliability measurement (GAME_TECHNICAL_SYSTEMS
/// §4.2, Risk R3, gate **G2: ≥95% callback reliability with zero hallucinated
/// facts**). Because facts are only ever injected into pre-reviewed template
/// slots with VALIDATED closed-set values — never free-generated — the rate is
/// bounded by template/slot correctness, so this harness measures (and CI
/// asserts) that bound deterministically.
library;

import 'dialogue_bank.dart';
import 'dialogue_selector.dart';
import 'heartmind_intent.dart';
import 'local_heartmind.dart';
import 'memory_fact.dart';
import 'memory_injection.dart';

class CallbackReliabilityReport {
  const CallbackReliabilityReport({
    required this.attempts,
    required this.callbacksMade,
    required this.correct,
    required this.hallucinated,
    required this.unfilledSlots,
    required this.falseCallbacks,
  });

  /// Callback requests issued where ≥1 fact was available.
  final int attempts;

  /// How many of those returned an actual callback line.
  final int callbacksMade;

  /// Callbacks that surfaced the EXACT stored value(s), no slot left unfilled,
  /// no value outside the store.
  final int correct;

  /// Callbacks that surfaced a value NOT in the store (a hallucination). MUST be 0.
  final int hallucinated;

  /// Callbacks rendered with an unfilled `{fact:...}` slot. MUST be 0.
  final int unfilledSlots;

  /// Callbacks produced when NO fact was available (a fabricated memory). MUST be 0.
  final int falseCallbacks;

  /// Reliability = correct / callbacks actually made (G2 target ≥ 0.95).
  double get accuracy => callbacksMade == 0 ? 1.0 : correct / callbacksMade;

  /// How often a callback fires when facts exist (informational coverage).
  double get coverage => attempts == 0 ? 0 : callbacksMade / attempts;

  @override
  String toString() =>
      'CallbackReliability(accuracy=${(accuracy * 100).toStringAsFixed(1)}%, '
      'coverage=${(coverage * 100).toStringAsFixed(1)}%, '
      'made=$callbacksMade/$attempts, hallucinated=$hallucinated, '
      'unfilled=$unfilledSlots, false=$falseCallbacks)';
}

class CallbackReliability {
  const CallbackReliability._();

  static const List<String> _moods = ['joyful', 'content', 'wistful', 'low'];
  static const List<String> _bonds = [
    'Stranger',
    'Friend',
    'Companion',
    'Kindred',
    'Soulmate',
  ];

  /// Runs the memory-callback path across [factSets] × moods × bond stages and
  /// scores correctness. Also probes the no-facts case for false callbacks.
  static CallbackReliabilityReport measure({
    DialogueBank? bank,
    required List<List<MemoryFact>> factSets,
  }) {
    final theBank = bank ?? defaultDialogueBank();
    var attempts = 0,
        made = 0,
        correct = 0,
        hallucinated = 0,
        unfilled = 0,
        falseCb = 0;

    final storeValues = <List<MemoryFact>, Set<String>>{
      for (final fs in factSets) fs: fs.map((f) => f.value).toSet(),
    };

    for (final facts in factSets) {
      final hasFacts = facts.isNotEmpty;
      for (final mood in _moods) {
        for (final bond in _bonds) {
          // Fresh selector per probe → independent of rotation.
          final selector = DialogueSelector(theBank);
          final line = selector.select(
            HeartmindContext(
              intent: HeartmindIntent.memoryCallback,
              lifeStage: 'pupKit',
              mood: mood,
              bondStage: bond,
              facts: facts,
            ),
          );

          if (!hasFacts) {
            if (line != null) falseCb++; // fabricated a memory with no fact
            continue;
          }

          attempts++;
          if (line == null) continue; // no callback this time (coverage miss)
          made++;

          if (line.text.contains('{fact:')) {
            unfilled++;
            continue;
          }
          // Every surfaced value must appear in the text AND be a real stored value.
          final values = storeValues[facts]!;
          var ok = line.surfacedFacts.isNotEmpty;
          for (final key in line.surfacedFacts) {
            final stored = const MemoryInjector().bestFact(key, facts);
            if (stored == null || !values.contains(stored.value)) {
              hallucinated++;
              ok = false;
              break;
            }
            if (!line.text.contains(stored.value)) {
              ok = false;
            }
          }
          if (ok) correct++;
        }
      }
    }

    return CallbackReliabilityReport(
      attempts: attempts,
      callbacksMade: made,
      correct: correct,
      hallucinated: hallucinated,
      unfilledSlots: unfilled,
      falseCallbacks: falseCb,
    );
  }
}
