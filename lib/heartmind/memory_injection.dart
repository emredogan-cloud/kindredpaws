/// Structured memory injection (GAME_TECHNICAL_SYSTEMS.md §4.2). Validated facts
/// from the closed-set store are inserted into pre-reviewed template slots like
/// `"I remembered you said you like {fact:favorite_thing}!"`. The model NEVER
/// free-generates a memory — so callback reliability is bounded by template/slot
/// correctness, not model recall. This is how we hit ≥95% with ZERO hallucinated
/// facts (Risk R3, gate G2). A line whose slot has no matching stored fact is
/// **ineligible** (the selector won't pick it), so no slot is ever left unfilled.
library;

import 'memory_fact.dart';

/// Maps a template slot name (snake_case) to its closed-set [FactKey].
const Map<String, FactKey> kSlotToFactKey = {
  'favorite_thing': FactKey.favoriteThing,
  'favorite_color': FactKey.favoriteColor,
  'had_a_hard_day_on': FactKey.hadAHardDayOn,
  'named_pet_after': FactKey.namedPetAfter,
  'likes_activity': FactKey.likesActivity,
  'important_date': FactKey.importantDate,
};

/// The memory-slot token pattern, `{fact:snake_case}`. Shared by the injector,
/// the content validator, and the bank manifest (one source of truth).
final RegExp kFactSlot = RegExp(r'\{fact:([a-z_]+)\}');

class InjectionResult {
  const InjectionResult({
    required this.text,
    required this.surfaced,
    required this.satisfied,
  });

  /// The line with every slot filled (or the original if it had no slots).
  final String text;

  /// The fact keys actually surfaced (for the Memory Book "remembered" log).
  final List<FactKey> surfaced;

  /// True if every slot was filled by a real stored fact (else the line is
  /// ineligible — the selector must not use it).
  final bool satisfied;
}

class MemoryInjector {
  const MemoryInjector();

  bool hasSlots(String line) => kFactSlot.hasMatch(line);

  /// Best stored fact for [key]: highest confidence, then most recent.
  MemoryFact? bestFact(FactKey key, List<MemoryFact> facts) {
    MemoryFact? best;
    for (final f in facts) {
      if (f.key != key) continue;
      if (best == null ||
          f.confidence > best.confidence ||
          (f.confidence == best.confidence &&
              f.createdAtMs > best.createdAtMs)) {
        best = f;
      }
    }
    return best;
  }

  /// Fills every `{fact:...}` slot in [line] from [facts]. If any slot has no
  /// matching fact (or an unknown slot name), returns `satisfied: false`.
  InjectionResult inject(String line, List<MemoryFact> facts) {
    if (!hasSlots(line)) {
      return InjectionResult(text: line, surfaced: const [], satisfied: true);
    }
    final surfaced = <FactKey>[];
    var ok = true;
    final text = line.replaceAllMapped(kFactSlot, (m) {
      final slot = m.group(1)!;
      final key = kSlotToFactKey[slot];
      if (key == null) {
        ok = false;
        return m.group(0)!; // leave the raw slot (line will be rejected)
      }
      final fact = bestFact(key, facts);
      if (fact == null) {
        ok = false;
        return m.group(0)!;
      }
      surfaced.add(key);
      return fact.value;
    });
    return InjectionResult(text: text, surfaced: surfaced, satisfied: ok);
  }
}
