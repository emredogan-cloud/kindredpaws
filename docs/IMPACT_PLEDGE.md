# The Impact Pledge — v0.1 (DRAFT skeleton) · KindredPaws

**Version 0.1 · Status: DRAFT (skeleton)** — the single, version-stamped source
of truth for every public "% of revenue" / impact claim (brief §9 trust pillar
1). Final percentages and the named intermediary/partners are finalized with
accounting + legal **before G4** (Open Decisions #4, #5) and re-stamped to v1.0.

> Canonical model: brief §9 + GAMEPLAY_AND_PROGRESSION_BIBLE.md §10 +
> GAME_DECISION_LOG.md (donation-ethics, D-021/D-047). This doc must never
> contradict them or invent figures.

## 1. The model (locked, Reconciled Conflict #4)
**Transparent Pooled Allocation with 1:1 Impact Mapping.** A percentage of
**NET** revenue (net of store fees 15–30%, payment processing, ad-network cut)
accrues to a segregated, auditable **Impact Pool** ledger, disbursed on a fixed
cadence through an **established giving-platform intermediary** to **1–3 vetted
partner shelters**. All "X% of revenue" claims are stated **NET**.

## 2. Hard ethical wall (non-negotiable, D-047)
- **Never** tie the virtual pet's wellbeing/survival to real donations.
- **Never** guilt-frame a donation ask. Donations are framed as shared pride.
- **Free players still generate real impact** via ad-funded daily "kind act" Coins.
- **NO donation-IAP, NO player tax-deductible donations in MVP.** Compassion
  Coins represent pooled intent, not personal deductible gifts.

## 3. Illustrative NET-revenue allocation (TO FINALIZE before G4)
| Revenue type | Illustrative donation slice (NET) |
|---|---|
| Rewarded ad watch | ~5% |
| IAP / Forever Friends subscription | ~5–10% |
| Donation-linked Rescue Bundles | ~70% of bundle price (disclosed pre-purchase + on receipt) |

Compassion Coin mapping (illustrative, always rounded DOWN): **50 Coins = 1 real
meal**. These figures are placeholders pending the §6 finalization.

## 4. Intermediary shortlist (Open Decision #4 — decide before G4)
| Candidate | Notes |
|---|---|
| **PayPal Giving Fund** | Broad nonprofit coverage; no platform fee on many flows; well-known. |
| **Percent** | API-first disbursement + vetting; built for in-product giving. |
| **Benevity** | Enterprise-grade vetting/reporting; heavier. |

Selection criteria: charity vetting rigor, disbursement API, fees, receipt/
acknowledgment support, multi-market coverage. Partners must be registered
nonprofits with a Charity Navigator/GuideStar rating + audited financials.

## 5. Trust pillars (brief §9) — engineering already supports these
- Segregated, append-only Impact-Pool ledger (`BackendService.append`,
  GAME_TECHNICAL_SYSTEMS.md §7.2); disburse only after the settlement window.
- Rescue Wall shows lifetime/personal real $, live campaign bars, **dated
  downloadable receipts**, partner acknowledgments; outcome claims rounded DOWN.
- Per-bundle donated-vs-cosmetic+fee split disclosed pre-purchase.
- Quarterly co-signed Impact Report (G6); third-party "Impact verified through
  <date>" badge past a volume threshold.
- Platform-native anti-fraud gates Coin minting (S2S postbacks + receipt
  validation + attestation) so represented impact maps only to PAID revenue.

## 6. To finalize before G4 (re-stamp to v1.0)
- [ ] Lock the exact donation % per revenue type with accounting + legal (#5).
- [ ] Select the intermediary + 1–3 named partner shelters (#4).
- [ ] Legal review of the revenue-share claim wording per market.
- [ ] Stand up the segregated Impact-Pool account + reconciliation process.
