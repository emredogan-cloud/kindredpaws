/// Dialogue-bank schema (GAME_TECHNICAL_SYSTEMS.md §4.1, CONTENT_FACTORY §7.2).
///
/// The hybrid MVP ships an offline-LLM-pre-generated, 100% human-reviewed bank
/// of lines keyed by pet-state. At runtime a line is selected on-device ($0
/// tokens, spinner-free) and 0–2 validated memory facts are injected into safe
/// template slots. This file defines the bank's data format + loader; the
/// runtime selection + anti-repetition rotation is Phase 2.
library;

import 'dart:convert';

/// One pre-generated, reviewed line set for a pet-state bucket.
class DialogueBankEntry {
  const DialogueBankEntry({
    required this.intent,
    required this.lifeStage,
    required this.mood,
    required this.bondStage,
    required this.personalityDial,
    required this.lines,
    this.memorySlots = const [],
  });

  final String intent; // e.g. greeting, comfort, idle, milestone
  final String lifeStage; // Pup/Kit | Young One | Grown
  final String mood; // Joyful | Content | Wistful | Low
  final String bondStage; // Stranger..Soulmate
  final String personalityDial; // e.g. playful | calm
  /// Reviewed lines; may contain `{fact:favorite_thing}` style safe slots.
  final List<String> lines;
  final List<String> memorySlots;

  /// Composite key used by the runtime selector (Phase 2).
  String get key => '$intent|$lifeStage|$mood|$bondStage|$personalityDial';

  Map<String, dynamic> toJson() => {
    'intent': intent,
    'lifeStage': lifeStage,
    'mood': mood,
    'bondStage': bondStage,
    'personalityDial': personalityDial,
    'lines': lines,
    'memorySlots': memorySlots,
  };

  factory DialogueBankEntry.fromJson(Map<String, dynamic> j) =>
      DialogueBankEntry(
        intent: j['intent'] as String,
        lifeStage: j['lifeStage'] as String,
        mood: j['mood'] as String,
        bondStage: j['bondStage'] as String,
        personalityDial: j['personalityDial'] as String,
        lines: (j['lines'] as List).map((e) => e as String).toList(),
        memorySlots:
            (j['memorySlots'] as List?)?.map((e) => e as String).toList() ??
            const [],
      );
}

class DialogueBank {
  const DialogueBank(this.entries);

  final List<DialogueBankEntry> entries;

  factory DialogueBank.fromJsonString(String s) {
    final list = jsonDecode(s) as List;
    return DialogueBank(
      list
          .map((e) => DialogueBankEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// A tiny seed bank used to validate the format + loader in Phase 0. The
  /// real bank is produced offline + human-reviewed (CONTENT_FACTORY §10.2).
  static const String seedJson = '''
[
  {"intent":"greeting","lifeStage":"Pup/Kit","mood":"Content","bondStage":"Stranger","personalityDial":"calm",
   "lines":["*peeks out shyly* ...hi.","*sniffs your hand, then relaxes*"],"memorySlots":[]},
  {"intent":"comfort","lifeStage":"Young One","mood":"Low","bondStage":"Friend","personalityDial":"calm",
   "lines":["I'm right here. We can just be quiet together."],"memorySlots":[]}
]
''';
}
