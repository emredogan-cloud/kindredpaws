/// Composes [Keepsake] cards from game events (P2-5). Each card is warm + never
/// guilt; the stable [Keepsake.id] dedupes so a given milestone is captured
/// once. The actual image is composed at share time (§3.2); this builds the
/// content (title + caption) deterministically.
library;

import '../game/model/bond.dart';
import '../game/model/pet_state.dart';
import 'keepsake.dart';

class KeepsakeFactory {
  const KeepsakeFactory();

  Keepsake _card(
    PetState pet,
    KeepsakeKind kind,
    String idSuffix,
    String caption,
    int nowMs,
  ) => Keepsake(
    id: '${pet.petId}:${kind.name}:$idSuffix',
    kind: kind,
    title: kind.displayName,
    caption: caption,
    petName: pet.name,
    species: pet.species.id,
    lifeStage: pet.lifeStage.id,
    createdAtMs: nowMs,
  );

  Keepsake rescueDay(PetState pet, int nowMs) => _card(
    pet,
    KeepsakeKind.rescueDay,
    'once',
    'The day ${pet.name} and I met. 🏠',
    nowMs,
  );

  Keepsake growth(PetState pet, int nowMs) => _card(
    pet,
    KeepsakeKind.beforeAfterGrowth,
    pet.lifeStage.id,
    '${pet.name} grew into a ${pet.lifeStage.displayName}! 🌱',
    nowMs,
  );

  Keepsake bondMilestone(PetState pet, BondStage stage, int nowMs) => _card(
    pet,
    KeepsakeKind.bondMilestone,
    stage.name,
    '${pet.name} and I are ${stage.displayName}s now. 💛',
    nowMs,
  );

  Keepsake streakMilestone(PetState pet, int days, int nowMs) => _card(
    pet,
    KeepsakeKind.streakMilestone,
    '$days',
    '$days cozy days together with ${pet.name}. 🔥',
    nowMs,
  );

  Keepsake memoryCallback(PetState pet, String factText, int nowMs) => _card(
    pet,
    KeepsakeKind.longMemoryCallback,
    factText.hashCode.toRadixString(16),
    '${pet.name} remembered something about you. 💭',
    nowMs,
  );

  Keepsake comfort(PetState pet, int nowMs) => _card(
    pet,
    KeepsakeKind.unpromptedComfort,
    '${nowMs ~/ Duration.millisecondsPerDay}',
    'A quiet, gentle moment with ${pet.name}. 💛',
    nowMs,
  );

  /// A décor set completed (GE-3 Cozy Corners) — once per set (stable id).
  Keepsake decorSet(PetState pet, String setId, String setTitle, int nowMs) =>
      _card(
        pet,
        KeepsakeKind.decorSet,
        setId,
        'We finished the $setTitle corner together. 🛋️',
        nowMs,
      );

  /// Five gentle days in one season (GE-5) — once per season-window (the
  /// window key holds the year, so every season is earnable again next
  /// year: anti-FOMO by id design).
  Keepsake season(
    PetState pet,
    String windowKey,
    String seasonName,
    int nowMs,
  ) => _card(
    pet,
    KeepsakeKind.season,
    windowKey,
    'A $seasonName spent together, day by gentle day. 🌤️',
    nowMs,
  );
}
