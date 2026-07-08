/// Local-first save repository with automated migration + cloud restore
/// (ADR-010, Risk R4). Load path: read local blob → migrate forward → decode.
/// Restore path: pull the authoritative cloud snapshot via [BackendService].
///
/// This is the persistence plumbing (a Phase-0 provisioning deliverable). It
/// does not run the simulation that mutates the state (Phase 1).
library;

import '../core/result.dart';
import '../services/backend_service.dart';
import 'kindred_save_state.dart';
import 'migration_runner.dart';
import 'save_envelope.dart';

/// A hook that resets analytics identifiers on account deletion (§11.2). Wired
/// in `createGameController` to the registered `AnalyticsService`; null in
/// persistence-only tests.
typedef IdentityResetHook = Future<void> Function();

/// Pluggable local persistence (SQLite/Hive in production; in-memory for tests).
abstract interface class LocalSaveStore {
  Future<String?> read();
  Future<void> write(String json);

  /// Erase the local save — the on-device half of right-to-be-forgotten (§8.3).
  Future<void> delete();

  /// Quarantine slot for an unreadable save blob (KP-010): preserved so no
  /// later write to the main slot can destroy a potentially recoverable pet.
  Future<void> writeBackup(String blob);
  Future<String?> readBackup();
}

class InMemoryLocalSaveStore implements LocalSaveStore {
  String? _blob;
  String? _backup;
  @override
  Future<String?> read() async => _blob;
  @override
  Future<void> write(String json) async => _blob = json;
  @override
  Future<void> delete() async {
    // Right-to-be-forgotten wipes the quarantine slot too — a corrupt-save
    // backup is still the player's personal data (§8.3).
    _blob = null;
    _backup = null;
  }

  @override
  Future<void> writeBackup(String blob) async => _backup = blob;
  @override
  Future<String?> readBackup() async => _backup;
}

/// The typed result of reading the local save — lets the load path distinguish
/// "no pet yet" from "there IS a pet we cannot read", which must never be
/// conflated (KP-010: conflating them dropped players into Rescue Day and the
/// next persist overwrote the recoverable blob).
sealed class SaveLoadOutcome {
  const SaveLoadOutcome();
}

/// A save existed and parsed (migrated forward as needed).
class SaveLoaded extends SaveLoadOutcome {
  const SaveLoaded(this.state);
  final KindredSaveState state;
}

/// No local save exists — a genuinely fresh install → Rescue Day.
class SaveAbsent extends SaveLoadOutcome {
  const SaveAbsent();
}

/// A local save exists but could not be read. The blob has been quarantined to
/// the backup slot and MUST NOT be overwritten by a fresh-pet persist.
class SaveUnreadable extends SaveLoadOutcome {
  const SaveUnreadable({
    required this.error,
    required this.rawBlob,
    this.stackTrace,
    this.isNewerSchema = false,
    this.salvagedPetId,
  });

  final Object error;
  final StackTrace? stackTrace;
  final String rawBlob;

  /// True when the blob was written by a NEWER app (a downgrade) — the save is
  /// healthy; the fix is "update the app", never data loss.
  final bool isNewerSchema;

  /// Best-effort pet id pulled from the broken blob so a cloud restore can
  /// still be keyed even when full deserialization failed.
  final String? salvagedPetId;
}

class SaveRepository {
  SaveRepository({
    required LocalSaveStore local,
    BackendService? backend,
    MigrationRunner? runner,
    IdentityResetHook? onIdentityReset,
  }) : _local = local,
       _backend = backend,
       _runner = runner ?? MigrationRunner(KindredSaveState.migrations),
       _onIdentityReset = onIdentityReset;

  final LocalSaveStore _local;
  final BackendService? _backend;
  final MigrationRunner _runner;
  final IdentityResetHook? _onIdentityReset;

  static const String _collection = 'saves';

  /// Load the local save, upgrading any older schema forward. Returns null if
  /// no local save exists yet.
  ///
  /// Prefer [loadOutcome] in app code: this legacy shape folds "unreadable"
  /// into [Err], which callers historically mistook for "no pet" (KP-010).
  Future<Result<KindredSaveState?>> load() async {
    final outcome = await loadOutcome();
    return switch (outcome) {
      SaveLoaded(:final state) => Ok(state),
      SaveAbsent() => const Ok(null),
      SaveUnreadable(:final error, :final stackTrace) => Err(error, stackTrace),
    };
  }

