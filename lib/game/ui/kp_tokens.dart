/// The PUBLIC design tokens (KP-027). The palette used to live as private
/// constants inside `cozy_theme.dart`, so every screen re-hardcoded hex
/// (13× ink, 9× card, 8× cream …) and ~38 ad-hoc font sizes drifted beside
/// `theme.textTheme`. One named token per ROLE kills the drift and gives
/// dark mode (KP-042) a single place to re-point chrome surfaces.
///
/// Values are byte-identical to the previously scattered literals — this
/// refactor changes no pixel (goldens pin that).
library;

import 'package:flutter/material.dart';

/// The cozy palette, named by role (not hue). UI chrome only — the pet's
/// coat/art colors belong to the renderer, and per-scene painterly accents
/// stay with their scenes.
abstract final class KpColors {
  /// Warm dark text — never pure black.
  static const Color ink = Color(0xFF4A3F38);

  /// Secondary text / section labels.
  static const Color taupe = Color(0xFF7A6A58);

  /// Raised card surface (slightly lighter than [cream]).
  static const Color card = Color(0xFFFFFBF5);

  /// The warm base surface.
  static const Color cream = Color(0xFFFFF6EC);

  /// Scaffold background — warm, never white.
  static const Color scaffold = Color(0xFFFCEFE0);

  /// Primary accent (buttons, highlights).
  static const Color peach = Color(0xFFE9A178);

  /// Translucent cream veil (chips/scrims over scenes).
  static const Color creamVeil = Color(0xE6FFF6EC);

  /// Celebration gold (sparkle/confetti moments).
  static const Color sunGold = Color(0xFFFFE9A8);
}

/// Named font sizes for the copy that deliberately sits OUTSIDE
/// `theme.textTheme` (chips, dock labels, emoji art). Same numeric values
/// as the previously ad-hoc literals.
abstract final class KpText {
  /// Dock labels — the legibility floor (KP-028).
  static const double caption = 11.5;

  /// Small chip/badge copy.
  static const double small = 12.5;

  /// Section labels.
  static const double label = 13;

  /// Emphasised chip copy.
  static const double chip = 16;

  /// Prominent inline copy.
  static const double prominent = 18;

  /// Decorative emoji, small (list leaders, chips).
  static const double emojiSmall = 30;

  /// Decorative emoji, large (empty states).
  static const double emojiLarge = 48;

  /// Decorative emoji, hero (recovery/celebration).
  static const double emojiHero = 56;
}
