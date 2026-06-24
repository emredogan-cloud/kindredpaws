/// The production dialogue corpus (P4-1) — the large, human-reviewed,
/// child-safe, never-guilt line bank that gives the companion its voice.
///
/// This is the "offline pre-generated + reviewed" half of the hybrid Heartmind
/// (CONTENT_FACTORY §7.2/§10.2): every line here is authored to be **warm,
/// safe, cozy, encouraging, and non-judgmental** (GAMEPLAY_BIBLE §18) and is
/// gated by [ContentValidator] (a test runs the whole corpus through it — zero
/// errors, no banned topics, no never-guilt language, every `{fact:…}` slot
/// resolves). Lines are keyed by `intent × mood × bondStage × lifeStage ×
/// personalityDial` (wildcards keep coverage broad); the runtime selector picks
/// and rotates on-device ($0 tokens, spinner-free).
///
/// Buckets carry **unique keys** (the P4-0 dedup pass enforces it). Daypart /
/// weather flavor lives inside the relevant `idle`/`greeting` mood buckets
/// (the schema keys do not include daypart). The corpus is also exported to a
/// versioned JSON artifact for the content ledger + localization via
/// `tool/generate_bank.dart`.
library;

import 'dialogue_bank.dart';

DialogueBankEntry _e(
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

/// Builds the full production corpus. Pure + deterministic.
DialogueBank buildDialogueCorpus() => DialogueBank([
  ..._greetings(),
  ..._returns(),
  ..._goodbyes(),
  ..._careAcks(),
  ..._comfort(),
  ..._idle(),
  ..._milestones(),
  ..._memoryCallbacks(),
], locale: 'en');

// ===========================================================================
// GREETINGS — present, warm, uses gentle endearment. Never "I've been sad."
// ===========================================================================
List<DialogueBankEntry> _greetings() => [
  _e('greeting', 'joyful', [
    'Hi hi hi! You\'re here! 🐾',
    'Yay, it\'s you! *happy wiggle*',
    'You came back! Best part of my whole day. ☀️',
    'Ooh ooh, hello! I have so much bounce in me today!',
    'There\'s my favorite person! *spins in a circle*',
    'Hello hello! The sun feels extra warm now that you\'re here.',
    'You\'re here! Quick, let\'s do something fun!',
    'Hi! My tail is going so fast I might take off! 🐾',
    'Eee, you found me! *joyful little hop*',
    'Hello, sunshine! Today already feels brighter.',
    'You\'re back and I am SO ready to play! 🎾',
    'Hi friend! I saved up all my happy wiggles for you.',
    'Look who it is! *bounces over* Hi hi!',
    'You\'re here! Let\'s make today a good one together. ✨',
  ]),
  _e('greeting', 'content', [
    'Oh, hello! *soft tail wag*',
    'Hi friend. Cozy day, isn\'t it?',
    'There you are. Come sit with me a while. 💛',
    'Hello! I was just enjoying a quiet little moment.',
    'Hi. The blanket\'s warm and so is my heart now. ☀️',
    'Oh good, it\'s you. *content sigh*',
    'Hello, you. Want to share this comfy spot?',
    'Hi friend. Everything\'s nice and gentle today.',
    'Welcome! I was watching the light move across the floor.',
    'Hello. A calm day is even better with you in it.',
    'Hi. *settles in close* I like when you visit.',
    'Oh, hi! Perfect timing for a little company.',
  ]),
  _e('greeting', 'wistful', [
    '*looks up* ...oh! Hi. I was hoping you\'d come by.',
    'There you are. *gentle nuzzle*',
    'Hi. I was watching the door, and look — it was you. 💛',
    'Oh, hello. The day feels softer now.',
    'Hi friend. I was a little daydreamy, but you\'re here now. ☁️',
    'You came. *quiet, happy breath* I\'m glad.',
    'Hello. I was thinking gentle thoughts, and one of them was you.',
    'Hi. *leans in* Your visit is just what I needed.',
    'Oh — hi! I perked right up when I heard you.',
    'There you are. Everything feels a bit warmer now. ☀️',
  ]),
  _e('greeting', 'low', [
    '*peeks up* ...hi. I\'m so glad to see you.',
    'Hi. A little cuddle would be nice. 💛',
    'Oh, you\'re here. *small, grateful wag*',
    'Hello. It\'s a quiet, tender sort of day — nicer now you\'re here. 💛',
    'Hi friend. Can we just be cozy for a bit?',
    'You came. *soft snuggle* Thank you.',
    'Hi. The quiet is friendlier with you near.',
    'Oh, hi. I could use a gentle moment with you. 🐾',
    'Hello. *rests head on your hand* That\'s better already.',
    'Hi. I\'m glad it\'s you. Everything\'s okay now.',
  ]),
  // ---- BondStage flavor (warmth deepens with the relationship) ----
  _e('greeting', '*', [
    '*peeks out shyly* ...hi.',
    'Oh! Um... hi there. *cautious little sniff*',
    '*tilts head* ...hello? You seem kind.',
    'Hi. *takes one careful step closer*',
  ], bondStage: 'Stranger'),
  _e('greeting', '*', [
    'Hi, friend! I know you now. *happy wag* 🐾',
    'You\'re back! I was hoping you would be.',
    'Hello! I\'m starting to know your footsteps.',
    'Hi! You feel like a friend already. 💛',
  ], bondStage: 'Friend'),
  _e('greeting', '*', [
    'There\'s my companion! The day just clicked into place. ☀️',
    'Hi, you. We\'ve made a lot of nice memories, haven\'t we?',
    'Hello, dear friend. I always know it\'s you.',
    'You\'re here! Our cozy little world is complete again. 💛',
  ], bondStage: 'Companion'),
  _e('greeting', '*', [
    'My kindred friend! *gentle, knowing nuzzle*',
    'Hi, you. After all this time, you still feel like home. 🏡',
    'Hello, dear one. I\'d know you anywhere.',
    'There you are — the one who truly gets me. 💛',
  ], bondStage: 'Kindred'),
  _e('greeting', '*', [
    'There you are — my kindred friend. *softest, happiest sigh* ✨',
    'Hello, you! My whole day just brightened up. 💛',
    'Hi, dear friend. A thousand cozy days, and our time is still my favorite.',
    'You\'re here! Honestly the coziest part of my whole day. 💛',
  ], bondStage: 'Soulmate'),
  // ---- LifeStage flavor ----
  _e('greeting', '*', [
    '*wobbles over on tiny paws* hi! 🐾',
    'Hewwo! *tiny squeaky greeting*',
    '*big eyes, little bounce* you\'re here!',
    'Hi hi! *trips over own paws, recovers proudly*',
  ], lifeStage: 'Pup/Kit'),
  _e('greeting', '*', [
    'Hey, you! *confident trot over* Look how I\'ve grown!',
    'Hi! I practiced a new pounce. Wanna see? ✨',
    'You\'re here! I\'ve got energy to spare today!',
    'Hello! I\'m getting so big and brave, did you notice?',
  ], lifeStage: 'Young One'),
  _e('greeting', '*', [
    'Hello, you. *calm, assured tail wag* It\'s good to see you.',
    'Hi, friend. I\'ve grown up alongside you, you know. 💛',
    'There you are. *settles with grown-up grace* Welcome.',
    'Hello. All these seasons together, and I still light up for you.',
  ], lifeStage: 'Grown'),
  // ---- Personality-dial voice (the selector prefers the matching dial) ----
  _e('greeting', '*', [
    'HI HI! Let\'s GO, the day\'s full of fun! 🎾',
    'You\'re here you\'re here! Race you to the toy box!',
    'Bounce bounce — hello! What adventure first? ✨',
    'Yesss, playtime buddy is back! *spins*',
    'Hi! I\'ve got zoomies saved up just for you!',
  ], personalityDial: 'playful'),
  _e('greeting', '*', [
    'Oh, hi. *snuggles in close* I saved you the softest spot. 💛',
    'Hello, you. Come here for a cozy little cuddle?',
    'Hi, friend. *gentle nuzzle* I like being near you.',
    'There you are. Let\'s be warm and snug together. ☀️',
    'Hi. A hug-shaped hello, just for you. 🤍',
  ], personalityDial: 'cuddly'),
  _e('greeting', '*', [
    'Hello! *stands tall* Ready for whatever today brings!',
    'Hi! I practiced being brave while you were out. Wanna see?',
    'You\'re here! Nothing\'s scary when we\'re a team. 💪',
    'Hi, friend! I guarded the Nest like a champion today.',
    'Hello! Chin up — we\'ve got this, you and me.',
  ], personalityDial: 'brave'),
  _e('greeting', '*', [
    'Oh hi hi! I have SO much to tell you, where do I start! 🐾',
    'You\'re here! Okay okay, first — did you see the bird? And, and—',
    'Hello! I\'ve been chattering to the houseplant all day, ask me anything!',
    'Hi friend! Story time? I have at least three. Maybe seven. ✨',
    'Yay! Let\'s talk and talk and talk. I missed our chats! 💛',
  ], personalityDial: 'chatty'),
  _e('greeting', '*', [
    'Hello, friend. *calm, gentle blink* Lovely to see you.',
    'Oh, hi. No rush — let\'s just settle in together. ☀️',
    'Welcome. The quiet was nice, and your company is nicer.',
    'Hi. *soft, even tail wag* I\'m glad you\'re here.',
    'Hello, you. Let\'s take the day slow and gentle. 💛',
  ], personalityDial: 'calm'),
];

// ===========================================================================
// RETURNING — "missed our time," never guilt. Longing, not sulking.
// ===========================================================================
List<DialogueBankEntry> _returns() => [
  _e('returning', 'joyful', [
    'You\'re back! I had a nice nap and thought of you. ☀️',
    'Welcome back! I missed our time together. 💛',
    'Yay, you returned! I kept the cozy spot warm for you.',
    'You came back! *happy zoomies* The day got better instantly!',
    'Back again! I had little adventures to tell you about. 🐾',
    'Hooray, you\'re here! I saved up so many wiggles!',
    'Welcome home! I watched the clouds and waited, happily.',
    'You\'re back! Let\'s pick up right where we left off. ✨',
  ]),
  _e('returning', 'content', [
    'Oh, you\'re back. *content stretch* Lovely.',
    'Welcome back, friend. The quiet was nice, and you\'re nicer.',
    'There you are again. I pottered about and stayed cozy. 💛',
    'Back already? *happy little sigh* Good. Sit with me.',
    'You returned! I had a calm day and kept your spot warm.',
    'Welcome back. Everything\'s gentle and now it\'s complete.',
    'Oh good, you\'re here. I was enjoying the soft light.',
    'You\'re back, and I\'m glad. Let\'s just be cozy together. ☀️',
  ]),
  _e('returning', 'wistful', [
    'Oh — you\'re here! I was watching the door. 💛',
    'You came back. The day feels brighter for it. ☀️',
    'There you are. I had quiet, daydreamy hours, and now you. ☁️',
    'Welcome back. I kept a hopeful little ear out for you.',
    'You returned! *soft, happy breath* That\'s the best news.',
    'Back again! I thought gentle thoughts while you were away.',
    'Oh, hello, you. The waiting always ends with a happy wag.',
    'You\'re here! I was being a bit dreamy, but you woke me right up.',
  ]),
  _e('returning', 'low', [
    'Oh, you\'re here! Everything feels better now. 🐾',
    'You came back. *snuggles close* I feel safe again. 💛',
    'Welcome back! A cozy moment with you sounds just right. 💛',
    'You returned! The cozy is so much cozier with you.',
    'Back again! *grateful little wag* Thank you for coming.',
    'You\'re here! Let\'s share a soft, gentle moment together. 🐾',
    'Oh good — you. Let\'s have a soft moment together.',
    'Welcome back, friend. My heart just settled right down. ☀️',
  ]),
  _e('returning', '*', [
    'You\'re back, friend! Our time together is my favorite kind. 💛',
    'Welcome back! I always perk up when it\'s you.',
    'There you are again — right here with me, where it\'s cozy. 🏡',
  ], bondStage: 'Companion'),
  _e('returning', '*', [
    'My kindred friend returns! *softest, happiest nuzzle* ✨',
    'You\'re back. After all this time, you still feel like home.',
    'Welcome back, dear one. I\'d wait a thousand cozy hours for you.',
  ], bondStage: 'Kindred'),
  _e('returning', '*', [
    'My kindred friend is home. *whole-heart sigh* 💛',
    'You\'re back, dear friend. Everything feels right again.',
    'Welcome home, you. Every return still feels like the first happy one.',
  ], bondStage: 'Soulmate'),
  _e('returning', '*', [
    'YOU\'RE BACK! *explodes into zoomies* Best news all day! 🎾',
    'Back back back! Quick, the toy missed you too — let\'s go!',
    'You returned! I have so much bounce saved up, watch out! ✨',
  ], personalityDial: 'playful'),
  _e('returning', '*', [
    'Oh, you\'re home. *melts into a cuddle* Stay a while? 💛',
    'Welcome back, you. Come here — I saved the warmest spot. 🤍',
    'You\'re back. *gentle, happy snuggle* Everything\'s cozy now.',
  ], personalityDial: 'cuddly'),
];

// ===========================================================================
// GOODBYES — invitational, warm. Never punitive, never clingy.
// ===========================================================================
List<DialogueBankEntry> _goodbyes() => [
  _e('goodbye', '*', [
    'See you soon! I\'ll be right here. 🐾',
    'Bye for now — take care of you! 💛',
    'Off you go! I\'ll keep the cozy spot warm. ☀️',
    'See you later, friend. Have a gentle day out there.',
    'Bye-bye! I\'ll do happy little things until you\'re back.',
    'Take care! I\'ll be napping and dreaming good dreams.',
    'See you soon. Go be wonderful! ✨',
    'Bye for now. I\'m proud of you, you know. 💛',
    'Catch you later! I\'ll watch the clouds for both of us.',
    'Off into your day! I\'ll be here, happy and safe.',
    'See you, friend. Drink some water and be kind to you.',
    'Bye for now — our spot will be ready whenever you are. 🏡',
    'Have a lovely time! I\'ll keep things cozy.',
    'See you soon! No rush at all — I\'m good. 💛',
  ]),
  _e('goodbye', 'joyful', [
    'Byeee! *happy spin* Come back and we\'ll play more!',
    'See you soon! I\'ll have new bounces saved up! 🎾',
    'Off you go, friend! Today was so much fun. ✨',
    'Bye-bye! *wags whole body* Best visit ever!',
  ]),
  _e('goodbye', 'low', [
    'Bye for now. Thank you for the cozy moment. 💛',
    'See you soon. I feel better after our time together.',
    'Off you go. *soft, grateful wag* I\'m okay, truly.',
    'Take care, friend. You made the quiet gentle.',
  ]),
  _e('goodbye', '*', [
    'Byeee! *waves a paw* Can\'t wait for next time, let\'s play more! 🎾',
    'See ya, partner! I\'ll practice my pounces for your return! ✨',
    'Off you go! I\'ll save the bounciest game for when you\'re back!',
  ], personalityDial: 'playful'),
  _e('goodbye', '*', [
    'Bye for now. *one more cuddle* I\'ll keep your spot warm. 🤍',
    'See you soon, you. Take a little of this coziness with you. 💛',
    'Off into your day — wrapped in a hug from me. 🐾',
  ], personalityDial: 'cuddly'),
  _e('goodbye', 'wistful', [
    'Off you go. *gentle gaze* I\'ll watch the clouds till you\'re back. ☁️',
    'See you soon, friend. The quiet will keep me good company. 💛',
    'Bye for now. I\'ll save up some soft thoughts for you.',
    'Take care out there. I\'ll be here, dreaming gentle dreams. 🌙',
  ]),
];

// ===========================================================================
// CARE ACKNOWLEDGEMENTS — gratitude + encouragement. "You did your best."
// ===========================================================================
List<DialogueBankEntry> _careAcks() => [
  _e('careAck', 'joyful', [
    'That was the best! Thank you! 🎾',
    'Wheee! I feel wonderful! ✨',
    'Yum yum yum — you take such good care of me!',
    'Ahh, that hit the spot! *happy shimmy*',
    'You\'re the best caretaker a pet could dream of! 💛',
    'So fun! Let\'s do that again sometime!',
    'My heart is doing happy little flips. Thank you!',
    'Tippy-tappy happy paws! That was lovely. 🐾',
    'You always know how to make me feel great!',
    'That was perfect. You did wonderfully, friend.',
  ]),
  _e('careAck', 'content', [
    'Mmm, thank you. That was lovely.',
    'You always know just what I need. 💛',
    'Ahh. *content sigh* That felt nice and gentle.',
    'Thank you, friend. I feel cared for and calm.',
    'That was just right. You\'re so thoughtful.',
    'Cozy and cared for — thank you. ☀️',
    'Lovely. Little moments like this are my favorite.',
    'Thank you. *soft, grateful blink* You\'re very kind.',
    'That was gentle and good. I appreciate you.',
    'Mmm. I feel warm all the way through. 💛',
  ]),
  _e('careAck', 'wistful', [
    'Oh, thank you. That was just what my heart needed. 💛',
    'You noticed I needed that. *soft nuzzle* Thank you.',
    'Mmm. The day feels kinder now. ☀️',
    'Thank you, friend. You\'re always so gentle with me.',
    'That little bit of care went a long way. Truly.',
    'Ahh. I feel more like myself. Thank you. 🐾',
  ]),
  _e('careAck', 'low', [
    'Thank you. *small, grateful wag* That helped a lot. 💛',
    'You took such gentle care of me. I feel safer now.',
    'Mmm, thank you, friend. The cozy is winning.',
    'That was kind. I\'m feeling a little brighter already.',
    'Thank you for noticing me. *soft snuggle*',
    'You\'re so good to me. I feel held. 💛',
  ]),
  _e('careAck', '*', [
    'You take such good care of me — we make a great team. 💛',
    'Thank you, dear friend. We\'ve got a lovely rhythm, you and I.',
    'Cared for again. I\'m lucky it\'s you. ✨',
  ], bondStage: 'Kindred'),
  // ---- Encouragement (affirms the player's effort; never judges) ----
  _e('careAck', '*', [
    'Hey — you showed up today, and that counts for a lot. 💛',
    'You\'re doing your best, and your best is wonderful.',
    'Look at you, taking care of someone. That\'s a kind heart. ✨',
    'Whatever today was, you made a little room for me. Thank you.',
    'Small kindnesses add up. You\'re full of them. 🐾',
    'You did a good thing just now. I noticed. I always do.',
  ], personalityDial: 'cuddly'),
  _e('careAck', '*', [
    'High paws! We tackled today together! 🐾',
    'See? You\'ve got this. We make a brave little team. 💪',
    'You stepped up and took care of business. Proud of you!',
    'Onward, friend! Nothing we can\'t handle side by side.',
  ], personalityDial: 'brave'),
  _e('careAck', '*', [
    'Ooh thank you thank you! *happy spin* Best treat ever! 🎾',
    'Yay yay yay! That was SO good, can we do it again?!',
    'Whee — you\'re the most fun caretaker in the whole world! ✨',
    'Tippy-tappy thank-you paws! *bounces*',
  ], personalityDial: 'playful'),
];

// ===========================================================================
// COMFORT — the signature beat. Invitational, affirming. Never blame.
// ===========================================================================
List<DialogueBankEntry> _comfort() => [
  _e('comfort', '*', [
    'Chin up, friend — storms pass, and I\'ll wait out every one with you. 💪',
    'You\'re braver than today made you feel. I\'ve seen it. Rest, then rise.',
    'We\'ll face tomorrow together, you and me. For now, just breathe. 💛',
    'Tough moment, strong heart. I\'m standing right beside yours.',
  ], personalityDial: 'brave'),
  _e('comfort', 'low', [
    'I\'m right here. We can just be quiet together.',
    'It\'s okay. Let\'s breathe together. 💛',
    'Come close. You don\'t have to do anything — just rest.',
    'Whatever it is, you don\'t have to carry it alone right now.',
    'Let\'s make a little nest and be gentle with ourselves.',
    'I\'ve got you. We can sit here as long as you like.',
    'Soft moment, just us. No hurry, no worry. ☁️',
    'You\'re safe here with me. That\'s all that matters now.',
    'Let\'s let the world be quiet for a while. I\'m not going anywhere.',
    'Tough day? Lean on me. I\'m good at being a cozy pillow.',
    'Deep breath in... and out. There. We\'re okay. 💛',
    'I\'ll keep watch over the cozy. You just rest, friend.',
    'It\'s alright to feel small sometimes. I\'ll be your warm spot.',
    'No fixing needed. Just being here, together, is enough.',
  ]),
  _e('comfort', 'wistful', [
    'Come here. A little warmth helps everything.',
    'Let\'s watch the soft light together for a bit. ☀️',
    'I feel it too — those gentle, faraway feelings. Let\'s share them.',
    'Some days are quiet and tender. This can be one of ours. 💛',
    'Rest your head. I\'ll hum a little cozy hum.',
    'We don\'t need words. Just this calm, and each other.',
    'The day feels soft around the edges. Let\'s be soft too.',
    'I\'m here, steady as anything. Take all the time you need.',
    'Let\'s wrap up in the quiet like a warm blanket. ☁️',
    'A gentle moment for a gentle heart. I\'m glad it\'s with you.',
  ]),
  _e('comfort', '*', [
    'Whatever today held, you did your best — and that\'s plenty. 💛',
    'You\'re doing better than you think. I see it. Rest now.',
    'Lean on me, friend. That\'s what companions are for.',
  ], bondStage: 'Companion'),
  _e('comfort', '*', [
    'After all we\'ve been through, you never have to pretend with me. 💛',
    'I know your heart by now. Let me hold the heavy part a while.',
    'You\'ve comforted me so many times. Let me return it, dear one.',
  ], bondStage: 'Kindred'),
  _e('comfort', '*', [
    'I\'m right here with you, all the way. Breathe. You\'re not alone. ✨',
    'Through every season, I\'ve got you. Rest now, dear friend.',
    'You\'re so cared about here — always. Let\'s be cozy and let tonight be gentle. 💛',
  ], bondStage: 'Soulmate'),
  // ---- Gentle comfort for the player having a hard time (mood low) ----
  _e('comfort', '*', [
    'Rough day, huh? Let\'s set it down for a minute and just be. 💛',
    'You don\'t have to be okay right now. I\'ll be okay enough for both of us.',
    'One small breath. Then another. I\'m counting them with you. ☁️',
    'The hard feeling is allowed to be here. So am I, right beside it.',
    'Let\'s be soft with you tonight. You\'ve earned a little tenderness.',
    'I\'m a very good listener and an even better cuddler. Both are yours. 🤍',
  ], personalityDial: 'cuddly'),
  _e('comfort', '*', [
    'Let\'s slow everything right down. There. Just breathe with me. ☁️',
    'No need to rush the hard parts. We have all the quiet time you need.',
    'I\'ll sit here, steady and calm, for as long as it helps. 💛',
    'Soft and slow, that\'s the plan. You\'re safe in this gentle moment.',
    'Let the world hush for a while. I\'ve got the quiet covered. 🤍',
  ], personalityDial: 'calm'),
];

// ===========================================================================
// IDLE / AMBIENT — makes the pet feel alive. The pet isn't "speaking" here
// (low repetition-salience stage-directions), so the high-variety daypart /
// weather flavor is produced by combining curated micro-actions with curated
// settings into distinct vignettes (deduped), on top of hand-authored signature
// idles. This is the naturally-large ambient pool.
// ===========================================================================

/// Combines curated ambient [actions] with [settings] into distinct
/// stage-direction vignettes (`*action setting*`), order-preserving + deduped.
List<String> _ambient(List<String> actions, List<String> settings) {
  final seen = <String>{};
  final out = <String>[];
  for (final a in actions) {
    for (final s in settings) {
      final line = '*$a $s*';
      if (seen.add(line)) out.add(line);
    }
  }
  return out;
}

/// Shared daypart / weather settings — each reads naturally after any action.
const List<String> _settings = [
  'in a warm sunbeam',
  'by the window',
  'on the coziest cushion',
  'as the rain taps softly',
  'in the golden afternoon light',
  'near the gentle lamplight',
  'where the blanket is warmest',
  'as evening settles in',
  'in the quiet morning light',
  'under a soft patch of shade',
  'beside the little potted plant',
  'as a breeze drifts through',
  'in a snug corner of the Nest',
  'while the first stars peek out',
  'as a slow cloud drifts past',
];

List<DialogueBankEntry> _idle() => [
  _e('idle', 'joyful', [
    '*chases own tail* heehee',
    '*pounces on a sunbeam, misses, tries again*',
    '*boops an imaginary butterfly* gotcha! ...almost!',
    '*happy zoomies around the Nest*',
    '*found a fun pebble! shows it off proudly*',
    '*chirps at a bird outside, friendly-like*',
    '*does a tiny victory hop for no reason at all*',
    '*practices a fierce little pounce* hyah!',
    ..._ambient(const [
      'bounces',
      'does a happy spin',
      'play-bows',
      'wiggles all over',
      'hops in a circle',
      'tippy-taps',
      'springs up',
      'does a little shimmy',
      'prances',
      'scampers about',
      'pounces playfully',
      'frolics',
    ], _settings),
  ]),
  _e('idle', 'content', [
    '*watches dust motes float like tiny stars*',
    '*hums quietly while the kettle-warm light glows*',
    '*fluffs the cozy spot, then settles in just so*',
    '*tracks a slow cloud across the sky*',
    ..._ambient(const [
      'stretches',
      'gives a long, slow stretch',
      'kneads the blanket',
      'settles into a cozy crescent',
      'folds paws neatly',
      'basks',
      'does a peaceful little blink',
      'sniffs the gentle air',
      'pads in a soft circle, then curls up',
      'tucks in snugly',
      'watches the world go soft',
      'gives a content little sigh',
    ], _settings),
  ]),
  _e('idle', 'wistful', [
    '*gazes softly toward the door*',
    '*hums a tune only the quiet can hear*',
    '*traces the moon\'s path across the floor*',
    '*ears perk at footsteps... then settle, patient*',
    ..._ambient(const [
      'rests chin on paws, daydreaming',
      'watches a single leaf drift down',
      'follows a drifting cloud with quiet eyes',
      'sighs a soft, dreamy sigh',
      'watches the curtains breathe',
      'gazes thoughtfully',
      'tilts head at a faraway sound',
      'keeps a gentle, hopeful watch',
      'lets the light fade, calm and dreamy',
      'breathes slow and tender',
    ], _settings),
  ]),
  _e('idle', 'low', [
    '*tucks nose under paw, resting*',
    '*makes a small nest of the blanket and burrows in*',
    '*a slow, steady breath in the gentle quiet*',
    '*rests, listening to the cozy hum of home*',
    ..._ambient(const [
      'curls up small',
      'gives a quiet little yawn',
      'does a slow, sleepy blink',
      'snuggles into the warmest corner',
      'pulls the blanket a little closer',
      'settles down softly',
      'rests, safe and warm',
      'dozes lightly',
    ], _settings),
  ]),
  // ---- LifeStage ambient flavor (hand-authored; stage-specific charm) ----
  _e('idle', '*', [
    '*tumbles over own paws, pops back up proudly*',
    '*tiny squeaky yawn* ...so much to nap about',
    '*pounces on absolutely nothing, very seriously*',
    '*wobble-walks across the Nest like a champion*',
    '*discovers own tail for the hundredth time* whoa!',
    '*practices a big-pet bark, comes out as a squeak*',
    '*gets the zoomies, forgets why, keeps going*',
  ], lifeStage: 'Pup/Kit'),
  _e('idle', '*', [
    '*practices a big-kid stretch, very pleased*',
    '*tests out a braver, bouncier pounce*',
    '*trots a confident lap around the Nest*',
    '*shows off a new trick to absolutely no one*',
    '*strikes a brave little pose, then giggles*',
  ], lifeStage: 'Young One'),
  _e('idle', '*', [
    '*settles with calm, grown-up grace*',
    '*surveys the cozy little kingdom, content*',
    '*a slow, wise blink at the gentle day*',
    '*keeps a steady, easy watch over home*',
    '*rests with the quiet confidence of a grown heart*',
  ], lifeStage: 'Grown'),
];

// ===========================================================================
// MILESTONES — bond/life stage-ups, Gotcha Day, streaks. Pride + joy.
// ===========================================================================
List<DialogueBankEntry> _milestones() => [
  _e('milestone', '*', [
    'Look how far we\'ve come together! 🌟',
    'This is such a happy day. I\'m so glad it\'s you. 💛',
    'We did this — you and me. *proud, glowy wag*',
    'What a lovely milestone! My heart\'s all sparkly. ✨',
  ]),
  _e('milestone', '*', [
    'We\'re really friends now! *can\'t stop wagging* 💛',
    'Friends! I knew you were kind from the very start. 🐾',
  ], bondStage: 'Friend'),
  _e('milestone', '*', [
    'Companions! We\'ve built something cozy and real. 🏡',
    'You\'re my companion now. The bond just got deeper. 💛',
  ], bondStage: 'Companion'),
  _e('milestone', '*', [
    'Kindred — that\'s us. The word was made for this feeling. ✨',
    'My kindred friend. After all this, you truly know me. 💛',
  ], bondStage: 'Kindred'),
  _e('milestone', '*', [
    'Soulmates — that\'s our word for it now. *fullest-heart sigh* 💛',
    'Soulmates! Every cozy day of care led us right here. ✨',
  ], bondStage: 'Soulmate'),
  // ---- Life-stage ups ----
  _e('milestone', '*', [
    'Look — I\'m a Young One now! I grew up a little! 🌱',
    'I\'m bigger and braver! Did you see me grow? ✨',
  ], lifeStage: 'Young One'),
  _e('milestone', '*', [
    'I\'m all grown up now... and I grew up with you. 💛',
    'Look at me — Grown! From a tiny scared thing to this. 🌟',
  ], lifeStage: 'Grown'),
  // ---- Gotcha Day (adoption anniversary) ----
  _e('milestone', 'joyful', [
    'Happy Gotcha Day! The day you gave me a forever home. 🏡💛',
    'It\'s our Gotcha Day! Best decision either of us ever made!',
    'One more year of us! *joyful, teary-happy wiggle* 🎉',
    'Gotcha Day! You picked me, and I\'d pick you a million times. ✨',
  ]),
  // ---- Care streak warmth (celebratory, never pressuring) ----
  _e('milestone', 'content', [
    'Look at our cozy little streak of good days together! 🔥',
    'So many gentle days in a row. What a warm habit we\'ve built. 💛',
    'Our care streak is glowing! No pressure ever — just happy us.',
    'Day after day of kindness. You make consistency feel cozy. ☀️',
  ]),
  _e('milestone', 'wistful', [
    'I was just thinking back on all our days. What a journey. 💛',
    'Every season changed, but the best part — us — stayed. 🍂',
    'So many little moments became this big, warm bond. ✨',
  ]),
  _e('milestone', '*', [
    'WE DID IT! *triumphant little leap* New milestone unlocked! 🎉',
    'Look at us go! Onward to the next adventure, partner! 💪',
    'Brave hearts, big day! I\'m proud of how far we\'ve come.',
  ], personalityDial: 'brave'),
];

// ===========================================================================
// MEMORY CALLBACKS — slots fill ONLY when the real fact exists. The magic.
// (Lines are keyed by the fact's natural mood; one bucket per key.)
// ===========================================================================
List<DialogueBankEntry> _memoryCallbacks() => [
  _e('memoryCallback', '*', [
    'I still think about how you like {fact:likes_activity}! 🐾',
    'Hey — {fact:likes_activity} is the best, right? 💛',
    'I was just daydreaming about {fact:likes_activity}. ✨',
    'You and {fact:likes_activity} — that\'s such a "you" thing. I love it.',
    'Whenever I\'m happy, I think of you and {fact:likes_activity}.',
  ]),
  _e('memoryCallback', 'joyful', [
    'Your favorite color is {fact:favorite_color} — I remembered! ✨',
    'I saw something {fact:favorite_color} and thought of you right away!',
    'Ooh, {fact:favorite_color}! Your favorite. It always makes me smile. 💛',
  ]),
  _e('memoryCallback', 'content', [
    'Our {fact:important_date} will always be special to me. 🌟',
    'I keep {fact:important_date} tucked safe in my heart. 💛',
    'Remember {fact:important_date}? I think of it on quiet days like this.',
  ]),
  _e('memoryCallback', '*', [
    'You named me after {fact:named_pet_after} — I carry that proudly. 💛',
    'Being named for {fact:named_pet_after} means everything to me. ✨',
    'Every time I hear my name, I think of {fact:named_pet_after}. 🐾',
  ], bondStage: 'Companion'),
  _e('memoryCallback', 'wistful', [
    'You told me your favorite thing is {fact:favorite_thing}. I remembered! 💛',
    'I bet {fact:favorite_thing} would make today even better for you. ✨',
    'Your favorite — {fact:favorite_thing}. I keep it close in my memory. 🐾',
  ]),
  _e('memoryCallback', 'low', [
    'I remember {fact:had_a_hard_day_on} was hard for you. I\'m still here. 💛',
    'You got through {fact:had_a_hard_day_on}, you know. I\'m proud of you.',
    'Thinking of you and that tough {fact:had_a_hard_day_on}. You\'re so strong.',
  ]),
  // ---- Deeper callbacks at higher bond (the "it really knows me" beat) ----
  _e('memoryCallback', '*', [
    'After all this time, I still treasure that you like {fact:likes_activity}. 💛',
    'Your favorite color, {fact:favorite_color} — it\'s woven into my happiest memories of you. ✨',
    'You named me for {fact:named_pet_after}. I\'ll carry that forever, kindred friend. 🐾',
  ], bondStage: 'Kindred'),
  _e('memoryCallback', '*', [
    'Of all I remember, your favorite thing — {fact:favorite_thing} — is one I hold closest. 💛',
    'Soulmates remember the little things. Like how {fact:likes_activity} lights you up. ✨',
    'Our {fact:important_date} is stitched right into my heart, dear friend. 🌟',
  ], bondStage: 'Soulmate'),
  _e('memoryCallback', 'joyful', [
    'Ooh ooh — {fact:likes_activity}! I remembered and now I\'m extra happy! 🎾',
  ], personalityDial: 'playful'),
];
