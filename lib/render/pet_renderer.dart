/// Pet rendering abstraction (Live2D integration seam).
///
/// Engine + style are locked: Flutter + Live2D Cubism (ADR-002). However, the
/// Live2D Cubism runtime has no first-party Flutter binding — integration is a
/// real technical risk evaluated at P0 (founder decision authorizes a Rive
/// fallback if Live2D-on-Flutter is blocked; see docs/LIVE2D_RIG_DESIGN_BRIEF.md
/// §"Integration spike"). This interface decouples the game from the concrete
/// rig backend so the actual rig (Live2D or Rive) drops in during P1/P2 without
/// touching gameplay code.
///
/// The placeholder below is NOT the rig and NOT gameplay — it is a cheap
/// stand-in that proves the rendering seam compiles, themes, and paints.
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
