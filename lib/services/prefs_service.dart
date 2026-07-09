/// Tiny player-preferences seam (sound/haptics… on/off). In-memory default
/// keeps dev/CI deterministic; the SharedPreferences-backed implementation is
/// a production swap in `main()` (same idiom as the home-widget writer).
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PrefsService {
  bool get soundEnabled;
  bool get hapticsEnabled;
  bool get notificationsEnabled;

  /// Southern-hemisphere seasons (GE-5): flips the nature-season calendar
  /// for friends below the equator. Presentation-only — never gameplay.
  bool get southernHemisphere;

  /// First-visit verb hints already shown (GE-6): a room's primary hint
  /// pulses exactly once per install. Device-local, never in the pet save.
  Set<String> get seenHints;

  /// A 24-bucket histogram of the local hours the app has been opened
  /// (GE-6 rhythm-aware notifications). On-device only — never leaves the
  /// phone, never a pet-save field.
  List<int> get openHourHistogram;

  Future<void> setSoundEnabled(bool value);
  Future<void> setHapticsEnabled(bool value);
  Future<void> setNotificationsEnabled(bool value);
  Future<void> setSouthernHemisphere(bool value);
  Future<void> markHintSeen(String id);
  Future<void> recordOpenHour(int hour);
}

/// Deterministic in-memory prefs (dev/CI/tests). Defaults: everything on,
/// northern seasons.
class InMemoryPrefsService implements PrefsService {
  @override
  bool soundEnabled = true;
  @override
  bool hapticsEnabled = true;
  @override
  bool notificationsEnabled = true;
  @override
  bool southernHemisphere = false;
  @override
  final Set<String> seenHints = {};
  @override
  final List<int> openHourHistogram = List<int>.filled(24, 0);

  @override
  Future<void> setSoundEnabled(bool value) async => soundEnabled = value;
  @override
  Future<void> setHapticsEnabled(bool value) async => hapticsEnabled = value;
  @override
  Future<void> setNotificationsEnabled(bool value) async =>
      notificationsEnabled = value;
  @override
  Future<void> setSouthernHemisphere(bool value) async =>
      southernHemisphere = value;
  @override
  Future<void> markHintSeen(String id) async => seenHints.add(id);
  @override
  Future<void> recordOpenHour(int hour) async {
    if (hour >= 0 && hour < 24) openHourHistogram[hour]++;
  }
}

/// SharedPreferences-backed prefs (production). Reads are memoized so the UI
/// can query synchronously; [initialize] hydrates once at boot.
class SharedPrefsService implements PrefsService {
  static const _kSound = 'prefs.sound_enabled';
  static const _kHaptics = 'prefs.haptics_enabled';
  static const _kNotifications = 'prefs.notifications_enabled';
  static const _kSouthern = 'prefs.southern_hemisphere';
  static const _kSeenHints = 'prefs.seen_hints';
  static const _kOpenHours = 'prefs.open_hour_histogram';

  SharedPreferences? _prefs;
  bool _sound = true;
  bool _haptics = true;
  bool _notifications = true;
  bool _southern = false;
  final Set<String> _seenHints = {};
  final List<int> _openHours = List<int>.filled(24, 0);

  Future<void> initialize() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    _sound = p.getBool(_kSound) ?? true;
    _haptics = p.getBool(_kHaptics) ?? true;
    _notifications = p.getBool(_kNotifications) ?? true;
    _southern = p.getBool(_kSouthern) ?? false;
    _seenHints
      ..clear()
      ..addAll(p.getStringList(_kSeenHints) ?? const []);
    final hours = p.getStringList(_kOpenHours);
    if (hours != null) {
      for (var i = 0; i < 24 && i < hours.length; i++) {
        _openHours[i] = int.tryParse(hours[i]) ?? 0;
      }
    }
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

  @override
  bool get notificationsEnabled => _notifications;

  @override
  Future<void> setNotificationsEnabled(bool value) async {
    _notifications = value;
    await _prefs?.setBool(_kNotifications, value);
  }

  @override
  bool get southernHemisphere => _southern;

  @override
  Future<void> setSouthernHemisphere(bool value) async {
    _southern = value;
    await _prefs?.setBool(_kSouthern, value);
  }

  @override
  Set<String> get seenHints => _seenHints;

  @override
  Future<void> markHintSeen(String id) async {
    if (_seenHints.add(id)) {
      await _prefs?.setStringList(_kSeenHints, _seenHints.toList());
    }
  }

  @override
  List<int> get openHourHistogram => _openHours;

  @override
  Future<void> recordOpenHour(int hour) async {
    if (hour < 0 || hour >= 24) return;
    _openHours[hour]++;
    await _prefs?.setStringList(
      _kOpenHours,
      _openHours.map((h) => '$h').toList(),
    );
  }
}
