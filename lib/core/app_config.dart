/// Central runtime configuration + feature flags for KindredPaws.
///
/// Values are read from `--dart-define` at build time with **safe defaults**:
/// the app runs fully on mock / in-memory adapters until real backends are
/// provisioned (see `REQUIRED_ENVIRONMENTS.md`). This is Phase-0 provisioning
/// scaffolding — it contains **no gameplay**.
library;

/// Which backend implementation is wired (see GAME_TECHNICAL_SYSTEMS.md §2).
enum BackendMode { mock, firebase }

/// Which pet-rendering backend is wired (ADR-001; engine = Flutter + **Rive**,
/// locked at P1-0 after the animation spike — see `docs/ANIMATION_SPIKE_REPORT.md`).
/// `placeholder` is the deterministic Flutter-drawn stand-in; `vector` is the
/// original hand-authored animated pet (the temporary renderer, honouring the
/// same state contract) shipped until the commissioned `.riv` rig arrives;
/// `rive` activates the real seam.
enum PetRendererBackend { placeholder, rive, vector }

/// Which billing implementation is wired (RevenueCat is the locked choice,
/// ADR-007; `noop` simulates purchases offline until the SDK + store products
/// are provisioned — REQUIRED_ENVIRONMENTS.md §5).
enum BillingMode { noop, revenuecat }

/// Immutable, build-time application configuration.
class AppConfig {
  const AppConfig({
    required this.backendMode,
    required this.petRendererBackend,
    required this.riveAssetPath,
    required this.heartmindLiveChatEnabled,
    required this.anthropicProxyConfigured,
    required this.environmentLabel,
    this.billingMode = BillingMode.noop,
    this.betaEnabled = false,
  });

  /// Default config used when nothing is overridden via `--dart-define`.
  /// Mock backend, live chat OFF, no proxy — fully offline-safe.
  ///
  /// [fallbackRenderer] applies only when `KP_PET_RENDERER` is unset: tests
  /// and CI (bare `bootstrap()`) stay on the deterministic placeholder, while
  /// the production app passes `vector` so players meet the animated pet.
  /// An explicit `KP_PET_RENDERER=placeholder|vector|rive` always wins.
  factory AppConfig.fromEnvironment({
    PetRendererBackend fallbackRenderer = PetRendererBackend.placeholder,
  }) {
    return AppConfig(
      backendMode: _backend == 'firebase'
          ? BackendMode.firebase
          : BackendMode.mock,
      petRendererBackend: switch (_renderer) {
        'rive' => PetRendererBackend.rive,
        'vector' => PetRendererBackend.vector,
        'placeholder' => PetRendererBackend.placeholder,
        _ => fallbackRenderer,
      },
      // Empty `--dart-define` ⇒ null ⇒ the Rive seam paints its stand-in.
      riveAssetPath: _riveAsset == '' ? null : _riveAsset,
      heartmindLiveChatEnabled: _liveChat,
      anthropicProxyConfigured: _proxy,
      environmentLabel: _env,
      billingMode: _billing == 'revenuecat'
          ? BillingMode.revenuecat
          : BillingMode.noop,
      betaEnabled: _beta,
    );
  }

  /// Selected backend (Firebase is the locked choice; mock until provisioned).
  final BackendMode backendMode;

  /// Selected pet-render backend (Rive is the locked rig runtime; placeholder
  /// until the commissioned `.riv` asset arrives at P2).
  final PetRendererBackend petRendererBackend;

  /// Path to the bundled `.riv` rig (from `KP_RIV_ASSET`), or null to run the
  /// Rive seam's native-free stand-in. Only consulted when [petRendererBackend]
  /// is `rive`.
  final String? riveAssetPath;

  /// Deferred feature #6b: live free-form LLM chat. MUST stay OFF for MVP
  /// (age-gated + subscriber-only, post-soft-launch). See the decision log.
  final bool heartmindLiveChatEnabled;

  /// Whether the server-side Heartmind proxy (the only holder of the Anthropic
  /// API key) is configured. The client NEVER calls Anthropic directly.
  final bool anthropicProxyConfigured;

  /// Free-form environment label (dev / staging / soft-launch / prod).
  final String environmentLabel;

  /// Selected billing backend (RevenueCat is locked; noop until provisioned).
  final BillingMode billingMode;

  /// Closed-beta build flag (P4-7) — surfaces the beta feedback + diagnostics
  /// entry points. Off in normal/golden builds (no UI change).
  final bool betaEnabled;

  bool get usingMockBackend => backendMode == BackendMode.mock;

  static const String _backend = String.fromEnvironment(
    'KP_BACKEND',
    defaultValue: 'mock',
  );
  static const String _renderer = String.fromEnvironment(
    'KP_PET_RENDERER',
    // Empty sentinel = "unset" → AppConfig.fromEnvironment's fallbackRenderer
    // decides (placeholder for tests/CI, vector for the shipped app).
    defaultValue: '',
  );
  static const String _riveAsset = String.fromEnvironment(
    'KP_RIV_ASSET',
    defaultValue: '',
  );
  static const bool _liveChat = bool.fromEnvironment('KP_HEARTMIND_LIVE_CHAT');
  static const bool _proxy = bool.fromEnvironment('KP_ANTHROPIC_PROXY');
  static const String _env = String.fromEnvironment(
    'KP_ENV',
    defaultValue: 'dev',
  );
  static const String _billing = String.fromEnvironment(
    'KP_BILLING',
    defaultValue: 'noop',
  );
  static const bool _beta = bool.fromEnvironment('KP_BETA');
}
