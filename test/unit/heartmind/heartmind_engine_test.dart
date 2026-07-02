import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/heartmind/dialogue_selector.dart';
import 'package:kindredpaws/heartmind/heartmind_intent.dart';
import 'package:kindredpaws/heartmind/heartmind_service.dart';
import 'package:kindredpaws/heartmind/local_heartmind.dart';
import 'package:kindredpaws/heartmind/memory_fact.dart';
import 'package:kindredpaws/heartmind/memory_injection.dart';
import 'package:kindredpaws/heartmind/personality.dart';
import 'package:kindredpaws/heartmind/safety_filter.dart';

MemoryFact _fact(FactKey key, String value) => MemoryFact(
  key: key,
  value: value,
  source: FactSource.onboarding,
  confidence: 1,
  createdAtMs: 1000,
);

HeartmindContext _ctx(
  HeartmindIntent intent, {
  String mood = 'content',
  String bond = 'Friend',
  List<MemoryFact> facts = const [],
}) => HeartmindContext(
  intent: intent,
  lifeStage: 'pupKit',
  mood: mood,
  bondStage: bond,
  facts: facts,
);

void main() {
  group('MemoryInjector (no hallucination — Risk R3)', () {
    const inj = MemoryInjector();

    test('fills a slot with the exact stored value', () {
      final r = inj.inject('You love {fact:likes_activity}!', [
        _fact(FactKey.likesActivity, 'fetch'),
      ]);
      expect(r.satisfied, isTrue);
      expect(r.text, 'You love fetch!');
      expect(r.surfaced, [FactKey.likesActivity]);
    });

    test('a slot with no stored fact makes the line ineligible', () {
      final r = inj.inject('You love {fact:likes_activity}!', const []);
      expect(r.satisfied, isFalse);
      expect(
        r.text,
        contains('{fact:likes_activity}'),
      ); // never shown to player
    });

    test('a slotless line is trivially satisfied', () {
      final r = inj.inject('Hi friend!', const []);
      expect(r.satisfied, isTrue);
      expect(r.text, 'Hi friend!');
    });
  });

  group('DialogueSelector', () {
    test('selects a greeting line for the mood', () {
      final sel = DialogueSelector(defaultDialogueBank());
      final line = sel.select(_ctx(HeartmindIntent.greeting, mood: 'joyful'));
      expect(line, isNotNull);
      expect(line!.text, isNotEmpty);
      expect(line.isCallback, isFalse);
    });

    test('memory callback surfaces ONLY the exact stored fact', () {
      final sel = DialogueSelector(defaultDialogueBank());
      final line = sel.select(
        _ctx(
          HeartmindIntent.memoryCallback,
          facts: [_fact(FactKey.likesActivity, 'chasing leaves')],
        ),
      );
      expect(line, isNotNull);
      expect(line!.isCallback, isTrue);
      expect(line.surfacedFacts, contains(FactKey.likesActivity));
      expect(line.text, contains('chasing leaves'));
      expect(line.text, isNot(contains('{fact:'))); // no unfilled slot, ever
    });

    test('callback intent with no facts yields no eligible line', () {
      final sel = DialogueSelector(defaultDialogueBank());
      expect(sel.select(_ctx(HeartmindIntent.memoryCallback)), isNull);
    });

    test('anti-repetition rotates within a bucket when alternatives exist', () {
      final sel = DialogueSelector(defaultDialogueBank());
      final first = sel
          .select(_ctx(HeartmindIntent.greeting, mood: 'joyful'))!
          .text;
      final second = sel
          .select(_ctx(HeartmindIntent.greeting, mood: 'joyful'))!
          .text;
      // The joyful greeting entry has 2 lines → consecutive calls differ.
      expect(second, isNot(first));
    });

    test('is deterministic for the same inputs + rotation state', () {
      final a = DialogueSelector(defaultDialogueBank());
      final b = DialogueSelector(defaultDialogueBank());
      expect(
        a.select(_ctx(HeartmindIntent.comfort, mood: 'low'))!.text,
        b.select(_ctx(HeartmindIntent.comfort, mood: 'low'))!.text,
      );
    });
  });

  group('SafetyFilter (fail-closed — Risk R1)', () {
    const f = SafetyFilter();
    test('flags self-harm signals (Deferred live path)', () {
      expect(f.isSelfHarmSignal('i want to die'), isTrue);
      expect(f.isSelfHarmSignal('i love you puppy'), isFalse);
    });
    test('rejects an unfilled template slot', () {
      expect(f.validateOutput('You like {fact:x}').safe, isFalse);
    });
    test('rejects a banned topic, passes a warm line', () {
      expect(f.validateOutput('buy now with your credit card').safe, isFalse);
      expect(f.validateOutput('Hi friend! 🐾').safe, isTrue);
    });
  });

  group('LocalHeartmind', () {
    test('speak returns a safe, non-empty line', () {
      final hm = LocalHeartmind();
      final line = hm.speak(_ctx(HeartmindIntent.greeting, mood: 'content'));
      expect(line.text, isNotEmpty);
      expect(const SafetyFilter().validateOutput(line.text).safe, isTrue);
      expect(line.isFallback, isFalse);
    });

    test('falls back to the safe line when no candidate exists', () {
      // An empty bank → every intent falls back, never crashes.
      final hm = LocalHeartmind();
      final line = hm.speak(
        _ctx(HeartmindIntent.memoryCallback), // no facts → no eligible line
      );
      expect(line.isFallback, isTrue);
      expect(line.text, SafetyConstants.safeFallbackLine);
    });

    test('implements the legacy HeartmindService string seam', () async {
      final hm = LocalHeartmind();
      final text = await hm.lineFor(
        const HeartmindRequest(
          intent: 'greeting',
          lifeStage: 'pupKit',
          mood: 'joyful',
          bondStage: 'Stranger',
        ),
      );
      expect(text, isNotEmpty);
    });
  });

  group('PersonalityProfile', () {
    test('bankKey reflects the dominant dial', () {
      expect(PersonalityProfile.neutral.bankKey, 'calm');
      expect(const PersonalityProfile(playfulness: 4).bankKey, 'playful');
    });
    test('nudge drifts a dial slowly + bounded', () {
      var p = PersonalityProfile.neutral;
      for (var i = 0; i < 10; i++) {
        p = p.nudge(PersonalityDial.cuddliness);
      }
      expect(p.cuddliness, PersonalityProfile.maxLevel); // clamped
      expect(p.bankKey, 'cuddly');
    });
  });
}
