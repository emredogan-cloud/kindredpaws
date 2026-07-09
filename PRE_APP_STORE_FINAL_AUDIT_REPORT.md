# PRE_APP_STORE_FINAL_AUDIT_REPORT

**Project:** KindredPaws — emotionally intelligent AI virtual-pet game (Flutter · iOS + Android)
**Audit date:** 2026-07-08
**Audited ref:** branch `feature/genre-evolution` @ `36cd0b2` (unmerged; no release tag)
**Auditor stance:** independent App Store Review team + senior studio QA + principal UI/UX designer + accessibility auditor + security auditor + performance engineer + product manager. Adversarial by mandate. Previous decisions were not protected.
**Method:** full static audit of 149 Dart files (~22k LOC) + all product/engineering docs; live toolchain gate (`flutter analyze` + `flutter test --coverage`); a fresh debug APK build; real-device probe (Xiaomi/Android 13); firsthand review of on-disk rendered UI (goldens + 60+ device screenshots + E2E video). Remediation backlog: **`PRE_RELEASE_REMEDIATION_ROADMAP.md`** (issues KP-001…KP-052).

---

## 1. Executive Summary

KindredPaws is a **genuinely impressive, ethically disciplined, well-engineered *vertical slice*** that is **not** an App Store submission candidate. The mission framing — "assume this is the build submitted to Apple" — is, itself, the headline finding: **this build must not be submitted.** By the project's own gate criteria it is a **P2/closed-beta-grade** artifact, roughly **two full phases (P3 MVP + P4 soft-launch)** away from a legitimate store presence.

The engineering *craft* is high and verified firsthand: `flutter analyze --fatal-infos --fatal-warnings` is clean, **644 tests pass at 91.0% line coverage**, the save-migration chain is complete (v1→v10), the child-safety architecture is fail-closed and free of any live LLM, accessibility scaffolding is above genre norms, and secret hygiene is clean. The environment art is genuinely premium and the vector pet is clean and charming.

But **every commerce, identity, backend, ad, and AI-live integration in the shipping build is an inert stub running on mock/in-memory adapters.** There is no real cloud save, no working purchases, no ads, no analytics, no privacy policy URL, no iOS build, no commissioned character art, and no legal children's-privacy sign-off. On top of that, the audit found **12 traced engineering defects** — including three that can **silently and permanently destroy the player's pet** — and two flagship pillars (AI memory, premium economy) that are structurally under-wired (the "it remembers" feature reduces to ~2 facts; the premium Heartstone currency is unspendable).

An Apple reviewer would reject this build on **at least five independent blockers**. A studio QA lead would hold it on the data-loss bugs. A product manager would note the content exhausts in 2–4 weeks. None of this contradicts the team's own documentation — the phase reports never claim Apple-readiness; they correctly scope public launch as founder- and counsel-gated. The gap to shippable is **provisioning, legal, art, and content depth — not code quality.**

**Verdict: DO NOT SUBMIT. Strong foundation; not a launch candidate.**

---

## 2. Overall Product Score

Scored as "distance to a credible global App Store launch," not "quality of the vertical slice."

| Dimension | Score /10 | Note |
|---|---|---|
| Engineering quality & test discipline | **8.5** | Clean analyzer, 644 tests @91%, migration chain, strong architecture seams |
| App Store / store compliance readiness | **2.0** | ≥5 blockers; stubs advertised as live commerce/charity |
| Privacy & security hygiene | **7.5** | Excellent posture; policy URL + iOS privacy manifest missing |
| Accessibility | **6.5** | Great reduced-motion/semantics; no l10n, no dark mode, dynamic-type clipping |
| Performance (as measurable) | **6.5** | Clean budgets; unverified on device; heavy backgrounds |
| Gameplay depth & retention | **5.0** | Lovely core loop; exhausts in weeks; flagships under-wired |
| Visual design | **6.5** | Premium backgrounds undercut by emoji hero surfaces |
| Character | **6.0** | Charming vector pet; no commissioned rig; sounds the same for months |
| Economy | **4.0** | Dead premium currency, uncapped faucet, surplus by month 2 |
| Data safety / no-pet-loss guarantee | **3.0** | The core promise is defeated by 3 traced data-loss paths |
| **Overall launch readiness** | **≈3.8 / 10** | High-quality slice; far from submittable |

