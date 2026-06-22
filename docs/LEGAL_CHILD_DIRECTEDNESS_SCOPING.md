# Legal Review Scoping — Child-Directedness & Compliance (P0 deliverable)

The **scope** for the budgeted pre-launch legal review. The G0 pass criterion is
"legal review booked" (a founder action); the binding sign-off itself is a **G3
gate** (Risk R1, the existential risk). **This is not legal advice** — it is the
question list + materials package to hand the reviewing attorney so the review is
efficient and complete.

> Canonical risk framing: brief §11 R1, GAME_TECHNICAL_SYSTEMS.md §11,
> GAMEPLAY_AND_PROGRESSION_BIBLE.md §18. Open Decision #9 (under-13 handling) is
> resolved at the G3 legal review.

## 1. The central determination
Is KindredPaws **"child-directed"** (or "mixed-audience") under COPPA, and the
analogous determinations under **GDPR-K (UK/EU)** and the **Apple App Store /
Google Play "Kids/Families"** policies? This single answer drives the age-gate
model (Open Decision #9: neutral age gate vs. fully-child-safe-for-all). The
product's working assumption (and what the engineering already builds to) is
**child-safe for ALL users**.

## 2. Materials to provide the attorney
- This file + brief §9, §11 and GAMEPLAY_AND_PROGRESSION_BIBLE.md §18 (ethics).
- The Heartmind hybrid architecture (no free-text storage from minors; under-13
  templated/non-generative only; two-sided moderation; fixed safe-fallback;
  self-harm static message) — GAME_TECHNICAL_SYSTEMS.md §4.5.
- The data map: account id, save data, closed-set memory facts, coarse analytics
  (no PII), no behavioral ad targeting; on-device-only voice (Deferred).
- The donation model (% NET revenue via vetted intermediary; NO donation-IAP;
  Compassion Coins are not tax-deductible) — `docs/IMPACT_PLEDGE.md`.

## 3. Question list for the review
1. Child-directed / mixed-audience determination (COPPA, GDPR-K, store Kids policy).
2. If child-directed: required age-gate / parental-consent (VPC) flow, and whether
   AI dialogue may be offered to under-13 at all (vs. templated-only).
3. Data-collection compliance: is the closed-set memory store + no-free-text-from-
   minors posture sufficient? Retention & right-to-be-forgotten path.
4. Advertising: confirm contextual-only / no-behavioral-targeting for minors meets
   COPPA + store kids rules; mediation SDK kids-config requirements.
5. AI safety/liability: adequacy of two-sided moderation + audit logging + the
   self-harm static-message path; any disclosures required.
6. Donation/charitable-solicitation: legality of the "% of NET revenue" claim and
   Rescue Bundles (commercial, disclosed split) across target markets; that
   Compassion Coins are NOT represented as tax-deductible player donations.
7. Voice mimic (Deferred): conditions under which on-device-only DSP voice is
   permissible for minors (biometric/consent).
8. Store-policy: gacha/loot-box ban compliance (we ship none), subscription
   cancellation, privacy nutrition labels / Data Safety form accuracy.

## 4. Outputs needed from the review (close G3)
- Written child-directedness determination + the required age-gate model.
- A compliance checklist signed off before closed beta (G3: "legal green-light").
- Approved privacy-policy + store data-disclosure language.

## 5. Booking (G0 action)
- [ ] Engage counsel with mobile games + children's-privacy (COPPA/GDPR-K) +
      charitable-solicitation experience.
- [ ] Budget the engagement (R1 mandates it is budgeted, not skipped).
- [ ] Schedule so the binding sign-off lands before P3/G3.
