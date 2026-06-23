/// Sharing seam (P3-3b). Keepsake cards are the MVP viral surface — "the
/// endearing card IS the ambient ad" (brief §8.6) — and shares feed the G4
/// virality KPI (≥1 share per DAU-week). This abstracts the platform share
/// sheet so the game loop + analytics stay decoupled from the native plugin.
///
/// The default [NoopShareService] reports a deterministic outcome (no native
/// dependency, so CI/tests/dev stay offline + deterministic). The real
/// `share_plus`-backed implementation is a provisioning swap — exactly the
/// pattern used for the backend / renderer / home-widget seams.
library;

/// The result of an attempted share. [platform] is a coarse, non-PII label of
/// where it went (or `dismissed` / `system_sheet`) for the `keepsakeShare`
/// telemetry param.
class ShareOutcome {
  const ShareOutcome({required this.shared, required this.platform});

  /// True if the user completed a share (false = cancelled/dismissed).
  final bool shared;

  /// Coarse destination label (e.g. `system_sheet`, `dismissed`). Never PII.
  final String platform;

  static const ShareOutcome dismissed = ShareOutcome(
    shared: false,
    platform: 'dismissed',
  );
}

/// Shares a composed Keepsake card. Implementations must never throw into the
/// game loop — return [ShareOutcome.dismissed] on any failure.
abstract interface class ShareService {
  Future<ShareOutcome> shareKeepsake({
    required String title,
    required String caption,
    required String imageRef,
  });
}

/// Default no-op share: reports a successful share to the system sheet without
/// touching a native plugin (offline-safe, deterministic for CI/tests). The
/// real share sheet drops in via provisioning (see REQUIRED_ENVIRONMENTS.md).
class NoopShareService implements ShareService {
  const NoopShareService();

  @override
  Future<ShareOutcome> shareKeepsake({
    required String title,
    required String caption,
    required String imageRef,
  }) async => const ShareOutcome(shared: true, platform: 'system_sheet');
}
