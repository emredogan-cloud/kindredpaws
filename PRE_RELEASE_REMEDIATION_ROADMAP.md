# PRE_RELEASE_REMEDIATION_ROADMAP

**Project:** KindredPaws (Flutter · iOS + Android)
**Audit date:** 2026-07-08
**Audited ref:** branch `feature/genre-evolution` @ `36cd0b2` (unmerged; no release tag)
**Toolchain reality at audit:** `flutter analyze --fatal-infos --fatal-warnings` clean · `flutter test` 644 pass · 91.0% line coverage · save schema v10
**Companion report:** `PRE_APP_STORE_FINAL_AUDIT_REPORT.md`

---

## How to read this roadmap

This is the single, complete remediation backlog produced by the pre-App-Store audit. It contains **every** improvement discovered, grouped into **seven sequential execution phases (R1→R7)**. Do not start a later phase until the earlier phase's Definition-of-Done holds, with one exception: R4/R5 art & content work may be commissioned in parallel with R1/R2 because it has long lead time (see dependencies).

**Severity scale:** `BLOCKER` (cannot ship / will be rejected) · `HIGH` (must fix before public launch) · `MED` (fix before scale) · `LOW` (polish / debt).
**Complexity:** `S` (≤1 day) · `M` (2–5 days) · `L` (1–3 weeks) · `XL` (>3 weeks / external dependency).

Each issue carries: Severity · Description · Reason · Recommended solution · Complexity · Dependencies · Risk · Expected user impact · Testing required · Acceptance criteria · Definition of Done.

> **Governing finding (read first).** By KindredPaws' *own* gates, this build is a **P2 vertical-slice / closed-beta-grade** engineering artifact, not a store candidate. A legitimate store presence is **G3 (MVP/closed beta)** and public launch is **G4 (soft launch)** — both `planned`, both requiring provisioned commerce/backends, a binding children's-privacy legal sign-off, and live retention data that do not yet exist. Every commerce, identity, backend, ad, and AI-live integration in the shipping build is an **inert stub running on mock/in-memory adapters**. The engineering *discipline* is genuinely high (green CI, 91% coverage, exemplary child-safety and accessibility scaffolding); the gap to "submittable" is provisioning, legal, art, and content — not code quality. **Do not submit the current build.**

---

# PHASE R1 — Critical App Store & Launch Blockers

*Goal: make the build legally submittable and non-destructive. Nothing in R2–R7 matters until R1 holds. No submission may occur before every R1 item's DoD is met AND the founder-only blockers in the audit report are cleared.*

### KP-001 — Shipping build runs entirely on mock/in-memory backend (no cloud save, auth, analytics, Crashlytics, Remote Config)
- **Severity:** BLOCKER
- **Description:** `main.dart` activates the real Firebase stack only when `FirebaseProvisioning.isProvisioned` is true; the committed `android/app/google-services.json` is a CI placeholder (`project_id: kindredpaws-ci-placeholder`, `current_key: ci-build-placeholder-not-a-real-key`), and `lib/firebase_options.dart` is gitignored/absent, so the app falls through to mock adapters. Cloud save, auth, analytics, Crashlytics, and Remote Config are all inert.
- **Reason:** The product's #1 catastrophic risk (R4: "losing the pet = refund + 1-star") is mitigated by "authoritative versioned cloud save." With mock backend, the pet lives only in local `SharedPreferences`; reinstall or device loss destroys it. Analytics/Crashlytics needed for the G3 crash-free ≥99% gate are not recording.
- **Recommended solution:** Provision a real Firebase project; run `flutterfire configure` for both platforms; commit nothing secret (keep `firebase_options.dart` gitignored, inject via CI). Set the release build to `KP_FIREBASE_PROVISIONED=true`. Exercise the real path end-to-end (see KP-050).
- **Complexity:** L (founder credential + integration work)
- **Dependencies:** Firebase account; CI secret injection; KP-050 (runtime-path validation).
- **Risk:** Firebase runtime path is **never CI-exercised** (self-flagged in PHASE5 §17) — first real activation may surface init/order bugs. Rollback: `KP_FIREBASE_PROVISIONED=false` reverts to mock.
- **Expected user impact:** Without fix: silent, permanent pet loss on reinstall — brand-defining negative reviews. With fix: durable pet + working restore.
- **Testing required:** Integration test on device with real project; cold-start with/without network; sign-out/sign-in restore; forced-kill mid-write; Crashlytics receives a test crash; analytics dashboard receives funnel events.
- **Acceptance criteria:** Fresh install → adopt → reinstall → same pet restored from cloud. Crash-free rate visible in console. Zero secrets in git history.
- **Definition of Done:** Real backend live in release config, restore proven on ≥2 devices, secret-scan CI green, PHASE5 §17 caveat retired with evidence.

### KP-002 — In-app purchases & subscriptions are non-functional stubs
- **Severity:** BLOCKER (Apple 2.1, 3.1.1, 3.1.2 / Play equivalents)
- **Description:** `NoopBillingService` fakes purchases in memory (flips `foreverFriends` locally, no store transaction); `RevenueCatBillingService` is inert (`isProvisioned => false`, `purchase()` returns cancelled, `restore()` returns `Entitlements.none`); `purchases_flutter` is not even in `pubspec.yaml`. The paywall advertises $5.99/mo · $39.99/yr + Heartstone/Rescue bundles that silently no-op.
- **Reason:** Apple rejects apps with non-functional or fake purchase buttons, and any real revenue requires StoreKit/Play Billing via the store. Store products aren't created (`store/checklist.md`).
- **Recommended solution:** Add `purchases_flutter`; wire `RevenueCatBillingService` to real entitlements; create products in App Store Connect / Play Console; validate receipts server-side (KP-001).
- **Complexity:** L
- **Dependencies:** KP-001 (entitlement persistence), RevenueCat account, store product setup, KP-003.
- **Risk:** Entitlement/restore edge cases; sandbox vs prod behavior. Mitigate with StoreKit/Play sandbox testing.
- **Expected user impact:** Purchases actually grant entitlements and survive reinstall; today they do nothing.
- **Testing required:** Sandbox purchase of each SKU; restore on a second device; subscription renewal & cancellation; refund/clawback path.
- **Acceptance criteria:** Every listed SKU completes a real sandbox transaction and grants the correct entitlement; restore rehydrates entitlements.
- **Definition of Done:** No stub billing in release; all SKUs transact in sandbox; restore verified; disclosures (KP-003) present.

### KP-003 — Subscription point-of-sale disclosures & Terms/Privacy links missing
- **Severity:** BLOCKER (Apple 3.1.2)
- **Description:** The paywall shows price + `/mo`·`/yr` but not the auto-renewal terms, "billed to your Apple ID/Google account," renewal/cancellation language, or **functional links to the EULA/Terms of Use and Privacy Policy at the point of sale.** A repo-wide search finds zero Terms/Privacy links in `lib/`.
- **Reason:** Apple 3.1.2 requires all of these adjacent to the purchase control; omission is an automatic rejection.
- **Recommended solution:** Add a disclosures block + tappable Terms & Privacy links to `paywall_sheet.dart`; host the documents (KP-004).
- **Complexity:** S
- **Dependencies:** KP-004 (URLs must exist), KP-002.
- **Risk:** Low.
- **Expected user impact:** Users see legally required terms before paying.
- **Testing required:** Widget test asserting disclosure text + both links render and open; manual tap-through.
- **Acceptance criteria:** Auto-renew terms + working Terms + Privacy links visible on the paywall at POS.
- **Definition of Done:** Disclosures shipped, links reachable, screenshot filed for review notes.

### KP-004 — No hosted Privacy Policy or Support URL (in-app or in store metadata)
- **Severity:** BLOCKER (Apple 5.1.1; Play Data Safety)
- **Description:** No privacy-policy or support URL exists anywhere. `store/checklist.md` itself lists "Public privacy policy URL + support URL live" as unchecked. `store/privacy/data_safety.md` is a solid internal draft, not a hosted policy.
- **Reason:** A reachable privacy policy URL is mandatory in App Store Connect and for the App Privacy label; Play requires it for a data-collecting app.
- **Recommended solution:** Publish a privacy policy + support page (derive from `data_safety.md`); add the URLs to store metadata and Settings.
- **Complexity:** S (writing) + founder hosting/legal review.
- **Dependencies:** Legal review (KP-009), hosting.
- **Risk:** Policy must match actual data behavior once KP-001/KP-002 land — write it against the *provisioned* posture.
- **Expected user impact:** Users can read how data is handled; trust + compliance.
- **Testing required:** Link reachability check; verify content matches `data_safety.md` declarations.
- **Acceptance criteria:** Live HTTPS privacy + support URLs referenced in-app and in store metadata.
- **Definition of Done:** URLs live, linked from Settings + paywall + store, reviewed by counsel.

