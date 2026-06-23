import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/heartmind/dialogue_selector.dart';
import 'package:kindredpaws/heartmind/heartmind_intent.dart';
import 'package:kindredpaws/heartmind/local_heartmind.dart';
import 'package:kindredpaws/heartmind/memory_fact.dart';
import 'package:kindredpaws/heartmind/safety_filter.dart';

/// Words a cozy, never-guilt companion must NEVER say (Risk R1/R6, D-047).
const _bannedGuilt = [
  'starving',
  'dying',
  'sick',
  'abandon',
  'guilt',
  'miss you',
  'forgot',
  'neglect',
  'punish',
  'lonely without',
];

void main() {
  const moods = ['joyful', 'content', 'wistful', 'low'];
  const bonds = ['Stranger', 'Friend', 'Companion', 'Kindred', 'Soulmate'];
  final facts = [
    MemoryFact(
      key: FactKey.likesActivity,
      value: 'fetch',
      source: FactSource.onboarding,
      confidence: 1,
      createdAtMs: 1000,
    ),
  ];

  test(
    'EVERY spoken line, across all intents/moods/bonds, is safe + never guilt',
    () {
      const safety = SafetyFilter();
      var checked = 0;
      for (final intent in HeartmindIntent.values) {
        for (final mood in moods) {
          for (final bond in bonds) {
            for (final withFacts in [true, false]) {
              final hm = LocalHeartmind();
              final line = hm.speak(
                HeartmindContext(
                  intent: intent,
                  lifeStage: 'pupKit',
                  mood: mood,
                  bondStage: bond,
                  facts: withFacts ? facts : const [],
                ),
              );
              checked++;
              // Passes the defensive safety filter.
              expect(
                safety.validateOutput(line.text).safe,
                isTrue,
                reason: '$intent/$mood/$bond: "${line.text}"',
              );
              // Contains no guilt/shame language.
              final t = line.text.toLowerCase();
              for (final banned in _bannedGuilt) {
                expect(
                  t.contains(banned),
                  isFalse,
                  reason:
                      '$intent/$mood/$bond said banned "$banned": '
                      '"${line.text}"',
                );
              }
            }
          }
        }
      }
      expect(
        checked,
        HeartmindIntent.values.length * moods.length * bonds.length * 2,
      );
    },
  );
}
