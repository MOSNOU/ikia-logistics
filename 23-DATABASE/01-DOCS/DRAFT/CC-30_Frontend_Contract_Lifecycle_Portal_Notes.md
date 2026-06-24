# CC-30 — Phase 2.23 Frontend Contract Lifecycle Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twenty-fourth platform step. Frontend-only — wires CC-14 `contract.*`
RPCs (preparation + executed + signatures) through Next.js Server Actions +
server-rendered pages across the buyer, supplier, and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 7 routes shipped | buyer × 3 + supplier × 2 + admin × 2. |
| Q2 | A — `/buyer/contracts/new` with `?decision_id=` prefill | RPC takes `p_decision_id`, not `p_offer_id`; URL param updated to match. |
| Q3 | A — tabbed view inside `/buyer/contracts` | `?tab=preparations\|executed`; same in `/admin/contracts`. |
| Q4 | Mapped to CC-14's actual surface | CC-14 exposes `admin_force_cancel_*`, `admin_supersede_*`, `admin_void_contract` — three discrete buttons rather than an arbitrary status selector. Narrower than CC-27 settlement but wider than CC-28 RFQ. |
| Q5 | A — single `[id]` URL accepts both | `getContractUnified` tries `get_preparation` first, falls back to `get_executed_contract`; page picks the right view. Same URL works after promotion. |
| Q6 | A — sidecar wrappers + enums | 6 wrappers + 6 enum aliases (`PreparationStatus`, `ContractStatus`, `SignatureStatus`, `ContractPartyType`, `ContractClauseType`, `PreparationContractType`). |
| Q7 | A — verifier extended | All 7 routes asserted under CC-30 section. |
| Q8 | A — per-row signature accept/decline | Decline opens a reason input inline. Audience-aware (supplier vs buyer dispatch). |
| Q9 | A — explicit promote-to-executed button | Surfaced only when status = `ready_for_contract`; reuses same `[id]` URL post-promotion (Q5). |
| Q10 | A — stop at green pgTAP + typecheck + build + verifier | No manual browser smoke. |

## Mid-execution finding — Preparation is keyed to decision_id, not offer_id

