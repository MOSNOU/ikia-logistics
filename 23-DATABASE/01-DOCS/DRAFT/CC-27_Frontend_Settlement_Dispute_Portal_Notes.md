# CC-27 — Phase 2.20 Frontend Settlement & Dispute Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twenty-first platform step. Frontend-only — wires CC-17 `settlement.*`
and CC-18 `dispute.*` RPCs through Next.js Server Actions + server-rendered
pages across supplier, buyer, and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## What changed

### Files created (28)

**Server modules (15):**

| File | Coverage |
|---|---|
| `src/lib/settlement/list-buyer-settlements.ts` | `settlement.buyer_list_settlements` |
| `src/lib/settlement/list-supplier-settlements.ts` | `settlement.supplier_list_my_settlements` |
| `src/lib/settlement/get-settlement.ts` | Audience-switched read across buyer / supplier / admin variants |
| `src/lib/settlement/buyer-actions.ts` | `mark_ready`, `hold`, `release`, `cancel` |
| `src/lib/settlement/supplier-actions.ts` | `confirm_reconciliation`, `open_dispute` (settlement-side) |
| `src/lib/admin/list-settlements.ts` | `settlement.admin_list_settlements` |
| `src/lib/admin/list-settlement-events.ts` | `settlement.admin_list_settlement_events` |
| `src/lib/admin/settlement-admin-actions.ts` | `admin_force_settlement_status` |
| `src/lib/dispute/list-buyer-disputes.ts` | `dispute.buyer_list_disputes` |
| `src/lib/dispute/list-supplier-disputes.ts` | `dispute.supplier_list_my_disputes` |
| `src/lib/dispute/get-dispute.ts` | Audience-switched read |
| `src/lib/dispute/buyer-actions.ts` | `open_dispute`, `submit_evidence`, `withdraw_dispute` |
| `src/lib/dispute/supplier-actions.ts` | `submit_evidence`, `withdraw_dispute` |
| `src/lib/admin/list-disputes.ts` | `dispute.admin_list_disputes` |
| `src/lib/admin/list-dispute-events.ts` | `dispute.admin_list_dispute_events`, `_evidence`, `_decisions` |
| `src/lib/admin/dispute-admin-actions.ts` | `admin_start_review`, `admin_review_evidence`, `admin_record_decision`, `admin_cancel_dispute` |

**Pages + components (13):**

| Path | Purpose |
|---|---|
| `app/buyer/settlements/page.tsx` | List + filter |
| `app/buyer/settlements/[id]/page.tsx` + `buyer-settlement-actions.tsx` | Detail + mark_ready/hold/release/cancel |
| `app/supplier/settlements/page.tsx` | List + filter |
| `app/supplier/settlements/[id]/page.tsx` + `supplier-settlement-actions.tsx` | Detail + confirm_reconciliation + open_dispute |
| `app/admin/settlements/page.tsx` | List + filter |
| `app/admin/settlements/[id]/page.tsx` + `force-status-form.tsx` | Detail + items + events + emergency force-status |
| `app/buyer/disputes/page.tsx` + `open-dispute-form.tsx` | List + inline new-dispute form |
| `app/buyer/disputes/[id]/page.tsx` + `buyer-dispute-actions.tsx` | Detail + submit_evidence + withdraw |
| `app/supplier/disputes/page.tsx` | List + filter |
| `app/supplier/disputes/[id]/page.tsx` + `supplier-dispute-actions.tsx` | Detail + submit_evidence + (own-opened) withdraw |
| `app/admin/disputes/page.tsx` | Cross-tenant queue |
| `app/admin/disputes/[id]/page.tsx` + `admin-dispute-actions.tsx` + `admin-evidence-actions.tsx` | Detail + start_review + record_decision + cancel + per-evidence accept/reject |
| `src/components/dispute/dispute-summary.tsx` | Shared summary panel (evidence + decisions + events) reused across all three dispute detail pages |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-27" sections with 14 wrapper interfaces + 9 enum aliases across settlement (`SettlementStatus`, `SettlementDisputeStatus`, `EscrowStatus`) and dispute (`DisputeCaseStatus`, `DecisionOutcome`, `EvidenceStatus`, `EvidenceKind`, `DisputeSettlementAction`, `PartyRole`). |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-27. Added admin settlement + dispute checks. Added supplier settlement + dispute checks. Added buyer settlement + dispute checks. |

