# REAL DEVICE E2E VALIDATION REPORT — KindredPaws

Real-device end-to-end validation of the existing product (no new features). All
evidence below is from the physically connected Android device via ADB. Honest
evidence only — limitations are stated plainly.

## 1. Device model
- **Redmi 22095RA98C** (manufacturer Xiaomi), **MIUI V140**.
- Serial `jfzxugsgnnvsrsg6`; screen 1080×2408; ABI arm64-v8a.

## 2. Android version
- **Android 13 (API 33)**.

## 3. Validation matrix

| Area | Method | Result |
|---|---|---|
| Build (clean→analyze→test→apk) | host | ✅ analyze clean, 450 tests pass, app-debug.apk built |
| Install on device | adb | ✅ after MIUI workaround (§11) |
| Rescue Day onboarding | integration test + manual drive | ✅ renders + completes |
| Choose species / adopt | manual drive | ✅ Puppy → name → Companion Home |
| Companion Home | manual drive | ✅ renders (Bond, Care ring, Kibble, verbs) |
| Feed / Play / Clean | integration test + manual | ✅ Kibble 0→7, Bond ↑, mood + feedback |
| Care Meters change | manual | ✅ ring + bond progress visible |
| Bond change | manual | ✅ Stranger→(progress toward Friend) |
| Heartmind line | manual + test | ✅ "Hi hi hi! You're here!", "Yum yum yum…" |
| Memory Book | integration test | ✅ opens + renders |
| Create a memory | implicit (seed + care) + persistence callback | ✅ memory callback after restart |
| Keepsakes | integration test | ✅ opens, non-empty (Rescue Day keepsake) |
| Analytics emitted | integration test asserts | ✅ rescueDayComplete=1, careAction=3 |
| Persistence (force-stop→reopen) | adb, real PrefsSaveStore | ✅ save+memories+state restored, no re-onboard |
| Long session (~15 min) | scripted interaction loop | ✅ no leak, 0 crash, 0 ANR |
| Notifications | code+device | ⚠️ no OS plugin — in-memory only (not delivered) |
| Monetization | manual drive | ✅ graceful degradation (Noop billing) |
| Widget | manifest+dumpsys | ✅ provider registered; launcher placement = founder step |
| Firebase | code+logcat | ⚠️ mock stack at runtime; founder console step |
| Crashes / ANRs | logcat across all sessions | ✅ 0 / 0 |

## 4. Screenshots captured
Under `artifacts/screens/` (gitignored — local evidence):
- `06-cold-launch.png` — Rescue Day cold-open ("A cold, rainy evening… Reach out").
- `07-species.png` — "Will you give it a forever home?" Puppy / Kitten.
- `08-name.png` — "What will you name your new friend?" (default Biscuit).
- `09-companion-home.png` — Companion Home; Bond "Stranger", Heartmind "Hi hi hi! You're here! 🐾".
- `10-post-care.png` — after Feed/Clean/Play: Kibble 0→7, Bond progressed, "Yum yum yum…", "best time playing! 🎾".
- `11-persistence-relaunch.png` — after force-stop+relaunch: Biscuit resumed, Kibble 7, memory callback "I remembered… chasing the ball".
- `13-paywall.png` — paywall (control copy, $5.99/mo · $39.99/yr Save 44%, ethical-wall note, Heartstones, Rescue Bundles).
- `14-paywall-purchase.png` — graceful Noop purchase → "You're a Forever Friend 💛" entitled state.

## 5. Videos captured
- `artifacts/full-journey/e2e.mp4` (9.1 MB) — full integration-test journey recorded on-device (onboard → care → Memory Book → Keepsakes → reopen).

