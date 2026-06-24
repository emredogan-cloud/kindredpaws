/// Ad-network kids-configuration (P3-6a) — the concrete mediation-SDK flags,
/// derived purely from the [ComplianceConfig]. Keeping this a pure function of
/// the compliance policy means the COPPA / GDPR-K posture is decided in exactly
/// one place ([ComplianceConfig]) and the ad SDK just reads the result.
///
/// No AdMob/mediation dependency lives here — the real SDK wiring (a
/// post-provisioning step, REQUIRED_ENVIRONMENTS.md §6) reads these fields when
/// it builds its request configuration. That keeps CI/dev free of an ad SDK and
/// makes the child-safe mapping unit-testable in isolation.
///
/// Authority: GAME_TECHNICAL_SYSTEMS.md §11.1/§11.3, brief §5/§11 R1,
/// `docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md` Q4 (advertising), D-007.
library;

import '../core/compliance_config.dart';

/// Maximum ad-content rating, mirroring AdMob's `MAX_AD_CONTENT_RATING_*`.
/// Child-safe bands are clamped to [g]; everyone else is still held to the cozy
/// [pg] ceiling (this is a gentle pet game — no [t]/[ma] inventory anywhere).
enum AdContentRating { g, pg, t, ma }

/// The kids-config a mediation SDK consumes, derived from [ComplianceConfig].
class AdConfig {
  const AdConfig({
    required this.tagForChildDirectedTreatment,
    required this.tagForUnderAgeOfConsent,
    required this.personalizedAdsAllowed,
    required this.maxAdContentRating,
  });

  /// COPPA "tag for child-directed treatment" (TFCD). On for child-safe bands.
  final bool tagForChildDirectedTreatment;

  /// GDPR-K "tag for under the age of consent" (TFUA). On for child-safe bands.
  final bool tagForUnderAgeOfConsent;

  /// Whether personalized/behavioral ad requests are permitted. Mirrors
  /// [ComplianceConfig.behavioralAdsAllowed] — `false` for everyone in MVP
  /// (contextual-only, §11.1).
  final bool personalizedAdsAllowed;

  /// The ceiling on ad-content rating for the request.
  final AdContentRating maxAdContentRating;

  /// Derive the network flags from the compliance policy. Child-safe bands
  /// (unknown / under-13) get TFCD + TFUA on and the rating clamped to G;
  /// personalized ads are off for every band in MVP.
  factory AdConfig.fromCompliance(ComplianceConfig compliance) {
    final childSafe = compliance.isChildSafe;
    return AdConfig(
      tagForChildDirectedTreatment: childSafe,
      tagForUnderAgeOfConsent: childSafe,
      personalizedAdsAllowed: compliance.behavioralAdsAllowed,
      maxAdContentRating: childSafe ? AdContentRating.g : AdContentRating.pg,
    );
  }

  /// True iff the request carries the full child-safe ad posture: both kids tags
  /// on, no personalization, G-rated ceiling. Pinned by tests for every
  /// child-safe band.
  bool get isFullyChildSafe =>
      tagForChildDirectedTreatment &&
      tagForUnderAgeOfConsent &&
      !personalizedAdsAllowed &&
      maxAdContentRating == AdContentRating.g;

  @override
  bool operator ==(Object other) =>
      other is AdConfig &&
      other.tagForChildDirectedTreatment == tagForChildDirectedTreatment &&
      other.tagForUnderAgeOfConsent == tagForUnderAgeOfConsent &&
      other.personalizedAdsAllowed == personalizedAdsAllowed &&
      other.maxAdContentRating == maxAdContentRating;

  @override
  int get hashCode => Object.hash(
    tagForChildDirectedTreatment,
    tagForUnderAgeOfConsent,
    personalizedAdsAllowed,
    maxAdContentRating,
  );
}
