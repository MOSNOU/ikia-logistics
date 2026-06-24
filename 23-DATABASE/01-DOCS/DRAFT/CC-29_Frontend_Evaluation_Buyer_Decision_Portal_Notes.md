# CC-29 — Phase 2.22 Frontend Evaluation & Buyer Decision Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Twenty-third platform step. Frontend-only — wires CC-13 `evaluation.*`
RPCs through Next.js Server Actions + server-rendered pages across the
buyer and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 5 routes shipped | buyer × 3 + admin × 2. |
| Q2 | A — dedicated `/buyer/rfqs/[id]/evaluate` entry point | redirects to existing eval when one exists for the offer. |
| Q3 | A — inline upsert score form (per dimension) | matches CC-24/27 inline-upsert pattern. |
| Q4 | Downgraded to read-only admin | CC-13 exposes no `admin_force_*_status` RPC for evaluations or decisions, so admin pages stay strictly read-only (intent of Q4=A, executed as Q4=C). |
| Q5 | A — no supplier-side visibility changes | supplier learns outcomes through CC-28 offer detail + CC-26 inbox. |
| Q6 | A — sidecar wrappers + enums | 6 wrappers + 2 enum aliases (`EvaluationStatus`, `DecisionStatus`). |
| Q7 | A — verifier extended | all 5 routes asserted under CC-29 section. |
| Q8 | A — per-offer decision posts immediately | each of `shortlist` / `select_for_contract` / `reject` is a separate Server Action. |
| Q9 | A — client-side weighted total | "امتیاز وزنی تجمعی" advisory column on `/buyer/evaluations/[id]`. |
| Q10 | A — stop at green pgTAP + typecheck + build + verifier | No manual browser smoke. |

## Mid-execution finding — Evaluation is per-OFFER, not per-RFQ matrix

The draft assumed a per-RFQ scoring "sheet" model where buyers add criteria once and score every offer along them. Inspection of the regenerated `database.ts` showed CC-13 actually models each **offer** as carrying its own **evaluation**, with free-text `dimension` score lines inside it. Decisions then target the offer directly via three buyer RPCs (`buyer_shortlist_offer`, `buyer_select_for_contract`, `buyer_reject_offer`), not the evaluation.

The implementation was adjusted accordingly:
- `/buyer/rfqs/[id]/evaluate` lists the RFQ's received offers and offers a "ایجاد ارزیابی" CTA per offer (or "مشاهده ارزیابی" if one already exists).
- `/buyer/evaluations/[id]` is a single-offer view with notes + score lines + decision buttons that target the linked `offer_id`.
- No matrix UI; no shared "criteria" entity.

This is a model adjustment, not a scope cut — every CC-13 RPC the buyer needs is wired.

## What changed

### Files created (16)

**Server modules (5):**

| File | Coverage |
|---|---|
| `src/lib/evaluation/list-buyer-evaluations.ts` | `evaluation.buyer_list_evaluations` |
| `src/lib/evaluation/get-evaluation.ts` | Audience-switched buyer/admin read |
| `src/lib/evaluation/buyer-actions.ts` | 9 Server Actions: create / update / upsert-score / remove-score / complete / cancel / shortlist / select-for-contract / reject |
| `src/lib/admin/list-evaluations.ts` | `evaluation.admin_list_evaluations` |
| `src/lib/admin/list-evaluation-decisions.ts` | `evaluation.admin_list_decisions` + `admin_list_decision_events` |

**Pages + components (11):**

| Path | Purpose |
|---|---|
| `app/buyer/evaluations/page.tsx` | List + filter |
| `app/buyer/evaluations/[id]/page.tsx` | Detail: notes + scores + decisions |
| `app/buyer/evaluations/[id]/evaluation-status-actions.tsx` | complete / cancel |
| `app/buyer/evaluations/[id]/notes-form.tsx` | overall / commercial / technical / risk notes |
| `app/buyer/evaluations/[id]/upsert-score-form.tsx` | per-dimension score upsert |
| `app/buyer/evaluations/[id]/remove-score-button.tsx` | one-click delete per score |
| `app/buyer/evaluations/[id]/decision-actions.tsx` | shortlist / select-for-contract / reject buttons |
| `app/buyer/rfqs/[id]/evaluate/page.tsx` | RFQ-scoped evaluation entry: list offers + per-offer CTA |
| `app/buyer/rfqs/[id]/evaluate/create-evaluation-button.tsx` | `buyer_create_evaluation` post → redirect |
| `app/admin/evaluations/page.tsx` | Cross-tenant queue |
| `app/admin/evaluations/[id]/page.tsx` | Read-only detail with decisions list |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added "CC-29: Evaluation portal types" section with 6 wrapper interfaces + 2 enum aliases. |
| `scripts/verify-admin-route-guards.sh` | Header expanded to CC-29. Added admin evaluation pages + buyer evaluation pages (including `rfqs/[id]/evaluate`). |

