# REQUIRED_ENVIRONMENTS.md — KindredPaws

Every external account, credential, secret, and API key the project needs, and
exactly how to obtain and place each one. The app and CI are **fully functional
without any of these** (mock/offline adapters + `--dart-define` defaults); this
list is what a founder provisions to turn live integrations on, in roughly the
order they're needed by phase.

> **Public repo — never commit any value below.** All secrets go in the
> platform's secret store (GitHub → Settings → Secrets and variables → Actions)
> or the app's `--dart-define` at build time, never in source. `.gitignore` +
> gitleaks (CI) enforce this.

Legend: **[P0]** needed now to fully exit Phase 0 · **[P1]** core-loop ·
**[P3]** closed beta · **[P4]** soft launch. **MANDATORY** vs **OPTIONAL** is
relative to the phase it's needed in.

---

## 1. Firebase (backend — LOCKED, ADR-003) — [P1, scaffold ready now]

The app's authoritative backend (auth, Firestore cloud save, Remote Config,
Analytics, **Crashlytics**, **Performance Monitoring**). The code seams exist —
`lib/services/firebase_backend.dart` (Firestore) + `lib/services/firebase_provisioning.dart`
(init + observability adapters) — and the app runs fully on in-memory/console
observability until wired. Activation is a credentialed step.

| Item | Value/var | Mandatory? | Where used | How to get it |
|---|---|---|---|---|
| Firebase project | (console project) | MANDATORY (P1) | all backend | console.firebase.google.com → **Add project** → name "KindredPaws" |
| `google-services.json` | `android/app/google-services.json` (gitignored) | MANDATORY | Android runtime | Firebase console → Project settings → Your apps → Android app (package `com.kindredpaws.kindredpaws`) → **Download** |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` (gitignored) | MANDATORY | iOS runtime | Firebase console → add iOS app → **Download** |
| `firebase_options.dart` | `lib/firebase_options.dart` | MANDATORY | `Firebase.initializeApp` | run `flutterfire configure` (writes it + native config) |

**Steps to activate (after Phase 0):**
1. `dart pub global activate flutterfire_cli`
2. `flutter pub add firebase_core cloud_firestore firebase_auth firebase_remote_config firebase_analytics firebase_crashlytics firebase_performance`
3. `flutterfire configure` (select the KindredPaws project; writes `firebase_options.dart` + native config + adds the `google-services` Gradle plugin)
4. Replace `FirebaseProvisioning.initialize()` with `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`; implement the bodies in `lib/services/firebase_backend.dart` against `cloud_firestore`; add real `CrashReporter`/`PerformanceMonitor`/`AnalyticsService` adapters (Crashlytics/Perf/Analytics) and register them in `bootstrap()`.
5. Run with `--dart-define=KP_BACKEND=firebase --dart-define=KP_FIREBASE_PROVISIONED=true`.
> Until step 5, the app runs on the in-memory backend + console/in-memory
> observability (defaults `KP_BACKEND=mock`, `KP_FIREBASE_PROVISIONED=false`).
> All observability code (structured `Logger`, `CrashReporter`,
> `PerformanceMonitor`, `ObservabilityFacade` incl. the mandatory leading-churn
> flags) is wired and unit-tested now — provisioning only swaps the sink.

---

## 2. Anthropic / Claude (Heartmind LLM — LOCKED) — [P0 cost-model done; key is P4]

| Item | Var | Mandatory? | Where used | How to get it |
|---|---|---|---|---|
| Anthropic API key | `ANTHROPIC_API_KEY` | MANDATORY for the **offline pre-gen** content op (P2) and the **Deferred live chat** (P4) | server-side Heartmind proxy ONLY — **never the client** | console.anthropic.com → API Keys → Create Key |

- Runtime/live model: `claude-haiku-4-5` (founder decision). Pre-gen model: `claude-opus-4-8`.
- The key lives only in the serverless Heartmind proxy (a Firebase/Cloud Function), set as a function secret — never shipped in the app.
- MVP needs **no runtime key** (the dialogue bank is selected on-device); the key is needed to *generate* the bank offline (P2) and for the gated live-chat pilot (P4).
- Cost gate already modeled & passing — see `docs/LLM_UNIT_ECONOMICS_MODEL.md` / `dart run tool/llm_cost_model.dart`.

---

## 3. Android release signing — [P3/release]

| Var (GitHub Actions secret) | Purpose |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | base64 of the upload keystore (`.jks`) |
| `ANDROID_STORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |

