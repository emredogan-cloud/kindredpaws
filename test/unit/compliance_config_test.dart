import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/compliance_config.dart';

void main() {
  group('AgeBand.requiresChildSafeTreatment', () {
    test('unknown and under13 require child-safe treatment (fail-safe)', () {
      expect(AgeBand.unknown.requiresChildSafeTreatment, isTrue);
      expect(AgeBand.under13.requiresChildSafeTreatment, isTrue);
    });

    test('teen and adult do not', () {
      expect(AgeBand.teen.requiresChildSafeTreatment, isFalse);
      expect(AgeBand.adult.requiresChildSafeTreatment, isFalse);
    });

    test('unknown sorts first so it is the natural default', () {
      expect(AgeBand.values.first, AgeBand.unknown);
    });
  });

  group('ComplianceConfig default posture (D-007 child-safe for ALL)', () {
    test('the default instance is the fully-protective child-safe posture', () {
      const c = ComplianceConfig();
      expect(c.ageBand, AgeBand.unknown);
      expect(c.consent, ConsentState.none);
      expect(c.isChildSafe, isTrue);
      expect(c.freeTextInputAllowed, isFalse);
      expect(c.mayUseGenerativeDialogue, isFalse);
      expect(c.behavioralAdsAllowed, isFalse);
    });

    test('an unknown band is treated identically to under-13', () {
      const unknown = ComplianceConfig(ageBand: AgeBand.unknown);
      const under13 = ComplianceConfig(ageBand: AgeBand.under13);
      expect(unknown.isChildSafe, under13.isChildSafe);
      expect(unknown.freeTextInputAllowed, under13.freeTextInputAllowed);
      expect(
        unknown.mayUseGenerativeDialogue,
        under13.mayUseGenerativeDialogue,
      );
    });
  });

  group('ComplianceConfig.freeTextInputAllowed (no free-text from minors)', () {
    test('off for child-safe bands, on for teen/adult', () {
      expect(
        const ComplianceConfig(ageBand: AgeBand.unknown).freeTextInputAllowed,
        isFalse,
      );
      expect(
        const ComplianceConfig(ageBand: AgeBand.under13).freeTextInputAllowed,
        isFalse,
      );
      expect(
        const ComplianceConfig(ageBand: AgeBand.teen).freeTextInputAllowed,
        isTrue,
      );
      expect(
        const ComplianceConfig(ageBand: AgeBand.adult).freeTextInputAllowed,
        isTrue,
      );
    });
  });

  group(
    'ComplianceConfig.mayUseGenerativeDialogue (§4.5 under-13 templated)',
    () {
      test(
        'under-13 / unknown are hard-excluded even with parental consent',
        () {
          const consented = ConsentState(parentalConsentVerified: true);
          expect(
            const ComplianceConfig(
              ageBand: AgeBand.unknown,
              consent: consented,
            ).mayUseGenerativeDialogue,
            isFalse,
          );
          expect(
            const ComplianceConfig(
              ageBand: AgeBand.under13,
              consent: consented,
            ).mayUseGenerativeDialogue,
            isFalse,
          );
        },
      );

      test('teen requires verified parental consent', () {
        expect(
          const ComplianceConfig(
            ageBand: AgeBand.teen,
          ).mayUseGenerativeDialogue,
          isFalse,
        );
        expect(
          const ComplianceConfig(
            ageBand: AgeBand.teen,
            consent: ConsentState(parentalConsentVerified: true),
          ).mayUseGenerativeDialogue,
          isTrue,
        );
      });

      test('adult qualifies on band alone', () {
        expect(
          const ComplianceConfig(
            ageBand: AgeBand.adult,
          ).mayUseGenerativeDialogue,
          isTrue,
        );
      });
    },
  );

  group('ComplianceConfig.behavioralAdsAllowed (no behavioral targeting)', () {
    test('false for EVERY band in MVP (contextual-only, §11.1)', () {
      for (final band in AgeBand.values) {
        expect(
          ComplianceConfig(
            ageBand: band,
            consent: const ConsentState(personalizedDataAllowed: true),
          ).behavioralAdsAllowed,
          isFalse,
          reason: 'behavioral ads must stay off for $band even with consent',
        );
      }
    });
  });

  group('ComplianceConfig.effectiveLiveChatEnabled', () {
    test(
      'a child-safe user can never reach live chat even if the flag is on',
      () {
        const c = ComplianceConfig(ageBand: AgeBand.unknown);
        expect(c.effectiveLiveChatEnabled(globalLiveChatFlag: true), isFalse);
      },
    );

    test('an eligible adult still needs the global flag on', () {
      const c = ComplianceConfig(ageBand: AgeBand.adult);
      expect(c.effectiveLiveChatEnabled(globalLiveChatFlag: false), isFalse);
      expect(c.effectiveLiveChatEnabled(globalLiveChatFlag: true), isTrue);
    });
  });

  group('value semantics', () {
    test('ComplianceConfig copyWith / == / hashCode', () {
      const base = ComplianceConfig();
      final adult = base.copyWith(ageBand: AgeBand.adult);
      expect(adult.ageBand, AgeBand.adult);
      expect(adult.consent, base.consent);
      expect(adult == base, isFalse);
      expect(adult == const ComplianceConfig(ageBand: AgeBand.adult), isTrue);
      expect(
        adult.hashCode,
        const ComplianceConfig(ageBand: AgeBand.adult).hashCode,
      );
    });

    test('ConsentState defaults, copyWith / == / hashCode', () {
      expect(ConsentState.none.parentalConsentVerified, isFalse);
      expect(ConsentState.none.personalizedDataAllowed, isFalse);
      final vpc = ConsentState.none.copyWith(parentalConsentVerified: true);
      expect(vpc.parentalConsentVerified, isTrue);
      expect(vpc == ConsentState.none, isFalse);
      expect(vpc == const ConsentState(parentalConsentVerified: true), isTrue);
      expect(
        vpc.hashCode,
        const ConsentState(parentalConsentVerified: true).hashCode,
      );
    });
  });
}
