/// Sentiment tagging (P5-5) — a tiny, deterministic, on-device tagger for the
/// optional note a beta tester leaves. NOT an LLM (MVP forbids live free-form
/// model calls); a transparent lexicon + the star rating, so it is reproducible,
/// testable, child-safe, and $0. It only *labels* feedback for triage — it never
/// changes gameplay or talks to the player. Authority: brief §10 (leading-churn
/// signals), GAME_TECHNICAL_SYSTEMS §10 (closed-beta ops).
library;

/// The coarse sentiment of a piece of feedback.
enum Sentiment { positive, neutral, negative, mixed }

/// Words that read as delight in a cozy-pet context (lowercased, matched whole).
const Set<String> _positiveLexicon = {
  'love',
  'loved',
  'lovely',
  'great',
  'awesome',
  'cute',
  'cozy',
  'fun',
  'happy',
  'adorable',
  'sweet',
  'enjoy',
  'enjoyed',
  'wonderful',
  'amazing',
  'best',
  'beautiful',
  'delightful',
  'charming',
  'relaxing',
  'calm',
  'good',
  'nice',
  'like',
  'liked',
  'perfect',
  'brilliant',
  'joy',
  'heartwarming',
  'soothing',
  'wholesome',
};

/// Words that read as a problem or displeasure (incl. churn/perf signals).
const Set<String> _negativeLexicon = {
  'hate',
  'hated',
  'bad',
  'boring',
  'bored',
  'broke',
  'broken',
  'crash',
  'crashed',
  'crashes',
  'crashing',
  'bug',
  'bugs',
  'buggy',
  'glitch',
  'laggy',
  'lag',
  'slow',
  'annoying',
  'annoyed',
  'confusing',
  'confused',
  'frustrating',
  'frustrated',
  'worst',
  'terrible',
  'awful',
  'dislike',
  'disliked',
  'disappointed',
  'disappointing',
  'stuck',
  'freeze',
  'froze',
  'frozen',
  'ugly',
  'sad',
  'guilt',
  'guilty',
  'pressure',
  'pressured',
  'nag',
  'nagging',
  'repetitive',
  'repeats',
  'repeating',
  'repeated',
  'samey',
  'predictable',
  'expensive',
  'creepy',
};

/// Tags the [comment] (with the [rating] as a strong prior) as a [Sentiment].
///
/// - No comment → rating decides (≥4 positive, ≤2 negative, 3 neutral).
/// - Both positive *and* negative words present → [Sentiment.mixed].
/// - Otherwise the lexicon lean decides; a lexicon tie falls back to the rating.
Sentiment tagSentiment(String? comment, {required int rating}) {
  final r = rating.clamp(1, 5);
  final words = _words(comment);
  if (words.isEmpty) return _fromRating(r);

  var pos = 0;
  var neg = 0;
  for (final w in words) {
    if (_positiveLexicon.contains(w)) pos++;
    if (_negativeLexicon.contains(w)) neg++;
  }

  if (pos > 0 && neg > 0) return Sentiment.mixed;
  if (pos > neg) return Sentiment.positive;
  if (neg > pos) return Sentiment.negative;
  return _fromRating(r); // no signal words → trust the stars
}

Sentiment _fromRating(int r) {
  if (r >= 4) return Sentiment.positive;
  if (r <= 2) return Sentiment.negative;
  return Sentiment.neutral;
}

/// Lowercased alphanumeric tokens (apostrophes folded so "don't" → "dont").
List<String> _words(String? comment) {
  if (comment == null) return const [];
  final cleaned = comment.toLowerCase().replaceAll("'", '');
  return cleaned
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();
}
