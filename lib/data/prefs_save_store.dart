/// Persistent [LocalSaveStore] backed by `shared_preferences` — the local-first
/// authoritative-feeling snapshot (GAME_TECHNICAL_SYSTEMS.md §3.4, ADR-010).
/// Keeps the save across app restarts so the player's pet is never lost on
/// reopen (Risk R4). The cloud mirror rides on top via [SaveRepository].
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'save_repository.dart';

class PrefsSaveStore implements LocalSaveStore {
  // `prefsName` (not `key`) on purpose: it's the SharedPreferences entry name,
  // not a credential — and a field literally named `key` trips secret scanners.
  PrefsSaveStore({this.prefsName = 'kindredpaws.save.v4'});

  final String prefsName;

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsName);
  }

  @override
  Future<void> write(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsName, json);
  }

  @override
  Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsName);
    // Right-to-be-forgotten wipes the quarantine slot too — a corrupt-save
    // backup is still the player's personal data (§8.3).
    await prefs.remove('$prefsName.corrupt_backup');
  }

  /// Quarantine slot (KP-010) — kept under a sibling key so a fresh-pet write
  /// to [prefsName] can never destroy an unreadable-but-recoverable save.
  @override
  Future<void> writeBackup(String blob) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$prefsName.corrupt_backup', blob);
  }

  @override
  Future<String?> readBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$prefsName.corrupt_backup');
  }
}
