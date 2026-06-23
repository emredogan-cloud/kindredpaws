import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/compliance_config.dart';
import 'package:kindredpaws/monetization/ad_config.dart';

void main() {
  group('AdConfig.fromCompliance — child-safe bands (COPPA/GDPR-K)', () {
    test('unknown and under-13 get the full child-safe ad posture', () {
      for (final band in [AgeBand.unknown, AgeBand.under13]) {
        final ad = AdConfig.fromCompliance(ComplianceConfig(ageBand: band));
        expect(ad.tagForChildDirectedTreatment, isTrue, reason: '$band TFCD');
        expect(ad.tagForUnderAgeOfConsent, isTrue, reason: '$band TFUA');
        expect(
          ad.personalizedAdsAllowed,
          isFalse,
          reason: '$band personalized',
        );
        expect(
          ad.maxAdContentRating,
          AdContentRating.g,
          reason: '$band rating',
        );
        expect(ad.isFullyChildSafe, isTrue, reason: '$band fully child-safe');
      }
    });
  });

  group('AdConfig.fromCompliance — non-child-safe bands', () {
    test(
      'teen/adult drop the kids tags but keep contextual-only + PG ceiling',
      () {
        for (final band in [AgeBand.teen, AgeBand.adult]) {
          final ad = AdConfig.fromCompliance(ComplianceConfig(ageBand: band));
          expect(
            ad.tagForChildDirectedTreatment,
            isFalse,
            reason: '$band TFCD',
          );
          expect(ad.tagForUnderAgeOfConsent, isFalse, reason: '$band TFUA');
          // Behavioral ads are off for everyone in MVP (§11.1).
          expect(
            ad.personalizedAdsAllowed,
            isFalse,
            reason: '$band personalized',
          );
          expect(
            ad.maxAdContentRating,
            AdContentRating.pg,
            reason: '$band rating',
          );
          expect(
            ad.isFullyChildSafe,
            isFalse,
            reason: '$band not child-safe tag',
          );
        }
      },
    );
  });

  group('AdConfig.fromCompliance — personalization never leaks via consent', () {
    test(
      'personalizedDataAllowed consent does NOT enable personalized ads',
      () {
        const consented = ConsentState(personalizedDataAllowed: true);
        for (final band in AgeBand.values) {
          final ad = AdConfig.fromCompliance(
            ComplianceConfig(ageBand: band, consent: consented),
          );
          expect(
            ad.personalizedAdsAllowed,
            isFalse,
            reason:
                'MVP runs contextual-only ads for $band regardless of consent',
          );
        }
      },
    );
  });

  group('AdConfig value semantics', () {
    test('== and hashCode', () {
      final a = AdConfig.fromCompliance(
        const ComplianceConfig(ageBand: AgeBand.under13),
      );
      final b = AdConfig.fromCompliance(
        const ComplianceConfig(ageBand: AgeBand.unknown),
      );
      final c = AdConfig.fromCompliance(
        const ComplianceConfig(ageBand: AgeBand.adult),
      );
      expect(a, equals(b)); // both fully child-safe ⇒ identical config
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
