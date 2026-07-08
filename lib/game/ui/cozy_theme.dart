/// The warm, cozy global theme (UI integration sprint). Replaces the sterile
/// default: warm cream surfaces (never stark white), a soft peach primary that
/// harmonises with the cream/gold cozy backgrounds, large corner radii, and
/// transparent app bars so the scene shows through. Pairs with `widgets/cozy.dart`.
library;

import 'package:flutter/material.dart';

import 'kp_tokens.dart';

// The palette now lives in the PUBLIC token set (KP-027) — one source of
// truth for the theme AND every call site; dark mode (KP-042) re-points it.
const _peach = KpColors.peach;
const _cream = KpColors.cream;
const _scaffold = KpColors.scaffold;
const _ink = KpColors.ink;

ThemeData cozyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _peach,
    brightness: Brightness.light,
  ).copyWith(surface: _cream, onSurface: _ink);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  return base.copyWith(
    scaffoldBackgroundColor: _scaffold,
    textTheme: base.textTheme.apply(bodyColor: _ink, displayColor: _ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _ink,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      color: KpColors.card,
      shadowColor: _peach.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
