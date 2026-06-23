/// Child-safety & privacy compliance policy (P3-6a). The single source of truth
/// for the protective defaults the rest of the app reads — derived from a coarse
/// [AgeBand] + [ConsentState], never from a stored birthdate.
///
/// **Build to a child-safe standard for ALL users** (D-007, GAME_TECHNICAL_
/// SYSTEMS.md §11.1, brief §11 R1 — the existential risk). The protective
/// posture is **fail-safe by construction**: [AgeBand.unknown] is treated
/// exactly like [AgeBand.under13], so a user whose age has not been established
/// gets the *most* locked-down experience — no free-text, templated-only
/// dialogue, COPPA/GDPR-K ad flags on. Loosening only happens for a band we have
/// affirmatively established.
///
/// What this file is NOT: the *flow* that establishes the band (a neutral
/// age-gate vs. verifiable-parental-consent UI) is **Open Decision #9**, a G3
/// legal-gated founder/counsel deliverable (`docs/LEGAL_CHILD_DIRECTEDNESS_
/// SCOPING.md`, ADR-011). This type is the downstream *enforcement* of whatever
/// that determination yields, not the gate itself. Until that ships, the band
/// stays [AgeBand.unknown] and every user is treated as a child (D-007).
library;

/// Coarse age band — never a precise age or birthdate (§11.2 PII minimization).
///
/// Order is deliberate: [unknown] sorts first and is the fail-safe default.
enum AgeBand {
  /// Age not established. Treated identically to [under13] (D-007 fail-safe).
  unknown,

  /// Under 13 (COPPA) / under the local age of digital consent (GDPR-K).
  under13,

  /// 13–17. Free-text/generative paths require verified parental consent.
  teen,

  /// 18+. The only band that may (post-MVP) opt into generative dialogue.
  adult,
}

extension AgeBandProtection on AgeBand {
  /// True when this band MUST receive the full child-safe treatment: [unknown]
  /// (fail-safe default, D-007) and [under13] (COPPA / GDPR-K). Teen and adult
  /// do not — though MVP keeps free-text and live chat off for *everyone*
  /// regardless (the global gate in [AppConfig]).
  bool get requiresChildSafeTreatment =>
      this == AgeBand.unknown || this == AgeBand.under13;
}

/// The consent signals captured for a user. **Data holder only** — the flow that
/// *collects* consent (the neutral age-gate / verifiable-parental-consent UI) is
/// the G3 legal-gated deliverable (Open Decision #9), deliberately NOT built
/// here. Defaults are the privacy-protective "nothing granted yet" state, so an
/// un-onboarded user is never assumed to have consented to anything.
class ConsentState {
  const ConsentState({
    this.parentalConsentVerified = false,
    this.personalizedDataAllowed = false,
  });

  /// COPPA verifiable parental consent (VPC) obtained for this account. Gates
  /// the teen generative-dialogue path; under-13 stays templated-only even with
  /// it (§4.5).
  final bool parentalConsentVerified;

  /// Affirmative consent to any personalized / behavioral data processing.
  /// Independent of [parentalConsentVerified]. In MVP nothing sets this true —
  /// the product collects no behavioral data and runs no behavioral ads
  /// (§11.1) — but the field models the GDPR-K consent signal for later phases.
  final bool personalizedDataAllowed;

  static const ConsentState none = ConsentState();

  ConsentState copyWith({
    bool? parentalConsentVerified,
    bool? personalizedDataAllowed,
  }) => ConsentState(
    parentalConsentVerified:
        parentalConsentVerified ?? this.parentalConsentVerified,
    personalizedDataAllowed:
        personalizedDataAllowed ?? this.personalizedDataAllowed,
  );

  @override
  bool operator ==(Object other) =>
      other is ConsentState &&
      other.parentalConsentVerified == parentalConsentVerified &&
      other.personalizedDataAllowed == personalizedDataAllowed;

  @override
  int get hashCode =>
      Object.hash(parentalConsentVerified, personalizedDataAllowed);
}

/// The compliance policy for the current user: a coarse [ageBand] + [consent],
/// from which every protective flag is *derived* (so callers read one source of
/// truth instead of re-deriving COPPA/GDPR-K logic ad hoc).
///
/// Immutable; the default instance is the fully-protective child-safe posture
/// that ships in MVP (unknown band, nothing consented).
class ComplianceConfig {
  const ComplianceConfig({
    this.ageBand = AgeBand.unknown,
    this.consent = ConsentState.none,
  });

  final AgeBand ageBand;
  final ConsentState consent;

  /// True when the user gets the full child-safe treatment (unknown / under-13).
  bool get isChildSafe => ageBand.requiresChildSafeTreatment;

  /// Whether free-text *input* (e.g. the pet's name field, any future chat box)
  /// may be offered. **No free-text from minors** (§11.1, §4.5) — so child-safe
  /// bands never get a raw text field; their input is constrained / templated.
  bool get freeTextInputAllowed => !isChildSafe;

  /// Whether *this user* may ever be offered generative / live dialogue — IF the
  /// global live-chat flag is also on (it is off for everyone in MVP). Child-safe
  /// bands are hard-excluded (under-13 = templated/non-generative only, §4.5); a
  /// teen additionally needs verified parental consent (GDPR-K); an adult
  /// qualifies on band alone.
  bool get mayUseGenerativeDialogue {
    switch (ageBand) {
      case AgeBand.unknown:
      case AgeBand.under13:
        return false;
      case AgeBand.teen:
        return consent.parentalConsentVerified;
      case AgeBand.adult:
        return true;
    }
  }

  /// Whether behavioral (personalized) ad targeting may be used. MVP posture is
  /// **no behavioral targeting for anyone** (D-007, §11.1 "no behavioral ad
  /// targeting anywhere"; the Data Safety form declares this, §11.3) — so this
  /// is `false` for every band today. It is a getter (not a bare constant) so
  /// the contextual-only contract is read from one place; the child-safe wall in
  /// [AdConfig] is keyed to [ageBand] independently, as defense in depth.
  bool get behavioralAdsAllowed => false;

  /// Combines the global live-chat feature flag (from [AppConfig]) with this
  /// user's eligibility — the one call the heartmind path uses so an under-13 /
  /// unknown user can never reach generative dialogue even if the flag flips on.
  bool effectiveLiveChatEnabled({required bool globalLiveChatFlag}) =>
      globalLiveChatFlag && mayUseGenerativeDialogue;

  ComplianceConfig copyWith({AgeBand? ageBand, ConsentState? consent}) =>
      ComplianceConfig(
        ageBand: ageBand ?? this.ageBand,
        consent: consent ?? this.consent,
      );

  @override
  bool operator ==(Object other) =>
      other is ComplianceConfig &&
      other.ageBand == ageBand &&
      other.consent == consent;

  @override
  int get hashCode => Object.hash(ageBand, consent);
}
