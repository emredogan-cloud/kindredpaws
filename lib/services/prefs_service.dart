/// Tiny player-preferences seam (sound/haptics… on/off). In-memory default
/// keeps dev/CI deterministic; the SharedPreferences-backed implementation is
/// a production swap in `main()` (same idiom as the home-widget writer).
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PrefsService {
  bool get soundEnabled;
  bool get hapticsEnabled;
  Future<void> setSoundEnabled(bool value);
  Future<void> setHapticsEnabled(bool value);
}

/// Deterministic in-memory prefs (dev/CI/tests). Defaults: everything on.
class InMemoryPrefsService implements PrefsService {
  @override
  bool soundEnabled = true;
  @override
  bool hapticsEnabled = true;

  @override
  Future<void> setSoundEnabled(bool value) async => soundEnabled = value;
  @override
  Future<void> setHapticsEnabled(bool value) async => hapticsEnabled = value;
}

/// SharedPreferences-backed prefs (production). Reads are memoized so the UI
/// can query synchronously; [initialize] hydrates once at boot.
class SharedPrefsService implements PrefsService {
  static const _kSound = 'prefs.sound_enabled';
  static const _kHaptics = 'prefs.haptics_enabled';

  SharedPreferences? _prefs;
  bool _sound = true;
  bool _haptics = true;

  Future<void> initialize() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    _sound = p.getBool(_kSound) ?? true;
    _haptics = p.getBool(_kHaptics) ?? true;
  }

  @override
  bool get soundEnabled => _sound;
  @override
  bool get hapticsEnabled => _haptics;

  @override
  Future<void> setSoundEnabled(bool value) async {
    _sound = value;
    await _prefs?.setBool(_kSound, value);
  }

  @override
  Future<void> setHapticsEnabled(bool value) async {
    _haptics = value;
    await _prefs?.setBool(_kHaptics, value);
  }
}