---

## 3. Engineering Review

**Strengths (verified firsthand).** The codebase is clean and disciplined. `flutter analyze --fatal-infos --fatal-warnings` → *"No issues found."* `flutter test --coverage` → **644 pass, 91.0% (6114/6722).** Architecture uses clear seams (`PetRenderer`, `BillingService`, `BackendService`, `NotificationScheduler`) with production swaps in `main.dart`; the mock/in-memory defaults keep CI hermetic. The migration framework (`MigrationRunner` + v1→v10 steps) is a genuine asset, and unknown item/species ids deserialize inert. The Rive renderer degrades cleanly on every failure mode. `Wallet.spendKibble`/`Inventory.consume` refuse underflow. No unguarded force-unwrap crash was found on a live UI path.

**Weaknesses.** (1) The entire provisioning stack (Firebase/RevenueCat/AdMob/Auth) is inert and — critically — the **Firebase runtime path is never CI-exercised** (self-flagged, PHASE5 §17); the service-rebind fix on the Firebase swap is in-memory-tested only [KP-050]. (2) **iOS has never been built** (Linux host) [KP-005/048]. (3) Save deserialization is inconsistently defensive — some fields default safely, adjacent fields use hard casts — producing data-loss paths [KP-010]. (4) 18 dependencies are behind newer versions (constrained; `rive` intentionally pinned to 0.13) — acceptable but track. (5) The audited work sits on an **unmerged feature branch with no tags**, and the declared SSOT is stale [KP-013].

---

## 4. App Store Review Findings

Simulating Apple App Review against the current guidelines, this build **would be rejected.** The compliance *engineering* is strong (account deletion, PII hygiene, child-safe AI, no pay-to-win), but the submission surface advertises live purchases, subscriptions, and charity impact that the build cannot perform.

- **Guideline 2.1 / 2.2 (completeness/beta):** commerce/identity/backends inert; release notes say "closed beta"; shipped strings say "walking skeleton." [KP-002, KP-012]
- **Guideline 3.1.1 / 3.1.2 (IAP/subscriptions):** RevenueCat stubbed, `purchases_flutter` not a dependency; paywall advertises $5.99/mo·$39.99/yr + bundles that no-op; no auto-renew terms or Terms/Privacy links at point of sale. [KP-002, KP-003]
- **Guideline 3.1.1 (unspendable currency):** Heartstone bundles are purchasable but nothing accepts Heartstones. [KP-007]
- **Guideline 3.2.1 (fundraising):** store copy + paywall claim "a share of net revenue funds vetted shelters … transparent, dated impact," but the pledge is a v0.1 draft with no intermediary, no partners, and a ledger that throws. [KP-006]
- **Guideline 5.1.1 (data collection & privacy):** no privacy-policy URL anywhere; App Privacy label cannot be completed truthfully against the stubbed posture. [KP-004]
- **Guideline 5.1.1(v) (account deletion):** **PASS** — fully implemented, reachable in Settings, double-confirmed, tested.
- **Guideline 1.3 / 5.1.4 (kids):** no age gate; "child-safe for everyone" claimed while ads/IAP/AI ship; the binding child-directedness determination is an unfinished legal action. [KP-009]
- **Privacy manifest:** no `PrivacyInfo.xcprivacy` (mandatory). [KP-005]
- **Guideline 2.3.3 / 2.3.7 (metadata):** no screenshots or app icon. [KP-008]

---

## 5. Potential Rejection Reasons (ranked)