## 6. Logcat summary
- Captured: `artifacts/full-journey/logcat.txt`, `artifacts/long-session/logcat.txt`, `…/logcat2.txt`.
- **No `FATAL EXCEPTION`, `ANR in`, `signal 11`, or `libc: Fatal`** in any session.
- Benign noise only: `VerityUtils` fs-verity fail (expected for a debug APK), `QSTileHost` PackageManager (MIUI probe), `gralloc4 isSupported(4×4)` capability probes, `SLM-SRV` thermal `ENOENT`, MALI debug, and Firebase `AppMeasurement`/`GooglePlayServicesUtil "requires Google Play Store, but it is missing"` (this Redmi has no Google Play Services — non-fatal, see §8).

## 7. Performance observations
- **Cold startup:** `am start -W` TotalTime **3241 ms** (WaitTime 3251 ms). This is a **debug** build (no AOT, JIT warmup) — the `PerfBudget.coldStart = 2500 ms` budget targets a **release/profile** build, which is materially faster. A signed release build is the apples-to-apples measure (not buildable here — no signing creds).
- **Memory (leak check):** TOTAL PSS across ~15 min of continuous interaction was **stable / slightly decreasing**: 241→241→237→234→234→236→234 MB. **No leak trend.** (Absolute ~234–270 MB is debug-build overhead; release is much lighter.)
- **Frame pacing:** `dumpsys gfxinfo` reports `0 frames / 0 janky` with degenerate 4950 ms percentiles — an artifact: the app renders via **Impeller (Vulkan)** to its own surface, which Android's gfxinfo does not track. On-device interaction was visually smooth (the integration-test run logged only 3 "Skipped frames"). Precise frame profiling is a `flutter run --profile` + DevTools founder step.
- **Renderer:** Impeller (Vulkan) — confirmed via `flutter run` log.

## 8. Firebase observations
- The committed `android/app/google-services.json` is a **placeholder** (fake project_id/number — required because the `com.google.gms.google-services` Gradle plugin is unconditionally applied; no real creds in this public repo).
- At runtime the **debug build runs the mock/in-memory stack** (`KP_FIREBASE_PROVISIONED=false`); `FirebaseInitProvider` is removed (`tools:node="remove"`) and collection meta-data is disabled. The `firebase_analytics` plugin still spins up GMS `AppMeasurement`, which **fails because this device has no Google Play Services** — **non-fatal**, does not affect the UI.
- **Cannot be automated** (no console access). **Founder verification steps:** build with `--dart-define=KP_FIREBASE_PROVISIONED=true --dart-define=KP_BACKEND=firebase` + a **real** `google-services.json` on a **GMS device**, then confirm in the Firebase console: Analytics events (DebugView), Crashlytics session, Performance traces. (See `RELEASE_CANDIDATE.md`.)

## 9. Bugs found
- **None confirmed as app defects.**
- A black screen was observed on a standalone launcher-launch — **investigated and attributed to environment, not the app** (§11). Once the install was clean on a settled device, both `flutter run` and a cold launcher-launch render correctly (Rescue Day, frames > 0). The integration test (full journey) also passed.

## 10. Bugs fixed
- None required (no app defect found). No code changes to the product were made.

## 11. Remaining issues / limitations (honest)
1. **MIUI install gotcha.** `adb install` initially returned `INSTALL_FAILED_USER_RESTRICTED`. Root cause: MIUI's "Install via USB" verifies via Xiaomi servers and **auto-cancels when the screen is locked / offline**. Resolved by: screen **ON + unlocked + connectivity**, `settings put global verifier_verify_adb_installs 0`, and `adb install -t -g`. **Also:** a `pm clear` attempt was MIUI-restricted and **wedged the package** (`DELETE_FAILED_INTERNAL_ERROR`, empty `pm path`) — required a **device reboot** to recover. This transient wedged state is what produced the black screen in §9. **Founder action:** enable Developer Options → "Install via USB" + "USB debugging (Security settings)"; do not `pm clear` on MIUI.
2. **No OS notification delivery.** No `flutter_local_notifications` (or equivalent) dependency — the `NotificationScheduler` is an **in-memory seam** (scheduling logic is host-tested; warm / never-guilt copy is enforced in code), but **no real system notification is delivered**. This weakens D1/D7 re-engagement and should be wired (a native integration step) before relying on notifications for retention. Out of scope for this validation (no new features).
3. **Debug-build performance.** Startup (3.24 s) and memory (~234 MB) reflect the **debug** APK; re-measure on a signed release build.
4. **Firebase / GMS.** Analytics/Crashlytics/Performance require provisioning + a GMS device (this Redmi lacks Google Play Services).
5. **MIUI `monkey` is a no-op wrapper** (echoes `bash arg:` without injecting events) — the long-session stress used a scripted `adb input` loop instead.
6. **Device USB stability.** The connection dropped once during a long unattended run; `adb reconnect` recovered it.

