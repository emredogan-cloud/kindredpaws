/// Maps the simulation [Mood] to the render layer's [PetMood]/[PetEmotion] and
/// to cozy, never-accusatory copy. Kept in the UI layer so the domain (model +
/// sim) and the render layer both stay free of each other.
library;

import '../../render/pet_renderer.dart';
import '../controller/game_controller.dart';
import '../model/mood.dart';
import '../sim/interaction.dart';

PetMood petMoodFor(Mood mood) => switch (mood) {
  Mood.joyful => PetMood.joyful,
  Mood.content => PetMood.content,
  Mood.wistful => PetMood.wistful,
  Mood.low => PetMood.low,
};

/// The reaction expression a care verb produces (§5.1 emotion motions).
PetEmotion petEmotionForReaction(
  CareInteraction interaction, {
  bool comfort = false,
}) => switch (interaction) {
  CareInteraction.feed => comfort ? PetEmotion.comforted : PetEmotion.happy,
  CareInteraction.clean => PetEmotion.proud,
  CareInteraction.play => PetEmotion.playful,
};

/// The pet's current expression: a reaction to the last care verb, else an
/// ambient idle expression, else the resting expression for the current mood.
PetEmotion currentPetEmotion(GameController c) {
  final last = c.lastInteraction;
  if (last != null) {
    return petEmotionForReaction(
      last,
      comfort: c.lastOutcome?.comfortBeat ?? false,
    );
  }
  return c.ambientEmotion ?? PetEmotion.restingFor(petMoodFor(c.mood));
}

/// Warm, invitational mood line (§5.2: invitational, never accusatory).
String moodLine(String petName, Mood mood) => switch (mood) {
  Mood.joyful => '$petName is over the moon!',
  Mood.content => '$petName is happy and content',
  Mood.wistful => '$petName is looking your way',
  Mood.low => '$petName would love a little comfort',
};