**Files NOT touched:** all migrations 0001–0032, every `settlement.*` / `dispute.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all KYC / pricing / notify / supplier / admin / buyer code from CC-19..CC-26, every other domain.

### Route inventory

12 new routes:

```
supplier:  /settlements, /settlements/[id], /disputes, /disputes/[id]
buyer:     /settlements, /settlements/[id], /disputes, /disputes/[id]
admin:     /settlements, /settlements/[id], /disputes, /disputes/[id]
```

Build route count: **43 → 55 (+12).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 12 | **55 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (admin + supplier + buyer + inbox + KYC sections all green) |

## Key design choices

1. **Audience-switched RPC dispatch.** `getSettlement(id, "buyer" | "supplier" | "admin")` and `getDispute(id, audience)` route to the matching SECURITY DEFINER RPC. The page is responsible for picking the right audience; RLS enforces correctness server-side anyway.
2. **`/buyer/disputes` opens new disputes inline.** Buyers paste a `settlement_id` UUID and a title. No separate `/new` route — keeps surface minimal. Open posts redirect to the new dispute's detail page.
3. **Status-driven action visibility.**
   - Buyer settlement actions appear only in legal transitions: `draft → ready` shows mark-ready; `ready → holding` shows hold; `holding → released` opens release form; `draft|ready → cancelled` opens cancel form.
   - Supplier settlement: `released → reconciled` shows confirm; `holding|released` shows open-dispute.
   - Buyer/supplier dispute: `opened|under_review` shows submit-evidence; suppliers can only withdraw disputes they opened (`opened_by_party === 'supplier'`); buyers can withdraw their own.
   - Admin dispute: `opened` shows start-review; `under_review` shows record-decision (with full outcome + settlement_action selectors + share amounts).
4. **`/admin/disputes/[id]` supplements the RPC payload.** `admin_get_dispute` returns a flat jsonb without sub-arrays, so the admin detail page calls the three list RPCs (events, evidence, decisions) in parallel and merges them into the same `DisputeDetail` shape `DisputeSummary` already expects. Buyer + supplier audiences get the sub-arrays directly from their respective RPCs.
5. **Force-status is gated behind a click-to-reveal toggle.** Admin emergency action requires explicit unfolding to prevent accidental mis-clicks.
6. **Currency-aware display.** All amounts are rendered with `toLocaleString("fa-IR")` next to the dispute / settlement currency code.

## Mid-execution findings

None. CC-17 and CC-18 RPC signatures mapped cleanly to TypeScript on the first pass; typecheck went green without iteration; build went green on the first attempt.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / migration changes. Settlement + dispute baselines are byte-identical.
- ✅ No new migrations. Migration list stays 0001–0032.
- ✅ No client-side Supabase mutations. All writes through `"use server"` modules.
- ✅ No new dependencies.
- ✅ No real-time / WebSocket / polling.
- ✅ No changes to existing supplier / admin / buyer routes.
- ✅ No changes to KYC / pricing / notify / commodity / RFQ / offer / contract / shipment / finance code.
- ✅ No cross-portal navigation injection (existing top-nav and sidebar lookups in `lib/config/nav.ts` untouched — appearance in nav is a future polish CC).

## Known limitations / handoff notes

1. **No file upload for evidence.** The `submit_evidence` flow takes a `title`, `kind`, and free-text `narrative`. The CC-18 RPC has no `storage_path` argument, so attachments live in narrative only for now.
2. **Open-dispute form takes a raw `settlement_id` UUID.** A picker driven by `buyer_list_settlements` is a future polish item; the current minimal pattern matches the existing pricing/KYC forms that also expect raw UUIDs.
3. **Admin force-status surface deliberately verbose.** Every target status is selectable. A safer narrowing (allow-list per current status) is possible in a future CC if oncall accidentally lands on the wrong transition.
4. **Supplier-side "open-dispute from settlement"** uses `settlement.supplier_open_dispute` (the settlement-domain shortcut). Suppliers can also open via `dispute.buyer_open_dispute` flow conceptually, but only buyers should — RLS enforces.
5. **No nav-bar entries added.** `lib/config/nav.ts` is unchanged; users reach `/supplier/settlements`, `/buyer/disputes`, etc., by direct URL or future nav update.
6. **`/admin/settlements/[id]` events RPC** calls `admin_list_settlement_events`, which only platform_admin can call (RLS). Buyer/supplier audiences see events embedded in the `get_my_settlement` jsonb instead — they cannot list events for arbitrary settlements.
7. **Decision form's share-amount inputs are optional.** The CC-18 RPC accepts them as optional; if you select `split` without shares, the RPC will apply server-side defaults / raise an error per its lifecycle rules — surfaced via the action's error toast.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 55 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm UUID-only settlement-id input on `/buyer/disputes` is acceptable as a starting point (vs. blocking on a settlement picker).
- [ ] Confirm CC-28 may proceed.
