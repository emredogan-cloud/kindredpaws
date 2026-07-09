/// Outbound-link seam (KP-003/KP-004). The app's legally-required links
/// (Privacy Policy, Terms, Support) open through this interface so widget
/// tests stay hermetic (no platform channel) and every launch is observable.
library;

import 'package:url_launcher/url_launcher.dart' as launcher;

abstract interface class LinkOpener {
  /// Opens [url] in the external browser. Returns false when it could not be
  /// opened (no handler / platform refusal) — callers surface a gentle toast.
  Future<bool> open(String url);
}

/// Production implementation over `url_launcher` (external application mode —
/// legal documents must open in the system browser, not an in-app view a
/// reviewer could mistake for unhosted content).
class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(String url) async {
    try {
      return await launcher.launchUrl(
        Uri.parse(url),
        mode: launcher.LaunchMode.externalApplication,
      );
    } on Exception {
      return false;
    }
  }
}

/// Hermetic default for bootstrap/tests: records what would have opened.
class RecordingLinkOpener implements LinkOpener {
  final List<String> opened = [];

  /// What [open] reports; tests flip it to exercise the failure toast.
  bool succeed = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return succeed;
  }
}
