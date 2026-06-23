/// Validates + sanitizes the **one** free-text field in the app: the pet's name
/// (Rescue Day). Child-safe-for-all (§11.1) means the single text surface must
/// never store or surface PII or profanity — so the field is *constrained*
/// input, not an open text store. This is the concrete enforcement of the "no
/// free-text from minors" posture ([ComplianceConfig.freeTextInputAllowed]): the
/// name field stays usable by everyone *because* every value passes this filter.
///
/// This is a **seed** filter (normalize → PII scan → profanity scan). Production
/// swaps the word lists for a maintained moderation service driven by Remote
/// Config — the same two-sided pipeline the Deferred live-chat path uses (§4.5).
/// The architecture stays; only the lists grow. Authority: GAME_TECHNICAL_
/// SYSTEMS.md §11.1/§4.5, D-007/D-019.
library;

/// Why a proposed name was rejected (drives the gentle, in-character UI copy).
enum NameRejection {
  /// Empty / whitespace-only.
  empty,

  /// Longer than [NameInputValidator.maxLength] after trimming.
  tooLong,

  /// Looks like contact info (email / URL / a long digit run) — never a name.
  containsPii,

  /// Matched the profanity filter (after leet/space normalization).
  containsProfanity,

  /// Contains control characters or other disallowed code points.
  invalidChars,
}

/// The result of validating a raw name. Immutable + const-constructible.
class NameValidation {
  const NameValidation._(this.isValid, this.rejection, this.sanitized);

  /// A passing name, carrying the cleaned value to persist.
  const NameValidation.valid(String sanitized) : this._(true, null, sanitized);

  /// A rejected name, carrying the reason (for UI copy).
  const NameValidation.rejected(NameRejection reason)
    : this._(false, reason, '');

  final bool isValid;

  /// Null when [isValid]; otherwise why it failed.
  final NameRejection? rejection;

  /// The cleaned name to persist (trimmed, whitespace-collapsed). Empty when
  /// invalid — callers must check [isValid] first.
  final String sanitized;
}

/// Stateless validator for the pet-name field. `const`-constructible.
class NameInputValidator {
  const NameInputValidator();

  /// Max stored length (mirrors the Rescue Day field's `maxLength`).
  static const int maxLength = 16;

  /// Validate [raw], returning the cleaned value or a rejection reason.
  NameValidation validate(String raw) {
    final collapsed = raw.trim().replaceAll(_whitespace, ' ');
    if (collapsed.isEmpty) {
      return const NameValidation.rejected(NameRejection.empty);
    }
    if (collapsed.runes.length > maxLength) {
      return const NameValidation.rejected(NameRejection.tooLong);
    }
    if (_control.hasMatch(collapsed)) {
      return const NameValidation.rejected(NameRejection.invalidChars);
    }
    if (_looksLikePii(collapsed)) {
      return const NameValidation.rejected(NameRejection.containsPii);
    }
    if (_hasProfanity(collapsed)) {
      return const NameValidation.rejected(NameRejection.containsProfanity);
    }
    return NameValidation.valid(collapsed);
  }

  // --- PII: a pet name has no business carrying contact info. ---------------

  bool _looksLikePii(String s) {
    if (_email.hasMatch(s) || _url.hasMatch(s)) return true;
    // 7+ digits anywhere (contiguous or formatted) reads as a phone/id, not a
    // name — count digits rather than match a run so "555-123-4567" is caught.
    final digits = _digit.allMatches(s).length;
    return digits >= 7;
  }

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _control = RegExp(r'[\x00-\x1f\x7f]');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _email = RegExp(
    r'[a-z0-9._%+-]+@[a-z0-9.-]+',
    caseSensitive: false,
  );
  static final RegExp _url = RegExp(
    r'(https?://|www\.|\b[a-z0-9-]+\.(?:com|net|org|io|app|co|gg|me)\b)',
    caseSensitive: false,
  );

  // --- Profanity: normalize away common evasions, then substring-match. -----

  bool _hasProfanity(String s) {
    final norm = _normalize(s);
    return _profanityRoots.any(norm.contains);
  }

  /// Lowercase, fold common leetspeak, then strip every non-letter so spaced /
  /// punctuated evasions ("f.u.c.k", "f u c k") collapse onto the root.
  String _normalize(String s) {
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      buf.write(_leet[ch] ?? ch);
    }
    return buf.toString().replaceAll(_nonLetter, '');
  }

  static final RegExp _nonLetter = RegExp(r'[^a-z]');

  static const Map<String, String> _leet = {
    '0': 'o',
    '1': 'i',
    '3': 'e',
    '4': 'a',
    '5': 's',
    '7': 't',
    '8': 'b',
    '@': 'a',
    r'$': 's',
    '!': 'i',
  };

  /// Seed list — unambiguous profanity roots chosen to minimize false positives
  /// (e.g. "asshole"/"dickhead", not bare "ass"/"dick", so "class"/"Dickens"
  /// pass; "Shih Tzu" normalizes to "shihtzu" which contains no root). NOT a
  /// slur list — this is the cozy-game tone filter, replaced in production by the
  /// maintained moderation service (§4.5).
  static const Set<String> _profanityRoots = {
    'fuck',
    'shit',
    'bitch',
    'cunt',
    'asshole',
    'bastard',
    'dickhead',
    'whore',
    'slut',
    'wanker',
    'bollocks',
    'motherf',
  };
}
