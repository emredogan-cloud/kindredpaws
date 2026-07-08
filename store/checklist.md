# Store submission checklist (P4-8) — prepare only, DO NOT publish

The gate from "closed-beta-ready" to a store submission. Engineering prepares the
version-controlled metadata; the credentialed store steps are founder actions.

## Text metadata (done — `store/metadata/en-US/`, length-validated)
- [x] title, subtitle, short_description, keywords, promotional_text
- [x] description, release_notes
- [ ] Localized metadata for the launch languages (Open Decision #6; AI-translate
      + human spot-check, per `docs/CONTENT_OPERATING_SYSTEM.md`)

## Visual assets (founder + design)
- [ ] App icon (1024×1024, no alpha) — cozy rescue motif
- [ ] iOS screenshots (6.7" + 6.5" + 5.5" + iPad) — capture via `just screenshots`
      / `just e2e-android`: Rescue Day, the companion + speech bubble, a memory
      callback, a Keepsake card, the Nest, the impact/Rescue Wall
- [ ] Android phone + tablet screenshots + feature graphic (1024×500)
- [ ] App preview video (optional) — the Rescue Day cold-open
- [ ] Each screenshot caption emphasizes one pillar (rescue · memory · impact · cozy)

## Privacy + compliance (gate)
- [x] Data Safety / privacy nutrition labels drafted (`store/privacy/data_safety.md`)
- [ ] Public privacy policy URL + support URL live — pages authored in `site/`
      (privacy/terms/support), deploy workflow `.github/workflows/pages.yml`
      ready, URLs wired in-app (`lib/core/legal_links.dart`) + in
      `metadata/en-US/privacy_url.txt`/`support_url.txt` (KP-003/KP-004).
      **Founder:** enable GitHub Pages (Settings → Pages → Source: GitHub
      Actions) and have counsel review the pages (F-2/F-7).
- [ ] **G3 child-directedness legal sign-off** (Open Decision #9) — blocks listing;
      drives "Made for Kids" / age rating / Kids-category choice
- [ ] Age rating questionnaires completed from `data_safety.md` inputs

## Products + accounts (credentialed — REQUIRED_ENVIRONMENTS)
- [ ] Forever Friends subscription + Heartstone/Rescue-Bundle IAPs created in App
      Store Connect + Play Console, mapped in RevenueCat (§5)
- [ ] AdMob app + ad units with COPPA/kids config (§6)
- [ ] Firebase project provisioned (§1); signing credentials (§3/§4)
- [ ] Giving-platform account + 1–3 vetted partner shelters (§7, before G4)

## Release pipeline
- [ ] Release notes flow: Release Please generates the changelog from Conventional
      Commits → `release_notes.txt` is the curated player-facing "What's New"
- [ ] Build numbers / versioning via Release Please (no hand-edited versions)
- [ ] **Submit to closed/internal testing track only** — do NOT publish to production
