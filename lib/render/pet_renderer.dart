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
/// The placeholder below is NOT the rig and NOT gameplay — it is a cheap,
/// deterministic stand-in that proves the rendering seam compiles and paints.
library;

import 'package:flutter/material.dart';

/// A pet "mood" the renderer can express. Mirrors the 4 derived mood states
/// (GAMEPLAY_AND_PROGRESSION_BIBLE.md §5.3) so the seam matches the design.
enum PetMood { joyful, content, wistful, low }

abstract interface class PetRenderer {
  /// Builds the pet visual for the given mood + life stage.
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
  });

  /// Identifies the concrete backend (e.g. "placeholder", "live2d", "rive").
  String get backendId;
}

/// Flutter-drawn placeholder. Cheap, deterministic (good for golden tests),
/// clearly not the final rig. Replaced by the commissioned Live2D/Rive rig.
class PlaceholderPetRenderer implements PetRenderer {
  const PlaceholderPetRenderer();

  @override
  String get backendId => 'placeholder';

  @override
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (mood) {
      PetMood.joyful => Icons.sentiment_very_satisfied,
      PetMood.content => Icons.pets,
      PetMood.wistful => Icons.sentiment_satisfied,
      PetMood.low => Icons.sentiment_dissatisfied,
    };
    return Semantics(
      label: 'pet placeholder ($lifeStage, ${mood.name})',
      child: Container(
        key: const Key('pet-renderer'),
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 64, color: scheme.onSecondaryContainer),
      ),
    );
  }
}
