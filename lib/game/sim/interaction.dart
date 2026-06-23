/// The three (and only three) core care interactions — feed / clean / play
/// (brief §2 #3, GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.1, §5.6). Each raises the
/// relevant meter and awards a small Bond increment, with **within-session
/// diminishing returns** (§5.6: effective = base × 0.6ⁿ) so tap-spam is pointless
/// and the pet's visible satisfaction is the natural stop cue.
library;

import 'dart:math' as math;

import '../model/care_meters.dart';
import 'sim_config.dart';

enum CareInteraction {
  feed('feed'),
  clean('clean'),
  play('play');

  const CareInteraction(this.id);
  final String id;
}

/// Per-session interaction tallies driving diminishing returns. Transient
/// (resets when a new session starts).
class SessionInteractions {
  const SessionInteractions({
    this.feed = 0,
    this.clean = 0,
    this.play = 0,
    this.petting = 0,
  });

  final int feed;
  final int clean;
  final int play;
  final int petting;

  int countOf(CareInteraction i) => switch (i) {
    CareInteraction.feed => feed,
    CareInteraction.clean => clean,
    CareInteraction.play => play,
  };

  /// Total care interactions this session — the `interactions_n` that drives
  /// the `sessionQuality` retention signal (empty session ⇔ total == 0).
  int get total => feed + clean + play + petting;

  SessionInteractions increment(CareInteraction i) => SessionInteractions(
    feed: feed + (i == CareInteraction.feed ? 1 : 0),
    clean: clean + (i == CareInteraction.clean ? 1 : 0),
    play: play + (i == CareInteraction.play ? 1 : 0),
    petting: petting,
  );

  static const SessionInteractions empty = SessionInteractions();
}

/// The raw, pre-mood-modifier, pre-daily-cap result of one interaction.
class InteractionEffect {
  const InteractionEffect({
    required this.meters,
    required this.rawBondPoints,
    required this.kibble,
    required this.wasNeeded,
    required this.session,
  });

  final CareMeters meters;

  /// Bond points before the mood multiplier + daily soft cap are applied.
  final double rawBondPoints;
  final int kibble;

  /// True if the action met a real need (meter was below full) — only "needed"
  /// care counts toward the Care Streak and pays full Bond.
  final bool wasNeeded;
  final SessionInteractions session;
}

class InteractionEngine {
  const InteractionEngine(this.config);

  final SimConfig config;

  double _diminish(double base, int priorUses) =>
      base * math.pow(config.diminishingFactor, priorUses);

  double _clamp(double v) => v.clamp(config.floor, 100);

  InteractionEffect apply(
    CareMeters meters,
    CareInteraction interaction,
    SessionInteractions session,
  ) {
    final n = session.countOf(interaction);
    final bp = config.bondPoints;

    switch (interaction) {
      case CareInteraction.feed:
        final needed = meters.hunger < 100;
        final next = meters.copyWith(
          hunger: _clamp(meters.hunger + _diminish(config.feedRestore, n)),
          happiness: _clamp(
            meters.happiness + _diminish(config.feedHappiness, n),
          ),
        );
        return InteractionEffect(
          meters: next,
          rawBondPoints: _diminish(
            needed ? bp.feedWhenHungry : bp.pettingTouch,
            n,
          ),
          kibble: needed ? 5 : 1,
          wasNeeded: needed,
          session: session.increment(interaction),
        );
      case CareInteraction.clean:
        final needed = meters.hygiene < 100;
        final next = meters.copyWith(
          hygiene: _clamp(meters.hygiene + _diminish(config.cleanRestore, n)),
        );
        return InteractionEffect(
          meters: next,
          rawBondPoints: _diminish(
            needed ? bp.cleanWhenDirty : bp.pettingTouch,
            n,
          ),
          kibble: needed ? 5 : 1,
          wasNeeded: needed,
          session: session.increment(interaction),
        );
      case CareInteraction.play:
        // Play costs energy (not diminished — it always tires the pet) and
        // boosts happiness (diminished).
        final next = meters.copyWith(
          happiness: _clamp(
            meters.happiness + _diminish(config.playHappiness, n),
          ),
          energy: _clamp(meters.energy - config.playEnergyCost),
        );
        final willing = meters.energy > config.playEnergyCost;
        return InteractionEffect(
          meters: next,
          rawBondPoints: _diminish(
            willing ? bp.playWhenWilling : bp.pettingTouch,
            n,
          ),
          kibble: willing ? 5 : 1,
          wasNeeded: meters.happiness < 100,
          session: session.increment(interaction),
        );
    }
  }
}
