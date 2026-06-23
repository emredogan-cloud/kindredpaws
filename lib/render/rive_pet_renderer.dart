/// Rive-backed implementation of the [PetRenderer] seam.
///
/// **Engine decision (ADR-001 / D-053, locked at P1-0):** the pet rig runtime is
/// **Rive** (Flutter-native), chosen over Live2D Cubism after the animation
/// spike — see `docs/ANIMATION_SPIKE_REPORT.md`.
///
/// This renderer is the **production integration**, not the rig art. The
/// commissioned `.riv` artboard (a `PetStateMachine` exposing the mood +
/// life-stage + emotion number inputs documented below) is a P2 art deliverable;
/// until it is bundled, [assetPath] is null and the renderer paints a
/// clearly-labelled, expressive, native-free stand-in.
///
/// When the asset IS supplied (P3-2 wires `KP_RIV_ASSET`), the renderer:
///   * loads the artboard **once** and caches the state-machine inputs,
///   * drives those inputs **reactively** from the pet's [PetMood] /
///     [PetEmotion] / life stage on every rebuild (the previous seam bound them
///     once at init, so the rig froze on the first expression — fixed here),
///   * **falls back gracefully** to the stand-in on any failure (asset missing,
///     state machine absent, inputs absent, parse error) and reports a
///     diagnostic so a malformed rig is caught loudly in dev, never crashes
///     play, and
///   * records the asset-load duration (a perf signal).
///
/// Keeping the loaded-rig path behind [assetPath] means widget/golden tests stay
/// asset-free and deterministic (CI runs the placeholder backend).
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

/// A diagnostic from the rig integration (load timing + failure modes). Wired
/// by `bootstrap()` to the observability stack; kept as a plain callback so the
/// render layer stays decoupled from `lib/services`. [code] is a stable,
/// PII-free identifier (e.g. `rive_load_failed`); [fields] is coarse context.
typedef RiveDiagnostic =
    void Function(String code, {Map<String, Object?> fields});

/// Canonical life-stage → render scale (GAME_TECHNICAL_SYSTEMS.md §3.1).
double lifeStageScale(String lifeStage) => petLifeStageScale(lifeStage);

/// State-machine input mappings (pure, unit-tested — the rig contract in code).
double riveMoodValue(PetMood mood) => mood.index.toDouble();
double riveEmotionValue(PetEmotion emotion) => emotion.index.toDouble();
double riveLifeStageValue(String lifeStage) => switch (lifeStage) {
  'youngOne' => 1.0,
  'grown' => 2.0,
  _ => 0.0, // pupKit / unknown → infancy
};

class RivePetRenderer implements PetRenderer {
  const RivePetRenderer({this.assetPath, this.size = 160, this.onDiagnostic});

  /// Path to the commissioned `.riv` rig (null until the asset is bundled).
  /// When null, the renderer paints the native-free stand-in.
  final String? assetPath;

  /// Edge length (logical px) of the square render area at full (`grown`) scale.
  final double size;

  /// Optional sink for load timing + failure diagnostics (see [RiveDiagnostic]).
  final RiveDiagnostic? onDiagnostic;

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
    final box = size * lifeStageScale(lifeStage);
    final asset = assetPath;

    final Widget visual = asset == null
        ? _RiveSeamStandin(
            mood: mood,
            lifeStage: lifeStage,
            emotion: expression,
          )
        : _RiveRig(
            assetPath: asset,
            mood: mood,
            lifeStage: lifeStage,
            emotion: expression,
            onDiagnostic: onDiagnostic,
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
}

/// Loads + reactively drives the commissioned rig. Falls back to the stand-in
/// (and reports a diagnostic) on any failure, so a missing/malformed asset can
/// never crash play.
class _RiveRig extends StatefulWidget {
  const _RiveRig({
    required this.assetPath,
    required this.mood,
    required this.lifeStage,
    required this.emotion,
    this.onDiagnostic,
  });

  final String assetPath;
  final PetMood mood;
  final String lifeStage;
  final PetEmotion emotion;
  final RiveDiagnostic? onDiagnostic;

  @override
  State<_RiveRig> createState() => _RiveRigState();
}

class _RiveRigState extends State<_RiveRig> {
  rive.Artboard? _artboard;
  rive.StateMachineController? _smc;
  rive.SMIInput<double>? _moodIn;
  rive.SMIInput<double>? _emotionIn;
  rive.SMIInput<double>? _lifeIn;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sw = Stopwatch()..start();
    try {
      final file = await rive.RiveFile.asset(widget.assetPath);
      final artboard = file.mainArtboard;
      final smc = rive.StateMachineController.fromArtboard(
        artboard,
        kRiveStateMachine,
      );
      if (smc == null) {
        _report('rive_state_machine_missing', {
          'asset': widget.assetPath,
          'machine': kRiveStateMachine,
        });
        return; // stay on the stand-in
      }
      artboard.addController(smc);
      final moodIn = smc.findInput<double>(kRiveMoodInput);
      final emotionIn = smc.findInput<double>(kRiveEmotionInput);
      final lifeIn = smc.findInput<double>(kRiveLifeStageInput);
      final missing = [
        if (moodIn == null) kRiveMoodInput,
        if (emotionIn == null) kRiveEmotionInput,
        if (lifeIn == null) kRiveLifeStageInput,
      ];
      if (missing.isNotEmpty) {
        smc.dispose();
        _report('rive_inputs_missing', {
          'asset': widget.assetPath,
          'missing': missing.join(','),
        });
        return;
      }
      _smc = smc;
      _moodIn = moodIn;
      _emotionIn = emotionIn;
      _lifeIn = lifeIn;
      _apply();
      sw.stop();
      widget.onDiagnostic?.call(
        'rive_loaded',
        fields: {'asset': widget.assetPath, 'ms': sw.elapsedMilliseconds},
      );
      if (mounted) setState(() => _artboard = artboard);
    } catch (e) {
      _report('rive_load_failed', {
        'asset': widget.assetPath,
        'error': e.toString(),
      });
    }
  }

  /// Pushes the current gameplay state into the (loaded) state machine.
  void _apply() {
    _moodIn?.value = riveMoodValue(widget.mood);
    _emotionIn?.value = riveEmotionValue(widget.emotion);
    _lifeIn?.value = riveLifeStageValue(widget.lifeStage);
  }

  void _report(String code, Map<String, Object?> fields) =>
      widget.onDiagnostic?.call(code, fields: fields);

  @override
  void didUpdateWidget(_RiveRig oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reactive: re-drive the inputs whenever gameplay state changes.
    if (_smc != null &&
        (oldWidget.mood != widget.mood ||
            oldWidget.emotion != widget.emotion ||
            oldWidget.lifeStage != widget.lifeStage)) {
      _apply();
    }
  }

  @override
  void dispose() {
    _smc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = _artboard;
    if (art == null) {
      // Loading or degraded → the expressive stand-in (never a blank/crash).
      return _RiveSeamStandin(
        mood: widget.mood,
        lifeStage: widget.lifeStage,
        emotion: widget.emotion,
      );
    }
    // The low-level Rive widget self-advances the artboard's controllers via its
    // TickerMode-gated render loop, so our state machine animates without a
    // separate Ticker.
    return rive.Rive(artboard: art, fit: BoxFit.contain);
  }
}

/// Deterministic, native-free stand-in shown while [RivePetRenderer.assetPath]
/// is null OR the rig fails to load. Shows the current emotion + advertises the
/// Rive backend so QA can tell which seam is active. (One-shot pop on emotion
/// change → test-safe.)
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
