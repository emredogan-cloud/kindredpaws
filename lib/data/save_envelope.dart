/// Versioned save envelope (GAME_TECHNICAL_SYSTEMS.md §3.4, ADR-010, Risk R4).
///
/// Every persisted blob carries its `schemaVersion`; the [MigrationRunner]
/// upgrades old blobs forward so **no update can ever orphan a pet**. This is
/// the persistence container — it carries data only, never simulation behavior.
library;

import 'dart:convert';

class SaveEnvelope {
  const SaveEnvelope({required this.schemaVersion, required this.data});

  final int schemaVersion;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJsonMap() => {
    'schemaVersion': schemaVersion,
    'data': data,
  };

  String toJsonString() => jsonEncode(toJsonMap());

  factory SaveEnvelope.fromJsonMap(Map<String, dynamic> map) {
    final v = map['schemaVersion'];
    if (v is! int) {
      throw const FormatException(
        'save envelope missing integer schemaVersion',
      );
    }
    final d = map['data'];
    if (d is! Map) {
      throw const FormatException('save envelope missing data object');
    }
    return SaveEnvelope(schemaVersion: v, data: Map<String, dynamic>.from(d));
  }

  factory SaveEnvelope.fromJsonString(String s) =>
      SaveEnvelope.fromJsonMap(jsonDecode(s) as Map<String, dynamic>);

  SaveEnvelope copyWith({int? schemaVersion, Map<String, dynamic>? data}) =>
      SaveEnvelope(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        data: data ?? this.data,
      );
}