The draft assumed `?offer_id=` URL prefill from the evaluation page. Inspection showed `buyer_create_preparation` takes `p_decision_id` (the id returned by CC-29's `buyer_select_for_contract`), not the offer id. The implementation was adjusted:
- `/buyer/contracts/new` accepts `?decision_id=` (not `?offer_id=`).
- The hidden field name is `decisionId`.
- A future polish CC can add an `?offer_id=` → decision_id resolver if buyers ask for offer-keyed deep links.

This is a model adjustment, not a scope cut — every CC-14 RPC the buyer needs is wired.

## What changed

### Files created (21)

**Server modules (7):**

| File | Coverage |
|---|---|
| `src/lib/contract/list-buyer-contracts.ts` | `contract.buyer_list_preparations` + `contract.buyer_list_executed_contracts` |
| `src/lib/contract/list-supplier-contracts.ts` | `supplier_list_my_preparations`, `_executed_contracts`, `_signature_requests` |
| `src/lib/contract/get-contract.ts` | Audience-switched read + `getContractUnified` (tries prep → executed) |
| `src/lib/contract/buyer-actions.ts` | 11 Server Actions: create / update / add-party / upsert-clause / remove-clause / move-to-review / mark-ready / promote-to-executed / cancel-preparation / mark-pending-signatures / cancel-executed |
| `src/lib/contract/signature-actions.ts` | 5 Server Actions: buyer create / sign / decline; supplier sign / decline |
| `src/lib/admin/list-contracts.ts` | `admin_list_preparations` + `admin_list_executed_contracts` |
| `src/lib/admin/contract-admin-actions.ts` | 5 admin Server Actions: force-cancel × 2, supersede × 2, void |

**Pages + components (14):**

| Path | Purpose |
|---|---|
| `app/buyer/contracts/page.tsx` | Tabbed queue (preparations / executed) |
| `app/buyer/contracts/new/page.tsx` + `create-preparation-form.tsx` | New preparation with `?decision_id=` prefill |
| `app/buyer/contracts/[id]/page.tsx` | Dispatcher — picks preparation vs executed view |
| `app/buyer/contracts/[id]/preparation-view.tsx` | Header + parties + clauses + events + status actions |
| `app/buyer/contracts/[id]/executed-view.tsx` | Header + parties + signature requests + events + status actions |
| `app/buyer/contracts/[id]/preparation-status-actions.tsx` | move-to-review / mark-ready / promote / cancel |
| `app/buyer/contracts/[id]/executed-status-actions.tsx` | mark-pending-signatures / cancel |
| `app/buyer/contracts/[id]/add-party-form.tsx` | Add party form |
| `app/buyer/contracts/[id]/upsert-clause-form.tsx` | Upsert clause form |
| `app/buyer/contracts/[id]/remove-clause-button.tsx` | One-click clause delete |
| `app/buyer/contracts/[id]/create-signature-request-form.tsx` | Signature request creation (party picker from existing parties) |
| `app/buyer/contracts/[id]/signature-request-actions.tsx` | Per-row sign / decline (audience-aware) |
| `app/supplier/contracts/page.tsx` + `app/supplier/contracts/[id]/page.tsx` | Supplier list + reuses buyer's view components in `audience="supplier"` mode |
| `app/admin/contracts/page.tsx` + `app/admin/contracts/[id]/page.tsx` + `admin-force-actions.tsx` | Tabbed admin queue + read-only detail + cancel/supersede/void panel |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-30: Contract portal types" section with 6 wrapper interfaces + 6 enum aliases. |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-30. Added admin + supplier + buyer contract page checks. |

**Files NOT touched:** all migrations 0001–0032, every `contract.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all CC-22..CC-29 portal code, every other domain.

### Route inventory

7 new routes:

```
buyer:     /contracts, /contracts/new, /contracts/[id]
supplier:  /contracts, /contracts/[id]
admin:     /contracts, /contracts/[id]
```

Build route count: **71 → 78 (+7).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 7 | **78 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (all sections green, including new CC-30 entries) |

## Key design choices

1. **Unified `[id]` URL across phases (Q5=A).** `getContractUnified` tries `get_preparation` first; on null, tries `get_executed_contract`. After buyer clicks "ایجاد قرارداد اجرایی", the redirect goes to the new executed-contract id — same URL pattern, new id; bookmarks remain valid because both ids resolve through the dispatcher.
2. **Shared view components across audiences.** `PreparationView` and `ExecutedView` accept an `audience` prop (`"buyer" | "supplier" | "admin"`). Supplier + admin detail pages import these from the buyer route. No duplication; status actions hide for non-buyer audiences via prop logic.
3. **Status-driven action visibility:**
   - Preparation: `draft → under_review → ready_for_contract → (promote → executed.draft_execution)`. Each transition is a separate button visible only at the right status; cancel available at any non-terminal status.
   - Executed: `draft_execution → pending_signatures → (signatures recorded) → executed`. Buyer can mark-pending and cancel until pending_signatures.
4. **Signature dispatch is audience-aware.** The `SignatureRequestActions` component swaps the Server Action based on `audience`: supplier sees `supplier_sign_*` / `supplier_decline_*`; buyer sees the same RPCs but on the buyer schema; admin sees a read-only status badge.
5. **Admin force surface = three discrete buttons.** `cancel`, `supersede`, `void` (executed-only). No arbitrary status selector exists in CC-14 RPCs — Q4=A maps to whatever CC-14 actually exposes.
6. **`?decision_id=` deep-link prefill.** `/buyer/contracts/new` accepts `?decision_id=<uuid>` from the URL; the create form defaults the field to that value so a buyer flowing from `/buyer/evaluations/[id]` can land with the decision id pre-filled.

## Mid-execution findings (1, accommodated)

1. **Preparation creation takes `p_decision_id` (not `p_offer_id`).** The draft suggested `?offer_id=` URL prefill; switched to `?decision_id=`. A future polish CC could add an `?offer_id=` → decision lookup helper if buyers prefer offer-keyed deep links.

No compile-time iterations needed; CC-14 RPC signatures mapped cleanly on the first pass.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / migration changes. CC-14 byte-identical.
- ✅ No new migrations.
- ✅ No client-side Supabase mutations — Server Actions only.
- ✅ No e-signature provider integration — `sign_signature_request` records via the existing RPC.
- ✅ No PDF generation / contract document rendering.
- ✅ No file upload for attachments.
- ✅ No automatic shipment / settlement creation downstream of execution.
- ✅ No contract template library / clause reuse UI.
- ✅ No KYC gating on preparation creation or promotion.
- ✅ No nav-bar entries added.
- ✅ No new dependencies — `package.json` untouched.

## Known limitations / handoff notes

1. **No comparison snapshots UI.** CC-14 exposes `buyer_create_snapshot` and `buyer_create_executed_snapshot` — both are reachable via RPC but not wired to UI buttons in CC-30. A future polish CC can add "snapshot history" tabs.
2. **No buyer-side party editor.** Add-party form is available; no `buyer_update_party` or `buyer_remove_party` RPC exists in CC-14, so party rows are append-only from the UI.
3. **No buyer-side item editor.** CC-14 doesn't expose `buyer_upsert_preparation_item` — items inherit from the offer at preparation-creation time and are not editable in CC-30.
4. **Signature requests cannot be revoked from the UI.** CC-14 has no `buyer_cancel_signature_request` RPC; the only way to invalidate a pending request is to cancel the whole executed contract.
5. **Admin cannot force a status other than cancel / supersede / void.** Q4 mapped to what CC-14 exposes — no arbitrary status selector. A future migration could add one and the UI can pick it up.
6. **`/buyer/contracts/new` requires raw `decision_id` UUID.** Most buyers will reach this route via a future "ایجاد قرارداد" CTA on `/buyer/evaluations/[id]` (not built in CC-30) that passes `?decision_id=` automatically; for now, paste from the evaluation page's decisions table.
7. **`update_executed_contract` and `update_preparation` RPCs exist but aren't surfaced** as a dedicated edit page. The preparation view's notes/terms are read-only after creation. A future CC could add an edit drawer.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 78 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm the `?decision_id=` URL contract (vs `?offer_id=`) is acceptable.
- [ ] Confirm the unified `[id]` URL pattern across preparation + executed phases is acceptable.
- [ ] Confirm CC-31 may proceed.
