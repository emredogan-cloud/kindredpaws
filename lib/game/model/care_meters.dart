/// The four Care Meters (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.1). Floats 0–100,
/// gentle decay, with a hard no-death FLOOR (§5.2, Risk R4): a meter can never
/// drop below the floor — the pet gets "sad but safe", never sick or dead.
library;

/// The four needs. `energy` is "energy / sleep".
enum CareNeed {
  hunger('hunger'),
  energy('energy'),
  hygiene('hygiene'),
  happiness('happiness');

  const CareNeed(this.id);
  final String id;
}

class CareMeters {
  const CareMeters({
    required this.hunger,
    required this.energy,
    required this.hygiene,
    required this.happiness,
  });

  final double hunger;
  final double energy;
  final double hygiene;
  final double happiness;

  /// A freshly-rescued pet starts topped up.
  static const CareMeters full = CareMeters(
    hunger: 100,
    energy: 100,
    hygiene: 100,
    happiness: 100,
  );

  double of(CareNeed need) => switch (need) {
    CareNeed.hunger => hunger,
    CareNeed.energy => energy,
    CareNeed.hygiene => hygiene,
    CareNeed.happiness => happiness,
  };

  CareMeters withNeed(CareNeed need, double value) => CareMeters(
    hunger: need == CareNeed.hunger ? value : hunger,
    energy: need == CareNeed.energy ? value : energy,
    hygiene: need == CareNeed.hygiene ? value : hygiene,
    happiness: need == CareNeed.happiness ? value : happiness,
  );

  CareMeters copyWith({
    double? hunger,
    double? energy,
    double? hygiene,
    double? happiness,
  }) => CareMeters(
    hunger: hunger ?? this.hunger,
    energy: energy ?? this.energy,
    hygiene: hygiene ?? this.hygiene,
    happiness: happiness ?? this.happiness,
  );

  /// True if every meter sits at or below [threshold] (used for "needs care").
  bool allAtOrBelow(double threshold) =>
      hunger <= threshold &&
      energy <= threshold &&
      hygiene <= threshold &&
      happiness <= threshold;

  /// The lowest meter — drives which need icon floats up first.
  double get lowest =>
      [hunger, energy, hygiene, happiness].reduce((a, b) => a < b ? a : b);

  Map<String, double> toMap() => {
    'hunger': hunger,
    'energy': energy,
    'hygiene': hygiene,
    'happiness': happiness,
  };

  /// A lost meter value defaults to a comfortable 80 — "doing fine, could use
  /// a little care" — never a shock state after save repair (KP-010).
  factory CareMeters.fromMap(Map<String, dynamic> m) => CareMeters(
    hunger: _meterOr(m['hunger']),
    energy: _meterOr(m['energy']),
    hygiene: _meterOr(m['hygiene']),
    happiness: _meterOr(m['happiness']),
  );

  static double _meterOr(Object? v) => v is num ? v.toDouble() : 80;

  @override
  bool operator ==(Object other) =>
      other is CareMeters &&
      other.hunger == hunger &&
      other.energy == energy &&
      other.hygiene == hygiene &&
      other.happiness == happiness;

  @override
  int get hashCode => Object.hash(hunger, energy, hygiene, happiness);
}
