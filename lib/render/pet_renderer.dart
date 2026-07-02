/// Pet rendering abstraction (rig integration seam).
///
/// Engine is locked to **Flutter** (ADR-001). The rig runtime was resolved at
/// **P1-0**: the animation spike found Live2D Cubism has no first-party Flutter
/// runtime (only an unproven community binding), so the rig backend switched to
/// **Rive** (the founder-pre-authorized fallback) — a first-party, multi-platform
/// Flutter runtime with the same "params, not frames" economics. Evidence +
/// decision: `docs/ANIMATION_SPIKE_REPORT.md`. (Art style stays Live2D-Cubism-
/// styled per ADR-002; only the *runtime* changed.)
///
/// This interface decouples the game from the concrete rig backend so the actual
/// commissioned rig (`RivePetRenderer`, P2) drops in without touching gameplay.
/// The placeholder below is NOT the rig — it is an **expressive, deterministic**
/// stand-in (implicit animations only, so widget tests still settle) that proves
/// the emotion/mood/life-stage state machine end-to-end until the `.riv` lands.
library;

import 'package:flutter/material.dart';

/// A pet "mood" the renderer can express. Mirrors the 4 derived mood states
/// (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.3) so the seam matches the design.
enum PetMood { joyful, content, wistful, low }

/// The 12 canonical emotion motions (GAME_CONTENT_FACTORY.md §5.1) — the
/// expressive vocabulary the rig animates as param blends. Each maps to one of
/// the 4 [PetMood]s. The renderer plays one as the current expression; the game
/// drives reactions (feed/clean/play) + ambient idle through these.
enum PetEmotion {
  happy('Happy', PetMood.joyful, Icons.sentiment_very_satisfied),
  excited('Excited', PetMood.joyful, Icons.celebration),
  playful('Playful', PetMood.joyful, Icons.sports_baseball),
  affectionate('Affectionate', PetMood.joyful, Icons.favorite),
  content('Content', PetMood.content, Icons.pets),
  proud('Proud', PetMood.content, Icons.emoji_events),
  calm('Calm', PetMood.content, Icons.self_improvement),
  sleepy('Sleepy', PetMood.wistful, Icons.bedtime),
  curious('Curious', PetMood.wistful, Icons.travel_explore),
  lonely('Lonely', PetMood.wistful, Icons.sentiment_satisfied),
  hungry('Hungry', PetMood.low, Icons.ramen_dining),
  comforted('Comforted', PetMood.low, Icons.volunteer_activism);

  const PetEmotion(this.displayName, this.mood, this.icon);

  final String displayName;
  final PetMood mood;
  final IconData icon;

  /// The default resting expression for a [PetMood] (used when no specific
  /// emotion/reaction is active).
  static PetEmotion restingFor(PetMood mood) => switch (mood) {
    PetMood.joyful => PetEmotion.happy,
    PetMood.content => PetEmotion.content,
    PetMood.wistful => PetEmotion.curious,
    PetMood.low => PetEmotion.comforted,
  };
}

/// Gentle, tangible care cues layered onto the pet's look (GE-2, "the pet
/// visibly carries its state"). Derived from the care meters by the game
/// layer; renderers may express or ignore them. Always warm — a mussed coat,
/// heavy eyelids, a peckish glance — never distress, never alarm (Charter §4:
/// tangible state without guilt).
class PetCareCues {
  const PetCareCues({
    this.mussed = false,
    this.drowsy = false,
    this.peckish = false,
  });

  /// Hygiene is low → soft smudges and a stray hair or two.
  final bool mussed;

  /// Energy is low → heavier eyelids, slower breathing.
  final bool drowsy;

  /// Hunger is low → a wistful glance toward the tummy.
  final bool peckish;

  bool get any => mussed || drowsy || peckish;

  static const PetCareCues none = PetCareCues();

  @override
  bool operator ==(Object other) =>
      other is PetCareCues &&
      other.mussed == mussed &&
      other.drowsy == drowsy &&
      other.peckish == peckish;

  @override
  int get hashCode => Object.hash(mussed, drowsy, peckish);
}

abstract interface class PetRenderer {
  /// Builds the pet visual for the given mood + life stage. [emotion] is the
  /// current expression (a reaction or ambient idle); when null the renderer
  /// uses the resting expression for [mood]. [cues] are optional tangible
  /// care cues (GE-2) — renderers may express or ignore them; they are NOT
  /// part of the Rive `PetStateMachine` contract (mood/lifeStage/emotion
  /// stays exactly 3 inputs — cue layers are composited renderer-side).
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
    PetEmotion? emotion,
    PetCareCues? cues,
  });

  /// Identifies the concrete backend (e.g. "placeholder", "live2d", "rive").
  String get backendId;
}

/// Flutter-drawn placeholder. Expressive (shows the current emotion + a soft
/// reaction "pop" when it changes) yet **deterministic and test-safe** — it uses
/// implicit/one-shot animations only, never an infinite repeating loop, so
/// `pumpAndSettle` always settles. Replaced by the commissioned Rive rig.
class PlaceholderPetRenderer implements PetRenderer {
  const PlaceholderPetRenderer();

  @override
  String get backendId => 'placeholder';

  @override
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
    PetEmotion? emotion,
    PetCareCues? cues, // the deterministic stand-in stays cue-less
  }) {
    return _ExpressivePet(
      mood: mood,
      lifeStage: lifeStage,
      emotion: emotion ?? PetEmotion.restingFor(mood),
    );
  }
}

/// Canonical life-stage → render scale (GAME_TECHNICAL_SYSTEMS.md §3.1).
double petLifeStageScale(String lifeStage) => switch (lifeStage) {
  'youngOne' => 0.85,
  'grown' => 1.0,
  _ => 0.7, // pupKit / infancy
};

class _ExpressivePet extends StatelessWidget {
  const _ExpressivePet({
    required this.mood,
    required this.lifeStage,
    required this.emotion,
  });

  final PetMood mood;
  final String lifeStage;
  final PetEmotion emotion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = petLifeStageScale(lifeStage);
    final box = 120 * scale;
    final tint = switch (mood) {
      PetMood.joyful => scheme.primaryContainer,
      PetMood.content => scheme.secondaryContainer,
      PetMood.wistful => scheme.tertiaryContainer,
      PetMood.low => scheme.surfaceContainerHighest,
    };

    return Semantics(
      label: 'pet ($lifeStage, ${mood.name}, ${emotion.displayName})',
      child: SizedBox(
        key: const Key('pet-renderer'),
        width: box,
        height: box,
        // A one-shot "pop" each time the expression changes (keyed by emotion):
        // TweenAnimationBuilder runs once to completion → pumpAndSettle settles.
        child: TweenAnimationBuilder<double>(
          key: ValueKey(emotion),
          tween: Tween(begin: 1.18, end: 1.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          builder: (context, t, child) =>
              Transform.scale(scale: t, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(
              emotion.icon,
              size: box * 0.5,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
