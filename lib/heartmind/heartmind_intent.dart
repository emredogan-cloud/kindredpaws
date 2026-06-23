/// The conversation intents the Heartmind selects a line for
/// (GAME_TECHNICAL_SYSTEMS.md §4.1 — the bank is keyed by intent). These map to
/// the Companion Presence triggers (§6): greetings, returns, goodbyes, care
/// acknowledgements, comfort, memory callbacks, milestones, and ambient idle.
library;

enum HeartmindIntent {
  greeting('greeting'),
  returning('returning'),
  goodbye('goodbye'),
  careAck('careAck'),
  comfort('comfort'),
  memoryCallback('memoryCallback'),
  milestone('milestone'),
  idle('idle');

  const HeartmindIntent(this.id);
  final String id;
}
