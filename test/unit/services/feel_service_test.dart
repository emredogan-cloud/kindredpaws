/// The Feel layer: player toggles gate every channel, cues route to the sink,
/// and the synthesized cue set maps 1:1 to bundled original assets.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kindredpaws/services/feel_service.dart';
import 'package:kindredpaws/services/prefs_service.dart';

class _CountingSink implements AudioSink {
  final List<SfxCue> played = [];
  @override
  Future<void> play(SfxCue cue) async => played.add(cue);
}

void main() {
  group('FeelService', () {
    test('plays and vibrates when enabled; both channels counted', () async {
      final sink = _CountingSink();
      final vibrations = <HapticKind>[];
      final feel = FeelService(
        prefs: InMemoryPrefsService(),
        audio: sink,
        vibrate: (k) async => vibrations.add(k),
      );
      await feel.cue(SfxCue.feedChime, HapticKind.success);
      expect(sink.played, [SfxCue.feedChime]);
      expect(vibrations, [HapticKind.success]);
      expect(feel.playedCount, 1);
      expect(feel.hapticCount, 1);
    });

    test(
      'sound toggle silences audio but leaves haptics (and vice versa)',
      () async {
        final sink = _CountingSink();
        final prefs = InMemoryPrefsService();
        final vibrations = <HapticKind>[];
        final feel = FeelService(
          prefs: prefs,
          audio: sink,
          vibrate: (k) async => vibrations.add(k),
        );

        await prefs.setSoundEnabled(false);
        await feel.cue(SfxCue.boing);
        expect(sink.played, isEmpty);
        expect(vibrations, hasLength(1));

        await prefs.setSoundEnabled(true);
        await prefs.setHapticsEnabled(false);
        await feel.cue(SfxCue.boing);
        expect(sink.played, [SfxCue.boing]);
        expect(vibrations, hasLength(1)); // unchanged
      },
    );

    test('every cue maps to a bundled original wav path', () {
      for (final cue in SfxCue.values) {
        expect(cue.assetPath, 'audio/${cue.file}.wav');
        expect(cue.file, isNotEmpty);
      }
    });
  });

  group('prefs services', () {
    test('in-memory round-trips toggles (defaults on)', () async {
      final prefs = InMemoryPrefsService();
      expect(prefs.soundEnabled, isTrue);
      expect(prefs.hapticsEnabled, isTrue);
      await prefs.setSoundEnabled(false);
      await prefs.setHapticsEnabled(false);
      expect(prefs.soundEnabled, isFalse);
      expect(prefs.hapticsEnabled, isFalse);
    });
  });
}
