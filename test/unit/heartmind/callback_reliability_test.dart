import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/heartmind/callback_reliability.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';
import 'package:kindredpaws/heartmind/memory_book.dart';
import 'package:kindredpaws/heartmind/memory_category.dart';
import 'package:kindredpaws/heartmind/memory_fact.dart';

MemoryFact _fact(FactKey key, String value, {int t = 1000}) => MemoryFact(
  key: key,
  value: value,
  source: FactSource.onboarding,
  confidence: 1,
  createdAtMs: t,
);

void main() {
  group('AI-memory callback reliability (gate G2 ≥ 95%, zero hallucination)', () {
    final factSets = <List<MemoryFact>>[
      const [], // no-facts probe → must NEVER fabricate a callback
      [_fact(FactKey.likesActivity, 'chasing the ball')],
      [_fact(FactKey.importantDate, 'our Gotcha Day')],
      [_fact(FactKey.favoriteColor, 'sky blue')],
      [
        _fact(FactKey.likesActivity, 'fetch'),
        _fact(FactKey.favoriteColor, 'green'),
        _fact(FactKey.importantDate, 'the day we met'),
      ],
    ];

    final report = CallbackReliability.measure(factSets: factSets);

    test('callbacks actually fire when facts exist (coverage > 0)', () {
      expect(report.callbacksMade, greaterThan(0));
      expect(report.attempts, greaterThan(0));
    });

    test('accuracy ≥ 95% (G2)', () {
      expect(report.accuracy, greaterThanOrEqualTo(0.95));
    });

    test('ZERO hallucinated facts', () {
      expect(report.hallucinated, 0, reason: report.toString());
    });

    test('ZERO unfilled template slots ever shown', () {
      expect(report.unfilledSlots, 0, reason: report.toString());
    });

    test('ZERO false callbacks (never fabricates a memory with no fact)', () {
      expect(report.falseCallbacks, 0, reason: report.toString());
    });

    test('the harness is NOT tautological — it catches a fabricated bank', () {
      // A deliberately BAD bank: a "memory callback" hardcoding a fake
      // remembered detail with no fact slot (a fabricated memory).
      const badBank = DialogueBank([
        DialogueBankEntry(
          intent: 'memoryCallback',
          lifeStage: '*',
          mood: '*',
          bondStage: '*',
          personalityDial: '*',
          lines: ['I remember you love secretsauce! (made up)'],
        ),
      ]);
      final bad = CallbackReliability.measure(
        bank: badBank,
        factSets: [
          [_fact(FactKey.likesActivity, 'fetch')],
        ],
      );
      // It selected a "callback" but surfaced no real fact → not correct,
      // so the harness reports a failing accuracy (proving it can detect bad).
      expect(bad.callbacksMade, greaterThan(0));
      expect(bad.accuracy, lessThan(0.95));
    });
  });

  group('Memory Book v2 (categorized)', () {
    MemoryBook book(List<MemoryFact> facts) => MemoryBook.build(
      facts: facts,
      petName: 'Biscuit',
      speciesLabel: 'Puppy',
      bondStageLabel: 'Friend',
      lifeStageLabel: 'Pup/Kit',
      createdAtMs: 5000,
    );

    test('always has the relationship + life-stage anchors', () {
      final b = book(const []);
      expect(b.inCategory(MemoryCategory.relationship), isNotEmpty);
      expect(b.inCategory(MemoryCategory.lifeStage), isNotEmpty);
    });

    test('categorizes facts into the right groups', () {
      final b = book([
        _fact(FactKey.likesActivity, 'fetch'),
        _fact(FactKey.importantDate, 'Rescue Day — the day we met'),
        _fact(FactKey.importantDate, 'Grew into a Young One'),
      ]);
      expect(
        b.inCategory(MemoryCategory.favorite).map((e) => e.text).join(),
        contains('fetch'),
      );
      expect(b.inCategory(MemoryCategory.rescue), isNotEmpty); // Rescue Day
      expect(b.inCategory(MemoryCategory.lifeStage).length, greaterThan(1));
    });

    test('entries are newest-first', () {
      final b = book([
        _fact(FactKey.favoriteColor, 'blue', t: 100),
        _fact(FactKey.likesActivity, 'fetch', t: 9000),
      ]);
      for (var i = 0; i < b.entries.length - 1; i++) {
        expect(
          b.entries[i].createdAtMs,
          greaterThanOrEqualTo(b.entries[i + 1].createdAtMs),
        );
      }
    });
  });
}
