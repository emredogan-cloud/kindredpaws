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

/// Pluggable local persistence (SQLite/Hive in production; in-memory for tests).
abstract interface class LocalSaveStore {
  Future<String?> read();
  Future<void> write(String json);
}

class InMemoryLocalSaveStore implements LocalSaveStore {
  String? _blob;
  @override
  Future<String?> read() async => _blob;
  @override
  Future<void> write(String json) async => _blob = json;
}

class SaveRepository {
  SaveRepository({
    required LocalSaveStore local,
    BackendService? backend,
    MigrationRunner? runner,
  }) : _local = local,
       _backend = backend,
       _runner = runner ?? MigrationRunner(KindredSaveState.migrations);

  final LocalSaveStore _local;
  final BackendService? _backend;
  final MigrationRunner _runner;

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
}
