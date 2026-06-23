/// Memory Book v2 view-model (P2-3). Turns the closed-set fact store + a little
/// pet context into categorized, player-facing journal entries — without adding
/// any new save state (entries are derived deterministically from facts + the
/// current pet, so there's nothing to migrate or corrupt).
library;

import 'memory_category.dart';
import 'memory_fact.dart';

class MemoryEntry {
  const MemoryEntry({
    required this.category,
    required this.text,
    required this.createdAtMs,
    this.factKey,
  });

  final MemoryCategory category;
  final String text;
  final int createdAtMs;
  final FactKey? factKey;
}

class MemoryBook {
  const MemoryBook(this.entries);

  /// All entries, newest first.
  final List<MemoryEntry> entries;

  List<MemoryEntry> inCategory(MemoryCategory c) =>
      entries.where((e) => e.category == c).toList();

  /// Categories that actually have entries, in display order.
  List<MemoryCategory> get populatedCategories =>
      MemoryCategory.values.where((c) => inCategory(c).isNotEmpty).toList();

  /// Builds the book from the player's [facts] + light pet context. Pure +
  /// deterministic.
  factory MemoryBook.build({
    required List<MemoryFact> facts,
    required String petName,
    required String speciesLabel,
    required String bondStageLabel,
    required String lifeStageLabel,
    required int createdAtMs,
  }) {
    final entries = <MemoryEntry>[];

    // The relationship anchor (always present once adopted).
    entries.add(
      MemoryEntry(
        category: MemoryCategory.relationship,
        text: '$petName and I are ${bondStageLabel}s. 💛',
        createdAtMs: createdAtMs,
      ),
    );
    // Current growth.
    entries.add(
      MemoryEntry(
        category: MemoryCategory.lifeStage,
        text: '$petName is a $lifeStageLabel ${speciesLabel.toLowerCase()}.',
        createdAtMs: createdAtMs,
      ),
    );

    // Each remembered fact becomes a categorized entry.
    for (final f in facts) {
      entries.add(
        MemoryEntry(
          category: categorizeFact(f),
          text: _factLine(petName, f),
          createdAtMs: f.createdAtMs,
          factKey: f.key,
        ),
      );
    }

    entries.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return MemoryBook(entries);
  }

  static String _factLine(String name, MemoryFact f) => switch (f.key) {
    FactKey.importantDate => f.value,
    FactKey.likesActivity => '$name loves ${f.value}',
    FactKey.favoriteThing => "$name's favorite is ${f.value}",
    FactKey.favoriteColor => 'Favorite color: ${f.value}',
    FactKey.namedPetAfter => 'Named after ${f.value}',
    FactKey.hadAHardDayOn => 'I was here for you on ${f.value}',
  };
}