1. **No functional purchases / subscriptions** (fake or dead buy buttons) — 3.1.1/3.1.2. [KP-002/003]
2. **No privacy policy URL** — 5.1.1. [KP-004]
3. **Missing iOS privacy manifest** (and never-built iOS) — privacy-manifest requirement. [KP-005]
4. **Unsubstantiated charity claims** — 3.2.1 + consumer-protection. [KP-006]
5. **Unspendable purchasable currency** — 3.1.1. [KP-007]
6. **No screenshots/icon** — 2.3.x. [KP-008]
7. **Presents as beta/incomplete** — 2.1/2.2. [KP-012]
8. **Kids-policy/age-rating unresolved** — 1.3/5.1.4 (also a regulatory, not just review, risk). [KP-009]
9. **Sign in with Apple absent** if any third-party login is later added (currently guest-only). [KP-011]
10. **ATT/AdMob not pre-wired** — surfaces when ads activate (5.1.2). [audit §7]

---

## 6. Security Review

**Posture: strong.** Firsthand checks: no hardcoded API keys, tokens, or private keys in tracked source; `lib/firebase_options.dart` is gitignored/untracked; the committed `android/app/google-services.json` is a CI placeholder (`project_number 000000000000`, `current_key: ci-build-placeholder-not-a-real-key`) — **no secret leak**; `.gitignore` comprehensively covers keystores, `key.properties`, `.env`, and both Firebase config files; no cleartext `http://` in `lib/`; a dedicated `security.yml` CI workflow exists. The client **never calls Anthropic directly** — dialogue is fully on-device; only a `anthropicProxyConfigured` flag exists for a deferred, server-mediated live-chat path. Android permissions are minimal (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`) with no camera/mic/location.

**Caveats.** Because the backend is unprovisioned, the **real Firestore security rules and server-side validation cannot be audited** (they don't run) — this must be reviewed when the backend goes live (anti-fraud mint-gating, receipt validation, attestation per the tech spec). The deferred live-LLM path will need proxy-side authz/rate-limit/moderation hardening before it is ever enabled (it is off and double-gated today).

---

## 7. Privacy Review

The **data posture is thoughtful and honest.** `store/privacy/data_safety.md` is a credible source-of-truth: minimal PII, no behavioral/cross-app ad targeting, on-device-only (deferred) voice, and a right-to-be-forgotten path. Analytics sinks strip `blockedKeys` (PII) in both the local and Firebase paths; native auto-collection is disabled until gated; the single free-text surface (pet name) is PII/profanity-filtered at the persistence boundary; no free-text is stored from minors. Account deletion wipes local save, resets analytics identifiers, and best-effort triggers a server cascade.

**Gaps for submission.** (1) No hosted privacy policy / support URL [KP-004]. (2) No iOS privacy manifest declaring required-reason API usage (e.g. `UserDefaults` via `shared_preferences`) [KP-005]. (3) The data-safety draft describes cloud save + RevenueCat receipts that the current build doesn't actually perform — the App Privacy label must be filled against the **provisioned** build, not the stub, to stay truthful. (4) The children's-privacy determination (COPPA/GDPR-K) that governs the whole label is unfinished [KP-009].

---

## 8. Accessibility Review

**Above genre norms.** 21 files use `Semantics`; icon-only buttons carry tooltips; decorative emoji/images are consistently excluded from semantics; the paywall status is a live region; the Care ring exposes coarse *kind* labels ("would love some care") rather than raw numbers. **Reduced-motion is respected system-wide** — the `AmbientScene.motionEnabled` master switch is `&&`-gated by `MediaQuery.disableAnimations` across the pet renderer and ambient layers (exemplary). Touch targets are compliant (IconButtons 48dp, care buttons 84px, dock chips ~64×66). **Color is never the sole signal** (need = arc length + alpha; mood = copy + pose).

**Gaps.** No localization infrastructure at all (English hardcoded; ~38 UI literals + hundreds of corpus lines) [KP-041]. No dark mode / no system-theme response despite explicit bedtime use [KP-042]. Dynamic Type clips warm copy at large sizes (fixed heights + `maxLines`+ellipsis; no clamp) [KP-043]. A few small-text contrast pairs are borderline ~4.5:1 and need AA verification [KP-044]. Reduced-motion isn't offered inside minigames [KP-045]. Dock labels at 9.5pt are below comfortable legibility [KP-028].

---

## 9. Performance Review

**What's good.** Performance budgets are a clean SSOT (`performance_budgets.dart`): cold start <2.5s, 16ms/frame (60fps), ≤150ms reaction beat, enforced by host-side perf tests that pass. Large PNGs are decoded with `cacheWidth/Height`. The render sweep test bounds mood×emotion cost.

**What's unverified / concerning.** This audit **could not profile on a physical device** — the connected Xiaomi blocked install via MIUI's `INSTALL_FAILED_USER_RESTRICTED` gate, so real frame pacing, memory-over-session, and battery are unmeasured on the current branch [KP-047]. Host-side budgets are not on-device budgets. **Assets total 70MB with 8 background PNGs at ~3MB each (29MB)** — the release AAB size is unmeasured and likely large without WebP/AVIF conversion [KP-046]. The debug APK measured 253MB (expected for debug; not indicative of release). The existing Huawei report validated a *release* APK on Android 9, but pre-GE-7.

---

## 10. Gameplay Review

**The core loop is lovely and the cozy design is best-in-class.** Rescue Day → name → starter kit → 8 rooms → feed/clean/play (diminishing returns) → comfort → dress-up → décor → 2 daily kindnesses → a minigame → tap-for-idle-chatter → shop. The first 30 minutes are warm and well-paced; there are honest reasons to return tomorrow (daily +50, fresh kindnesses, streak). Care-meter balancing is excellent (floor 15 = no death, 8h grace, 7-day catch-up cap, gentle decay: one daily visit suffices, never nagging). **Neglect-guilt is genuinely forbidden and the design holds** — "longing not guilt," forgiving streak with auto-warmth, non-punitive repair. This is a real differentiator; protect it.

**Where it thins (fast).** Content exhausts in **~2–4 weeks**: growth is terminal at Grown (Companion bond + 28 active days); Bond continues to Kindred (~73 days) and Soulmate (~182 days) but those stages **unlock nothing tangible** [KP-036]. Total content: 2 species, 8 rooms, 38 items, **4 shallow 45s no-fail minigames** (no depth/progression [KP-039]), 12 evergreen + 8 seasonal kindnesses. Minute-to-minute is identical from day 2. The aspirational ladder past month 1 is a label change.

---

## 11. UX Review

**Onboarding/first impression** is strong: a 60–90s, no-account, no-tutorial-wall cold-open over genuinely atmospheric art with warm copy. **Navigation** is the right model — a swipeable `PageView` + floating room dock, no route pushes, no dead ends, honest "coming soon" for locked doors. Empty states are handled with dedicated illustrations + warm copy.

**Problems.** (1) The **notification permission is requested at cold boot, before onboarding** — spending the one prompt over the emotional peak, tanking grant rate [KP-023]. (2) **No load-failure/timeout/retry state** — a hung `controller.load()` strands the user on a bare spinner [KP-024]. (3) The sideways-scroll world isn't discoverable on first run [KP-026]. (4) Onboarding has no skip/back for repeat users [KP-025]. (5) Structural consistency debt: **96 hardcoded hex + ~38 ad-hoc font sizes** because theme tokens are private [KP-027] — this also blocks dark mode.

---

## 12. UI Review

The UI system is warm, clean, and coherent where it uses the theme: rounded cream cards, generous spacing, friendly type, a consistent peach/brown palette. Cards, sheets, and the dock read as one design language. The care ring and mood visuals are tasteful and legible.

The recurring UI weakness is **enforcement, not taste**: the palette lives as private constants, so screens re-hardcode colors and sizes, guaranteeing drift and blocking theming (dark mode, dynamic type). Consolidating into a public token set (`ThemeExtension`/`KpColors` + named text styles) is the single highest-leverage UI-hygiene fix [KP-027], and it unblocks KP-042/043/044.

---

## 13. Visual Design Review

**The most important nuance in this audit:** the app is **not uniformly cheap** — it is **inconsistent**. The environment/illustration art is genuinely **premium**: the rainy-cottage onboarding backgrounds and the painterly "forever home" rug are atmospheric, expensive-looking AI art (8 backgrounds, ~29MB). Against that, the **hero interactive/character surfaces render as flat OS emoji** — the species-choice cards are 🐶🐱, Keepsake cards are one emoji on a peach rectangle (while the designed `keepsake_template.png` sits unused), and the Profile portrait is a raw emoji [KP-029]. Seeing the premium rug sit directly above two OS emoji at the emotional peak of adoption is jarring and reads as prototype. Minigames are visibly programmer-art (geometry + emoji) [KP-031], and there is **no background music** (10 SFX only) [KP-032]. Fixing the three emoji hero surfaces + adding music would raise the *perceived* production value dramatically for modest effort.

---

## 14. Character Review

The pet is the product, and here the finding is bittersweet. The **vector pet is clean, cohesive, and genuinely cute** — 12 emotion poses, mood cross-blends, deterministic blink, care-cue smudges — a legitimate, hand-authored `CustomPainter` character that is *good enough to ship as the character*. But: (1) **there is no commissioned rig** — `assets/rigs/` contains only a README, no `.riv`; the "living companion" promise rests on art that doesn't exist, and the Rive fallback with no asset is a Material icon labeled "rive" [KP-030]. (2) More damaging to the *character*, the pet **sounds identical from day-1 stranger to 6-month soulmate**, puppy or grown, playful or cuddly, because the bond/life-stage/personality dialogue buckets are shadowed by the selector's mood weighting [KP-035], and the evolving `personality.dart` produces no audible change. A character you raise for months should visibly and audibly grow with you; today it changes pose set at day 28 and little else.

---

## 15. Economy Review

The three-currency design (Kibble/Heartstones/Compassion Coins) is sound on paper but **broken in the build**:
- **Heartstones are a dead currency** — buyable in $1.99–$19.99 bundles, but nothing accepts them (`wallet.dart` has only `spendKibble`; no `ItemDef` has a Heartstone price). Real money → an unredeemable number [KP-007]. This is both an economy failure and a likely rejection.
- **Kibble is an uncapped faucet** — "play" mints 5 Kibble/tap forever (meter floor 15 > cost 10 makes "willing" permanently true), with no diminishing and no daily cap; shop items are trivially farmable [KP-014].
- **Kibble goes to surplus by month 2** — faucets never close; the entire ~4,160-Kibble non-consumable catalog is affordable in ~6–8 weeks from the daily bonus + kindnesses alone, after which only cheap consumables remain as a sink [KP-037].
- **Compassion Coins are inert** — minted server-side but with no in-game sink or display [KP-038].
- **Time-travel farming** — any device-clock change grants the daily bonus, greeting Bond, and growth day [KP-015].

Net: there is no long-term economic tension, and the premium purchase loop is non-functional.

---

## 16. Retention Review

**Day 1–7 is warm.** Streak (forgiving), daily +50, fresh kindnesses, seeded memory, keepsake scrapbook, and a growing pet give honest reasons to return. The never-guilt discipline protects the highest-LTV personas.

**Day 30+ is weak.** The single highest-retention lever — AI memory — reduces to ~2 facts and ~12 lines [KP-034]; the pet's voice doesn't evolve [KP-035]; growth stops at day 28 and bond stages unlock nothing [KP-036]; notifications are ~15 templates that will feel same-y [KP-040]. The project's own worst-case ("if AI memory disappoints, D30 → ~5–6%") is the realistic case for this build until R5 lands. Retention risk is **content depth**, not core-loop quality.

---

## 17. Notification Review

**Design intent is excellent** — a hard 2/day cap, rhythm-aware anchors, kill-switchable, warm and never-guilt templates gated by an SSOT and a guilt-language validator. **Execution has bugs:** (1) all notifications fire at **UTC, not local time** (`tz.local` never set) — a "10am hello" arrives at 2am for a US-Pacific user [KP-016]; (2) re-arming daily presence on resume **cancels queued celebration/streak notifications** before they fire [KP-017]; (3) day boundaries use UTC midnight [KP-018]; (4) the permission prompt is mistimed to cold boot [KP-023]. Content is also thin (~15 templates) and can't yet reference a real memory [KP-040]. These are high-value fixes because notifications are the cheapest retention lever.

---

## 18. AI Companion (Heartmind) Review

**Architecturally exemplary for safety and cost.** The companion is a fully **on-device templated bank** — no live LLM, `$0` runtime tokens, no network in the dialogue path; generative chat is globally off and double-gated; self-harm routes to a static crisis line; the only free-text surface (pet name) is filtered; the `claude-haiku-4-5` identifier is a deferred, unused constant. The ≥95% callback-reliability harness (G2) genuinely proves zero hallucination.

**But the feature is thin where it counts.** Reliability is measured over a **near-empty fact set** — only `importantDate` and `likesActivity` are ever created; there's **no fact-capture mechanism**, so 15 of 27 slot callback-lines are permanently unfillable [KP-034]. The corpus is ~430 lines against a ≥1000 target, and ~45% is unreachable because the selector shadows bond/life/personality buckets [KP-035]. Within-session repetition is genuinely low (10–20 lines per mood), so it holds up for a session — but the "it remembered me" and "only my pet would say this" promises, the entire emotional differentiator, do not land past a few days. **Fixable without new corpus** by capturing 1–2 real facts and re-weighting the selector.

---

## 19. Real Device Findings

**Environment:** a Xiaomi (Redmi, Android 13 / SDK 33) device was connected; the toolchain (`flutter`/`adb`/`just`) is fully available. A fresh **debug APK built successfully** (253MB debug). **Installation was blocked by MIUI** (`INSTALL_FAILED_USER_RESTRICTED` — the Xiaomi "Install via USB" security gate requiring manual developer opt-in), so a live on-device walkthrough of the current branch was not possible in this session [KP-049]. Notably, the device already has the real competitor installed (`com.outfit7.mytalkingtom2`).

**Evidence used instead:** firsthand review of on-disk rendered UI — Linux goldens (`test/golden/goldens/*`) and 60+ real-device screenshots (`screenshots/device_final/*`, `screenshots/huawei_e2e/*`, `artifacts/ui/*`) plus an E2E video. These confirm: premium backgrounds, a clean/cute vector pet, working room flow, and the emoji hero-surface problem (verified visually on the species-choice screen). The prior **Huawei P20 Lite / Android 9** report validated a release APK end-to-end (with a real emoji-render fix and MIUI/scroll fixes), but **pre-GE-7**. **iOS has never been built or run on any hardware** [KP-005/048]. On-device performance and OEM background-kill behavior (which interacts with the notification bugs) remain unverified on the current branch [KP-047].

---

## 20. Competitive Analysis

Against the modern cozy/virtual-pet bar (My Talking Tom, Pou, Finch, Nintendogs) — comparing to expectations, not copying:

| Axis | KindredPaws today | Genre bar | Gap |
|---|---|---|---|
| Interaction richness | Feed/clean/play + comfort + décor + 4 minigames | Rich mini-game suites, mini-economies | **Behind** — shallow minigames, thin mid-game [KP-036/039] |
| Character craft | Clean vector pet, no rig | Polished animated hero (3D/Live2D) | **Behind** on fidelity; **ahead** on cost discipline [KP-030] |
| Emotional attachment | Memory + presence + never-guilt (best-in-class *intent*) | Mostly shallow | **Ahead in design, behind in delivery** [KP-034/035] |
| Comfort / non-predatory | No-death floor, forgiving streak, no guilt | Often manipulative | **Clearly ahead** — a real moat |
| Accessibility | Reduced-motion + semantics strong; no l10n/dark | Usually mediocre | **Mixed** — ahead on motion, behind on l10n/dark [KP-041/042] |
| Retention depth | Warm week 1, thin month 2 | Deep live-ops | **Behind** [KP-036] |
| Real-world impact | Donation *promise* (not operational) | None | **Unique — if made real** [KP-006] |
| Store-readiness/polish | Emoji hero surfaces; stubs | Finished | **Behind** [KP-029] |

**Where KindredPaws can win:** comfort/non-predatory design, emotional-attachment *intent*, and real-world impact — but only if memory delivers (R5) and the donation loop becomes real (R1/KP-006). Where it's weakest: character fidelity, mid/late-game depth, and finished-product polish.

---

## 21. Every Bug Found

Traced engineering defects (full detail + fixes in the roadmap):

| # | Bug | Severity | Roadmap |
|---|---|---|---|
| 1 | Corrupt/partial save → orphaned pet, then overwrites recoverable blob; `restoreFromCloud` never called | DATA-LOSS | KP-010 |
| 2 | Newer-schema (downgrade) save treated as unrecoverable → wipe | DATA-LOSS | KP-010 |
| 3 | Unguarded casts (`lastSimTimestampMs`, meter keys) → one missing field = total pet loss | DATA-LOSS | KP-010 |
| 4 | "Play" mints 5 Kibble/tap forever; no cap/diminish | ECONOMY | KP-014 |
| 5 | Device-clock change farms daily bonus / greeting Bond / growth | ECONOMY/LOGIC | KP-015 |
| 6 | All notifications fire at UTC, not local time | LOGIC (retention) | KP-016 |
| 7 | Daily-presence re-arm cancels queued celebration/streak notifications | LOGIC | KP-017 |
| 8 | Day/streak/season boundaries use UTC midnight | LOGIC | KP-018 |
| 9 | Care streak counts a backward day-gap as consecutive | LOGIC | KP-019 |
| 10 | `_persist` snapshot/widget write unguarded → unhandled async error | ROBUSTNESS | KP-020 |
| 11 | Offline catch-up stranded if background yields only `hidden` | LOGIC | KP-021 |
| 12 | `V3ToV4` migration non-idempotent; runner allows duplicate `fromVersion` | LATENT | KP-022 |

Plus the "dead Heartstone currency" (KP-007) and "auth throws UnimplementedError" (KP-011), which are architectural/economy defects as much as bugs.

---

## 22. Every Weakness Found (consolidated)

**Blockers/compliance:** mock backend [KP-001]; stub IAP/subs [KP-002]; missing POS disclosures/links [KP-003]; no privacy/support URL [KP-004]; no iOS build/privacy manifest [KP-005]; live charity claims w/o backing [KP-006]; dead Heartstones [KP-007]; no screenshots/icon [KP-008]; unresolved kids/legal [KP-009]; silent pet-loss [KP-010]; guest-only auth [KP-011]; beta/skeleton framing [KP-012]; stale SSOT/three roadmaps/unmerged branch [KP-013].
**Bugs/economy:** KP-014…KP-022 (above).
**UX:** permission timing [KP-023]; no load-failure state [KP-024]; no onboarding skip/back [KP-025]; swipe discoverability [KP-026]; 96 hardcoded hex/38 font sizes [KP-027]; 9.5pt dock labels [KP-028].
**Visual/character:** emoji hero surfaces [KP-029]; no rig / icon fallback [KP-030]; programmer-art minigames [KP-031]; no music [KP-032]; near-empty cosmetics shop [KP-033].
**Gameplay/AI/economy depth:** memory ~2 facts [KP-034]; shadowed/undersized corpus [KP-035]; content exhausts / dead bond stages [KP-036]; Kibble surplus [KP-037]; inert Compassion Coins [KP-038]; shallow minigames [KP-039]; thin notifications [KP-040].
**Perf/a11y/l10n:** no l10n [KP-041]; no dark mode [KP-042]; dynamic-type clipping [KP-043]; contrast AA [KP-044]; minigame reduced-motion [KP-045]; unmeasured size [KP-046]; unverified on-device perf [KP-047].
**Launch validation:** iOS unvalidated [KP-048]; Android/MIUI matrix [KP-049]; provisioned smoke [KP-050]; store dry-run [KP-051]; G3/G4 KPIs [KP-052].

---

## 23. Launch Readiness Score

**Launch readiness: ≈3.8/10 — NOT READY. Two phases (P3+P4) of the project's own roadmap remain.**

| Gate | State | Blockers |
|---|---|---|
| Buildable for iOS | ❌ | KP-005/048 |
| Store-submittable (Apple) | ❌ | KP-001–009, 012 |
| Non-destructive to user data | ❌ | KP-010 |
| Functional monetization | ❌ | KP-002, 007, 011 |
| Legally cleared (kids/donation) | ❌ | KP-006, 009 (founder/counsel) |
| Engineering quality/tests | ✅ | — |
| Privacy/security hygiene | ✅ (bar URL/manifest) | KP-004/005 |
| Accessibility baseline | ⚠️ | KP-041/042/043 |
| Content depth for D30 | ❌ | KP-034/035/036 |
| Validated on real devices | ⚠️ (Android pre-GE-7 only) | KP-047/048/049 |

---

## 24. Founder-only Blockers

These cannot be resolved by engineering alone and gate a legitimate submission:

1. **Children's-privacy legal determination + sign-off** (COPPA/GDPR-K/store kids policy). Existential (R1); drives store category, ad config, parental gating, PII rules. [KP-009]
2. **Donation operationalization** — choose intermediary + partner shelters + net %, or remove all impact claims until live (open decisions #4/#5; legal). [KP-006]
3. **Apple toolchain + hardware** (macOS/Xcode/iPhone) — the current host is Linux; iOS has never been built. [KP-005/048]
4. **Commercial provisioning** — real Firebase, RevenueCat, AdMob, store products, signing credentials. [KP-001/002]
5. **Rig commission + 2nd-species ship/cut** (open decision #2; art budget). [KP-030]
6. **Soft-launch geos + subscription pricing** (open decisions #7/#8) and the go/no-go on live-LLM for adults (#10). [KP-052]

---

## 25. Final Recommendation

**Do not submit this build to the App Store.** It would be rejected on at least five independent grounds, and — worse than rejection — it can silently destroy a player's pet (KP-010) and advertises purchases and charity impact it cannot deliver. Submitting now would risk a rejection record, a data-loss reputation, and (on the kids/donation axes) regulatory exposure.

**But do not read this as a failing project.** KindredPaws is a **high-quality, ethically distinctive vertical slice** with genuinely strong engineering discipline, a best-in-class comfort/never-guilt design, premium environment art, and a safety/privacy posture most shipped games never reach. The distance to launch is **provisioning, legal, art, and content depth — not a rewrite.**

**Recommended path:**
1. **Founder-only track (start immediately, long lead):** legal sign-off (KP-009), donation decision (KP-006), Apple environment (KP-005), provisioning accounts (KP-001/002), rig/art commission (KP-030/033).
2. **Engineering track (start now, parallel):** R1 data-loss + compliance wiring and R2 bug fixes — none of these need the founder track.
3. **Then** R3 UX → R4 visual → R5 content/AI depth (the retention unlock) → R6 perf/a11y/l10n.
4. **Finally** R7: validate the provisioned, art-complete build on a real iOS + Android matrix, run the provisioned smoke (KP-050), complete the store listings (KP-051), and clear the project's own **G3 then G4** gates on live cohorts before global launch (KP-052).

Ship the roadmap in order; hold at each gate; keep the comfort-first soul intact. **Target a submission only after Phase R7's Definition-of-Done holds — not before.**

*Companion backlog: `PRE_RELEASE_REMEDIATION_ROADMAP.md` (KP-001…KP-052). Audit is documentation-only; no source files were modified.*
