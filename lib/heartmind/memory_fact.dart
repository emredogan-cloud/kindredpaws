/// The Memory Book fact store schema (ADR-006, Risk R3). "It remembered me" is
/// powered by a small, **closed set** of durable, validated facts — never
/// free-form generation. Reliability > breadth: facts are only ever injected
/// into pre-reviewed template slots, which is how the ≥95% callback reliability
/// / zero-hallucination gate (G2) is met.
///
/// This is the schema + validation only. The runtime selection/injection of
/// facts into dialogue is Phase 2.
library;

/// The enumerated, closed set of fact keys. Under-13 stays templated/
/// non-generative; no free-text personal data is stored in MVP (Risk R1).
enum FactKey {
  favoriteThing,
  favoriteColor,
  hadAHardDayOn,
  namedPetAfter,
  likesActivity,
  importantDate,
}

/// How a fact entered the store. `extracted` rides with the Deferred live chat.
enum FactSource { onboarding, explicit, extracted }

class MemoryFact {
  MemoryFact({
    required this.key,
    required this.value,
    required this.source,
    required this.confidence,
    required this.createdAtMs,
    this.lastSurfacedAtMs,
  }) {
    // Validate the trimmed length consistently (whitespace is not content).
    final trimmedLength = value.trim().length;
    if (trimmedLength == 0 || trimmedLength > maxValueLength) {
      throw ArgumentError('MemoryFact value must be 1..$maxValueLength chars');
    }
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError('confidence must be 0..1');
    }
  }

  /// Closed-set values are short & sanitized — caps the no-hallucination risk.
  static const int maxValueLength = 120;

  /// Brief §6: 10–30 durable facts per player.
  static const int minFacts = 10;
  static const int maxFacts = 30;

  final FactKey key;
  final String value;
  final FactSource source;
  final double confidence;
  final int createdAtMs;
  final int? lastSurfacedAtMs;

  Map<String, dynamic> toJson() => {
    'key': key.name,
    'value': value,
    'source': source.name,
    'confidence': confidence,
    'createdAtMs': createdAtMs,
    'lastSurfacedAtMs': lastSurfacedAtMs,
  };

  factory MemoryFact.fromJson(Map<String, dynamic> j) => MemoryFact(
    key: FactKey.values.byName(j['key'] as String),
    value: j['value'] as String,
    source: FactSource.values.byName(j['source'] as String),
    confidence: (j['confidence'] as num).toDouble(),
    createdAtMs: (j['createdAtMs'] as num).toInt(),
    lastSurfacedAtMs: (j['lastSurfacedAtMs'] as num?)?.toInt(),
  );
}
