/// The Feel layer — KindredPaws' sound + haptic warmth in one gated facade.
/// Every cue is an ORIGINAL synthesized asset (tool/generate_sfx.dart);
/// haptics are always soft (bible §4: gentle feedback, never startling).
/// Both channels respect the player's toggles (PrefsService) and default to
/// silent no-ops in dev/CI so tests stay byte-deterministic.
library;

import 'package:flutter/services.dart';

import 'prefs_service.dart';

/// The original cue set (`assets/audio/*.wav` — license-clean synthesis).
enum SfxCue {
  feedChime('feed_chime'),
  softPop('soft_pop'),
  splash('splash'),
  boing('boing'),
  lullabyDip('lullaby_dip'),
  morningChirp('morning_chirp'),
  tada('tada'),
  basket('basket'),
  heartGlow('heart_glow'),
  sparkle('sparkle');

  const SfxCue(this.file);
  final String file;

  /// Path relative to the asset bundle root's audio dir (audioplayers'
  /// AssetSource expects no leading `assets/`).
  String get assetPath => 'audio/$file.wav';
}

/// Soft haptic vocabulary (never a heavy thud).
enum HapticKind { tap, success, celebrate }

/// Low-level audio sink seam. [NoopAudioSink] for dev/CI; the audioplayers
/// implementation is a production swap in `main()`.
abstract interface class AudioSink {
  Future<void> play(SfxCue cue);
}

class NoopAudioSink implements AudioSink {
  @override
  Future<void> play(SfxCue cue) async {}
}

/// The app-facing facade: gate → route. UI and controllers call this and
/// never think about toggles or platforms again.
class FeelService {
  FeelService({required this.prefs, required this.audio, this.vibrate});

  final PrefsService prefs;
  final AudioSink audio;

  /// Haptic executor (injectable for tests; defaults to Flutter's soft set).
  final Future<void> Function(HapticKind kind)? vibrate;

  /// Counters exposed for tests (proves gating without platform channels).
  int playedCount = 0;
  int hapticCount = 0;

  Future<void> play(SfxCue cue) async {
    if (!prefs.soundEnabled) return;
    playedCount++;
    await audio.play(cue);
  }

  Future<void> haptic(HapticKind kind) async {
    if (!prefs.hapticsEnabled) return;
    hapticCount++;
    final run = vibrate ?? _defaultVibrate;
    try {
      await run(kind);
    } catch (_) {
      // Haptics are garnish: no binding (pure unit tests) or no vibrator
      // (some devices) must never surface into gameplay.
    }
  }

  /// One warm gesture = sound + touch together.
  Future<void> cue(SfxCue sfx, [HapticKind kind = HapticKind.tap]) async {
    await Future.wait([play(sfx), haptic(kind)]);
  }

  static Future<void> _defaultVibrate(HapticKind kind) => switch (kind) {
    HapticKind.tap => HapticFeedback.selectionClick(),
    HapticKind.success => HapticFeedback.lightImpact(),
    HapticKind.celebrate => HapticFeedback.mediumImpact(),
  };
}
