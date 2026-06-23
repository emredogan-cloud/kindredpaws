/// Stores the latest [PetStatusSnapshot] (GAME_TECHNICAL_SYSTEMS.md §6.1). The
/// game writes it on every meaningful change; the notification scheduler and
/// (P2-6) the home widget read it. Kept behind a seam so the production impl can
/// write to shared storage (app group / SharedPreferences) the native widget
/// reads, while tests use the in-memory impl.
library;

import '../game/model/pet_status_snapshot.dart';

abstract interface class StatusSnapshotService {
  Future<void> write(PetStatusSnapshot snapshot);
  Future<PetStatusSnapshot?> read();

  /// Last snapshot written this session (sync read for the in-app UI).
  PetStatusSnapshot? get latest;
}

/// Default in-memory impl — fully functional for dev/CI/tests.
class InMemoryStatusSnapshotService implements StatusSnapshotService {
  PetStatusSnapshot? _latest;

  @override
  PetStatusSnapshot? get latest => _latest;

  @override
  Future<void> write(PetStatusSnapshot snapshot) async => _latest = snapshot;

  @override
  Future<PetStatusSnapshot?> read() async => _latest;
}
