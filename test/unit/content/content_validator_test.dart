import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/content/content_distribution.dart';
import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';
import 'package:kindredpaws/heartmind/local_heartmind.dart';

DialogueBankEntry _entry({
  String intent = 'greeting',
  String mood = '*',
  String bondStage = '*',
  String lifeStage = '*',
  String personalityDial = '*',
  List<String> lines = const ['Hi friend! 🐾'],
}) => DialogueBankEntry(
  intent: intent,
  lifeStage: lifeStage,
  mood: mood,
  bondStage: bondStage,
  personalityDial: personalityDial,
  lines: lines,
);

void main() {
  const validator = ContentValidator();

  group('ContentValidator — the bundled launch bank is shippable', () {
    test(
      'defaultDialogueBank() passes with zero errors (safe by construction)',
      () {
        final report = validator.validateBank(defaultDialogueBank());
        expect(
          report.ok,
          isTrue,
          reason: report.errors.map((e) => e.toString()).join('\n'),
        );
      },
    );
  });

  group('ContentValidator — catches each violation class', () {
    test('unknown intent / mood / bondStage / lifeStage are errors', () {
      expect(
        validator.validateBank(DialogueBank([_entry(intent: 'bogus')])).ok,
        isFalse,
      );
      expect(
        validator.validateBank(DialogueBank([_entry(mood: 'grumpy')])).ok,
        isFalse,
      );
      expect(
        validator.validateBank(DialogueBank([_entry(bondStage: 'BFF')])).ok,
        isFalse,
      );
      expect(
        validator.validateBank(DialogueBank([_entry(lifeStage: 'Elder')])).ok,
        isFalse,
      );
    });

    test('an unknown memory slot is an error (unfillable content)', () {
      final r = validator.validateBank(
        DialogueBank([
          _entry(lines: ['I love your {fact:not_a_real_slot}!']),
        ]),
      );
      expect(r.ok, isFalse);
      expect(
        r.errors.any((e) => e.message.contains('unknown memory slot')),
        isTrue,
      );
    });

    test('a known slot is accepted', () {
      final r = validator.validateBank(
        DialogueBank([
          _entry(lines: ['You love {fact:likes_activity}! 🐾']),
        ]),
      );
      expect(r.ok, isTrue);
    });

    test('banned-topic content fails the safety filter', () {
      final r = validator.validateBank(
        DialogueBank([
          _entry(lines: ['Time to buy now with a credit card!']),
        ]),
      );
      expect(r.ok, isFalse);
    });

    test('never-guilt language is an error (Risk R6)', () {
      final r = validator.validateBank(
        DialogueBank([
          _entry(lines: ['I missed you so much, why did you abandon me?']),
        ]),
      );
      expect(r.ok, isFalse);
      expect(r.errors.any((e) => e.message.contains('never-guilt')), isTrue);
    });

    test('an empty line and an entry with no lines are errors', () {
      expect(
        validator
            .validateBank(
              DialogueBank([
                _entry(lines: ['  ']),
              ]),
            )
            .ok,
        isFalse,
      );
      expect(
        validator.validateBank(DialogueBank([_entry(lines: [])])).ok,
        isFalse,
      );
    });

    test('an unrecognized personality dial is a warning, not an error', () {
      final r = validator.validateBank(
        DialogueBank([_entry(personalityDial: 'mysterious')]),
      );
      expect(r.ok, isTrue); // still shippable
      expect(r.warningCount, greaterThan(0));
    });
  });

  group('mergeRemoteContent — validated, fail-safe Remote Config top-ups', () {
    final bundled = DialogueBank([_entry()]);

    test('null/empty payload leaves the bundled bank untouched', () {
      expect(mergeRemoteContent(bundled, null).bank.entries.length, 1);
      expect(mergeRemoteContent(bundled, '   ').acceptedCount, 0);
    });

    test('a valid remote entry is merged in', () {
      const remote =
          '[{"intent":"idle","lifeStage":"*","mood":"joyful","bondStage":"*",'
          '"personalityDial":"*","lines":["*does a happy spin* ✨"],"memorySlots":[]}]';
      final res = mergeRemoteContent(bundled, remote);
      expect(res.acceptedCount, 1);
      expect(res.rejectedCount, 0);
      expect(res.bank.entries.length, 2);
    });

    test('an unsafe remote entry is rejected (never reaches the live bank)', () {
      const remote =
          '[{"intent":"idle","lifeStage":"*","mood":"joyful","bondStage":"*",'
          '"personalityDial":"*","lines":["buy now with a credit card"],"memorySlots":[]}]';
      final res = mergeRemoteContent(bundled, remote);
      expect(res.acceptedCount, 0);
      expect(res.rejectedCount, 1);
      expect(res.bank.entries.length, 1); // bundled only
    });

    test('an unparseable payload is ignored (keeps the safe bundled bank)', () {
      final res = mergeRemoteContent(bundled, 'not json{');
      expect(res.acceptedCount, 0);
      expect(res.bank.entries.length, 1);
      expect(res.report.errorCount, greaterThan(0));
    });
  });
}
