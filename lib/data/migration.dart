/// One forward migration step for the save schema. Each step upgrades a save
/// blob from [fromVersion] to [toVersion] (always toVersion == fromVersion + 1).
library;

abstract class Migration {
  const Migration();

  int get fromVersion;
  int get toVersion;

  /// Pure transform of the `data` map from [fromVersion] to [toVersion].
  Map<String, dynamic> migrate(Map<String, dynamic> data);
}