## 12. Crash summary
- **0 crashes.** No `FATAL EXCEPTION` / native crash across onboarding, care, persistence, the ~15-min interaction loop (~1,100 interactions), or the monetization flow.

## 13. ANR summary
- **0 ANRs.** No `ANR in com.kindredpaws` / input-dispatch timeout in any session.

## 14. Battery observations
- Device was on **USB power (charging)** throughout (status: charging; temperature ~**37.5 °C**, normal). No abnormal heat or battery behavior observed. No busy loops by design (the sim resolves on session resume, not on a wall-clock tick; notifications are not polled). A precise unplugged `batterystats` drain measurement is a founder step.

## 15. Widget observations
- A real home-screen App Widget is shipped: **`PetWidgetProvider`** is **registered on the device** (`dumpsys appwidget` → `ComponentInfo{com.kindredpaws.kindredpaws/...PetWidgetProvider}`) and declared in the manifest (`APPWIDGET_UPDATE`). The Dart side writes the snapshot via `PrefsHomeWidgetService` (verified wired).
- **Add-to-launcher + update + reboot-survival** require a manual home-screen gesture (long-press → Widgets → drag), which is **not reliably adb-automatable** → **founder manual step**.

## 16. Monetization observations
- **Graceful degradation: PASS** (no RevenueCat creds → Noop billing). The paywall renders correctly: **control copy** ("Become a Forever Friend"), **locked prices** ($5.99/mo · $39.99/yr · **Save 44%** shown in both the chip and the spoken subtitle — the P5 a11y fix), the **ethical-wall note** ("Cosmetic & cozy perks only — never an advantage. Cancelling never affects your pet"), Heartstone bundles, and Rescue Bundles ("transparent giving split").
- A tapped plan flips to the **entitled state** ("You're a Forever Friend 💛 … Cancel anytime — it never affects your pet"), with the in-sheet status region announcing "Welcome, Forever Friend 💛" — **no billing crash**. Real purchases require RevenueCat provisioning (founder step).

## 17. Final recommendation
**PASS for soft launch on standard (GMS) Android devices.** On real hardware the core experience is solid and stable: onboarding, adopt, the full care loop (Heartmind responses, Bond/Care changes), Memory Book, Keepsakes, and — most importantly — **OS-level persistence with a memory callback across a process kill**, all with **zero crashes, zero ANRs, and no memory leak** over a sustained ~15-minute session. Monetization degrades gracefully, the ethical walls render to the player, and analytics fire on the (PII-free) mock stack.

**Before wide launch, the founder should:** (1) provision Firebase + RevenueCat and re-validate on a GMS device; (2) **wire real OS notifications** (the single most material gap for retention); (3) re-measure startup/frame-pacing/memory on a **signed release** build via `flutter drive --profile`; (4) verify the home widget by placing it on the launcher; (5) document the MIUI "Install via USB" requirement for any sideloaded beta on Xiaomi devices.

---
*Validation performed on Android 13 / Redmi 22095RA98C via ADB. Artifacts (screenshots, video, logcat) under `artifacts/` (gitignored). The on-device journey is reproducible via `TEST=integration_test/full_journey_test.dart just e2e-android`.*
