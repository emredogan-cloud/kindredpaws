/// The on-device hybrid Heartmind (GAME_TECHNICAL_SYSTEMS.md §4). MVP magic with
/// **zero runtime tokens, no network, no spinner** (gate G2 architectural
/// guarantee): select a reviewed line for the pet-state, inject closed-set
/// memory facts into safe slots, run the defensive safety filter, fail closed to
/// the fixed safe line. NO live free-form generation (Deferred, gated).
library;

import 'dialogue_bank.dart';
import 'dialogue_corpus.dart';
import 'dialogue_selector.dart';
import 'heartmind_intent.dart';
import 'heartmind_service.dart';
import 'safety_filter.dart';

/// Richer companion API (the game uses this); also satisfies the legacy
/// [HeartmindService] string seam.
abstract interface class Heartmind implements HeartmindService {
  HeartmindLine speak(HeartmindContext context);
}

class LocalHeartmind implements Heartmind {
  LocalHeartmind({DialogueBank? bank, this.safety = const SafetyFilter()})
    : selector = DialogueSelector(bank ?? defaultDialogueBank());

  final DialogueSelector selector;
  final SafetyFilter safety;

  @override
  HeartmindLine speak(HeartmindContext context) {
    final selected = selector.select(context);
    if (selected == null) return _fallback(context.intent);
    // Defensive, fail-closed safety check on the fully-rendered line.
    if (!safety.validateOutput(selected.text).safe) {
      return _fallback(context.intent);
    }
    return selected;
  }

  HeartmindLine _fallback(HeartmindIntent intent) => HeartmindLine(
    text: SafetyConstants.safeFallbackLine,
    intent: intent,
    isFallback: true,
  );

  /// Legacy string seam: select a factless line for the request's intent.
  @override
  Future<String> lineFor(HeartmindRequest request) async {
    final intent = HeartmindIntent.values.firstWhere(
      (i) => i.id == request.intent,
      orElse: () => HeartmindIntent.idle,
    );
    return speak(
      HeartmindContext(
        intent: intent,
        lifeStage: request.lifeStage,
        mood: request.mood,
        bondStage: request.bondStage,
        personalityKey: request.personalityDial,
      ),
    ).text;
  }
}

/// The default reviewed dialogue bank — the large, human-reviewed **production
/// corpus** (P4-1, CONTENT_FACTORY §10.2). Child-safe + never-guilt by
/// construction and gated by `ContentValidator` (a test runs the whole corpus
/// through it); topped up at runtime via Remote Config (`mergeRemoteContent`).
/// The corpus itself lives in `dialogue_corpus.dart`.
DialogueBank defaultDialogueBank() => buildDialogueCorpus();
