/// Memory Book v2 categories (P2-3). The player-visible journal organizes
/// remembered facts + milestone moments into warm, recognizable groups — the
/// tangible "it remembered me" trust signal (Risk R3, GAMEPLAY §7.2).
library;

import 'memory_fact.dart';

enum MemoryCategory {
  rescue('Rescue', '🏠'),
  firstTime('First Times', '✨'),
  favorite('Favorites', '⭐'),
  milestone('Milestones', '🌟'),
  relationship('Our Bond', '💛'),
  lifeStage('Growing Up', '🌱');

  const MemoryCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

/// Best-effort category for a stored [MemoryFact] (by key, then value hints).
MemoryCategory categorizeFact(MemoryFact f) {
  switch (f.key) {
    case FactKey.likesActivity:
    case FactKey.favoriteThing:
    case FactKey.favoriteColor:
      return MemoryCategory.favorite;
    case FactKey.namedPetAfter:
      return MemoryCategory.rescue;
    case FactKey.hadAHardDayOn:
      return MemoryCategory.relationship;
    case FactKey.importantDate:
      final v = f.value.toLowerCase();
      if (v.contains('rescue')) return MemoryCategory.rescue;
      if (v.contains('grew') || v.contains('grown')) {
        return MemoryCategory.lifeStage;
      }
      return MemoryCategory.milestone;
  }
}
