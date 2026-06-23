/// Dialogue-bank generation/export tool (P4-1) — the "offline pre-gen → validate
/// → ship" workflow made reproducible.
///
///   dart run tool/generate_bank.dart [out.json]
///
/// Builds the production corpus (`lib/heartmind/dialogue_corpus.dart`), gates it
/// through [ContentValidator] (exits non-zero on ANY error — no unsafe content
/// ships), prints the [BankManifest], and writes the versioned/localized JSON
/// artifact (P4-0 format) to the given path, or to stdout if none is given. The
/// JSON is what a translator / content-ledger / live-ops top-up consumes; the
/// runtime uses the compiled Dart corpus directly (sync, $0, spinner-free).
///
/// Generation workflow (CONTENT_FACTORY §10.2):
///   1. Author/extend curated, child-safe, never-guilt lines in dialogue_corpus.
///   2. `dart run tool/generate_bank.dart` — validator gates safety + dedup.
///   3. Founder review (the human checkpoint) of any new/changed lines.
///   4. Ship (compiled in) and/or export JSON for localization / Remote Config.
library;

import 'dart:io';

import 'package:kindredpaws/content/bank_manifest.dart';
import 'package:kindredpaws/content/content_validator.dart';
import 'package:kindredpaws/heartmind/dialogue_corpus.dart';

void main(List<String> args) {
  final bank = buildDialogueCorpus();
  final report = const ContentValidator().validateBank(bank);
  final manifest = BankManifest.of(bank);

  stderr.writeln('generate-bank: building the production corpus');
  stderr.writeln(manifest.describe());
  for (final issue in report.issues) {
    stderr.writeln('  $issue');
  }
  stderr.writeln(report.summary(bank.entries.length, bank.lineCount));

  if (!report.ok) {
    stderr.writeln(
      'generate-bank: ABORTED — corpus has errors, nothing shipped',
    );
    exit(1);
  }

  final json = bank.toJsonString();
  if (args.isNotEmpty) {
    File(args.first).writeAsStringSync('$json\n');
    stderr.writeln(
      'generate-bank: wrote ${bank.lineCount} lines → ${args.first}',
    );
  } else {
    stdout.writeln(json);
  }
}
