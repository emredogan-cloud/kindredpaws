/// Maps the simulation [Mood] to the render layer's [PetMood] and to cozy,
/// never-accusatory copy. Kept in the UI layer so the domain stays Flutter-free.
library;

import '../../render/pet_renderer.dart';
import '../model/mood.dart';

PetMood petMoodFor(Mood mood) => switch (mood) {
  Mood.joyful => PetMood.joyful,
  Mood.content => PetMood.content,
  Mood.wistful => PetMood.wistful,
  Mood.low => PetMood.low,
};

/// Warm, invitational mood line (§5.2: invitational, never accusatory).
String moodLine(String petName, Mood mood) => switch (mood) {
  Mood.joyful => '$petName is over the moon!',
  Mood.content => '$petName is happy and content',
  Mood.wistful => '$petName is looking your way',
  Mood.low => '$petName would love a little comfort',
};