**Files NOT touched:** all migrations 0001–0032, every `evaluation.*` SQL surface, `database.ts` generated file, `supabase/config.toml`, all CC-22..CC-28 portal code, every other domain.

### Route inventory

5 new routes:

```
buyer:  /evaluations, /evaluations/[id], /rfqs/[id]/evaluate
admin:  /evaluations, /evaluations/[id]
```

Build route count: **66 → 71 (+5).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows by 5 | **71 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (all sections green, including new CC-29 entries) |

## Key design choices

1. **Per-offer evaluation model.** Each evaluation row corresponds to exactly one offer; scores are free-text `dimension` lines inside that evaluation. No shared criteria entity.
2. **Decision actions target the offer, not the evaluation.** `buyer_shortlist_offer` / `buyer_select_for_contract` / `buyer_reject_offer` post against `p_offer_id`; the evaluation page reads `evaluation.offer_id` and forwards it.
3. **Status-driven editor visibility:**
   - Notes editor + score upsert + score-remove available when `status in ('draft', 'in_review')`.
   - Complete button needs at least one score row.
   - Decision actions appear only when the evaluation is `completed`.
4. **Advisory weighted total (Q9=A):** sum of `weighted_score` values across score rows, rendered as a header card. Pure client-side computation; no RPC change.
5. **Read-only admin pages.** With no force-status RPC available, the admin detail page renders evaluation + scores + decisions; no destructive actions exposed.
6. **`/buyer/rfqs/[id]/evaluate` deduplicates per offer.** It builds a `Map<offer_id, evaluation_id>` from `buyer_list_evaluations({ requestId })` and shows either "ایجاد ارزیابی" or "مشاهده ارزیابی" per offer row, preventing accidental double-creation.

## Mid-execution findings (1, accommodated)

1. **No `admin_force_*_status` RPC for evaluations or decisions.** Q4 default fell back to the C-equivalent (admin read-only). The admin detail page surfaces decisions via the public `admin_list_decisions` RPC for transparency.

No compile-time iterations needed; CC-13 RPC signatures mapped cleanly on the first pass.

## Boundaries respected

- ✅ No DB / RPC / RLS / grant / trigger / migration changes. CC-13 byte-identical.
- ✅ No new migrations.
- ✅ No client-side Supabase mutations — Server Actions only.
- ✅ No multi-buyer voting / consensus UI.
- ✅ No automatic decision based on weighted total — advisory only.
- ✅ No supplier-side score visibility.
- ✅ No file upload / contract-prep / nav-bar changes.
- ✅ No bulk score import / Excel paste.
- ✅ No real-time updates.
- ✅ No KYC / pricing / quotation cross-domain UI changes.
- ✅ No new dependencies — `package.json` untouched.

## Known limitations / handoff notes

1. **No `comparison snapshot` UI.** CC-13 exposes `buyer_create_comparison_snapshot(p_request_id, p_title, p_snapshot_data, p_notes)` but it's not wired in CC-29 — adding it later only needs a button on `/buyer/rfqs/[id]/evaluate`.
2. **Manual evaluator-user UUID input.** The "create evaluation" CTA doesn't ask for `p_evaluator_user_id`; it defers to the RPC default (the caller). A picker can be added later.
3. **Score `weighted_score` is buyer-input, not auto-computed server-side.** If a future helper RPC computes `weight × score / max_score`, the UI can stop asking for it.
4. **Admin pages depend on `admin_get_evaluation` returning embedded scores.** If the RPC's projection ever changes, the page renders an empty scores table without breaking.
5. **`/buyer/evaluations/[id]` only shows decisions bundled inside `buyer_get_evaluation`.** If the bundling is later removed, the page should call `admin_list_decisions({ offer_id })` instead — same pattern already implemented for the admin detail page.
6. **No nav-bar entry for evaluations.** Buyers reach them via the existing RFQ detail page (which already links to `/buyer/rfqs/[id]/evaluate` per Q2=A; the verifier asserts the route exists).
7. **Supplier-side outcome visibility is fully handled by CC-28 + CC-26.** When a buyer rejects / shortlists / selects an offer, the offer's status flips via `fn_sync_offer_status_for_decision` and the supplier sees it on `/supplier/offers/[id]` and through the inbox.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 71 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm the per-offer evaluation model (vs. matrix sheet) is acceptable as it matches the actual CC-13 RPC surface.
- [ ] Confirm admin pages staying read-only is acceptable (no force-status RPC exists in CC-13).
- [ ] Confirm CC-30 may proceed.