Generate: `keytool -genkeypair -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 9125 -alias upload`, then `base64 -w0 upload-keystore.jks`. Add the four as repo Actions secrets. `release.yml` already consumes them (debug-signs as a fallback when absent). `android/app/build.gradle.kts` reads `android/key.properties` written by CI.

---

## 4. iOS signing & delivery (Codemagic / App Store Connect) — [P3/P4, macOS]

| Item | Purpose | How |
|---|---|---|
| Apple Developer account | iOS distribution | developer.apple.com (paid) |
| `CODEMAGIC_API_TOKEN` | CD on managed macOS | codemagic.io → Teams → Integrations |
| App Store Connect API key (`.p8` + key id + issuer id) | TestFlight/App Store upload | appstoreconnect.apple.com → Users and Access → Keys |
| fastlane match repo + passphrase | cert/profile storage | private git repo for `match` |

(Documented in the pre-Phase-0 device-cloud strategy; iOS cannot be built on this Linux host.)

---

## 5. RevenueCat (IAP/subscription — ADR-007) — [P3]

| Var | Purpose | How |
|---|---|---|
| `REVENUECAT_PUBLIC_SDK_KEY_IOS` / `_ANDROID` | client SDK init | app.revenuecat.com → Project → API keys |
| StoreKit / Play Billing products | "Forever Friends" $5.99/mo · $39.99/yr + Heartstone bundles | App Store Connect / Play Console product setup |

---

## 6. Ads mediation (AdMob/ironSource, child-safe) — [P3]

| Var | Purpose | Notes |
|---|---|---|
| `ADMOB_APP_ID_IOS` / `_ANDROID` | ads SDK | admob.google.com; set **COPPA/kids flags**, rewarded-first, no behavioral targeting (Risk R1) |
| rewarded/interstitial ad unit ids | placements | per the ad cadence in the gameplay bible §9.2 |

---

## 7. Donation intermediary (Impact Pledge) — [before P4]

| Item | Purpose | How |
|---|---|---|
| Giving-platform account | NET-revenue disbursement to vetted shelters | PayPal Giving Fund / Percent / Benevity (Open Decision #4) |
| 1–3 vetted partner shelters | named recipients | Charity Navigator / GuideStar vetting |

See `docs/IMPACT_PLEDGE.md`. No donation-IAP / no player tax-deductible donations in MVP.

---

## 8. App-level `--dart-define` flags (client config, not secrets)

| Flag | Default | Meaning |
|---|---|---|
| `KP_ENV` | `dev` | environment label |
| `KP_BACKEND` | `mock` | `mock` \| `firebase` |
| `KP_FIREBASE_PROVISIONED` | `false` | `true` only after `flutterfire configure` + deps added |
| `KP_PET_RENDERER` | `placeholder` | `placeholder` \| `rive` (rig runtime; default keeps goldens deterministic) |
| `KP_HEARTMIND_LIVE_CHAT` | `false` | Deferred #6b — keep OFF for MVP |
| `KP_ANTHROPIC_PROXY` | `false` | whether the server proxy is wired |

Example live build: `flutter build apk --release --dart-define=KP_ENV=prod --dart-define=KP_BACKEND=firebase`

---

## Outstanding founder actions to fully close G0
- [ ] Create the Firebase project + run `flutterfire configure` (§1) — *or* defer to P1 (the scaffold + cost model satisfy "tech stack provisioned" for G0).
- [ ] Create an Anthropic API key for the pre-gen content op (§2).
- [ ] Secure a **Rive** rig contractor (deliver `.riv` artboards against the `PetStateMachine` contract; rig runtime locked to Rive at P1-0, D-053 — see `docs/ANIMATION_SPIKE_REPORT.md`) with the locked concept (`docs/LIVE2D_RIG_DESIGN_BRIEF.md` for art direction) — **G0 pass criterion**.
- [ ] Book the child-directedness legal review (see `docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md`) — **G0 pass criterion**.