  /// Load the local save with a typed outcome (KP-010).
  ///
  /// Guarantees: an unreadable blob is quarantined to the backup slot before
  /// returning, a newer-schema blob is reported as [SaveUnreadable] with
  /// `isNewerSchema` (update the app — the save is fine), and the pet id is
  /// salvaged from the broken blob whenever possible so [restoreFromCloud]
  /// can still be attempted.
  Future<SaveLoadOutcome> loadOutcome() async {
    final String? blob;
    try {
      blob = await _local.read();
    } catch (e, st) {
      // The store itself failed (platform I/O) — nothing to quarantine.
      return SaveUnreadable(error: e, stackTrace: st, rawBlob: '');
    }
    if (blob == null) return const SaveAbsent();

    SaveEnvelope? envelope;
    try {
      envelope = SaveEnvelope.fromJsonString(blob);
      if (envelope.schemaVersion > KindredSaveState.currentSchemaVersion) {
        await _quarantine(blob);
        return SaveUnreadable(
          error: StateError(
            'save schema v${envelope.schemaVersion} is newer than app '
            'v${KindredSaveState.currentSchemaVersion} (downgrade)',
          ),
          rawBlob: blob,
          isNewerSchema: true,
          salvagedPetId: _salvagePetId(envelope, blob),
        );
      }
      final upgraded = _runner.upgrade(
        envelope,
        KindredSaveState.currentSchemaVersion,
      );
      return SaveLoaded(KindredSaveState.fromEnvelope(upgraded));
    } catch (e, st) {
      await _quarantine(blob);
      return SaveUnreadable(
        error: e,
        stackTrace: st,
        rawBlob: blob,
        salvagedPetId: _salvagePetId(envelope, blob),
      );
    }
  }

  /// Preserve an unreadable blob in the backup slot (latest corruption wins —
  /// an older quarantined blob was already abandoned by an explicit fresh
  /// start). Best-effort: quarantine failure never masks the load failure.
  Future<void> _quarantine(String blob) async {
    try {
      await _local.writeBackup(blob);
    } catch (_) {
      // Nothing safe to do — the main slot still holds the original blob and
      // the recovery flow refuses to overwrite it.
    }
  }

  /// The quarantined blob from the last unreadable load, if any.
  Future<String?> quarantinedBlob() async {
    try {
      return await _local.readBackup();
    } catch (_) {
      return null;
    }
  }

  /// Pull the pet id out of a blob that failed full deserialization: from the
  /// parsed envelope when available, else a lenient text scan (truncation
  /// usually eats the tail; petId is written near the head).
  String? _salvagePetId(SaveEnvelope? envelope, String blob) {
    final fromData = envelope?.data['petId'];
    if (fromData is String && fromData.isNotEmpty) return fromData;
    final m = RegExp(r'"petId"\s*:\s*"([^"]+)"').firstMatch(blob);
    return m?.group(1);
  }

  /// Persist locally, then best-effort mirror to the authoritative backend.
  Future<Result<void>> save(KindredSaveState state) async {
    try {
      final env = state.toEnvelope();
      await _local.write(env.toJsonString());
      await _backend?.writeDocument(
        _collection,
        state.pet.petId,
        env.toJsonMap(),
      );
      return const Ok(null);
    } catch (e, st) {
      return Err(e, st);
    }
  }

  /// Restore from the authoritative cloud snapshot (e.g. on a new device),
  /// upgrading the schema forward. Returns null if no cloud save / no backend.
  Future<Result<KindredSaveState?>> restoreFromCloud(String petId) async {
    try {
      final backend = _backend;
      if (backend == null) return const Ok(null);
      final doc = await backend.readDocument(_collection, petId);
      if (doc == null) return const Ok(null);
      final upgraded = _runner.upgrade(
        SaveEnvelope.fromJsonMap(doc),
        KindredSaveState.currentSchemaVersion,
      );
      final state = KindredSaveState.fromEnvelope(upgraded);
      await _local.write(upgraded.toJsonString());
      return Ok(state);
    } catch (e, st) {
      return Err(e, st);
    }
  }

  /// Right-to-be-forgotten (GDPR / COPPA, §8.3): erase the player's data.
  ///
  /// On-device-first so the visible data is gone even if the network fails:
  /// 1. erase the local save,
  /// 2. reset analytics identifiers (so future telemetry can't link to the
  ///    deleted account, §11.2),
  /// 3. best-effort delete the authoritative cloud save.
  ///
  /// Deleting the cloud save is the **trigger** for the server-side cascade that
  /// purges the memory-fact store and **anonymizes** ledger entries (retain the
  /// financial fact, drop the personal link) so donation-audit integrity
  /// survives deletion — that cascade is enforced server-side (a Cloud
  /// Function), never client-trusted. [petId] is the cloud save key; omit it for
  /// a guest with no cloud save (steps 1–2 still run).
  Future<Result<void>> deleteAccount({String? petId}) async {
    try {
      await _local.delete();
      // Isolate the identity reset: a non-critical reset failure must NOT skip
      // the cloud delete, which is the trigger for the server-side purge +
      // ledger-anonymization cascade — the right-to-be-forgotten guarantee
      // (§8.3; P3-8 audit).
      try {
        await _onIdentityReset?.call();
      } catch (_) {
        // best-effort: a failed analytics-id reset never blocks the cascade.
      }
      if (petId != null) {
        await _backend?.deleteDocument(_collection, petId);
      }
      return const Ok(null);
    } catch (e, st) {
      return Err(e, st);
    }
  }
}
