# FOUNDER ACTIONS — TODO LEDGER

**Created:** 2026-07-08 · **Maintained by:** engineering agent during the pre-release remediation program
**Authority:** `PRE_RELEASE_REMEDIATION_ROADMAP.md` (KP-001…KP-052) · Audit: `PRE_APP_STORE_FINAL_AUDIT_REPORT.md`

These items **cannot be completed by engineering** — they need founder credentials, money, legal counsel, Apple hardware, or a human decision. Engineering does **not** stop for them: every seam is built, tested, and documented so each item becomes a provision-and-flip step. Items are ordered by how hard they gate a store submission.

Legend: 🔴 gates any legitimate submission · 🟠 gates public launch quality/revenue · 🟡 decision that shapes later work

---

## 🔴 F-1 · Merge the green PRs (5 minutes)

**What:** Squash-merge, in order: **PR #65 → PR #66 → the rolling `feature/pre-release-remediation` PR** (each 9/9 CI-green; later PRs contain the earlier ones, so GitHub will show shrinking diffs as you merge in order).
**Why founder:** the live harness guard blocks agent `gh pr merge` this session (two-party-review rule). Alternative: add a permission rule allowing `gh pr merge`, and the agent resumes self-merging per `CONTRIBUTING.md §5`.
**Roadmap:** KP-013 (last clause of its DoD).

## 🔴 F-2 · Children's-privacy legal determination (KP-009) — THE existential gate

**What:** Engage counsel; obtain the binding child-directedness / Kids-Category determination (COPPA, GDPR-K, Apple 1.3/5.1.4, Play Families). Decide: neutral age gate **or** child-safe-for-all + parental gate before commerce.
**Needs from you:** pick/pay counsel; share `docs/COMPLIANCE.md`, `docs/LEGAL_CHILD_DIRECTEDNESS_SCOPING.md`, `store/privacy/data_safety.md`.
**Engineering readiness:** child-safe architecture is already fail-closed; whatever counsel mandates (age gate / parental gate) is an S–M task on existing seams.
**Blocks:** store age questionnaires (KP-051), ad configuration, final App Privacy label.

## 🔴 F-3 · Firebase provisioning (KP-001)

**What:** Create the production Firebase project; run `flutterfire configure` for Android + iOS; put `firebase_options.dart` + real `google-services.json`/`GoogleService-Info.plist` into CI **secrets** (never git); set `KP_FIREBASE_PROVISIONED=true` + `KP_BACKEND=firebase` in the release build config.
**Needs from you:** Google account + billing; CI secret injection (repo Settings → Actions secrets; workflow seam already reads them).
**Engineering readiness:** gated init, service rebind, migration chain, and mock fallback are built + tested; KP-010 recovery/cloud-restore path (shipped in this program) activates automatically once provisioned.
**Then:** KP-050 provisioned smoke (engineering runs it with you present).

## 🔴 F-4 · RevenueCat + store products (KP-002)

**What:** RevenueCat account + API keys; create products in App Store Connect / Play Console: `forever_friends` $5.99/mo · $39.99/yr, Heartstone bundles, Rescue Bundles (only the SKUs that survive KP-006/KP-007 decisions); sandbox testers.
**Engineering readiness:** `BillingService` seam + `RevenueCatBillingService` gate exist; the roadmap's `purchases_flutter` wiring is engineering work that activates when keys exist.
**Blocks:** any real revenue; paywall must stay honest until then (KP-003 disclosures shipped by engineering).

## 🔴 F-5 · Apple environment (KP-005 / KP-048)

**What:** Apple Developer account, a macOS/Xcode machine (or Codemagic credit — seam exists), a physical iPhone. First iOS build, CocoaPods resolution, signing, privacy-manifest validation via Organizer upload, TestFlight round.
**Engineering readiness:** `ios/Runner/PrivacyInfo.xcprivacy` is authored in-repo (KP-005 engineering leg); bundle id + Info.plist exist. iOS has **never** been compiled — budget for plugin/signing surprises.

## 🔴 F-6 · Donation claims decision (KP-006) — decide, sign, or stay silent

**What:** Either (a) operationalize: choose intermediary (PayPal Giving Fund / Percent / Benevity), sign agreements, pick 1–3 partner shelters, fix net-%, stand up the ledger + first disbursement — or (b) ratify the **claims-removal** engineering shipped in R1 (all specific impact/split claims removed from paywall + store copy until real).
**Why founder:** legal agreements + money movement (open decisions #4/#5).
**Engineering readiness:** ledger seams + Rescue Wall UI remain behind flags; copy re-add is trivial once claims become literally true.

## 🔴 F-6b · Enable GitHub Pages for the legal/support site (2 minutes) — KP-004

**What:** Repo Settings → Pages → Source: **GitHub Actions**. Then run the `Pages` workflow (or push anything under `site/`). The Privacy Policy, Terms, and Support pages are fully authored in `site/`, the deploy workflow exists (`.github/workflows/pages.yml`), and the app + store metadata already point at the final URLs (`https://emredogan-cloud.github.io/kindredpaws/{privacy,terms,support}/`).
**Why founder:** the harness guard blocks the agent from creating a new public web surface (attempted via `gh api .../pages`, denied 2026-07-09). Counsel review of the page content remains part of F-2/F-6.
**Roadmap:** KP-004 (everything else in its DoD is engineering-complete).

## 🔴 F-7 · Store listing assets & consoles (KP-008 / KP-051)

**What:** App Store Connect + Play Console access; upload final icon/screenshots (engineering produces candidates after R4); complete age/content questionnaires **consistent with F-2**; App Privacy / Data Safety labels **against the provisioned posture**; review notes.
**Engineering readiness:** text metadata already complete; icon/screenshot candidates are an R4/R7 engineering deliverable; the dry-run checklist is in the audit report §4–5.

## 🟠 F-8 · Rive rig commission or vector ratification (KP-030)

**What:** Decide the shipping character: commission original `.riv` rig(s) per `docs/RIVE_CONTRACTOR_HANDOFF.md` (~$1.2–2k/species + revisions, long lead — start now if chosen), **or** ratify the polished vector pet as the launch character.
**Engineering readiness:** drop-in seam is test-pinned (`assets/rive/README.md`, PR #62); R4 ships vector-pet polish + removes the icon-fallback either way.

## 🟠 F-9 · Soft-launch decisions (KP-052)

**What:** launch localization languages (open decision #6 — gates KP-041 beyond `en`), soft-launch geos (#7), subscription price validation (#8), live-LLM go/no-go for adults (#10). Then run the G3→G4 KPI gates on live cohorts.

## 🟡 F-10 · Physical-device install approval (KP-049)

**What:** On the connected Xiaomi (MIUI): Settings → Developer options → enable **Install via USB** (needs a MIUI account login), or tap the install-confirm dialog when the agent installs. Without it, emulator E2E remains the validation of record.

---

*Updated by engineering as items complete or new founder dependencies surface. Do not delete completed entries — mark them ✅ with date.*
