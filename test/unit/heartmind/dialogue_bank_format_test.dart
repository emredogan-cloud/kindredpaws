import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';

void main() {
  group('DialogueBank format (P4-0 versioning + localization-ready)', () {
    test('parses the legacy bare-array form (defaults v1/en)', () {
      const json = '''
[ {"intent":"greeting","lifeStage":"*","mood":"joyful","bondStage":"*",
   "personalityDial":"*","lines":["Hi!","Hello!"],"memorySlots":[]} ]''';
      final bank = DialogueBank.fromJsonString(json);
      expect(bank.entries, hasLength(1));
      expect(bank.lineCount, 2);
      expect(bank.schemaVersion, DialogueBank.currentSchemaVersion);
      expect(bank.locale, 'en');
    });

    test('parses the versioned/localized wrapper form', () {
      const json = '''
{ "schemaVersion": 1, "locale": "fr",
  "entries": [ {"intent":"idle","lifeStage":"*","mood":"content","bondStage":"*",
   "personalityDial":"*","lines":["*bâille*"],"memorySlots":[]} ] }''';
      final bank = DialogueBank.fromJsonString(json);
      expect(bank.locale, 'fr');
      expect(bank.entries, hasLength(1));
      expect(bank.lineCount, 1);
    });

    test('toJsonString round-trips through the wrapper form', () {
      const bank = DialogueBank([
        DialogueBankEntry(
          intent: 'comfort',
          lifeStage: 'Grown',
          mood: 'low',
          bondStage: 'Friend',
          personalityDial: 'calm',
          lines: ['I am right here. 💛'],
        ),
      ], locale: 'en');
      final restored = DialogueBank.fromJsonString(bank.toJsonString());
      expect(restored.locale, 'en');
      expect(restored.schemaVersion, bank.schemaVersion);
      expect(restored.entries.single.lines, ['I am right here. 💛']);
      expect(restored.lineCount, 1);
    });
  });
}
