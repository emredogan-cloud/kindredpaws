import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/core/name_input_validator.dart';

void main() {
  const v = NameInputValidator();

  group('valid names pass + are sanitized', () {
    test('the species default names pass (onboarding must not break)', () {
      for (final name in ['Biscuit', 'Mochi']) {
        final r = v.validate(name);
        expect(r.isValid, isTrue, reason: name);
        expect(r.sanitized, name);
        expect(r.rejection, isNull);
      }
    });

    test('names with spaces, hyphens, apostrophes pass', () {
      for (final name in ['Sir Reginald', 'Bella-Rose', "O'Malley", 'Mr Tum']) {
        expect(v.validate(name).isValid, isTrue, reason: name);
      }
    });

    test('trims + collapses internal whitespace', () {
      expect(v.validate('  Bella  ').sanitized, 'Bella');
      expect(v.validate('Sir   Tom').sanitized, 'Sir Tom');
      expect(v.validate('\tNoodle\n').sanitized, 'Noodle');
    });

    test('a couple of digits are fine (R2D2, Agent7)', () {
      expect(v.validate('R2D2').isValid, isTrue);
      expect(v.validate('Agent7').isValid, isTrue);
    });
  });

  group('empty / length', () {
    test('empty or whitespace-only is rejected', () {
      expect(v.validate('').rejection, NameRejection.empty);
      expect(v.validate('   ').rejection, NameRejection.empty);
      expect(v.validate('\t\n').rejection, NameRejection.empty);
    });

    test('longer than maxLength is rejected', () {
      expect(NameInputValidator.maxLength, 16);
      expect(v.validate('a' * 17).rejection, NameRejection.tooLong);
      expect(v.validate('a' * 16).isValid, isTrue);
    });
  });

  group('PII is rejected (a name is never contact info)', () {
    test('emails', () {
      expect(v.validate('a@b.com').rejection, NameRejection.containsPii);
    });

    test('URLs / web addresses', () {
      expect(v.validate('cat.com').rejection, NameRejection.containsPii);
      expect(v.validate('www.x.io').rejection, NameRejection.containsPii);
    });

    test('phone-like digit runs (contiguous or formatted)', () {
      expect(v.validate('5551234567').rejection, NameRejection.containsPii);
      expect(v.validate('555-123-4567').rejection, NameRejection.containsPii);
    });
  });

  group('profanity is rejected (cozy-game tone)', () {
    test('direct hits', () {
      for (final bad in ['shit', 'fuck', 'a bitch']) {
        expect(
          v.validate(bad).rejection,
          NameRejection.containsProfanity,
          reason: bad,
        );
      }
    });

    test('leetspeak evasion is normalized', () {
      for (final bad in ['sh1t', r'$h1t', 'b1tch', 'a55hole']) {
        expect(
          v.validate(bad).rejection,
          NameRejection.containsProfanity,
          reason: bad,
        );
      }
    });

    test('spaced / punctuated evasion collapses onto the root', () {
      expect(v.validate('s h i t').rejection, NameRejection.containsProfanity);
      expect(v.validate('f.u.c.k').rejection, NameRejection.containsProfanity);
    });
  });

  group('does NOT over-reject innocent names (Scunthorpe guard)', () {
    test('clean names that contain bad substrings still pass', () {
      // 'dick'→'dickhead' root, 'ass'→'asshole' root, so these are safe:
      for (final ok in ['Dickens', 'Classy', 'Bass', 'Shih Tzu', 'Assisi']) {
        expect(v.validate(ok).isValid, isTrue, reason: ok);
      }
    });
  });

  group('control characters are rejected', () {
    test('a control char fails as invalidChars', () {
      expect(v.validate('Bella').rejection, NameRejection.invalidChars);
    });
  });
}
