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
/// `.riv` artboard (with a `PetStateMachine` exposing the mood + life-stage +
/// emotion inputs documented below) arrives at P2; until then [assetPath] is
/// null and the renderer paints a clearly-labelled, expressive, native-free
/// stand-in. When the asset is supplied, it loads the artboard, scales it per
/// life stage (§3.1: 0.7 / 0.85 / 1.0), and drives the named state-machine
/// inputs from the pet's [PetMood] + [PetEmotion]. Keeping the loaded-rig path
/// behind [assetPath] means widget/golden tests never need the native runtime.
library;

import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

import 'pet_renderer.dart';

/// The Rive state machine the rig is authored against (the P2 contract). The
/// rig must expose three NUMBER inputs:
///   - `mood`      0..3  = [PetMood.index] (joyful/content/wistful/low)
///   - `lifeStage` 0..2  = pupKit/youngOne/grown
///   - `emotion`   0..11 = [PetEmotion.index] (the 12 emotion motions)
/// plus an idle loop per mood and a one-shot reaction state per emotion that
/// returns to idle. Documented here so the rig commission and the client agree
/// on the interface before the asset exists.
const String kRiveStateMachine = 'PetStateMachine';
const String kRiveMoodInput = 'mood';
const String kRiveLifeStageInput = 'lifeStage';
const String kRiveEmotionInput = 'emotion';

/// Canonical life-stage → render scale (GAME_TECHNICAL_SYSTEMS.md §3.1).
/// Delegates to the shared [petLifeStageScale].
double lifeStageScale(String lifeStage) => petLifeStageScale(lifeStage);

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
    PetEmotion? emotion,
  }) {
    final expression = emotion ?? PetEmotion.restingFor(mood);
    final scale = lifeStageScale(lifeStage);
    final box = size * scale;
    final asset = assetPath;

    final Widget visual = asset == null
        ? _RiveSeamStandin(
            mood: mood,
            lifeStage: lifeStage,
            emotion: expression,
          )
        : rive.RiveAnimation.asset(
            asset,
            stateMachines: const [kRiveStateMachine],
            onInit: (artboard) =>
                _bindInputs(artboard, mood, lifeStage, expression),
            fit: BoxFit.contain,
          );

    return Semantics(
      label: 'pet ($lifeStage, ${mood.name}, ${expression.displayName})',
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
  void _bindInputs(
    rive.Artboard artboard,
    PetMood mood,
    String lifeStage,
    PetEmotion emotion,
  ) {
    final controller = rive.StateMachineController.fromArtboard(
      artboard,
      kRiveStateMachine,
    );
    if (controller == null) return;
    artboard.addController(controller);
    controller.findInput<double>(kRiveMoodInput)?.value = mood.index.toDouble();
    controller.findInput<double>(kRiveEmotionInput)?.value = emotion.index
        .toDouble();
    final stageIndex = switch (lifeStage) {
      'youngOne' => 1.0,
      'grown' => 2.0,
      _ => 0.0,
    };
    controller.findInput<double>(kRiveLifeStageInput)?.value = stageIndex;
  }
}

/// Deterministic, native-free stand-in shown while [RivePetRenderer.assetPath]
/// is null. Shows the current emotion + advertises the Rive backend so QA can
/// tell which seam is active. (One-shot pop on emotion change → test-safe.)
class _RiveSeamStandin extends StatelessWidget {
  const _RiveSeamStandin({
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
    return TweenAnimationBuilder<double>(
      key: ValueKey(emotion),
      tween: Tween(begin: 1.15, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emotion.icon, size: 44, color: scheme.onTertiaryContainer),
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
      ),
    );
  }
}
