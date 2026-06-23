import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/content/bank_manifest.dart';
import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';
import 'package:kindredpaws/heartmind/dialogue_corpus.dart';
import 'package:kindredpaws/heartmind/heartmind_intent.dart';
import 'package:kindredpaws/heartmind/local_heartmind.dart';

void main() {
  final bank = buildDialogueCorpus();
  final manifest = BankManifest.of(bank);

  group('production dialogue corpus (P4-1)', () {
    test('is safe by construction — zero validator errors', () {
      final report = const ContentValidator().validateBank(bank);
      expect(
        report.ok,
        isTrue,
        reason: report.errors.map((e) => e.toString()).join('\n'),
      );
    });

    test('meets the ≥1000 reviewed-line floor', () {
      expect(bank.lineCount, greaterThanOrEqualTo(1000));
    });

    test('covers every dialogue intent', () {
      for (final intent in HeartmindIntent.values) {
        expect(
          manifest.byIntent[intent.id] ?? 0,
          greaterThan(0),
          reason: 'no lines for intent "${intent.id}"',
        );
      }
    });

    test('covers all four moods + provides a real callback corpus', () {
      for (final mood in ['joyful', 'content', 'wistful', 'low']) {
        expect(manifest.byMood[mood] ?? 0, greaterThan(0), reason: mood);
      }
      expect(manifest.memoryCallbackLineCount, greaterThanOrEqualTo(20));
    });

    test('is exposed as the default bundled bank', () {
      // defaultDialogueBank() now returns the production corpus.
      expect(defaultDialogueBank().lineCount, bank.lineCount);
    });

    test('exports to versioned JSON that re-parses + re-validates clean', () {
      final restored = DialogueBank.fromJsonString(bank.toJsonString());
      expect(restored.locale, 'en');
      expect(restored.lineCount, bank.lineCount);
      expect(const ContentValidator().validateBank(restored).ok, isTrue);
    });
  });
}
