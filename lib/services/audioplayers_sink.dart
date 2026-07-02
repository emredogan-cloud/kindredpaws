/// Production [AudioSink] over the `audioplayers` plugin. A tiny round-robin
/// player pool so quick successive cues (feed + sparkle) overlap instead of
/// cutting each other off; players are created lazily and configured for
/// short low-latency UI sounds. Kept out of bootstrap() so dev/CI never touch
/// platform audio channels (NoopAudioSink stands in there).
library;

import 'package:audioplayers/audioplayers.dart';

import 'feel_service.dart';

class AudioplayersSink implements AudioSink {
  AudioplayersSink({int poolSize = 3})
    : _players = List.generate(poolSize, (_) => AudioPlayer());

  final List<AudioPlayer> _players;
  int _next = 0;

  @override
  Future<void> play(SfxCue cue) async {
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    try {
      await player.stop();
      await player.play(
        AssetSource(cue.assetPath),
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      // Sound is garnish — a platform hiccup must never surface to play.
    }
  }

  Future<void> dispose() async {
    for (final p in _players) {
      await p.dispose();
    }
  }
}
