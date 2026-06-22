/// Canonical product terminology, mirrored verbatim from
/// `game-os/KINDREDPAWS_CANONICAL_DECISION_BRIEF.md` §1 (the SSOT).
///
/// The brief wins all conflicts; these constants exist so app code has a single
/// typed source for the locked names instead of stringly-typed literals. If the
/// brief changes, update here and log the change in GAME_DECISION_LOG.md.
library;

class KindredTerms {
  KindredTerms._();

  static const String gameTitle = 'KindredPaws';
  static const String subscription = 'Forever Friends';
  static const String seasonalPass = 'Care Pass';
  static const String softCurrency = 'Kibble';
  static const String premiumCurrency = 'Heartstones';
  static const String donationCurrency = 'Compassion Coins';

  static const List<String> species = ['puppy', 'kitten'];
  static const Map<String, String> exampleNames = {
    'kitten': 'Mochi',
    'puppy': 'Biscuit',
  };

  static const String affectionSystem = 'The Bond';
  static const List<String> bondStages = [
    'Stranger',
    'Friend',
    'Companion',
    'Kindred',
    'Soulmate',
  ];
  static const List<String> lifeStages = ['Pup/Kit', 'Young One', 'Grown'];

  static const String aiCompanion = 'Heartmind';
  static const String memoryStore = 'The Memory Book';
  static const String needsSystem = 'Care Meters';
  static const String dailyLifeIntegration = 'Companion Presence';
  static const String streak = 'Care Streak';
  static const String donationPolicy = 'The Impact Pledge';
  static const String impactUi = 'Rescue Wall';
  static const String adoptionOnboarding = 'Rescue Day';
  static const String shareArtifacts = 'Keepsake Cards';
  static const String homeCustomization = 'The Nest';
}