### KP-005 — iOS never built; missing privacy manifest & iOS Firebase config
- **Severity:** BLOCKER (Apple privacy-manifest requirement)
- **Description:** The project has only ever been built on Linux (Android). No `ios/Runner/PrivacyInfo.xcprivacy` (Apple's now-mandatory privacy manifest) and no `ios/Runner/GoogleService-Info.plist`. Bundle id is set (`com.kindredpaws.kindredpaws`) and `Info.plist` exists, but the app has never compiled or run on Apple hardware.
- **Reason:** Apple requires a privacy manifest declaring required-reason API usage (e.g. `UserDefaults` via `shared_preferences`, file-timestamp APIs) and any tracking; Firebase/plugins are linked at build time regardless of runtime provisioning. Missing manifest → rejection. Never-built iOS → unknown compile/runtime state.
- **Recommended solution:** Build on macOS/Xcode; add `PrivacyInfo.xcprivacy` (aggregate app + per-SDK reasons); add iOS Firebase config; resolve CocoaPods; fix any iOS-only issues; validate on device (KP-048).
- **Complexity:** L (requires Apple toolchain the current host lacks)
- **Dependencies:** macOS/Xcode environment; KP-001; KP-048.
- **Risk:** First iOS build often surfaces plugin/podfile/signing issues; budget time.
- **Expected user impact:** Enables an iOS submission at all.
- **Testing required:** iOS build succeeds; app runs on a physical iPhone; privacy manifest validated by Xcode Organizer upload.
- **Acceptance criteria:** iOS archive uploads to App Store Connect without privacy-manifest or missing-usage warnings.
- **Definition of Done:** iOS release archive validated + TestFlight build installs and runs a full journey.

### KP-006 — Live charity/donation claims with no operational mechanism
- **Severity:** BLOCKER (Apple 3.2.1; consumer-protection/advertising law)
- **Description:** Store `description.txt`/`promotional_text.txt` and the in-app paywall assert "a share of net revenue funds vetted animal shelters … with transparent, dated impact you can see," and Rescue Bundles state "$3.49 of $4.99 goes to real rescues." But `docs/IMPACT_PLEDGE.md` is "v0.1 DRAFT (skeleton)" — no intermediary chosen, no partner shelters, percentages illustrative, giving account not stood up, and the ledger backend throws `_notProvisioned`.
- **Reason:** Unsubstantiated fundraising claims violate Apple 3.2.1 (fundraising must run through approved mechanisms/registered nonprofits) and are a legal/false-advertising exposure (Priya persona = public backlash risk R5).
- **Recommended solution:** For first submission, **either** remove all specific donation claims/split language from store copy + paywall, **or** stand up the intermediary + ledger and make claims literally true and dated. Do not ship the middle ground.
- **Complexity:** S (remove) / XL (operationalize: intermediary + legal + ledger + first disbursement)
- **Dependencies:** Founder decision; open decisions #4/#5 (intermediary, net %); legal.
- **Risk:** Overclaiming = rejection + reputational damage; underclaiming loses a differentiator. Prefer honest removal until operational.
- **Expected user impact:** Users are not misled about real-world impact.
- **Testing required:** Copy audit; if operationalized, reconciliation test of pledged vs disbursed.
- **Acceptance criteria:** Every donation statement shown to a user is literally true and substantiated, or absent.
- **Definition of Done:** Store + in-app copy pass a claims audit; if kept, a signed intermediary agreement + working ledger back each claim.

### KP-007 — Heartstones are a dead premium currency (buyable, unspendable)
- **Severity:** BLOCKER (Apple 3.1.1 — selling consumable currency with no use)
- **Description:** `product_catalog.dart` sells Heartstone bundles ($1.99–$19.99), but `wallet.dart` implements only `spendKibble`; no `spendHeartstones` exists and no `ItemDef` has a Heartstone price. The two premium cosmetics are gated by the *subscription* entitlement, not Heartstones. Real money converts into an unredeemable number.
- **Reason:** A purchasable currency with zero redemption is a broken purchase loop and a plausible rejection; it also erodes trust (Tom/Priya personas).
- **Recommended solution:** Add a Heartstone storefront (premium cosmetics/décor priced in Heartstones) + `spendHeartstones` with underflow guards, **or** remove Heartstone bundles from the launch catalog until the sink exists.
- **Complexity:** M (build sink) / S (remove)
- **Dependencies:** KP-002; KP-033 (cosmetic art for the sink).
- **Risk:** Shipping the sink half-built repeats the problem; prefer remove-until-ready.
- **Expected user impact:** Premium purchases become meaningful (or absent) instead of a trap.
- **Testing required:** Purchase → spend → entitlement/cosmetic granted; underflow refused; restore.
- **Acceptance criteria:** No purchasable currency lacks an in-app sink at submission.
- **Definition of Done:** Either a working Heartstone economy with tests, or the bundles removed from `product_catalog` for launch.

### KP-008 — No screenshots, app icon, or localized store assets
- **Severity:** BLOCKER (Apple 2.3.3 / 2.3.7)
- **Description:** `store/checklist.md` shows all visual store assets unchecked (icon, screenshots, feature graphic, localizations). Text metadata (title/subtitle/keywords/description/release notes) is complete and non-placeholder.
- **Reason:** You cannot submit without a 1024² icon + per-device screenshots.
- **Recommended solution:** Produce a final app icon + device-frame screenshots of the (art-polished, KP-029/030) hero screens; localize per launch-market decision (KP-041 dependency).
- **Complexity:** M
- **Dependencies:** KP-029/030 visual polish (so screenshots aren't of emoji surfaces); KP-041 (languages).
- **Risk:** Screenshots taken before visual polish will misrepresent the app; sequence after R4.
- **Expected user impact:** Store listing exists and reflects real quality.
- **Testing required:** Asset spec validation (sizes/formats) in App Store Connect / Play Console.
- **Acceptance criteria:** All required store visuals uploaded and accepted.
- **Definition of Done:** Listing passes store asset validation for every targeted device class.

### KP-009 — Children's-privacy legal sign-off undone; no age gate despite ads/IAP/AI
- **Severity:** BLOCKER (Apple 1.3 / 5.1.4; COPPA / GDPR-K; Play Families)
- **Description:** No age gate exists; everyone is treated as `unknown → child-safe` (`compliance_config.dart`), and copy repeatedly claims "always child-safe / for everyone," yet the app has ads, IAP, subscriptions, and an AI companion. The binding child-directedness / Kids-Category determination is explicitly deferred to an unfinished G3 legal sign-off (`docs/COMPLIANCE.md`, `docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md`).
- **Reason:** This is the project's existential risk (R1). Whether the app is child-directed drives the entire store category, ad configuration, parental-gate requirement (5.1.4 bars purchase links behind a parental gate in the Kids Category), and PII rules. It must be decided by counsel before the store age questionnaire.
- **Recommended solution:** Obtain the legal determination (founder + counsel); implement whatever it mandates — either a neutral age gate or full child-safe-for-all with a parental gate before commerce; complete the store age questionnaires accordingly.
- **Complexity:** L (engineering) + founder/legal (gating item)
- **Dependencies:** Legal counsel (founder-only); drives KP-002 ad/commerce gating, store category.
- **Risk:** Getting this wrong is a removal + regulatory risk, not just a rejection.
- **Expected user impact:** Correct, lawful experience for minors and adults.
- **Testing required:** Parental-gate flow (if required); ad-config assertions per age; PII-boundary tests (already strong).
- **Acceptance criteria:** Written legal determination on file; app behavior + store metadata match it.
- **Definition of Done:** Counsel sign-off recorded; age/parental gating implemented + tested; store questionnaires submitted consistently.

### KP-010 — Silent pet-loss: corrupt/partial/downgrade save orphans the pet, then overwrites the recoverable blob
- **Severity:** BLOCKER (DATA-LOSS)
- **Description:** `GameController.load()` treats every `repo.load()` error as "no pet" (`save_repository.dart` funnels all exceptions to `Err`), dropping the player into Rescue Day; adopting then `_persist()`s a fresh pet **over** the recoverable blob. Triggers: truncated write (app killed mid-save), any deserialization exception, a newer-schema save after downgrade (`migration_runner.dart` throws on `schemaVersion > target`), or a single missing/renamed field hitting an unguarded cast (`kindred_save_state.dart` / `care_meters.dart`). `restoreFromCloud` is never called anywhere in `lib/`.
- **Reason:** Directly defeats the R4 "no update may orphan a pet" guarantee — the product's most trust-critical promise.
- **Recommended solution:** On load error: **do not** treat as no-pet — enter a non-destructive "recovery" state, log to Crashlytics, attempt cloud restore, and never overwrite an unparsed blob. Make deserialization total: default every field like its safe siblings already do. Handle newer-schema as "please update the app," not data loss.
- **Complexity:** M
- **Dependencies:** KP-001 (cloud restore path).
- **Risk:** Recovery UX must be gentle; test corrupt-blob permutations thoroughly.
- **Expected user impact:** Eliminates the worst possible experience — waking up to a stranger where your pet was.
- **Testing required:** Unit tests for truncated/partial/missing-field/newer-version blobs → no overwrite, recovery entered; cloud-restore integration.
- **Acceptance criteria:** No load failure ever results in silent creation-over-existing-save; corrupt blob is preserved + restore attempted.
- **Definition of Done:** All corrupt/downgrade permutations covered by tests and enter recovery; `restoreFromCloud` wired into the load path.

### KP-011 — Federated sign-in throws `UnimplementedError` (guest-only identity)
- **Severity:** HIGH (BLOCKER if commerce/cloud depend on it)
- **Description:** `auth_service.dart` Apple/Google sign-in throws `UnimplementedError`; only guest identity works. Entitlements and cloud save therefore cannot follow a user across devices/reinstalls.
- **Reason:** Cross-device restore of purchases and the pet (KP-001/002) requires durable identity; guest-only undermines both. (Note: guest-only also means Apple 5.1.1(v) account-deletion is arguably not even triggered — but the app implements deletion anyway, which is a plus.)
- **Recommended solution:** Implement Sign in with Apple (required if you offer any third-party sign-in on iOS) + Google Sign-In; keep guest with an upgrade path.
- **Complexity:** M
- **Dependencies:** KP-001.
- **Risk:** Sign in with Apple is itself an Apple requirement once any social login exists — implement together.
- **Expected user impact:** Pet + purchases survive device changes.
- **Testing required:** Sign-in on both platforms; guest→account upgrade preserves save; restore across devices.
- **Acceptance criteria:** A user can sign in, change devices, and recover pet + entitlements.
- **Definition of Done:** Both providers implemented + Apple sign-in present on iOS; cross-device restore proven.

### KP-012 — Build presents as incomplete ("closed beta" / "walking skeleton")
- **Severity:** BLOCKER (Apple 2.1/2.2 for a public submission)
- **Description:** `store/metadata/en-US/release_notes.txt` opens "Welcome to the KindredPaws closed beta"; `lib/src/build_info.dart` and `pubspec.yaml` still self-describe as a "walking skeleton for environment validation only."
- **Reason:** Apple rejects apps that present as betas/demos on the public store (TestFlight excepted).
- **Recommended solution:** Rewrite release notes for GA; remove "walking skeleton" self-description from shipped code/metadata; bump `version` from `0.1.0+1` to a real launch version.
- **Complexity:** S
- **Dependencies:** None (but do last, once the build truly is GA-grade).
- **Risk:** Low.
- **Expected user impact:** App reads as a finished product.
- **Testing required:** Metadata review; grep shipped strings for "beta"/"skeleton"/"placeholder."
- **Acceptance criteria:** No beta/skeleton/placeholder language in any user- or reviewer-visible surface.
- **Definition of Done:** Release notes + version + build strings reflect a GA product.

### KP-013 — Governance SSOT is untruthful about project state
- **Severity:** HIGH (process; indirect launch risk)
- **Description:** The declared machine-readable SSOT `game-os/current_state.json` says `currentPhase = P2` (last updated 2026-06-23), `README.md` says "Phase 1 … in progress," and `pubspec.yaml` says "walking skeleton" — while the code is actually a GE-7, schema-v10, 644-test build. Schema/test/coverage claims drift across every report (v4→v10; 31→644 tests). Three competing "authority" roadmaps exist (`game-os/GAME_MASTER_EXECUTION_ROADMAP.md` P0–P6, `MASTER_PRODUCT_ROADMAP.md` E1–E6, `MASTER_KINDREDPAWS_PRODUCT_ROADMAP.md` GE-1–7). The audited build is on an unmerged feature branch with no tags. `current_state.json` still references retired "Live2D" rig budget though runtime is locked to Rive.
- **Reason:** A stale SSOT causes wrong go/no-go decisions and reviewer confusion; three roadmaps make "what is canonical" unanswerable.
- **Recommended solution:** Update `current_state.json` to the true phase/schema/test state; retire or clearly subordinate the E-series and GE-series roadmaps under one canonical roadmap; fix README/pubspec; merge the audited branch through the normal gate; scrub Live2D residue.
- **Complexity:** S–M
- **Dependencies:** None.
- **Risk:** Low, but skipping it perpetuates decision errors.
- **Expected user impact:** Indirect (correct release decisions).
- **Testing required:** Doc-consistency review; the project's own Consistency Auditor pass.
- **Acceptance criteria:** One canonical roadmap; SSOT matches code (phase, schema v10, test count); no retired-alias/Live2D references.
- **Definition of Done:** SSOT + README + pubspec reconciled; single roadmap of record; audited work merged.

---

# PHASE R2 — Correctness, Economy & Notification Bugs

*Goal: fix the traced defects that corrupt data, break the economy, or degrade the retention surfaces. These are engineering-only and can proceed in parallel with R1 provisioning.*

### KP-014 — Uncapped Kibble faucet ("play" mints 5 Kibble/tap forever)
- **Severity:** HIGH (ECONOMY)
- **Description:** `interaction.dart` awards `kibble: willing ? 5 : 1` where `willing = energy > playEnergyCost(10)`, but the energy meter floor is 15, so `15 > 10` is permanently true → 5 Kibble per tap with no diminishing (Kibble skips `_diminish`) and no daily cap. Feed/clean also mint 1/tap when full. Shop items (60–800 Kibble) are trivially farmable.
- **Reason:** Destroys economic tension and any purchase incentive; interacts with the dead-currency/surplus problems (KP-037).
- **Recommended solution:** Apply diminishing returns / a per-day Kibble cap to care-action minting; decouple "willing" from the meter floor.
- **Complexity:** S
- **Dependencies:** Coordinate with KP-037 economy rebalance.
- **Risk:** Over-tightening hurts the cozy feel; tune against the reward-cadence design.
- **Expected user impact:** Earning stays rewarding but not trivially exploitable.
- **Testing required:** Unit test: N taps yield a bounded daily total; floor/cost interaction.
- **Acceptance criteria:** Kibble income per day is bounded and follows the intended curve.
- **Definition of Done:** Cap/diminish implemented + tested; economy sim (KP-037) re-balanced.

### KP-015 — Time-travel farming (clock change grants daily bonus, Bond, growth)
- **Severity:** HIGH (ECONOMY/LOGIC)
- **Description:** `game_simulation.dart` computes `isNewDay = lastActiveDayEpoch != today` — **any** clock change (forward or backward) grants the +50 daily bonus, first-daily greeting Bond, and increments `activeDays` (half the life-stage gate). `resolveOnResume` runs every cold start/foreground → repeatable at will.
- **Reason:** Trivial exploit of economy + progression via device clock.
- **Recommended solution:** Guard against backward time and clamp per-day grants to monotonic server/authoritative time where possible; only advance on forward day boundaries; sanity-cap huge elapsed jumps (also see KP-018).
- **Complexity:** M
- **Dependencies:** KP-001 (authoritative time helps); KP-018 (local-midnight fix).
- **Risk:** Legitimate travel across timezones must still work — use monotonic guards, not wall-clock equality.
- **Expected user impact:** Fair progression; honest players unaffected.
- **Testing required:** Unit tests: clock forward/backward, DST, large jumps → no duplicate grants.
- **Acceptance criteria:** No clock manipulation yields extra bonus/Bond/growth.
- **Definition of Done:** Monotonic day-advance logic + tests for time-attack vectors.

### KP-016 — All notifications fire at UTC, not local time
- **Severity:** HIGH (retention quality)
- **Description:** `tz.setLocalLocation` is never called, so `tz.local` stays UTC; the scheduler builds 10:00/19:00 anchors in UTC. A "10am gentle hello" arrives at 10:00 UTC (e.g. 2am US-Pacific). Code comment concedes it as a "documented enhancement."
- **Reason:** Mis-timed notifications wreck the primary retention lever and read as broken/creepy (2am pings).
- **Recommended solution:** Initialize the device's timezone (`flutter_timezone` → `tz.setLocalLocation`) before scheduling; recompute anchors in local time.
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Low.
- **Expected user impact:** Warm reminders arrive at humane local hours.
- **Testing required:** Unit test scheduling in non-UTC zones; on-device check across a timezone change.
- **Acceptance criteria:** Anchors resolve to the user's local 10am/7pm.
- **Definition of Done:** Local timezone set at init; tests cover ±12h offsets and DST.

### KP-017 — Daily-presence re-arm cancels queued event/celebration/streak notifications
- **Severity:** HIGH (retention quality)
- **Description:** Every resume calls `scheduleDailyPresence`, which `_scheduled.clear()`s and (`LocalNotificationScheduler`) `cancelAll()`s then re-mirrors only presence — wiping any `scheduleEvent` notification (e.g. a Bond-stage-up celebration queued 4h out) before it can fire.
- **Reason:** Silently drops exactly the delightful moments the design intends (celebrations, streak saves).
- **Recommended solution:** Track event notifications separately from daily presence; re-arm presence without cancelling still-pending events (namespace IDs; cancel only the presence set).
- **Complexity:** M
- **Dependencies:** None.
- **Risk:** ID collisions if not namespaced — design IDs carefully.
- **Expected user impact:** Promised celebration/streak notifications actually arrive.
- **Testing required:** Unit test: queue event, resume (re-arm presence), assert event survives.
- **Acceptance criteria:** Re-arming presence never cancels a pending non-presence notification.
- **Definition of Done:** Separate scheduling domains + regression test.

### KP-018 — Day/streak/season boundaries use UTC midnight, not local
- **Severity:** MED (LOGIC)
- **Description:** `dayOfMs = ms ~/ msPerDay` (UTC) drives streak day, daily bonus, and season windows. A UTC+13 player's "new day" flips mid-afternoon; two local days can collapse to one UTC day (missed streak) or split (double).
- **Reason:** Corrupts streaks (a core habit loop) and season timing for non-UTC users (i.e. most of the world).
- **Recommended solution:** Compute calendar-day using the device's local timezone (pairs with KP-016).
- **Complexity:** S
- **Dependencies:** KP-016 (tz init).
- **Risk:** Interacts with KP-015 anti-exploit — implement monotonic + local together.
- **Expected user impact:** Streaks and seasons align with the player's real day.
- **Testing required:** Unit tests around local midnight in several zones.
- **Acceptance criteria:** Day boundaries match the user's local calendar day.
- **Definition of Done:** Local-day math across streak/daily/season + tests.

### KP-019 — Care streak counts a backward day-gap as consecutive
- **Severity:** MED (LOGIC)
- **Description:** `care_streak_engine.dart`: `gap = today - last - 1; if (gap <= 0) newCount = count + 1;` — when `today < last` (clock back / DST), `gap` is negative so the streak increments and `lastCareDayEpoch` moves backward, corrupting later gap math.
- **Reason:** Streak integrity + downstream corruption.
- **Recommended solution:** Treat `today <= last` as "same or earlier day" (no increment, no backward move); only advance on a strictly forward, adjacent day.
- **Complexity:** S
- **Dependencies:** KP-018.
- **Risk:** Low.
- **Expected user impact:** Streaks behave correctly around clock shifts.
- **Testing required:** Unit tests: backward/same/forward day transitions.
- **Acceptance criteria:** No backward or same-day action increments the streak or moves the anchor backward.
- **Definition of Done:** Guarded streak math + tests.

### KP-020 — `_persist` snapshot/widget write is unguarded, violating "never blocks the game"
- **Severity:** MED (robustness)
- **Description:** `repo.save` is Result-guarded, but `await _publishSnapshot(save)` (→ `snapshots.write` / `homeWidget.update`, both awaited unguarded) can throw out of `interact()`/`purchase()`, which the UI calls fire-and-forget → unhandled async error despite the "best-effort; never blocks" contract.
- **Reason:** A SharedPreferences/widget failure can throw into an un-awaited UI path (uncaught error, possible visible glitch).
- **Recommended solution:** Wrap `_publishSnapshot` in try/catch (log + continue); honor the best-effort contract.
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Low.
- **Expected user impact:** Transient platform errors never surface as crashes/glitches.
- **Testing required:** Unit test: snapshot/widget throw → `interact()` still completes.
- **Acceptance criteria:** No snapshot/widget failure propagates out of a gameplay action.
- **Definition of Done:** Guard added + regression test.

### KP-021 — Offline catch-up can be stranded if a background delivers only `hidden`
- **Severity:** MED (LOGIC; embedder-dependent)
- **Description:** `onAppForegrounded` no-ops while `_sessionStartMs != null`, cleared only by `paused`/`detached` via `_endSession`. If an embedder delivers only `hidden` (treated as transient) on a real background, `_sessionStartMs` never clears, so the next `resumed` skips catch-up/greeting.
- **Reason:** Some OS/embedder versions emit `hidden` without `paused`; the returning-player greeting + offline sim would silently not run.
- **Recommended solution:** Treat `hidden` as session-ending (or add a wall-clock-gap fallback that forces catch-up when elapsed exceeds a threshold regardless of the lifecycle path).
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Medium confidence; validate on real devices across OS versions.
- **Expected user impact:** Returning players reliably get catch-up + greeting.
- **Testing required:** Lifecycle unit tests for `hidden`-only transitions; on-device background/foreground on iOS + Android.
- **Acceptance criteria:** Catch-up + greeting run after any real background/foreground cycle.
- **Definition of Done:** Robust lifecycle handling + device-verified.

### KP-022 — `V3ToV4` migration is non-idempotent; runner doesn't guard duplicate `fromVersion`
- **Severity:** LOW (latent)
- **Description:** `v3_to_v4.dart` unconditionally rebuilds `bond` from now-removed flat keys, so a second application resets bond to `{value:0, stage:'Stranger'}` and re-nulls `nest`/`careStreak`. `MigrationRunner` doesn't guard against a duplicate `fromVersion` registration. Not triggered today (each step runs once).
- **Reason:** Any future re-run path or duplicate registration silently loses data.
- **Recommended solution:** Make the step idempotent (no-op if already migrated); add a runner assertion that `fromVersion`s are unique and strictly increasing.
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Low (latent).
- **Expected user impact:** None today; prevents a future data-loss regression.
- **Testing required:** Apply v3→v4 twice → stable; runner rejects duplicate steps.
- **Acceptance criteria:** Re-running any migration is a no-op; runner enforces unique ordered steps.
- **Definition of Done:** Idempotent step + runner guard + tests.

---

# PHASE R3 — UX Improvements

*Goal: raise first-impression, flow, and structural UX quality. Depends on nothing in R1/R2 except where noted.*

### KP-023 — Notification permission requested at cold boot, before the player cares
- **Severity:** MED
- **Description:** `main.dart` fires `notifications.requestPermission()` inside `main()` before `runApp()`, so the OS dialog pops over the rainy cold-open's first beat — spending the one prompt before the user is invested.
- **Reason:** Kills grant rate and steps on the emotional hook; premium apps (Finch, Duolingo) prime, then request after investment.
- **Recommended solution:** Gate the request behind a post-adoption priming card tied to the "warm reminders" promise; pair with the existing Settings toggle.
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Low.
- **Expected user impact:** Higher opt-in, uninterrupted onboarding.
- **Testing required:** Flow test: no permission prompt until post-adoption priming accepted.
- **Acceptance criteria:** Prompt appears only after a contextual priming moment.
- **Definition of Done:** Primed request shipped; onboarding never shows the raw OS prompt first.

### KP-024 — No load-failure / timeout / retry state (bare spinner)
- **Severity:** MED
- **Description:** `game_root.dart` shows a bare `CircularProgressIndicator` while `controller.load()` runs; if it hangs or throws there is no timeout, retry, or error UI — the user is stranded.
- **Reason:** A stuck load is an un-recoverable dead end.
- **Recommended solution:** Add a load timeout + gentle retry + error illustration; on repeated failure, offer recovery (KP-010).
- **Complexity:** S
- **Dependencies:** KP-010 (recovery path).
- **Risk:** Low.
- **Expected user impact:** No stranded-spinner state.
- **Testing required:** Widget test: slow/failed load → timeout + retry UI.
- **Acceptance criteria:** Every load outcome resolves to content, retry, or recovery — never an infinite spinner.
- **Definition of Done:** Timeout + retry + error UI shipped + tested.

### KP-025 — Onboarding has no skip and no back
- **Severity:** LOW
- **Description:** Rescue Day `_beat` only increments; a returning/reinstalling user must sit through all three story beats with no skip or step-back.
- **Reason:** Friction for repeat users; minor.
- **Recommended solution:** Add a subtle "Skip" and per-beat back affordance.
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Don't let skip bypass the emotional hook for first-timers (consider first-run-only full flow).
- **Expected user impact:** Faster re-entry.
- **Testing required:** Widget test: skip advances to naming; back decrements.
- **Acceptance criteria:** Skip + back available on the story beats.
- **Definition of Done:** Controls shipped + tested.

### KP-026 — Swipe-between-rooms is not discoverable
- **Severity:** LOW
- **Description:** Room changes rely on horizontal swipe or a dock chip, but nothing signals the world scrolls sideways on first run (the `FirstVisitHint` covers verbs, not the swipe).
- **Reason:** Users may never find most rooms.
- **Recommended solution:** One-time swipe/dock nudge on first home visit.
- **Complexity:** S
- **Dependencies:** None.
- **Risk:** Low.
- **Expected user impact:** Higher room discovery → more content engaged.
- **Testing required:** Widget test: nudge shows once then never again.
- **Acceptance criteria:** First-run users see a swipe affordance.
- **Definition of Done:** One-time nudge shipped + tested.

### KP-027 — Design tokens not enforced: 96 hardcoded hex + ~38 ad-hoc font sizes
- **Severity:** MED
- **Description:** `cozyTheme()` is clean but its palette constants are private to `cozy_theme.dart`, so screens re-hardcode `Color(0xFF4A3F38)`×11, `0xFFFFFBF5`×9, etc.; ~38 hardcoded `fontSize` values sit alongside `theme.textTheme`.
- **Reason:** Palette/type changes (and dark mode, KP-042) require hunting ~96 sites; drift is inevitable.
- **Recommended solution:** Promote colors/type to a public token set (`ThemeExtension`/`KpColors` + named text styles); refactor call sites.
- **Complexity:** M
- **Dependencies:** Unblocks KP-042 (dark mode).
- **Risk:** Mechanical but wide; do with golden coverage to catch regressions.
- **Expected user impact:** Indirect (enables consistent theming/dark mode).
- **Testing required:** Golden tests unchanged after refactor.
- **Acceptance criteria:** No raw palette hex or ad-hoc font sizes outside the token layer.
- **Definition of Done:** Tokens centralized; call sites migrated; goldens green.

### KP-028 — Dock labels are 9.5pt (below comfortable legibility)
- **Severity:** LOW
- **Description:** Room-dock labels use `fontSize: 9.5`, below comfortable minimums before low-vision scaling.
- **Reason:** Legibility, esp. under Dynamic Type (KP-043).
- **Recommended solution:** Raise to ≥11pt; allow scaling.
- **Complexity:** S
- **Dependencies:** KP-043.
- **Risk:** Layout impact on the 78px dock — verify.
- **Expected user impact:** Readable navigation labels.
- **Testing required:** Golden at default + large text.
- **Acceptance criteria:** Dock labels legible at default and scaled sizes.
- **Definition of Done:** Size raised; dock layout holds under scaling.

---

# PHASE R4 — Visual & Character Polish

*Goal: close the "premium backgrounds undermined by emoji placeholders" gap. Commission long-lead art EARLY (parallel with R1). Store screenshots (KP-008) depend on this phase.*

### KP-029 — Emoji-as-art on the three hero surfaces (species choice, Keepsake cards, Profile portrait)
- **Severity:** HIGH
- **Description:** The species-choice cards render OS emoji 🐶🐱; Keepsake cards (the app's viral share surface) are a solid peach `Container` + one emoji at `fontSize:48` while the designed `keepsake_template.png`/`memory_card.png` sit unused; the Profile "Our story" portrait is a raw emoji though the docstring promises the dressed pet.
- **Reason:** These are the emotional peak (adoption), the primary marketing artifact (shared cards), and the identity screen — rendering them as platform emoji reads as a prototype and clashes with the genuinely premium painterly backgrounds. (Emoji also render differently per device — an Android-9 render bug is already noted in history.)
- **Recommended solution:** Render `VectorPetRenderer`/`DressedPet` previews for species choice + profile; composite the real card template with the rendered pet for Keepsakes.
- **Complexity:** M
- **Dependencies:** KP-030 (character decision); unblocks KP-008 screenshots.
- **Risk:** Low; large perception gain for small effort.
- **Expected user impact:** The screens users judge and share look finished.
- **Testing required:** Golden tests for each surface; share-image composition test.
- **Acceptance criteria:** No OS emoji stands in for the pet/character on species choice, Keepsakes, or Profile.
- **Definition of Done:** All three surfaces render real art; goldens updated.

### KP-030 — No commissioned pet rig; vector pet is the de facto shipping character; Rive fallback is a Material icon
- **Severity:** HIGH
- **Description:** `assets/rigs/` contains only `README.md` — no `.riv`. Production runs the temporary `VectorPetRenderer` (`main.dart:43`); if `KP_PET_RENDERER=rive` is ever set without an asset, the fallback is a Material icon in a circle labeled "rive." The commissioned rig (G13) is a pending founder action.
- **Reason:** The whole "living companion" promise rests on the character. The vector pet is clean and charming (a legitimate MVP character) but simpler than premium competitors; the decision to ship it *as the character* vs. commission the rig must be made and finished, not left ambiguous.
- **Recommended solution:** Decide: (a) commission the `.riv` rig(s) and wire them, or (b) commit to the vector pet as the shipping character and polish it (more emotion depth, secondary motion) — either way, remove the icon-fallback ambiguity.
- **Complexity:** XL (commission) / M (commit-to-vector polish)
- **Dependencies:** Founder/contractor (rig commission, open decision #2 2nd species); art budget.
- **Risk:** Rig commission is long-lead — start now if chosen. Don't ship the icon fallback.
- **Expected user impact:** A cohesive, premium-feeling companion.
- **Testing required:** Renderer golden/perf sweep; on-device animation smoothness.
- **Acceptance criteria:** One intentional, polished character path ships; no placeholder-icon fallback reachable in release.
- **Definition of Done:** Character decision executed end-to-end; goldens + perf budgets green on device.

### KP-031 — Minigames are visibly programmer-art
- **Severity:** LOW-MED
- **Description:** Minigames use primitive `CustomPaint` (yellow circle ball, brown rrect basket, emoji snacks at `fontSize:30`) — coherent and cozy but inexpensive-looking.
- **Reason:** Contributes to an "emoji/geometry as art" impression in aggregate.
- **Recommended solution:** Replace with simple sprite art matching the pet's style; keep the (good) no-fail cozy design.
- **Complexity:** M
- **Dependencies:** Art style lock (KP-030).
- **Risk:** Low.
- **Expected user impact:** Minigames feel designed, not prototyped.
- **Testing required:** Golden per minigame; perf under motion.
- **Acceptance criteria:** Minigames use styled art consistent with the pet.
- **Definition of Done:** Art integrated; goldens updated.

### KP-032 — No background music (SFX only)
- **Severity:** MED
- **Description:** `assets/audio` has 10 original SFX cues and no music; the asset budget planned ~5 music tracks. A cozy pet game leans heavily on ambient audio for comfort/immersion (GE-6 even deferred "ambient audio").
- **Reason:** Music is a large part of the "cozy/premium" feeling and bedtime/comfort loops.
- **Recommended solution:** Add a small set of license-clean ambient loops (home day/night, bedroom lullaby, celebration), respecting a mute/settings toggle and silence-by-default policies where appropriate.
- **Complexity:** M
- **Dependencies:** Audio sourcing; Feel/settings integration exists.
- **Risk:** Battery/size — keep loops small (see KP-046).
- **Expected user impact:** Warmer, more immersive, more premium feel.
- **Testing required:** Audio sink integration test; settings mute honored.
- **Acceptance criteria:** Ambient music present, toggleable, memory/battery-safe.
- **Definition of Done:** Music integrated with mute controls + tests.

### KP-033 — Cosmetics/wardrobe shop art essentially absent
- **Severity:** MED
- **Description:** `assets/wardrobe/` holds only `collar_examples.png` and `hat_examples.png` (art-direction *examples*, not wearables); `assets/shop/` has one badge. The plan calls for ~30 cosmetics as the primary non-sub revenue surface.
- **Reason:** The cosmetics economy (and any Heartstone sink, KP-007) needs actual cosmetic assets; today there's little to buy or wear.
- **Recommended solution:** Produce the launch cosmetic set (overlay sprites + palette-swaps per the asset-discipline rules); wire prices; feed the Heartstone/Kibble sinks.
- **Complexity:** L
- **Dependencies:** KP-030 (style lock), KP-007/KP-037 (economy).
- **Risk:** Art volume; use palette-swap discipline to control cost.
- **Expected user impact:** A real shop with desirable items.
- **Testing required:** Equip/wear-follows-pet across rooms (already tested for the few items); price/economy tests.
- **Acceptance criteria:** A launch cosmetic catalog exists with art, prices, and sinks.
- **Definition of Done:** Cosmetic set shipped + integrated into shop + economy.

---

# PHASE R5 — Gameplay, Economy Depth & AI Companion

*Goal: make the flagship pillars (AI memory, premium economy, long-term progression) actually deliver. This is what converts a cozy MVP into a month-2-sticky product.*

### KP-034 — "It remembers" reduces to ~2 fact types / ~12 lines
- **Severity:** HIGH
- **Description:** Only two `FactKey`s are ever created (`importantDate`, `likesActivity`), both seeded at adoption/growth; there is **no fact-capture mechanism** (`FactSource.explicit`/`extracted` are defined but never produced). So 15 of 27 slot callback-lines (favorite_thing/color, named_pet_after, had_a_hard_day_on) are permanently unfillable and rejected by the selector.
- **Reason:** Memory is the single highest-retention lever (per `docs/RETENTION.md`) and the signature differentiator (R3). With two facts it feels canned within days; the ">=95% callback reliability" G2 claim is technically true but over a near-empty fact set.
- **Recommended solution:** Capture real facts safely (closed-set, child-safe): `named_pet_after` at naming; a `favorite_*` via a gentle onboarding/among-play choice; optionally an activity preference learned from play frequency. This unlocks already-authored callback lines with no new corpus.
- **Complexity:** M
- **Dependencies:** None (content already exists).
- **Risk:** Keep capture closed-set to preserve child-safety (no free-text from minors).
- **Expected user impact:** The pet genuinely "remembers" personal facts — the promised emotional payoff.
- **Testing required:** Callback-reliability harness re-run with the new facts; slot-eligibility tests; child-safety validator still green.
- **Acceptance criteria:** ≥4 distinct fact types can be populated and are recalled reliably.
- **Definition of Done:** Fact capture shipped; previously-dead callback lines fire; reliability ≥95% over the enlarged fact set.

### KP-035 — Corpus ~430 lines (target ≥1000) and ~45% unreachable; bond/life/personality dialogue is shadowed
- **Severity:** HIGH
- **Description:** `dialogue_corpus.dart` is ~430 lines across 75 buckets vs the ">1000 reviewed lines" done-ness bar (`docs/DIALOGUE_BANK.md`). The selector weights mood ×4 vs bondStage ×2, lifeStage/personality ×1 and surfaces only the top tier; since every intent covers all four moods, the bond-stage/life-stage/personality-specific buckets essentially never play — the pet sounds identical from day-1 stranger to 6-month soulmate, puppy or grown, playful or cuddly.
- **Reason:** Kills the "only my pet would say this" and longitudinal-freshness promises; the evolving `personality.dart` system produces no audible change.
- **Recommended solution:** Raise bond/life/personality scoring weight so specific buckets win when present (or fold flavor into mood buckets); grow the corpus toward the target with reviewed, child-safe lines. (Within-mood variety is already healthy — 10–20 lines each — so within-session repetition is genuinely low; fix personalization + longitudinal depth.)
- **Complexity:** L (content) + S (selector weighting)
- **Dependencies:** Offline pre-gen pipeline (claude-opus-4-8) for reviewed lines; KP-034 (facts feed personalization).
- **Risk:** Content-review load; keep the child-safe CI gate.
- **Expected user impact:** The pet's voice visibly evolves with bond, age, and personality.
- **Testing required:** Selector tests proving specific buckets surface; corpus size + slot-safety + child-safe CI gates.
- **Acceptance criteria:** Bond/life/personality changes produce audibly different lines; corpus meets the reviewed-line target.
- **Definition of Done:** Re-weighted selector + grown corpus; personalization demonstrable in tests + playthrough.

### KP-036 — Content exhausts in ~2–4 weeks; growth terminal at day 28; Bond stages unlock nothing
- **Severity:** MED
- **Description:** Life stages end at Grown (Companion bond + 28 active days); after ~day 28 there's no further visible growth. Bond continues to Kindred (~73 days) and Soulmate (~182 days) but those unlock nothing tangible. Total content: 2 species, 8 rooms, 38 items, 4 minigames, 12 evergreen + 8 seasonal kindnesses.
- **Reason:** The day-to-day loop is identical from day 2; the aspirational ladder past month 1 is just a label change — poor D30+ retention (the G4/G6 gates).
- **Recommended solution:** Attach concrete unlocks (a room, décor set, cosmetic, minigame, or dialogue tier) to Companion/Kindred/Soulmate; consider a post-Grown "elder"/seasonal cosmetic track.
- **Complexity:** L
- **Dependencies:** KP-033 (cosmetics), KP-035 (dialogue tiers), KP-039 (minigame depth).
- **Risk:** Content treadmill (R8) — use data-driven/remote-config unlocks to stay solo-sustainable.
- **Expected user impact:** A reason to keep climbing past month 1.
- **Testing required:** Progression tests; economy/pacing sim.
- **Acceptance criteria:** Each bond stage past Friend grants a tangible unlock.
- **Definition of Done:** Milestone unlocks shipped + tested; pacing validated.

### KP-037 — Kibble becomes surplus with nothing to buy (faucets never close)
- **Severity:** MED
- **Description:** Faucets never close (daily +50 forever, ~24–30/day from kindnesses, +5/care action, capped minigame Kibble). The entire non-consumable catalog (~4,160 Kibble) is affordable in ~6–8 weeks from the daily bonus + kindnesses alone; after that only cheap consumables remain as a sink.
- **Reason:** No economic goal for retained users; combined with dead Heartstones (KP-007) the economy loses tension by month 2.
- **Recommended solution:** Add a rotating premium-cosmetic/décor sink (ideally the Heartstone store, KP-007) or taper the daily faucet; tie sinks to the new unlock ladder (KP-036).
- **Complexity:** M
- **Dependencies:** KP-007, KP-014, KP-033.
- **Risk:** Don't make it grindy — preserve the cozy, non-predatory feel (R6).
- **Expected user impact:** A meaningful long-term earn/spend loop.
- **Testing required:** Economy sim over 90 days; sink availability tests.
- **Acceptance criteria:** A retained player always has a desirable Kibble sink.
- **Definition of Done:** Rotating sink + rebalanced faucets shipped + sim-validated.

### KP-038 — Compassion Coins are inert (no sink or display)
- **Severity:** LOW
- **Description:** Compassion Coins are minted server-side post-purchase but have no in-game sink or display; the third wallet slot is inert.
- **Reason:** Fine as scaffolding, but don't surface it as a "currency" to players until it does something (and until donations are operational, KP-006).
- **Recommended solution:** Either hide Compassion Coins until the Rescue Wall/impact loop is live, or wire the intended impact display.
- **Complexity:** S (hide) / L (wire impact loop)
- **Dependencies:** KP-006 (donation operationalization).
- **Risk:** Surfacing an inert "impact currency" invites the charity-washing critique (R5).
- **Expected user impact:** No confusing dead currency; honest impact story when ready.
- **Testing required:** UI test that inert currency isn't shown; (later) impact-ledger display test.
- **Acceptance criteria:** Compassion Coins are either hidden or fully functional — never a visible dead number.
- **Definition of Done:** Decision executed + tested.

### KP-039 — Only 4 shallow 45s no-fail minigames; no depth or progression
- **Severity:** MED
- **Description:** 4 minigames (all 45s, no-fail, no depth/progression). Good for cozy accessibility, but no mastery, variety, or reward scaling.
- **Reason:** Minigames are a daily-loop pillar; shallow ones don't sustain engagement or reward variety.
- **Recommended solution:** Add light progression (difficulty tiers, personal bests, escalating cozy rewards) without introducing fail-states that break the no-stress design; add 1–2 more games over time via the shared kit (GE-4).
- **Complexity:** M–L
- **Dependencies:** KP-031 (art), KP-037 (rewards).
- **Risk:** Keep it no-fail/cozy (brand).
- **Expected user impact:** More reason to play daily; reward variety.
- **Testing required:** Minigame logic + reward tests; reduced-motion accommodation (KP-045).
- **Acceptance criteria:** Minigames offer optional depth + scaling rewards while staying no-fail.
- **Definition of Done:** Progression shipped + tested across the game kit.

### KP-040 — Notification content is thin (~15 templates)
- **Severity:** LOW-MED
- **Description:** ~15 warm, well-capped templates with `{name}` substitution — will feel same-y over weeks; memory-nudges can't yet reference a real fact (KP-034).
- **Reason:** Repetitive notifications lose their pull (leading-churn indicator: "noticed AI repetition").
- **Recommended solution:** Expand templates; let memory-nudge notifications reference a real captured fact (post-KP-034); keep the 2/day cap + never-guilt tone.
- **Complexity:** S–M
- **Dependencies:** KP-034 (facts), KP-016 (local timing).
- **Risk:** Preserve the never-guilt/cap discipline (a real differentiator — protect it).
- **Expected user impact:** Fresher, more personal reminders.
- **Testing required:** Template variety + never-guilt validator; fact-substitution safety.
- **Acceptance criteria:** Notifications vary over weeks and can reference real facts, still capped + warm.
- **Definition of Done:** Expanded, personalized templates shipped + gated by the safety validator.

---

# PHASE R6 — Performance, Accessibility & Localization

*Goal: meet accessibility, globalization, and performance bars for a broad, global, all-ages audience.*

### KP-041 — No localization infrastructure (English hardcoded everywhere)
- **Severity:** HIGH (long-term) / BLOCKER for any non-English market
- **Description:** No `flutter_localizations`, no `intl`, no `l10n/`, no `.arb`; ~38 hardcoded `Text('…')` in the UI alone plus hundreds of corpus lines.
- **Reason:** A cozy pet game is a global category; you cannot ship non-English without a rebuild, and retrofitting later touches every file. Open decision #6 (launch languages) is unresolved.
- **Recommended solution:** Introduce `AppLocalizations`/`.arb` scaffolding now, even launching en-only; externalize UI strings; plan dialogue localization separately (with per-language safety validation).
- **Complexity:** L
- **Dependencies:** Launch-language decision (#6); KP-008 (localized store assets).
- **Risk:** Dialogue localization must re-run child-safety per language.
- **Expected user impact:** Enables global reach without a rewrite.
- **Testing required:** l10n wiring test; pseudo-localization pass for overflow.
- **Acceptance criteria:** All user-facing UI strings resolve through the l10n layer.
- **Definition of Done:** l10n scaffolding shipped; strings externalized; at least en (+decided languages) generated.

### KP-042 — No dark mode / no system-theme response
- **Severity:** MED
- **Description:** `cozyTheme()` hardcodes `Brightness.light`; there is no `darkTheme`/`ThemeMode`. The home background swaps day/night on a clock, but UI chrome stays bright cream at night and ignores system dark mode — jarring for an app that encourages bedtime use (lullaby, bedroom).
- **Reason:** Modern expectation; comfort for night/bedtime use; accessibility.
- **Recommended solution:** Add a dark chrome variant + `ThemeMode.system`; unblocked by the token refactor (KP-027).
- **Complexity:** M
- **Dependencies:** KP-027 (tokens).
- **Risk:** Verify contrast in both themes (KP-044).
- **Expected user impact:** Comfortable night use; matches OS preference.
- **Testing required:** Golden tests in light + dark; system-toggle test.
- **Acceptance criteria:** UI adapts to system dark mode with a designed dark palette.
- **Definition of Done:** Dark theme shipped; goldens in both modes; contrast verified.

### KP-043 — Dynamic Type clipping at large text sizes
- **Severity:** MED
- **Description:** Hardcoded `fontSize` still scales, but fixed-height containers (78px dock, 150px portrait, clamped `CareRing`) and many `maxLines:1/2/3 + ellipsis` fields clip pet speech and mood copy at large text sizes; no `textScaler` clamp.
- **Reason:** Accessibility (low vision); Apple/Play expect Dynamic Type support.
- **Recommended solution:** Allow key copy to wrap; flex fixed heights; add a sensible `textScaler` clamp; test at 200%.
- **Complexity:** M
- **Dependencies:** KP-027 (type tokens), KP-028.
- **Risk:** Layout regressions — cover with goldens at large scale.
- **Expected user impact:** Readable for large-text users without clipped warmth.
- **Testing required:** Golden at 130%/200% text scale; overflow checks.
- **Acceptance criteria:** No key copy clips at up to 200% text scale.
- **Definition of Done:** Scaling-safe layouts + large-text goldens green.

### KP-044 — Contrast needs WCAG-AA verification
- **Severity:** MED
- **Description:** Bold `scheme.primary` (mid peach-brown) on cream chips for small badge/feedback text, and taupe `Color(0xFF7A6A58)` section labels on cream, are borderline ~4.5:1.
- **Reason:** WCAG AA / accessibility audits (and Apple/Play scrutiny).
- **Recommended solution:** Measure all small-text pairs; darken where <4.5:1; re-check in dark mode.
- **Complexity:** S
- **Dependencies:** KP-042 (dark), KP-027 (tokens).
- **Risk:** Low.
- **Expected user impact:** Legible text for low-vision users.
- **Testing required:** Automated contrast check on the token pairs.
- **Acceptance criteria:** All small text meets AA (≥4.5:1) in both themes.
- **Definition of Done:** Contrast verified + fixed across the palette.

### KP-045 — Reduced-motion not applied in minigames
- **Severity:** LOW
- **Description:** Reduced-motion is respected system-wide (exemplary) except in minigames, where motion is the gameplay.
- **Reason:** Full accessibility coverage; some users need reduced motion even in play.
- **Recommended solution:** Offer a reduced-motion minigame variant or a gentle-mode toggle; document the tradeoff.
- **Complexity:** S–M
- **Dependencies:** KP-039.
- **Risk:** Low.
- **Expected user impact:** Motion-sensitive users can still play.
- **Testing required:** Reduced-motion flag honored in minigame render tests.
- **Acceptance criteria:** A reduced-motion play path exists.
- **Definition of Done:** Reduced-motion accommodation shipped + tested.

### KP-046 — Release download size unmeasured; heavy backgrounds
- **Severity:** MED
- **Description:** `assets/` is 70MB, dominated by 8 background PNGs at ~3MB each (backgrounds = 29MB). The debug APK is 253MB (expected for debug); the **release AAB size is unmeasured** by this audit and no on-device size/perf profiling was possible (MIUI blocked install).
- **Reason:** Download size affects install conversion + cellular-download limits; large uncompressed PNGs inflate it.
- **Recommended solution:** Convert backgrounds to WebP/AVIF or optimized PNG; measure the release AAB; consider Play Asset Delivery / on-demand for non-critical art; validate `cacheWidth/Height` decode sizing.
- **Complexity:** M
- **Dependencies:** KP-030/033 final art.
- **Risk:** Watch quality loss on the premium backgrounds — tune compression.
- **Expected user impact:** Smaller download; faster install; less memory.
- **Testing required:** Release AAB size measurement; on-device memory profile (`flutter drive --profile`); visual regression on compressed art.
- **Acceptance criteria:** Release download within target; backgrounds optimized without visible quality loss.
- **Definition of Done:** Optimized assets; measured AAB under target; memory profile within budget.

### KP-047 — On-device performance budgets unverified by this audit
- **Severity:** LOW-MED
- **Description:** Performance budgets are a clean SSOT (`performance_budgets.dart`: cold start <2.5s, 16ms frame, 150ms reaction) enforced host-side, but this audit could not profile on a physical device (MIUI install blocked). The existing Huawei report validated a release APK on Android 9, but current-branch GE-7 has not been device-profiled here.
- **Reason:** Host-side budgets ≠ real frame pacing/memory/battery on device.
- **Recommended solution:** Profile the current build on a device matrix (`flutter drive --profile`): cold start, sustained 60fps, memory over a long session, battery.
- **Complexity:** M
- **Dependencies:** KP-049 (device access incl. MIUI install path).
- **Risk:** Low.
- **Expected user impact:** Confidence in real-world smoothness.
- **Testing required:** On-device profiling across the matrix.
- **Acceptance criteria:** Budgets met on real hardware (low-end included).
- **Definition of Done:** Device profiling report attached; budgets green on the matrix.

---

# PHASE R7 — Final Launch Candidate

*Goal: prove the provisioned, art-complete, content-deep build on real hardware across both platforms, then validate against the project's own G3/G4 gates. Only after this phase is a submission legitimate.*

### KP-048 — iOS validated on real Apple hardware
- **Severity:** BLOCKER (for iOS launch)
- **Description:** iOS has never been built or run. After KP-005, build, archive, and run a full journey on a physical iPhone + iPad.
- **Reason:** Unknown iOS runtime behavior; Apple submission requires a working iOS build.
- **Recommended solution:** Full E2E on iOS device(s); fix iOS-only issues; TestFlight internal round.
- **Complexity:** L
- **Dependencies:** KP-005, KP-001, KP-002.
- **Risk:** First iOS pass often finds plugin/native issues.
- **Expected user impact:** A working iOS app.
- **Testing required:** Full integration journey on iPhone + iPad; TestFlight install.
- **Acceptance criteria:** Complete journey passes on physical iOS hardware.
- **Definition of Done:** TestFlight build validated end-to-end; no iOS-only regressions.

### KP-049 — Real-device Android matrix (incl. MIUI/Xiaomi install path)
- **Severity:** HIGH
- **Description:** This audit's device install was blocked by MIUI (`INSTALL_FAILED_USER_RESTRICTED`). Validate on a matrix incl. Xiaomi/MIUI, Samsung/One UI, a Pixel, and a low-RAM Android-9 device (Huawei partly covered).
- **Reason:** MIUI/OEM skins have known install, notification, and background-kill quirks (a MIUI gotcha is already noted in project history); OEM fragmentation is R9.
- **Recommended solution:** Establish an install path for MIUI (developer "Install via USB", signed build); run the full journey + notification delivery + background/foreground on each device.
- **Complexity:** M
- **Dependencies:** Signed build; device access.
- **Risk:** OEM background-kill can affect notifications (KP-016/017/021) — verify on device.
- **Expected user impact:** Works across the real Android landscape.
- **Testing required:** Full E2E + notification + lifecycle per device.
- **Acceptance criteria:** Journey + notifications pass on each matrix device.
- **Definition of Done:** Device matrix report attached; no OEM-specific blockers.

### KP-050 — Provisioned end-to-end smoke (Firebase runtime path, cloud save/restore, entitlement restore)
- **Severity:** BLOCKER
- **Description:** The Firebase runtime path is **never CI-exercised** (self-flagged, PHASE5 §17); the `rewireDerivedServices` fix on the Firebase swap is in-memory-tested only. Prove the real provisioned stack: cloud save + restore, entitlement restore, analytics/Crashlytics ingestion, crash-free ≥99%.
- **Reason:** First real activation is the highest-risk moment; the G3 gate needs crash-free + restore evidence.
- **Recommended solution:** Add a provisioned integration test (or staged manual runbook) exercising the real Firebase/RevenueCat path on device; capture crash-free over a beta cohort.
- **Complexity:** L
- **Dependencies:** KP-001, KP-002, KP-011.
- **Risk:** Init ordering/service-rebind bugs may surface — this is exactly where.
- **Expected user impact:** Durable saves + purchases that actually work in production.
- **Testing required:** On-device provisioned smoke; restore across devices; forced crash → Crashlytics; funnel → Analytics.
- **Acceptance criteria:** Real backend/commerce paths proven on device; crash-free ≥99% over the beta.
- **Definition of Done:** Provisioned smoke passes; PHASE5 §17 caveat retired with evidence.

### KP-051 — Store review dry-run + complete metadata/screenshots/age questionnaires
- **Severity:** BLOCKER
- **Description:** Complete App Store Connect / Play Console listings: final metadata, screenshots (KP-008), age/content questionnaires consistent with the legal determination (KP-009), App Privacy / Data Safety labels from `data_safety.md` (aligned to the provisioned posture), review notes (guest path, donation status).
- **Reason:** The submission surface itself must be complete and internally consistent to pass review.
- **Recommended solution:** Fill both consoles; run an internal reviewer dry-run against the latest guidelines using this audit's findings as a checklist.
- **Complexity:** M
- **Dependencies:** KP-004, KP-006, KP-008, KP-009.
- **Risk:** Inconsistency between privacy label and actual behavior triggers rejection — align to the provisioned build.
- **Expected user impact:** Smooth review.
- **Testing required:** Internal guideline dry-run; label-vs-behavior consistency check.
- **Acceptance criteria:** Both listings complete + internally consistent with the shipped build.
- **Definition of Done:** Dry-run passes; listings submitted (TestFlight/internal track first).
### KP-052 — Soft-launch KPI validation against G3/G4 before global
- **Severity:** HIGH
- **Description:** Per the project's gates, validate closed-beta (G3: D1≥40%/D7≥18%, crash-free ≥99%, cloud-restore proven, 0 child-safety incidents, legal green-light) then soft-launch (G4: D1≥42%/D7≥20%/D30≥10%, ARPDAU ≥$0.03, LLM cost/DAU <35% ARPDAU, ≥1 viral share/DAU-week, clean donation reconciliation) before global launch.
- **Reason:** These are the founder's own go/no-go criteria; skipping them risks a public launch on unvalidated retention/economics.
- **Recommended solution:** Run phased geo soft launch; instrument the ~15-event funnel (needs KP-001 analytics live); hold at each gate.
- **Complexity:** XL (time/market)
- **Dependencies:** All of R1–R6; KP-001 analytics; open decisions #4–#8.
- **Risk:** Retention may reveal the content-depth gaps (R5) — fix before scaling spend.
- **Expected user impact:** A launch backed by real data.
- **Testing required:** Live KPI dashboards; cohort retention; economy/donation reconciliation.
- **Acceptance criteria:** G3 then G4 pass criteria met on live cohorts.
- **Definition of Done:** Both gates cleared with dashboard evidence; founder go decision recorded.

---

## Appendix A — Phase dependency summary

| Phase | Blocks | Can parallelize with |
|---|---|---|
| R1 Blockers | everything | R2 (engineering), R4 art commissioning (long lead) |
| R2 Bugs | R7 device validation | R1, R3 |
| R3 UX | store screenshots quality | R2, R4 |
| R4 Visual | KP-008 screenshots, KP-051 | R1 (commission early), R5 |
| R5 Content/AI | G4 retention (KP-052) | R4, R6 |
| R6 Perf/A11y/L10n | KP-051 (localized assets), device perf | R5 |
| R7 Launch candidate | submission | — (terminal) |

## Appendix B — Founder-only / external-dependency items (cannot be resolved by engineering alone)

- KP-009 Children's-privacy legal determination (counsel) — **gating.**
- KP-006 Donation intermediary + partner shelters + net-% (open decisions #4/#5, legal).
- KP-005/KP-048 Apple toolchain + hardware (macOS/Xcode) — current host is Linux.
- KP-001/KP-002 Firebase + RevenueCat + AdMob + store-product provisioning (accounts/credentials).
- KP-030 Rig commission + 2nd-species ship/cut (open decision #2, art budget).
- KP-052 Soft-launch geos + subscription pricing (open decisions #7/#8).

## Appendix C — What is already strong (protect during remediation)

- Green CI: analyze clean (`--fatal-infos --fatal-warnings`), 644 tests, 91.0% coverage, save-migration chain v1→v10.
- Child-safety by construction: on-device templated AI (no live LLM), no free-text from minors, fail-closed safety filter, self-harm → static crisis line.
- Never-guilt design: no-death floor, forgiving streak (Streak Warmth), capped warm notifications — a genuine differentiator.
- Privacy/security hygiene: PII-stripped analytics, no committed secrets, comprehensive `.gitignore`, `security.yml` CI, minimal Android permissions, client never calls Anthropic directly.
- Account deletion implemented + reachable + tested (Apple 5.1.1(v)).
- Accessibility scaffolding: broad Semantics, exemplary system-wide reduced-motion, compliant touch targets, color never the sole signal.
- Genuinely premium environment/illustration art and a clean, charming vector pet.

*End of roadmap. Companion analysis: `PRE_APP_STORE_FINAL_AUDIT_REPORT.md`.*
