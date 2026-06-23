/// The on-device hybrid Heartmind (GAME_TECHNICAL_SYSTEMS.md §4). MVP magic with
/// **zero runtime tokens, no network, no spinner** (gate G2 architectural
/// guarantee): select a reviewed line for the pet-state, inject closed-set
/// memory facts into safe slots, run the defensive safety filter, fail closed to
/// the fixed safe line. NO live free-form generation (Deferred, gated).
library;

import 'dialogue_bank.dart';
import 'dialogue_selector.dart';
import 'heartmind_intent.dart';
import 'heartmind_service.dart';
import 'safety_filter.dart';

/// Richer companion API (the game uses this); also satisfies the legacy
/// [HeartmindService] string seam.
abstract interface class Heartmind implements HeartmindService {
  HeartmindLine speak(HeartmindContext context);
}

class LocalHeartmind implements Heartmind {
  LocalHeartmind({DialogueBank? bank, this.safety = const SafetyFilter()})
    : selector = DialogueSelector(bank ?? defaultDialogueBank());

  final DialogueSelector selector;
  final SafetyFilter safety;

  @override
  HeartmindLine speak(HeartmindContext context) {
    final selected = selector.select(context);
    if (selected == null) return _fallback(context.intent);
    // Defensive, fail-closed safety check on the fully-rendered line.
    if (!safety.validateOutput(selected.text).safe) {
      return _fallback(context.intent);
    }
    return selected;
  }

  HeartmindLine _fallback(HeartmindIntent intent) => HeartmindLine(
    text: SafetyConstants.safeFallbackLine,
    intent: intent,
    isFallback: true,
  );

  /// Legacy string seam: select a factless line for the request's intent.
  @override
  Future<String> lineFor(HeartmindRequest request) async {
    final intent = HeartmindIntent.values.firstWhere(
      (i) => i.id == request.intent,
      orElse: () => HeartmindIntent.idle,
    );
    return speak(
      HeartmindContext(
        intent: intent,
        lifeStage: request.lifeStage,
        mood: request.mood,
        bondStage: request.bondStage,
        personalityKey: request.personalityDial,
      ),
    ).text;
  }
}

/// The default reviewed dialogue bank. In production this is a large,
/// human-reviewed, offline-pre-generated set (CONTENT_FACTORY §10.2) topped up
/// via Remote Config; this representative seed proves the engine end-to-end and
/// is child-safe by construction. Wildcards (`*`) keep coverage robust.
DialogueBank defaultDialogueBank() {
  DialogueBankEntry e(
    String intent,
    String mood,
    List<String> lines, {
    String bondStage = '*',
    String lifeStage = '*',
    String personalityDial = '*',
  }) => DialogueBankEntry(
    intent: intent,
    lifeStage: lifeStage,
    mood: mood,
    bondStage: bondStage,
    personalityDial: personalityDial,
    lines: lines,
  );

  return DialogueBank([
    // ---- Greetings (per mood) ----
    e('greeting', 'joyful', [
      'Hi hi hi! You\'re here! 🐾',
      'Yay, it\'s you! *happy wiggle*',
    ]),
    e('greeting', 'content', [
      'Oh, hello! *soft tail wag*',
      'Hi friend. Cozy day, isn\'t it?',
    ]),
    e('greeting', 'wistful', [
      '*looks up* ...oh! Hi. I was hoping you\'d come by.',
      'There you are. *gentle nuzzle*',
    ]),
    e('greeting', 'low', [
      '*peeks up* ...hi. I\'m so glad to see you.',
      'Hi. A little cuddle would be nice. 💛',
    ]),
    // First-stage shy greeting (more specific → outranks generic).
    e('greeting', 'content', [
      '*peeks out shyly* ...hi.',
    ], bondStage: 'Stranger'),

    // ---- Returning after absence (warm, never guilt) ----
    e('returning', '*', [
      'You\'re back! I had a nice nap and thought of you. ☀️',
      'Welcome back! I missed our time together. 💛',
    ]),
    e('returning', 'low', [
      'Oh, you\'re here! Everything feels better now. 🐾',
    ]),

    // ---- Goodbyes ----
    e('goodbye', '*', [
      'See you soon! I\'ll be right here. 🐾',
      'Bye for now — take care of you! 💛',
    ]),

    // ---- Care acknowledgements ----
    e('careAck', 'joyful', [
      'That was the best! Thank you! 🎾',
      'Wheee! I feel wonderful! ✨',
    ]),
    e('careAck', '*', [
      'Mmm, thank you. That was lovely.',
      'You always know just what I need. 💛',
    ]),

    // ---- Comfort (signature beat) ----
    e('comfort', 'low', [
      'I\'m right here. We can just be quiet together.',
      'It\'s okay. Let\'s breathe together. 💛',
    ]),
    e('comfort', 'wistful', ['Come here. A little warmth helps everything.']),

    // ---- Milestones ----
    e('milestone', '*', [
      'Look how far we\'ve come together! 🌟',
      'This is such a happy day. I\'m so glad it\'s you. 💛',
    ]),

    // ---- Idle / ambient ----
    e('idle', 'joyful', [
      '*chases own tail* heehee',
      '*does a little bouncy spin*',
    ]),
    e('idle', 'content', [
      '*stretches in a sunbeam*',
      '*watches a leaf drift by, content*',
    ]),
    e('idle', 'wistful', [
      '*gazes softly toward the door*',
      '*tilts head, curious about a sound*',
    ]),
    e('idle', 'low', ['*curls up in a cozy spot*', '*slow, sleepy blink*']),

    // ---- Memory callbacks (slots; only chosen when the fact exists) ----
    e('memoryCallback', '*', [
      'I still think about how you like {fact:likes_activity}! 🐾',
      'Hey — {fact:likes_activity} is the best, right? 💛',
    ]),
    e('memoryCallback', '*', [
      'Our {fact:important_date} will always be special to me. 🌟',
    ]),
    e('memoryCallback', '*', [
      'I remembered: your favorite color is {fact:favorite_color}! ✨',
    ]),
    // A greeting variant that *references* memory when available.
    e('greeting', '*', [
      'Hi! I was just thinking about {fact:likes_activity}. 🐾',
    ]),
  ]);
}
