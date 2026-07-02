/// The rooms of the KindredPaws home — the Immersive Pet Experience sprint
/// (founder-approved product evolution). The pet lives across a small, cozy,
/// swipeable home; every room reads the SAME [GameController]/simulation so
/// changing rooms never resets or forks pet state.
///
/// Order in [RoomId.values] is the spatial swipe order (left → right), laid
/// out like a real home: the store and kitchen to one side, resting spaces to
/// the other, with the hearth (Home) in the middle.
library;

enum RoomId {
  groceryStore('groceryStore', 'Grocery Store', 'Treats & pantry refills'),
  kitchen('kitchen', 'Kitchen', 'Mealtime together'),
  bathroom('bathroom', 'Bathroom', 'Splash & sparkle'),
  home('home', 'Home', 'The cozy hearth'),
  playRoom('playRoom', 'Play Garden', 'Toys & giggles'),
  bedroom('bedroom', 'Bedroom', 'Sleepy snuggles'),
  wardrobe('wardrobe', 'Wardrobe', 'Dress-up corner'),
  medicalRoom('medicalRoom', 'Care Corner', 'Gentle check-ups');

  const RoomId(this.id, this.displayName, this.tagline);

  /// Stable identifier (telemetry + persistence safe; never rename).
  final String id;

  /// Player-facing room name (warm, child-safe).
  final String displayName;

  /// One-line warm descriptor (dock tooltips / a11y).
  final String tagline;

  static RoomId fromId(String id) =>
      values.firstWhere((r) => r.id == id, orElse: () => RoomId.home);
}
