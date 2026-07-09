/// Runs the ordered chain of [Migration]s to bring any old [SaveEnvelope] up to
/// a target schema version. Throws on a missing step (a gap) rather than
/// silently producing a corrupt save — protecting Risk R4 ("no orphaned pet").
library;

import 'migration.dart';
import 'save_envelope.dart';

class MigrationRunner {
  MigrationRunner(List<Migration> migrations)
    : _byFrom = {for (final m in migrations) m.fromVersion: m} {
    // A duplicate fromVersion would silently shadow a step in the map above —
    // and a shadowed or re-applied step is a latent data-loss path (KP-022).
    if (_byFrom.length != migrations.length) {
      throw ArgumentError(
        'Duplicate migration fromVersion registration '
        '(${migrations.map((m) => m.fromVersion).toList()})',
      );
    }
    for (final m in migrations) {
      if (m.toVersion != m.fromVersion + 1) {
        throw ArgumentError(
          'Migration ${m.fromVersion}->${m.toVersion} must increment by exactly 1',
        );
      }
    }
  }

  final Map<int, Migration> _byFrom;

  /// Upgrade [envelope] forward to [targetVersion]. Returns it unchanged if it
  /// is already at the target. Throws if it is newer than the target (a
  /// downgrade — never allowed) or if a step is missing.
  SaveEnvelope upgrade(SaveEnvelope envelope, int targetVersion) {
    if (envelope.schemaVersion > targetVersion) {
      throw StateError(
        'Save schemaVersion ${envelope.schemaVersion} is newer than the app '
        'target $targetVersion — refusing to downgrade (would orphan the pet).',
      );
    }
    var data = envelope.data;
    var version = envelope.schemaVersion;
    while (version < targetVersion) {
      final step = _byFrom[version];
      if (step == null) {
        throw StateError('No migration from schema version $version');
      }
      data = step.migrate(data);
      version = step.toVersion;
    }
    return SaveEnvelope(schemaVersion: version, data: data);
  }
}
