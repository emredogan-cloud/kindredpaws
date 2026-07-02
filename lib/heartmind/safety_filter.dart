/// Child-safety filter (GAME_TECHNICAL_SYSTEMS.md §4.5, Risk R1). In MVP the
/// bank is 100% human-reviewed and facts are closed-set, so the pipeline is
/// child-safe by construction; this filter is the **defensive, fail-closed**
/// backstop and the seam the (Deferred) live path will reuse:
///  - any self-harm/crisis signal → a fixed static safe message, never a model
///    line;
///  - any output that trips the banned-topic scan → the fixed safe fallback;
///  - never surface a raw refusal or an unfilled template slot to a child.
library;

class SafetyVerdict {
  const SafetyVerdict(this.safe, [this.reason]);
  final bool safe;
  final String? reason;
  static const SafetyVerdict ok = SafetyVerdict(true);
}

class SafetyFilter {
  const SafetyFilter();

  /// Crisis/self-harm signals in *input* (only reachable on the Deferred live
  /// path; under-13 has no free-text). Caller serves the static safe message.
  static const List<String> _selfHarmSignals = [
    'kill myself',
    'want to die',
    'end my life',
    'hurt myself',
    'self harm',
    'suicide',
  ];

  /// Topics the pet must never produce (scary/violent/romantic/medical/
  /// commercial-pressure). Defensive output scan; the bank should never contain
  /// these — a hit means something is wrong → fail closed to the safe line.
  static const List<String> _bannedTopics = [
    'kill',
    'die',
    'blood',
    'weapon',
    'sexy',
    'kiss me',
    'buy now',
    'credit card',
    'diagnose',
    'medication',
  ];

  bool isSelfHarmSignal(String input) {
    final t = input.toLowerCase();
    return _selfHarmSignals.any(t.contains);
  }

  /// Validates a fully-rendered output line before it reaches the player.
  SafetyVerdict validateOutput(String line) {
    final t = line.toLowerCase();
    if (t.trim().isEmpty) return const SafetyVerdict(false, 'empty');
    if (line.contains('{fact:')) {
      return const SafetyVerdict(false, 'unfilled template slot');
    }
    for (final term in _bannedTopics) {
      if (t.contains(term)) return SafetyVerdict(false, 'banned: $term');
    }
    return SafetyVerdict.ok;
  }
}
