/// Care meters → tangible pet cues (GE-2). The mapping lives in the game
/// layer so the render seam stays engine-pure; renderers just express the
/// cues. Thresholds sit BELOW the wellness "needs care" line on purpose:
/// the pet's look changes only when a need is genuinely pronounced —
/// tangible cause→effect, never a nag (Charter §4).
library;

import '../../render/pet_renderer.dart';
import '../model/care_meters.dart';

/// Below this hygiene the coat looks gently mussed (a bath clears it).
const double kMussedBelowHygiene = 45;

/// Below this energy the eyelids grow heavy and breathing slows.
const double kDrowsyBelowEnergy = 35;

/// Below this hunger the pet glances wistfully at its tummy.
const double kPeckishBelowHunger = 40;

PetCareCues cuesFor(CareMeters meters) => PetCareCues(
  mussed: meters.hygiene < kMussedBelowHygiene,
  drowsy: meters.energy < kDrowsyBelowEnergy,
  peckish: meters.hunger < kPeckishBelowHunger,
);
