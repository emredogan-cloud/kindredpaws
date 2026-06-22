import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/heartmind/dialogue_bank.dart';
import 'package:kindredpaws/heartmind/heartmind_service.dart';
import 'package:kindredpaws/heartmind/memory_fact.dart';

void main() {
  group('Memory Book fact schema (Risk R3)', () {
    test('valid fact serializes round-trip', () {
      final f = MemoryFact(
        key: FactKey.favoriteThing,
        value: 'rainy days',
        source: FactSource.onboarding,
        confidence: 0.9,
        createdAtMs: 1000,
      );
      final back = MemoryFact.fromJson(f.toJson());
      expect(back.key, FactKey.favoriteThing);
      expect(back.value, 'rainy days');
      expect(back.source, FactSource.onboarding);
    });

    test('rejects empty value', () {
      expect(
        () => MemoryFact(
          key: FactKey.favoriteColor,
          value: '',
          source: FactSource.onboarding,
          confidence: 1,
          createdAtMs: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects out-of-range confidence', () {
      expect(
        () => MemoryFact(
          key: FactKey.favoriteColor,
          value: 'blue',
          source: FactSource.onboarding,
          confidence: 1.5,
          createdAtMs: 0,
        ),
        throwsArgumentError,
      );
    });

    test('fact set is a closed enum (no free-form keys)', () {
      expect(FactKey.values, contains(FactKey.namedPetAfter));
      expect(MemoryFact.minFacts, 10);
      expect(MemoryFact.maxFacts, 30);
    });
  });

  group('Dialogue bank schema', () {
    test('parses the seed bank and keys entries by pet-state', () {
      final bank = DialogueBank.fromJsonString(DialogueBank.seedJson);
      expect(bank.entries, isNotEmpty);
      expect(bank.entries.first.key, startsWith('greeting|'));
    });

    test('entry round-trips JSON', () {
      const e = DialogueBankEntry(
        intent: 'idle',
        lifeStage: 'Grown',
        mood: 'Content',
        bondStage: 'Companion',
        personalityDial: 'playful',
        lines: ['*chases tail*'],
      );
      final back = DialogueBankEntry.fromJson(e.toJson());
      expect(back.intent, 'idle');
      expect(back.lines.single, '*chases tail*');
    });
  });

  group('Heartmind provisioning seam', () {
    test(
      'locked model ids match founder decision (Haiku runtime / Opus pregen)',
      () {
        expect(HeartmindModels.runtimeModel, 'claude-haiku-4-5');
        expect(HeartmindModels.pregenModel, 'claude-opus-4-8');
      },
    );

    test(
      'stub returns the reviewed safe-fallback line (never generated)',
      () async {
        const svc = StubHeartmind();
        final line = await svc.lineFor(
          const HeartmindRequest(
            intent: 'greeting',
            lifeStage: 'Pup/Kit',
            mood: 'Content',
            bondStage: 'Stranger',
          ),
        );
        expect(line, SafetyConstants.safeFallbackLine);
      },
    );
  });
}
