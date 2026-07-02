/// Firebase provisioning seam (P1-1). The single, dependency-free description of
/// how Firebase comes online + an init seam the app can call safely today.
///
/// **Why inert:** activating Firebase requires `flutterfire configure` (which
/// writes `firebase_options.dart` + native `google-services.json` /
/// `GoogleService-Info.plist`) and adding the `firebase_*` pub packages — a
/// **credentialed founder step** (REQUIRED_ENVIRONMENTS.md). Adding the SDK
/// without that config crashes at init and turns CI red (no secrets in CI). So
/// until provisioned this seam is a no-op and the app runs fully on the
/// in-memory/console observability + mock backend. Flipping it on is: add the
/// deps, run `flutterfire configure`, set `--dart-define=KP_FIREBASE_PROVISIONED=true`,
/// and replace the [initialize] body + register the real adapters in `bootstrap`.
library;

/// Result of a Firebase init attempt (no firebase types leak out of the seam).
class FirebaseStatus {
  const FirebaseStatus({required this.provisioned, required this.detail});

  final bool provisioned;
  final String detail;
}

class FirebaseProvisioning {
  /// Set true ONLY once `flutterfire configure` has run and the deps are added.
  static const bool isProvisioned = bool.fromEnvironment(
    'KP_FIREBASE_PROVISIONED',
  );

  /// Firebase products this app integrates behind seams (P1-1 / P1-2).
  static const List<String> products = <String>[
    'Auth (anonymous/guest + Apple/Google)',
    'Cloud Firestore (authoritative versioned cloud save)',
    'Remote Config (live tuning of decay/bond/floor keys)',
    'Analytics (~15-event taxonomy, no PII)',
    'Crashlytics (crash-free ≥99% gate)',
    'Performance Monitoring (cold-start + reaction-beat traces)',
  ];

  /// Exact founder activation steps (mirrors REQUIRED_ENVIRONMENTS.md).
  static const List<String> activationSteps = <String>[
    'flutter pub add firebase_core cloud_firestore firebase_auth '
        'firebase_analytics firebase_crashlytics firebase_performance '
        'firebase_remote_config',
    'flutterfire configure  # writes lib/firebase_options.dart + native config',
    'Build with --dart-define=KP_FIREBASE_PROVISIONED=true --dart-define=KP_BACKEND=firebase',
    'Replace FirebaseProvisioning.initialize() body + register the real '
        'CrashReporter/PerformanceMonitor/Analytics adapters in bootstrap()',
  ];

  /// Safe init seam. Real impl (post-provisioning) calls
  /// `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
  /// Today it is a no-op that reports the unprovisioned status — never throws,
  /// so `main()` can always await it.
  static Future<FirebaseStatus> initialize() async {
    if (!isProvisioned) {
      return const FirebaseStatus(
        provisioned: false,
        detail:
            'Firebase not provisioned — running on in-memory/console '
            'observability + mock backend. See REQUIRED_ENVIRONMENTS.md.',
      );
    }
    // Provisioned flag set but the native SDK init is intentionally not wired
    // here yet (kept dependency-free for CI). Wiring it is the documented step.
    return const FirebaseStatus(
      provisioned: true,
      detail:
          'KP_FIREBASE_PROVISIONED=true — wire Firebase.initializeApp() + real '
          'adapters (firebase_provisioning.dart activationSteps).',
    );
  }
}
