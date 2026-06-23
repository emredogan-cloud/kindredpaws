import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/content/bank_manifest.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';

DialogueBankEntry _e(
  String intent,
  String mood,
  List<String> lines, {
  String bond = '*',
  String life = '*',
  String dial = '*',
}) => DialogueBankEntry(
  intent: intent,
  lifeStage: life,
  mood: mood,
  bondStage: bond,
  personalityDial: dial,
  lines: lines,
);

void main() {
  group('BankManifest.of (content versioning + categorization)', () {
    test('counts entries, lines, and per-dimension categories', () {
      final bank = DialogueBank([
        _e('greeting', 'joyful', ['Hi!', 'Hello!']),
        _e(
          'comfort',
          'low',
          ['I remember {fact:favorite_color}.'],
          life: 'Grown',
          bond: 'Friend',
        ),
      ], locale: 'en');

      final m = BankManifest.of(bank);
      expect(m.schemaVersion, DialogueBank.currentSchemaVersion);
      expect(m.locale, 'en');
      expect(m.entryCount, 2);
      expect(m.lineCount, 3);
      expect(m.byIntent, {'greeting': 2, 'comfort': 1});
      expect(m.byMood, {'joyful': 2, 'low': 1});
      expect(m.byLifeStage, {'*': 2, 'Grown': 1});
      expect(m.byBondStage, {'*': 2, 'Friend': 1});
    });

    test('counts memory-callback lines (lines with a {fact:} slot)', () {
      final bank = DialogueBank([
        _e('memoryCallback', '*', [
          'I remember {fact:favorite_color}!',
          'You like {fact:likes_activity}, right?',
          'Just a normal line.', // no slot
        ]),
      ]);
      expect(BankManifest.of(bank).memoryCallbackLineCount, 2);
    });

    test('toJson + describe surface the breakdown', () {
      final bank = DialogueBank([
        _e('idle', 'content', ['*stretch*']),
      ]);
      final m = BankManifest.of(bank);
      expect(m.toJson()['entryCount'], 1);
      expect(m.toJson()['byIntent'], {'idle': 1});
      expect(m.describe(), contains('1 entries / 1 lines'));
      expect(m.describe(), contains('locale=en'));
    });
  });
}
