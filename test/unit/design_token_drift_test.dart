import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// KP-027 — the chrome palette lives in ONE place. The audit found 96
/// re-hardcoded hex sites (13× ink, 9× card, 8× cream …) because the theme's
/// palette was private; drift was inevitable and dark mode (KP-042) was
/// blocked. This guard fails the build if a chrome-palette literal reappears
/// outside the token/theme layer. (Scene-art accents and the pet renderer's
/// character colors are deliberately exempt — they are art, not chrome.)
void main() {
  const chromeHex = [
    '0xFF4A3F38', // KpColors.ink
    '0xFF7A6A58', // KpColors.taupe
    '0xFFFFFBF5', // KpColors.card
    '0xFFFFF6EC', // KpColors.cream
    '0xFFFCEFE0', // KpColors.scaffold
    '0xFFE9A178', // KpColors.peach
    '0xE6FFF6EC', // KpColors.creamVeil
    '0xFFFFE9A8', // KpColors.sunGold
  ];
  const tokenLayer = [
    'lib/game/ui/kp_tokens.dart',
    'lib/game/ui/cozy_theme.dart',
  ];
  // Character/scene art may share a hue with the chrome by coincidence —
  // exempt by design (the renderer's palette is the character's, KP-030).
  const artExempt = ['lib/render/vector_pet_renderer.dart'];

  test('no chrome-palette hex outside the token layer (KP-027)', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final f in files) {
      if (tokenLayer.contains(f.path) || artExempt.contains(f.path)) continue;
      final s = f.readAsStringSync();
      for (final hex in chromeHex) {
        if (s.contains(hex)) offenders.add('${f.path}: $hex');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Chrome palette values must come from KpColors, never re-hardcoded:'
          '\n${offenders.join('\n')}',
    );
  });

  test('the dock-label floor is referenced via the token (KP-028)', () {
    final s = File('lib/game/ui/rooms/room_host.dart').readAsStringSync();
    expect(s, contains('fontSize: KpText.caption'));
    expect(s, isNot(contains('fontSize: 9.5')));
  });
}
