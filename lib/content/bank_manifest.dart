/// Content manifest + categorization (P4-0). A machine-readable summary of a
/// dialogue bank for content operations: the schema version + locale, the
/// entry/line totals, the per-dimension category breakdown, and the
/// memory-callback coverage. Produced for `just content-validate` and for the
/// content ledger so a founder can see — at a glance — what a bank actually
/// contains before it ships (CONTENT_FACTORY §7.2/§11.4).
library;

import '../heartmind/dialogue_bank.dart';
import '../heartmind/memory_injection.dart';

class BankManifest {
  const BankManifest({
    required this.schemaVersion,
    required this.locale,
    required this.entryCount,
    required this.lineCount,
    required this.byIntent,
    required this.byMood,
    required this.byBondStage,
    required this.byLifeStage,
    required this.byPersonalityDial,
    required this.memoryCallbackLineCount,
  });

  final int schemaVersion;
  final String locale;
  final int entryCount;
  final int lineCount;

  /// Line counts grouped by each keying dimension (the value for a wildcard
  /// dimension is bucketed under `*`).
  final Map<String, int> byIntent;
  final Map<String, int> byMood;
  final Map<String, int> byBondStage;
  final Map<String, int> byLifeStage;
  final Map<String, int> byPersonalityDial;

  /// Lines carrying at least one `{fact:…}` memory slot — the callback corpus
  /// (feeds the ≥95% reliability gate, R3).
  final int memoryCallbackLineCount;

  /// Computes the manifest for [bank].
  factory BankManifest.of(DialogueBank bank) {
    final byIntent = <String, int>{};
    final byMood = <String, int>{};
    final byBond = <String, int>{};
    final byLife = <String, int>{};
    final byDial = <String, int>{};
    var callbackLines = 0;

    for (final e in bank.entries) {
      final n = e.lines.length;
      byIntent.update(e.intent, (v) => v + n, ifAbsent: () => n);
      byMood.update(e.mood, (v) => v + n, ifAbsent: () => n);
      byBond.update(e.bondStage, (v) => v + n, ifAbsent: () => n);
      byLife.update(e.lifeStage, (v) => v + n, ifAbsent: () => n);
      byDial.update(e.personalityDial, (v) => v + n, ifAbsent: () => n);
      callbackLines += e.lines.where((l) => kFactSlot.hasMatch(l)).length;
    }

    return BankManifest(
      schemaVersion: bank.schemaVersion,
      locale: bank.locale,
      entryCount: bank.entries.length,
      lineCount: bank.lineCount,
      byIntent: Map.unmodifiable(byIntent),
      byMood: Map.unmodifiable(byMood),
      byBondStage: Map.unmodifiable(byBond),
      byLifeStage: Map.unmodifiable(byLife),
      byPersonalityDial: Map.unmodifiable(byDial),
      memoryCallbackLineCount: callbackLines,
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'locale': locale,
    'entryCount': entryCount,
    'lineCount': lineCount,
    'memoryCallbackLineCount': memoryCallbackLineCount,
    'byIntent': byIntent,
    'byMood': byMood,
    'byBondStage': byBondStage,
    'byLifeStage': byLifeStage,
    'byPersonalityDial': byPersonalityDial,
  };

  /// A compact human-readable breakdown for the validate-content CLI.
  String describe() {
    String row(String label, Map<String, int> m) {
      final parts =
          (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              .map((e) => '${e.key}:${e.value}')
              .join(', ');
      return '  $label  $parts';
    }

    return [
      'content manifest: v$schemaVersion · locale=$locale · '
          '$entryCount entries / $lineCount lines · '
          '$memoryCallbackLineCount callback lines',
      row('by intent  ', byIntent),
      row('by mood    ', byMood),
      row('by bond    ', byBondStage),
      row('by lifeStage', byLifeStage),
    ].join('\n');
  }
}
