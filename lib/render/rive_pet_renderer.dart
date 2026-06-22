/// Rive-backed implementation of the [PetRenderer] seam.
///
/// **Engine decision (ADR-001, locked at P1-0):** the pet rig runtime is
/// **Rive** (Flutter-native), chosen over Live2D Cubism after the animation
/// spike — Live2D has no first-party Flutter runtime and the only community
/// binding is unproven, whereas Rive ships a first-party, multi-platform
/// runtime with the same "params, not frames" economics. Evidence + decision:
/// `docs/ANIMATION_SPIKE_REPORT.md`.
///
/// This renderer is the **integration seam**, not the rig. The commissioned
/// `.riv` artboard (with a state machine exposing the mood + life-stage inputs)
/// arrives at P2; until then [assetPath] is null and the renderer paints a
/// clearly-labelled Rive-backend stand-in. When the asset is supplied, it loads
/// the Rive artboard, scales it per life stage (§3.1: 0.7 / 0.85 / 1.0), and
/// drives the named state-machine inputs from [PetMood]. Keeping the loaded-rig
/// path behind [assetPath] means widget tests and golden tests never need the
/// native runtime or a binary asset — they exercise the deterministic fallback.
library;

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'pet_renderer.dart';

/// The Rive state-machine the rig is authored against (P2 contract). The rig
/// must expose a number input `mood` (0..3, matching [PetMood.index]) and a
/// number input `lifeStage` (0..2). Documented here so the rig commission and
/// the client agree on the interface before the asset exists.
const String kRiveStateMachine = 'PetStateMachine';
const String kRiveMoodInput = 'mood';
const String kRiveLifeStageInput = 'lifeStage';

/// Canonical life-stage → render scale (GAME_TECHNICAL_SYSTEMS.md §3.1).
double lifeStageScale(String lifeStage) {
  switch (lifeStage) {
    case 'youngOne':
      return 0.85;
    case 'grown':
      return 1.0;
    case 'pupKit':
    default:
      return 0.7; // infancy — smallest scale, big head ratio
  }
}

class RivePetRenderer implements PetRenderer {
  const RivePetRenderer({this.assetPath, this.size = 160});

  /// Path to the commissioned `.riv` rig (null until P2). When null, the
  /// renderer paints a deterministic stand-in instead of touching the native
  /// runtime, so CI/tests stay asset-free and offline.
  final String? assetPath;

  /// Edge length (logical px) of the square render area at full (`grown`) scale.
  final double size;

  @override
  String get backendId => 'rive';

  @override
  Widget build(
    BuildContext context, {
    required PetMood mood,
    required String lifeStage,
  }) {
    final scale = lifeStageScale(lifeStage);
    final box = size * scale;
    final asset = assetPath;

    final Widget visual = asset == null
        ? _RiveSeamStandin(mood: mood, lifeStage: lifeStage)
        : rive.RiveAnimation.asset(
            asset,
            stateMachines: const [kRiveStateMachine],
            onInit: (artboard) => _bindInputs(artboard, mood, lifeStage),
            fit: BoxFit.contain,
          );

    return Semantics(
      label: 'pet ($lifeStage, ${mood.name})',
      child: SizedBox(
        key: const Key('pet-renderer'),
        width: box,
        height: box,
        child: visual,
      ),
    );
  }

  /// Drives the rig's state-machine inputs from gameplay state. Pure mapping;
  /// only runs once an actual artboard is loaded (P2+).
  void _bindInputs(rive.Artboard artboard, PetMood mood, String lifeStage) {
    final controller = rive.StateMachineController.fromArtboard(
      artboard,
      kRiveStateMachine,
    );
    if (controller == null) return;
    artboard.addController(controller);
    controller.findInput<double>(kRiveMoodInput)?.value = mood.index.toDouble();
    final stageIndex = switch (lifeStage) {
      'youngOne' => 1.0,
      'grown' => 2.0,
      _ => 0.0,
    };
    controller.findInput<double>(kRiveLifeStageInput)?.value = stageIndex;
  }
}

/// Deterministic, native-free stand-in shown while [RivePetRenderer.assetPath]
/// is null. Visually distinct from [PlaceholderPetRenderer] (it advertises the
/// Rive backend) so provisioning/QA can tell which seam is active.
class _RiveSeamStandin extends StatelessWidget {
  const _RiveSeamStandin({required this.mood, required this.lifeStage});

  final PetMood mood;
  final String lifeStage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (mood) {
      PetMood.joyful => Icons.sentiment_very_satisfied,
      PetMood.content => Icons.pets,
      PetMood.wistful => Icons.sentiment_satisfied,
      PetMood.low => Icons.sentiment_dissatisfied,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onTertiaryContainer),
            const SizedBox(height: 2),
            Text(
              'rive',
              style: TextStyle(
                fontSize: 10,
                color: scheme.onTertiaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
