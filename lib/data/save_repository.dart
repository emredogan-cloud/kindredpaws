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
}

class InMemoryLocalSaveStore implements LocalSaveStore {
  String? _blob;
  @override
  Future<String?> read() async => _blob;
  @override
  Future<void> write(String json) async => _blob = json;
  @override
  Future<void> delete() async => _blob = null;
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
  Future<Result<KindredSaveState?>> load() async {
    try {
      final blob = await _local.read();
      if (blob == null) return const Ok(null);
      final upgraded = _runner.upgrade(
        SaveEnvelope.fromJsonString(blob),
        KindredSaveState.currentSchemaVersion,
      );
      return Ok(KindredSaveState.fromEnvelope(upgraded));
    } catch (e, st) {
      return Err(e, st);
    }
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
      await _onIdentityReset?.call();
      if (petId != null) {
        await _backend?.deleteDocument(_collection, petId);
      }
      return const Ok(null);
    } catch (e, st) {
      return Err(e, st);
    }
  }
}
