/// The two MVP pet species (KINDREDPAWS_CANONICAL_DECISION_BRIEF.md §1).
/// Exactly two; the player names the individual. Default example names are
/// canonical for mocks/onboarding (Biscuit = puppy, Mochi = kitten).
library;

enum Species {
  puppy('puppy', 'Puppy', 'Biscuit'),
  kitten('kitten', 'Kitten', 'Mochi');

  const Species(this.id, this.displayName, this.defaultName);

  /// Stable serialization id (persisted in the save).
  final String id;
  final String displayName;

  /// Canonical default individual name (GAME_CONTENT_FACTORY §1.1).
  final String defaultName;

  static Species fromId(String id) =>
      values.firstWhere((s) => s.id == id, orElse: () => Species.puppy);
}
