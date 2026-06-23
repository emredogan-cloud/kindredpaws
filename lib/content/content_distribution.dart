/// Content Operating System — distribution (P3-3).
///
/// Live-ops ships dialogue **top-ups via Remote Config** without an app update
/// (CONTENT_FACTORY §9, GAME_TECHNICAL_SYSTEMS.md §4.1). [mergeRemoteContent]
/// merges a remote payload onto the bundled bank, but **re-validates every
/// remote entry through the same [ContentValidator] gate first** and accepts
/// only the clean ones — a malformed or off-tone remote push can never corrupt
/// the live bank or reach a child (fail-safe per entry, not all-or-nothing).
library;

import '../heartmind/dialogue_bank.dart';
import 'content_validator.dart';

/// Result of merging a remote content payload onto the bundled bank.
class RemoteContentResult {
  const RemoteContentResult({
    required this.bank,
    required this.report,
    required this.acceptedCount,
    required this.rejectedCount,
  });

  /// The effective bank = bundled entries + accepted remote entries.
  final DialogueBank bank;

  /// Issues found in the remote payload (rejected entries' errors).
  final ContentReport report;

  final int acceptedCount;
  final int rejectedCount;
}

/// Merges [remoteJson] (from Remote Config) onto [bundled], validating each
/// remote entry and dropping any that fails. A null/empty/unparseable payload
/// leaves the bundled bank untouched.
RemoteContentResult mergeRemoteContent(
  DialogueBank bundled,
  String? remoteJson, {
  ContentValidator validator = const ContentValidator(),
}) {
  if (remoteJson == null || remoteJson.trim().isEmpty) {
    return RemoteContentResult(
      bank: bundled,
      report: ContentReport(const []),
      acceptedCount: 0,
      rejectedCount: 0,
    );
  }

  final DialogueBank remote;
  try {
    remote = DialogueBank.fromJsonString(remoteJson);
  } catch (e) {
    // Malformed payload → ignore it entirely; keep the (safe) bundled bank.
    return RemoteContentResult(
      bank: bundled,
      report: ContentReport([
        ContentIssue(
          ContentSeverity.error,
          '<remote>',
          'unparseable remote content: $e',
        ),
      ]),
      acceptedCount: 0,
      rejectedCount: 0,
    );
  }

  final accepted = <DialogueBankEntry>[];
  final issues = <ContentIssue>[];
  var rejected = 0;
  for (final entry in remote.entries) {
    // Validate each entry in isolation so one bad line drops only its entry.
    final r = validator.validateBank(DialogueBank([entry]));
    if (r.ok) {
      accepted.add(entry);
    } else {
      rejected++;
      issues.addAll(r.issues);
    }
  }

  return RemoteContentResult(
    bank: DialogueBank([...bundled.entries, ...accepted]),
    report: ContentReport(issues),
    acceptedCount: accepted.length,
    rejectedCount: rejected,
  );
}
