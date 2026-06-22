/// Firebase adapter SEAM for [BackendService] (locked backend, ADR-003 → LOCKED).
///
/// Provisioning state: the integration point is defined here, but the Firebase
/// SDK packages and native config (`flutterfire configure` + the `google-services`
/// plugin / `GoogleService-Info.plist`) are a **credentialed founder step** (see
/// REQUIRED_ENVIRONMENTS.md). Until then this adapter is intentionally inert so
/// the app builds and runs on the in-memory backend with zero credentials.
///
/// To activate (Phase 1 onward, after provisioning):
///   1. `flutter pub add firebase_core cloud_firestore firebase_auth firebase_analytics firebase_remote_config`
///   2. `flutterfire configure` (writes firebase_options.dart + native config)
///   3. Replace the bodies below with `cloud_firestore` calls and register this
///      adapter in bootstrap() when AppConfig.backendMode == BackendMode.firebase.
library;

import 'backend_service.dart';

class FirebaseBackendService implements BackendService {
  // Inert until provisioned: an adapter that throws on every call is not an
  // authoritative source of truth yet. This flips to `true` in the same change
  // that replaces the bodies below with real cloud_firestore calls (step 3),
  // so the provisioning screen never mislabels an unprovisioned backend.
  @override
  bool get isAuthoritative => false;

  Never _notProvisioned() => throw UnimplementedError(
    'Firebase is selected but not provisioned. Run `flutterfire configure` '
    'and add the Firebase SDK packages — see REQUIRED_ENVIRONMENTS.md. '
    'Until then run with --dart-define=KP_BACKEND=mock (the default).',
  );

  @override
  Future<Map<String, dynamic>?> readDocument(String c, String k) async =>
      _notProvisioned();

  @override
  Future<void> writeDocument(
    String c,
    String k,
    Map<String, dynamic> v,
  ) async => _notProvisioned();

  @override
  Future<void> append(String s, Map<String, dynamic> e) async =>
      _notProvisioned();
}
