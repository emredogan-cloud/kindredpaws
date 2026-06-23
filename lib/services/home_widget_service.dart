/// Home-widget bridge (GAME_TECHNICAL_SYSTEMS.md §6.2, P2-6). The single
/// [PetStatusSnapshot] is the only thing the native widgets need (§6.1) — this
/// seam writes it to shared storage the native widget reads (Android: the
/// Flutter SharedPreferences file; iOS: the app-group UserDefaults). The native
/// widget shows a PRE-RENDERED mood image + name + soft status, never a live rig
/// render (battery/complexity — §6.2). Triggering an immediate OS refresh is a
/// thin platform call documented as a founder step (docs/HOME_WIDGET_FOUNDATION).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/model/pet_status_snapshot.dart';

abstract interface class HomeWidgetService {
  /// Publish the latest snapshot to where the native widget can read it.
  Future<void> update(PetStatusSnapshot snapshot);
}

/// The key the native widget reads. On Android, `shared_preferences` stores
/// string keys in the `FlutterSharedPreferences` XML prefixed with `flutter.`,
/// so the AppWidget reads `flutter.$kHomeWidgetKey`. Documented contract.
const String kHomeWidgetKey = 'kindredpaws.widget.snapshot';

/// Test-safe default: records the payloads instead of touching the platform.
class NoopHomeWidgetService implements HomeWidgetService {
  PetStatusSnapshot? lastPublished;
  int updates = 0;

  @override
  Future<void> update(PetStatusSnapshot snapshot) async {
    lastPublished = snapshot;
    updates++;
  }
}

/// Production bridge: writes the snapshot JSON to shared preferences the native
/// widget reads on its next refresh.
class PrefsHomeWidgetService implements HomeWidgetService {
  @override
  Future<void> update(PetStatusSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kHomeWidgetKey, jsonEncode(snapshot.toMap()));
    // NOTE: an immediate OS widget refresh (AppWidgetManager / WidgetCenter)
    // is a thin platform-channel call wired with the native widget target —
    // see docs/HOME_WIDGET_FOUNDATION.md. Without it the widget refreshes on
    // its own OS-budgeted schedule, which is fine for an ambient surface.
  }
}
