# HUAWEI REAL DEVICE E2E VALIDATION REPORT — KindredPaws

**Mission:** Real Huawei-device end-to-end production validation (`Talking_tom_mission.md`).
**Date:** 2026-07-04 · **Branch:** `feature/genre-evolution` (PR #66, the Genre-Evolution build with GE-1…GE-7).
**Method:** the current build installed and driven on a physically connected Huawei device via ADB. Verified evidence only; limitations stated plainly; nothing exaggerated.

This was a validation sprint, not a feature phase — but two real, engineering-owned defects surfaced on the device and were reproduced, root-caused, fixed, retested on the device, and committed (STEP 9). They are the headline of this report.

---

## 1. Executive summary

The current KindredPaws build **runs correctly, performs well, and persists reliably on a completely different real Android device** than any prior validation — a Huawei ANE-LX1 (P20 Lite) on **Android 9 (API 28)**, where both earlier reports used a Xiaomi on Android 13. Install was clean on the first attempt (no vendor block, unlike the earlier MIUI device). The full user journey — onboarding → adopt → all eight rooms → the whole care loop → all four mini-games → wardrobe/décor/shop → Memory Book, Keepsakes, Daily Kindnesses, Seasons, Settings, Profile → force-stop → reopen — ran with **zero crashes and zero ANRs**, and reopening restored the pet, currency, kindness progress, and memory **with a genuine memory-callback greeting across a full process kill**.

Two device-found bugs were fixed and re-verified on the device:

1. **[HIGH] The shop/closet item lists could not be finger-scrolled** past the first section, making the Toy, Care-supply, and **Cozy Corners décor (GE-3)** shelves unreachable. Root cause: a `GridView` nested inside the scrolling shop `ListView` swallowed the vertical drag. Fixed; the décor shelf is now reachable on the device.
2. **[MEDIUM] Several emoji newer than Android 9's set rendered as "tofu" boxes** (🤍 🫧 🫙 🪢 🪶 🫐). Since the app's `minSdk` is API 24, this affected a whole class of supported devices. Replaced with universally-supported equivalents; verified on the device (e.g. the Bubble Drift game card now shows 💧, not a box).

A third positive finding corrects the earlier reports: **real OS notifications are now scheduled** (`flutter_local_notifications` is wired; the device shows real `RTC_WAKEUP` alarms) — the prior "in-memory only" limitation no longer applies.

**Release-build performance was measured for the first time on real hardware** (prior reports had only debug builds): cold start **1.46 s** (well under the 2.5 s budget), warm reopen **0.79 s**, memory **~98 MB PSS**.

After the fixes: **644 tests green, 0 analyzer issues**, release APK rebuilt, reinstalled, and re-walked on the device.

---

## 2. Device information

| Property | Value |
|---|---|
| Manufacturer / Brand | HUAWEI |
| Model | **ANE-LX1** (P20 Lite / Nova 3e) |
| Android version | **9 (Pie), API level 28** |
| Build | ANE-LX1 9.1.0.368(C432E6R1P7) / EMUI |
| Fingerprint | `HUAWEI/ANE-LX1/HWANE:9/HUAWEIANE-L01/9.1.0.368C432:user/release-keys` |
| Security patch | 2020-08-01 |
| ABI | **arm64-v8a** |
| Screen | **1080 × 2280** px |
| Density | **480 dpi** (xxhdpi) |
| Google Play Services | **present** (`com.google.android.gms`) + `com.huawei.hwid` |
| Serial | 89U4C18908003735 (USB debugging authorized: `device` state) |

Only this one device was connected (the previous Xiaomi was gone), so selection was unambiguous. Notch/cutout: none on this model; safe areas and full-bleed scenes both render correctly.

## 3. APK information

- **Type:** Release (`flutter build apk --release`). The release build falls back to **debug-key signing** when no release keystore is configured (`android/app/build.gradle.kts`), so it installs without store credentials.
- **Package:** `com.kindredpaws.kindredpaws` · **minSdk 24** (Flutter default) → API 28 is supported · targetSdk/compileSdk = Flutter defaults.
- **Size:** ~142.8 MB (universal, debug-keyed).
- **Renderer:** Impeller (Vulkan).
- **md5, three builds this sprint** (each verified on-device against local — no silent stale-install): before fixes `7356d23255deeb0d2b67fa6d0d6b0009` → first fix (`9b1c281`) `4c6dc0048a443347e3eb4bb7fe897f03` → **final refined build (`c4baacf`) `648d07d51544367f0cc9daea869e7841`** (reinstalled and re-walked; on-device md5 matched exactly).

## 4. Installation results

- `flutter clean` → `pub get` → `analyze --fatal-infos --fatal-warnings` (clean) → `flutter test` (all green) before building, per the mission.
- **Install succeeded on the first `adb install -r -t -g`** — output `Success`, no vendor restriction. This is a better outcome than the earlier MIUI device, which required a workaround.
- **md5 verified** on-device against local after each install (guarding the `adb install -r` silent-stale-install pitfall from the prior report); both matched exactly.
- Uninstall-first was used for a clean slate; a reinstall of the fixed build also matched md5.

## 5. End-to-end walkthrough

The complete required flow was executed on the device (53 screenshots archived under `screenshots/huawei_e2e/`, gitignored local evidence). Highlights with verified on-screen evidence:

- **Launch → Onboarding:** the four-beat Rescue Day arc ("A cold, rainy evening" → "You kneel down and reach out" → "A tiny tail gives a hopeful wag" → "Will you help?"), each with its own generated storybook art, rendered correctly.
- **Species selection → Adoption:** Puppy chosen → named "Biscuit" (pre-filled, 7/16) → "Welcome home" → Home.
- **Home:** Bond "Stranger → Friend", the **GE-1 "Today's kindnesses · 0/2" chip**, the **GE-3 décor button**, Heartmind speech, the vector puppy on the generated room interior, Feed/Clean/Play verbs.
- **Care loop (Home Feed):** Kibble 0→1, care-streak chip (🔥1 ❄️1), warm line "Biscuit gobbled it right up!".
- **Kitchen:** own generated pantry interior, the **GE-6 first-visit hint** ("Tap a food on the pantry shelf…") which dismissed on tap (GE-6), pantry feed (apple consumed, Kibble +1, item-specific line, fullness meter).
- **Bathroom:** own interior, **GE-2 ambient bubbles**, Quick rinse + Potty break (Kibble +1 each, "happy shimmy").
- **Bedroom:** own interior, **GE-6 tuck-in hint** (which correctly did NOT block the tuck-in button — the exact GE-7 fix), **GE-2 twinkling fairy-lights**. Tuck-in → **completed a GE-1 Daily Kindness (+12 Kibble)** → sleep with the **GE-2 held-sleep pose (eyes closed)** → Memory-Book dream "dreaming of chasing the ball" → gentle wake.
- **Play Garden:** own interior, **GE-2 butterfly ambient** + the **GE-2 garden-visitor songbird** (appeared after play, happiness ≥ 70). **All four GE-4 mini-games** played: **Starlight Trail** (full run + celebration + the GE-7 Listener hold-control fix confirmed — a drag-hold collected glimmers), Bounce, Snack Catch, Bubble Drift.
- **Care Corner:** own interior, Temp check + Cuddle (the cuddle **completed the second GE-1 Daily Kindness, +12 Kibble**).
- **Wardrobe:** own interior, closet + Boutique (cosmetics 250–450 with sticker art).
- **Grocery Store:** own interior, priced foods; **after the scroll fix, the Toy/Care/Décor sections are reachable** (Décor: Snuggle Rug 180, Herb Jars 60, Recipe Board 80, Duck Parade 40, Cloud Nightlight 100, Wildflower Jar 55). A purchase was validated (Crisp Apple, Kibble 38→28).
- **Décor (GE-3):** the decorate sheet ("Decorate · Play Garden", three slots, "Pieces for this spot live at the Grocery") rendered on the device.
- **Memory Book:** Our Story, Rescue, Favorites ("chasing the ball"), Our Bond, Growing Up.
- **Keepsakes:** the "Rescue Day" keepsake with share button.
- **Daily Kindnesses sheet (GE-1):** today's two — "A gentle cuddle ✓ Done" and "A garden romp · +12" — chip 1/2.
- **Seasons (GE-5):** the "Southern-hemisphere seasons" Settings toggle flipped the season (autumn ⇄ spring for this July date).
- **Settings:** Sound/Haptics/Notifications toggles, the GE-5 Seasons toggle, Delete-my-data (right-to-be-forgotten), About, licenses.
- **Profile ("Our story"):** portrait, Bond, Care streak, **Gotcha Day 2026-07-04** (correct real date), Days together, Rescue Day milestone.
- **Persistence:** **force-stop → reopen** restored Biscuit, **Kibble 12**, **kindness 1/2**, Bond, and greeted with a **memory callback: "I still think about how you like chasing the ball!"** — full state survived a process kill.
- **Monetization:** the paywall ("Become a Forever Friend", $5.99/mo · $39.99/yr Save 44%, ethical-wall note, Heartstone tiers, Rescue Bundles with transparent giving split) rendered with graceful Noop billing.

## 6. Every screen tested

Rescue-Day cold-open, 4 onboarding beats, species selection, naming, Home, Kitchen, Bathroom, Bedroom (awake + asleep-with-dream), Play Garden, the four mini-game screens (Starlight Trail, Bounce, Snack Catch, Bubble Drift) + celebration, Care Corner, Wardrobe, Grocery Store (all sections after the scroll fix), the Decorate sheet, the drawer, Memory Book, Keepsakes, the Daily-Kindnesses sheet, Settings, the Paywall/Shop sheet, and Profile ("Our story"). All rendered correctly at 1080×2280 / 480 dpi.

## 7. Every feature tested

Onboarding & adoption; the three care verbs; species-aware vector pet; care meters, Bond, care streak + warmth; **GE-1 Daily Kindnesses (both completed on device)**; **GE-2 tangible-state renderer, ambient room life, garden visitor, held-sleep pose, autonomous idle**; **GE-3 décor slots + decorate sheet + shop décor shelf (post-fix)** + the wishlist mechanism; **GE-4 all four mini-games + shared engine**; **GE-5 season engine + hemisphere toggle**; **GE-6 first-visit hints + camera intimacy + rhythm notifications**; inventory + economy (earn via care/games, spend via purchase); pantry/grocery/wardrobe/care shelves; sleep + persisted nap + dream; Memory Book + memory callback; Keepsakes + share affordance; notifications (real OS alarms); Settings toggles + right-to-be-forgotten; Profile; monetization paywall (graceful). Emotion reactions, transitions, particles, and haptics were exercised throughout.

*Not fully exercised on-device (bounded by a fresh save's economy):* buying a 250+ Kibble cosmetic to equip, and buying a 40+ Kibble décor piece to place — both are covered by the widget test suite (`wardrobe_room_test`, `decor_*_test`) and their UIs rendered on the device; only the grind to afford them was skipped.

*Correctly not shown:* the GE-2 low-need care cues (mussed coat / drowsy lids / peckish glance) did not appear — the pet's meters stayed high the whole session, which is exactly when those cues should be absent. The cue mapping is unit-tested (`care_cues_test`).

## 8. Huawei compatibility findings

- **Install:** clean, first-try, no EMUI "Install via USB" block (contrast the earlier MIUI device). `settings get secure install_non_market_apps` = 1.
- **Display / safe area / cutout:** no notch on this model; status bar and nav bar insets respected; full-bleed room scenes fill correctly; no clipped or overlapping UI at 1080×2280 / 480 dpi.
- **Gestures:** taps, drags (scrub, minigame joysticks), and swipes all worked. The one gesture issue found (nested-list scroll) was an app bug, not Huawei-specific — see §14.
- **Emoji / system font:** **Android 9 ships Emoji 11.0**, so several newer emoji the app used rendered as tofu boxes — a real cross-device bug (fixed, §15).
- **Notifications:** **real OS alarms scheduled** — `dumpsys alarm` shows two `RTC_WAKEUP` entries via `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver`, decoding to **2026-07-05 19:00 UTC** and **2026-07-07 19:00 UTC** (the evening-daypart presence notifications). On Android 9, `POST_NOTIFICATIONS` is not required (pre-13), so they are auto-permitted. This corrects the prior report's "no OS notification delivery".
- **Google Play Services:** present on this device, so the Firebase `AppMeasurement` GMS path does not fail the way it did on the GMS-less Redmi (still runs the mock stack at runtime; non-fatal either way).
- **Power management:** device on USB power throughout; no background-kill or Doze anomalies observed during the session; force-stop persistence verified.
- **Flutter engine:** Impeller/Vulkan renders correctly on this Mali-GPU Android-9 device; no rendering artifacts.

## 9. Performance metrics

- **Cold start (release, `am start -W`):** **TotalTime 1463 ms** (WaitTime 1533 ms) — well **under the 2500 ms budget**. This is the apples-to-apples release measurement the prior reports lacked (they only had debug builds at 3.2–4.0 s).
- **Warm reopen (after force-stop):** **786 ms**.
- **Frame pacing:** `dumpsys gfxinfo` reports a degenerate 3-frame window (100% "janky") — the known Impeller/Vulkan artifact recorded in both prior reports (Android's gfxinfo does not track the Impeller surface). On-device interaction was visually smooth across the entire ~1-hour session (50 captured states, all 8 rooms, 4 minigames); no visible jank, image-load stalls, or slow rebuilds.
- **Renderer:** Impeller (Vulkan), confirmed.

## 10. Memory observations

- **TOTAL PSS ≈ 98 MB** (release build) mid-session. This is far below the prior **debug-build** readings (~234–238 MB) and confirms the `cacheWidth` decode strategy holds even with the full generated-art set (rooms, ~38 stickers). No OOM/lowmem events in logcat. (A fresh session was used, so no long-run leak trend is claimed here; the prior report's ~15-min leak check on the older build showed a flat/decreasing trend.)

## 11. Battery observations

- Device on **USB power (charging)** throughout. Temperature read **45.0 °C** at end of a continuous ~1-hour intensive session (constant screencaps + scripted interaction while charging) — warm but within normal active-charging range, below thermal-throttle territory (typically 50 °C+). No abnormal heat, no runaway drain by design (the sim resolves on session resume, not on a wall-clock tick; notifications are OS-scheduled, not polled). A precise unplugged `batterystats` drain is a founder step.

## 12. Crash analysis

- **0 crashes.** No `FATAL EXCEPTION`, `signal 11`, `libc: Fatal`, or `E/AndroidRuntime` for the package across the entire session: onboarding, all rooms, all four mini-games, purchases, the decorate/paywall sheets, Settings, force-stop + reopen, and a full uninstall/reinstall cycle.

## 13. Logcat summary

- Cleared before the session and re-scanned after. **No `FATAL EXCEPTION`, `ANR in com.kindredpaws`, `signal 11`, `libc: Fatal`, `E/flutter`, or package `E/AndroidRuntime`.**
- Benign noise only (consistent with the prior reports): GMS `AppMeasurement` chatter, gralloc/Mali capability probes, EMUI system-service logs. Nothing app-fatal.

## 14. Bugs found

1. **[HIGH] Shop/closet lists un-scrollable → Toy/Care/Décor shelves unreachable.** In the Grocery Store (and Wardrobe), the item list would not scroll past the first section by finger. **Reproduced** on the device (three deliberate drag attempts; only the first ~1.5 rows were ever reachable). **Root-caused:** `ShelfGrid` is a `GridView.count(shrinkWrap: true)` with no `physics` override; nested inside the scrolling shop `ListView`, each grid's own scroll physics swallowed the vertical drag in its area, so the parent list never moved. The pre-existing scroll tests missed it because `scrollUntilVisible` drives the target `Scrollable` directly, bypassing the gesture arena a real finger hits. Impact: on this device the entire **Cozy Corners décor system (GE-3)**, plus buyable toys and care supplies, were unreachable from the shop.
2. **[MEDIUM] Post-Emoji-11 emoji render as tofu on Android 9.** Android 9 ships the Emoji 11.0 (2018) set; the app used several newer glyphs that show as missing-glyph boxes: 🤍 (Emoji 12.0), 🫧/🫙/🫐 (12.0/14.0), 🪢/🪶 (13.0). Seen on device in the bath clean feedback ("…fresh and happy □"), the Bubble Drift game card, and elsewhere. Because the app's `minSdk` is API 24 (Android 7.0), an even wider class of supported devices is affected.
3. **[HIGH, introduced-then-corrected] Over-broad first fix would clip standalone grids.** The initial fix set `NeverScrollableScrollPhysics` on `ShelfGrid` globally. An adversarial review (and independent inspection) caught that this would silently clip the bottom row of the *standalone* grids (kitchen pantry, play toys, care shelf) — where the grid is the only scrollable — on short screens or with a full inventory. Corrected before finalizing (see §15).

No other app defects were found. (One earlier-build regression — the sleeping pet's eyes reopening — was already fixed in a prior sprint and is validated fixed here: the held-sleep pose showed eyes closed on the device.)

## 15. Bugs fixed

1. **Shop/closet scroll (bug 1 + 3):** `ShelfGrid` gained a `nested` flag. When `nested: true` (only where it sits inside the shop/closet `ListView` — Grocery, Wardrobe) it uses `NeverScrollableScrollPhysics` so the drag falls through to the parent list; otherwise (standalone — Kitchen, Play, Care Corner) it keeps its own scroll so overflow rows stay reachable. **Re-verified on the device against the final refined build `c4baacf` (md5 `648d07d5`):** reinstalled, and a finger swipe over the Grocery grid scrolls the list all the way to the Cozy Corners décor shelf — Snuggle Rug 180, Herb Jars 60, Recipe Board 80, Duck Parade 40, Cloud Nightlight 100, Wildflower Jar 55 (screenshots `52`→`53`), the exact items that were unreachable before the fix. Guarded by a new behavioral test (`test/widget/shelf_scroll_test.dart`): a `tester.drag` over a nested grid scrolls the parent, and a standalone grid keeps scrollable physics.
2. **Emoji rendering (bug 2):** all post-Emoji-11 glyphs replaced with universally-supported (≤ Emoji 11.0) equivalents — 💛 for comfort hearts, 💗 for the "A Quiet Comfort" keepsake (distinct from the 💛 bond keepsake), 🛁/💧/💦 for bath/bubbles, 💜 for the lavender balm, 🧶/🎀/🍇 for the rope/wand/berry. A comprehensive codepoint scan confirms none remain in `lib/`. **Re-verified on the final build `c4baacf`:** the Bubble Drift game card shows 💧 (was a box), and the Home screen renders the 💛 "Today's kindnesses" chip and the 💧 Clean / 🧶 Play care verbs cleanly with no tofu (screenshot `51`).

Both fixes: **644 tests green, 0 analyzer issues**, release APK rebuilt (`c4baacf`, md5 `648d07d5`) + reinstalled (on-device md5 matched) + re-walked on the device with zero crashes. Cold start of this final build re-measured at **1.14 s** (`am start -W` TotalTime 1138 ms).

## 16. Remaining founder blockers

Unchanged from the standing ledger — all founder-owned, none introduced by this sprint:
1. **Merge** PR #66 (and the still-open #62/#65) — agent self-merge is harness-blocked.
2. **Rive rig commission** — the drop-in seam is ready; the vector renderer is the shipped stand-in.
3. **Provisioning** — Firebase, RevenueCat, Play Console, release signing keys (a real keystore replaces the debug-key fallback for store distribution).
4. **iOS** — macOS runner + Apple account.
5. **G3 legal review** (COPPA/GDPR-K) before public release.

## 17. CI evidence

- Local `just verify` green after every commit this sprint: **644 tests, 91.0 % line coverage (6114/6722 lines)** (threshold 60 %), **0 analyzer issues** (`--fatal-infos --fatal-warnings`).
- **PR #66 CI is fully green against the final HEAD commit `c4baacf`** — all 9 checks pass (`analyze`, `build-android`, `test`, `integration-android`, `dependency-scan`, `osv-scanner`, `sbom`, `secret-scan`, `workflow-hardening`), and the PR is `MERGEABLE`. Verified against `head_sha = c4baacf` (not a stale run); local `HEAD` = `origin/feature/genre-evolution` = `c4baacf`.

## 18. Commit hashes

| Hash | Commit |
|---|---|
| `9b1c281` | `fix(device): shop/closet lists scroll + Android-9 emoji render (Huawei E2E)` — the initial two fixes + regression test |
| `c4baacf` | `fix(device): narrow the ShelfGrid scroll fix to nested grids + strengthen guard` — parameterized `nested` (prevents the §14-bug-3 standalone clip), distinct comfort keepsake, behavioral drag test |

(The prior GE-1…GE-7 program commits `446ff2b…1db3232` are the build under validation.)

## 19. Repository state

- Branch `feature/genre-evolution` (PR #66). Working tree clean except the founder's untracked scratch files (`Talking_tom_mission.md`, `Untitled.svg`) and gitignored local evidence (`screenshots/huawei_e2e/`, `build/`, `.env`).
- `.env` present locally, gitignored, never committed.
- Save schema v10 (the GE build); no schema change this sprint.

## 20. Final production assessment

**Engineering validation on real Huawei / Android-9 hardware is complete and passes.** The app installs cleanly, boots fast (1.46 s release; 1.14 s re-measured on the final refined build), stays light (~98 MB), renders every room and system correctly, drives the full care loop and all GE-1…GE-7 features, schedules real OS notifications, and — most importantly — **persists across a process kill with a memory callback**, all with **zero crashes and zero ANRs**. Two genuine cross-device bugs (un-scrollable shop lists blocking the décor system; Android-9 emoji tofu) were found, fixed, and re-verified on the device — exactly the "find every real bug before users do" objective.

The remaining items are the standing **founder-owned** ledger (merge, Rive rig, provisioning, iOS, legal review). From the engineering side, on this second, older, different-vendor device, **KindredPaws is a production-quality, stable, cross-device virtual-pet experience.**

---
*Verified evidence only: device screenshots (`screenshots/huawei_e2e/`, 53 states, gitignored), `am start -W` timings, `dumpsys meminfo/alarm/battery/gfxinfo`, md5 digests, `just verify` output, and logcat scans from this session. Where a check could not be completed on-device (steady-state frame trace under Impeller; buying 250+ Kibble cosmetics), this report says so and points to the covering tests.*
