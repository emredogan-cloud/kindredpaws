/// Store-metadata validation gate (P4-8) — `dart run tool/validate_store_metadata.dart`.
///
/// Proves the version-controlled `store/metadata/<locale>/*.txt` fields exist,
/// are non-empty, and fit the **strictest** App Store / Play length limit, so an
/// over-length title/notes can never reach a store submission. Exits non-zero on
/// any violation. The same limits are pinned by `store_metadata_test.dart`.
library;

import 'dart:io';

/// field → strictest length limit across App Store + Google Play.
const Map<String, int> kStoreLimits = {
  'title': 30, // App Store 30 (Play title 50)
  'subtitle': 30, // App Store subtitle 30
  'short_description': 80, // Play short description 80
  'keywords': 100, // App Store keywords 100
  'promotional_text': 170, // App Store promotional text 170
  'description': 4000, // both 4000
  'release_notes': 500, // Play "What's New" 500 (App Store 4000)
};

const String kLocaleDir = 'store/metadata/en-US';

void main() {
  final issues = <String>[];
  for (final entry in kStoreLimits.entries) {
    final file = File('$kLocaleDir/${entry.key}.txt');
    if (!file.existsSync()) {
      issues.add('MISSING ${entry.key}.txt');
      continue;
    }
    final text = file.readAsStringSync().trim();
    final len = text.runes.length;
    if (text.isEmpty) {
      issues.add('EMPTY ${entry.key}.txt');
    } else if (len > entry.value) {
      issues.add('OVER ${entry.key}.txt ($len > ${entry.value})');
    }
    stdout.writeln('  ${entry.key.padRight(18)} $len / ${entry.value}');
  }

  if (issues.isEmpty) {
    stdout.writeln(
      'store-metadata: OK (${kStoreLimits.length} fields within limits)',
    );
    exit(0);
  }
  for (final i in issues) {
    stderr.writeln('store-metadata: $i');
  }
  exit(1);
}
