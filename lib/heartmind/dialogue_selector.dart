/// The runtime dialogue selection engine (GAME_TECHNICAL_SYSTEMS.md §4.1, step
/// 1–4). On-device, $0 tokens, no network, no spinner. Given the pet state it
/// (1) finds the best-matching reviewed bank entries for the intent,
/// (2) keeps only lines whose memory slots can be filled from the closed-set
/// store, (3) applies anti-repetition rotation, and (4) injects the facts.
/// Deterministic given the same inputs + rotation state.
library;

import 'dialogue_bank.dart';
import 'heartmind_intent.dart';
import 'memory_fact.dart';
import 'memory_injection.dart';

/// The pet-state the selector keys on (strings keep Heartmind decoupled from the
/// game enums; the controller maps enum→string when building this).
class HeartmindContext {
  const HeartmindContext({
    required this.intent,
    required this.lifeStage, // LifeStage.id, e.g. 'pupKit'
    required this.mood, // Mood.name, e.g. 'joyful'
    required this.bondStage, // BondStage.displayName, e.g. 'Friend'
    this.personalityKey = 'calm',
    this.facts = const [],
  });

  final HeartmindIntent intent;
  final String lifeStage;
  final String mood;
  final String bondStage;
  final String personalityKey;
  final List<MemoryFact> facts;

  /// The anti-repetition bucket (don't reuse a line for the same situation).
  String get rotationKey => '${intent.id}|$mood|$bondStage';
}

class HeartmindLine {
  const HeartmindLine({
    required this.text,
    required this.intent,
    this.surfacedFacts = const [],
    this.isCallback = false,
    this.isFallback = false,
  });

  final String text;
  final HeartmindIntent intent;
  final List<FactKey> surfacedFacts;
  final bool isCallback;
  final bool isFallback;
}

class DialogueSelector {
  DialogueSelector(
    this.bank, {
    this.injector = const MemoryInjector(),
    int recentCap = 8,
  }) : _recentCap = recentCap;

  final DialogueBank bank;
  final MemoryInjector injector;
  final int _recentCap;

  /// Per-bucket list of recently surfaced LINE TEMPLATES (not injected text),
  /// oldest first. Anti-repetition rotates within a bucket (§7.2).
  final Map<String, List<String>> _recent = {};

  static bool _matches(String entryValue, String ctxValue) {
    if (entryValue == '*' || entryValue.isEmpty) return true; // wildcard
    return entryValue.toLowerCase() == ctxValue.toLowerCase();
  }

  /// Match score: mood weighted most, then bondStage, then lifeStage/dial.
  /// Returns -1 if the entry can't apply (a *specified* dimension mismatches).
  static int _score(DialogueBankEntry e, HeartmindContext c) {
    int dim(String entryV, String ctxV, int weight) {
      if (entryV == '*' || entryV.isEmpty) return 0; // wildcard: applies, 0 pts
      if (entryV.toLowerCase() != ctxV.toLowerCase()) return -1000; // mismatch
      return weight;
    }

    final m = dim(e.mood, c.mood, 4);
    final b = dim(e.bondStage, c.bondStage, 2);
    final l = dim(e.lifeStage, c.lifeStage, 1);
    final p = dim(e.personalityDial, c.personalityKey, 1);
    if (m < 0 || b < 0 || l < 0 || p < 0) return -1;
    return m + b + l + p;
  }

  /// Selects + injects a line. Returns null if no eligible line exists for the
  /// intent (caller falls back to the safe line).
  HeartmindLine? select(HeartmindContext ctx) {
    final candidates = <(DialogueBankEntry, String, int)>[];
    for (final e in bank.entries) {
      if (!_matches(e.intent, ctx.intent.id)) continue;
      final score = _score(e, ctx);
      if (score < 0) continue;
      for (final line in e.lines) {
        candidates.add((e, line, score));
      }
    }
    if (candidates.isEmpty) return null;

    // Keep only lines whose memory slots can be filled.
    final eligible = candidates
        .where((c) => injector.inject(c.$2, ctx.facts).satisfied)
        .toList();
    if (eligible.isEmpty) return null;

    // Highest score wins.
    final best = eligible.map((c) => c.$3).reduce((a, b) => a > b ? a : b);
    final top = eligible.where((c) => c.$3 == best).toList();

    // Anti-repetition: prefer a line not used recently in this bucket; else the
    // one used longest ago. Deterministic (no RNG).
    final recent = _recent[ctx.rotationKey] ?? const [];
    final fresh = top.where((c) => !recent.contains(c.$2)).toList();
    final chosen = fresh.isNotEmpty
        ? fresh.first
        : top.reduce(
            (a, b) => recent.indexOf(a.$2) <= recent.indexOf(b.$2) ? a : b,
          );

    _remember(ctx.rotationKey, chosen.$2);

    final injected = injector.inject(chosen.$2, ctx.facts);
    return HeartmindLine(
      text: injected.text,
      intent: ctx.intent,
      surfacedFacts: injected.surfaced,
      isCallback: injected.surfaced.isNotEmpty,
    );
  }

  void _remember(String key, String line) {
    final list = _recent.putIfAbsent(key, () => <String>[]);
    list.remove(line);
    list.add(line);
    while (list.length > _recentCap) {
      list.removeAt(0);
    }
  }

  /// Clears rotation state (e.g. a new session); harmless to omit.
  void resetRotation() => _recent.clear();
}
