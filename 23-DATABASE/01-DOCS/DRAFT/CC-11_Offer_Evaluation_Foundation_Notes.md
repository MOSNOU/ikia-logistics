# CC-11 — Phase 2.4 Offer Evaluation / Buyer Decision Foundation, Schema Notes

Version: 1.1 (DRAFT — acceptance addendum)
Scope: Fifth business domain — buyer-side offer evaluation, scoring, comparison snapshots, buyer decisions, supplier decision visibility, and immutable decision events
Migration: `23-DATABASE/migrations/0022_offer_evaluation_foundation.sql` (single, append-only). No new migration in v1.1.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Mission

CC-11 introduces the **buyer evaluation** surface. Buyer organizations evaluate the supplier offers they received in CC-10, record structured scoring across multiple dimensions, snapshot comparison views, and finalize decisions to shortlist, reject, or mark an offer as the one to advance toward contract preparation. Strictly scoped to evaluation and decision tracking — no contract generation, no award finalization, no shipment, no pricing engine, no escrow, no settlement, no payment, no negotiation.

## Relationship to existing foundations

| Foundation | How CC-11 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` for caller scope checks |
| organization | `organizations`, `memberships` for buyer-side and supplier-side RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` reused; decisions read by supplier portal callers filter by their own supplier_id |
| commodity | (none directly; evaluation operates on offer artefacts that already reference commodity) |
| rfq | `rfq.requests(id)` parent of every evaluation/decision/snapshot; buyer-org ownership derived via the RFQ |
| offer | `offer.supplier_offers(id)` is the central target of evaluation; offer status sync mirrors decisions for shortlist/reject only |
| audit | `audit.audit_event` written by `evaluation.fn_audit` and indirectly via the generic audit trigger on every `evaluation.*` table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0022_offer_evaluation_foundation.sql`. | CC-11 prompt |
| 2 | New `evaluation` schema. | CC-11 prompt |
| 3 | RPC namespaces: `evaluation.buyer_*`, `evaluation.supplier_*`, `evaluation.admin_*`. | CC-11 prompt |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-11 prompt |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-11 prompt |
| 6 | Buyer RPCs derive organization from `identity.current_organization_id()` — no `p_buyer_organization_id` parameter. | CC-11 prompt |
| 7 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — no `p_supplier_id` parameter. | CC-11 prompt |
| 8 | One active evaluation per `(offer_id, evaluator_user_id)` via partial unique index `WHERE deleted_at IS NULL`. | CC-11 prompt |
| 9 | One active decision per `offer_id` via partial unique index `WHERE deleted_at IS NULL`. Re-decision updates the same row and writes a `decision_events` row. | CC-11 prompt |
| 10 | `shortlist` and `reject` decisions sync `offer.supplier_offers.status` (and write `offer.supplier_offer_status_events`). `select_for_contract` does NOT change offer status. | CC-11 prompt |
| 11 | Evaluation is buyer-private. Suppliers cannot see evaluation rows / scores / snapshots. They CAN see decisions on their own offers (status + reason). | CC-11 prompt |
| 12 | Snapshots and decision_events are immutable: no UPDATE/DELETE policies. Inserts via RPC. | CC-11 prompt |
| 13 | Evaluation is only allowed on offers in status `submitted`, `shortlisted`, or `rejected`. `draft / withdrawn / expired / accepted` are not evaluatable. | CC-11 prompt |

## Schema overview

### Enums (2)

- `evaluation.evaluation_status` — `draft, in_review, completed, cancelled`
- `evaluation.decision_status` — `shortlisted, rejected, selected_for_contract`

### Tables (5)

| Table | Purpose |
|-------|---------|
| `evaluation.offer_evaluations` | Buyer evaluation record per `(offer, evaluator)`. Carries technical / commercial / risk / overall notes, status lifecycle, evaluator user. |
| `evaluation.offer_evaluation_scores` | Per-dimension scores attached to an evaluation. Suggested dimensions: `price, delivery, technical_compliance, document_readiness, supplier_reliability, payment_terms, risk, overall`. Per `(evaluation, lower(dimension))` upsert. |
| `evaluation.offer_comparison_snapshots` | **Immutable** buyer-side snapshot of comparison data (jsonb). No UPDATE/DELETE policies. |
| `evaluation.offer_decisions` | Buyer decision record per offer. Status can transition between `shortlisted`, `rejected`, `selected_for_contract`. |
| `evaluation.offer_decision_events` | **Immutable** audit trail of decision transitions. No UPDATE/DELETE policies. |

## Lifecycle / status model

### Evaluation

```
       buyer_create_evaluation (offer must be submitted/shortlisted/rejected)
                         │
                         ▼
                       draft
                         │
                buyer_update_evaluation / buyer_upsert_score / buyer_remove_score
                         │
              ┌──────────┴─────────────────┐
              │                            │
   buyer_complete_evaluation     buyer_cancel_evaluation
              │                            │
              ▼                            ▼
          completed (locked)         cancelled (locked)
```

`completed` and `cancelled` are terminal — both block further edits via `fn_assert_evaluation_editable` (P0001).

### Decision

```
                buyer_shortlist_offer / buyer_reject_offer / buyer_select_for_contract
                                            │
                                            ▼
                                  offer_decisions row exists
                                  with current decision_status

   Re-call with a different status -> updates the existing row in place
                                   -> writes one offer_decision_events row (from_status → to_status)
                                   -> for shortlist/reject only, syncs offer.supplier_offers.status
                                      and writes one offer.supplier_offer_status_events row
```

- Decisions are **mutable** by RPC: a `shortlisted` decision may be flipped to `rejected`, then to `selected_for_contract`. Each transition is recorded as a decision_event row.
- Idempotent re-call with the same status updates `reason`/`notes` only and writes no event.
- `selected_for_contract` never touches offer.status — contract preparation is a future CC.

## Security model

### RLS

All 5 tables have RLS enabled with predicates that admit three audiences:

1. **Buyer-side** — members of the buyer organization that owns the parent RFQ. Applies to: `offer_evaluations`, `offer_evaluation_scores`, `offer_comparison_snapshots`, `offer_decisions`, `offer_decision_events`.
2. **Supplier-side (decisions only)** — members of the supplier organization that owns the parent offer. Applies to: `offer_decisions`, `offer_decision_events`. **Not** to `offer_evaluations`, `offer_evaluation_scores`, or `offer_comparison_snapshots` — those are buyer-private.
3. **Platform admin** — always.

Backstop `*_admin_modify` policies on the mutable tables (`offer_evaluations`, `offer_evaluation_scores`, `offer_decisions`) allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Snapshots and decision_events have no INSERT/UPDATE/DELETE policies — append-only via RPC.

### Grants

```
anon          → offer_evaluations, offer_evaluation_scores,
                offer_decisions                                  SELECT (RLS returns 0 for anon)

authenticated → all 5 tables                                     SELECT
```

`offer_comparison_snapshots` and `offer_decision_events` are intentionally not exposed to anon. **No INSERT/UPDATE/DELETE direct grants on any evaluation table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `evaluation.fn_audit(action, resource_id, payload)` | Writes domain audit event; exception-swallowed. Resolves tenant/org from evaluations, decisions, or snapshots. |
| `evaluation.fn_assert_buyer_for_offer(offer_id)` | Raises `42501` if caller's org is not the RFQ-owning buyer org (or platform_admin). Returns `(buyer_org_id, request_id)`. Also requires `buyer_admin / organization_admin / platform_admin` role. |
| `evaluation.fn_assert_buyer_for_request(request_id)` | Same gate at RFQ scope (used by snapshot RPC). |
| `evaluation.fn_assert_offer_actionable(offer_id)` | Raises `P0001` unless offer.status ∈ `(submitted, shortlisted, rejected)`. |
| `evaluation.fn_assert_evaluation_owned(evaluation_id)` | Raises `42501` if caller's org doesn't own the evaluation. |
| `evaluation.fn_assert_evaluation_editable(evaluation_id)` | Raises `P0001` if evaluation.status not in `(draft, in_review)`. |
| `evaluation.fn_record_decision_event(...)` | Inserts immutable decision_events row. |
| `evaluation.fn_record_decision(offer_id, status, reason?, notes?)` | Shared implementation of the three decision RPCs. Idempotent on same-status re-call. |
| `evaluation.fn_sync_offer_status_for_decision(offer_id, status)` | Mirrors `shortlisted`/`rejected` decision into `offer.supplier_offers.status` and writes `offer.supplier_offer_status_events`. No-op for `selected_for_contract`. |

## RPC inventory (19)

### Buyer RPCs (12)

| Function | Vol | Purpose |
|----------|-----|---------|
| `buyer_create_evaluation(offer_id, evaluator?, notes...)` returns uuid | volatile | Creates draft evaluation. Verifies offer ownership + actionable status + no active duplicate (23505). |
| `buyer_update_evaluation(eval_id, notes...)` | volatile | Partial update of draft / in_review evaluation. |
| `buyer_upsert_score(eval_id, dimension, score, max, weight, weighted, notes)` returns uuid | volatile | Upsert by `(evaluation_id, lower(dimension))`. |
| `buyer_remove_score(score_id)` | volatile | Soft-delete a score row. |
| `buyer_complete_evaluation(eval_id)` | volatile | draft/in_review → completed. Writes audit event. |
| `buyer_cancel_evaluation(eval_id, reason?)` | volatile | draft/in_review → cancelled. |
| `buyer_create_comparison_snapshot(request_id, title, snapshot_data?, notes?)` returns uuid | volatile | Append-only snapshot. |
| `buyer_list_evaluations(request_id?, status?, limit, offset)` returns table | stable | List own org evaluations. |
| `buyer_get_evaluation(eval_id)` returns jsonb | stable | Detail with scores array. |
| `buyer_shortlist_offer(offer_id, reason?, notes?)` returns uuid | volatile | Create or transition decision to `shortlisted`. Syncs offer.status → `shortlisted`. |
| `buyer_reject_offer(offer_id, reason?, notes?)` returns uuid | volatile | Create or transition decision to `rejected`. Syncs offer.status → `rejected`. |
| `buyer_select_for_contract(offer_id, reason?, notes?)` returns uuid | volatile | Create or transition decision to `selected_for_contract`. **Does NOT** change offer.status. |

### Supplier RPCs (2 — read-only)

| Function | Vol | Purpose |
|----------|-----|---------|
| `supplier_list_my_decisions(status?, limit, offset)` returns table | stable | List decisions on caller's own offers. |
| `supplier_get_my_decision(decision_id)` returns jsonb | stable | Detail iff decision is on caller's supplier offers. |

### Admin RPCs (5)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_evaluations(request_id?, offer_id?, status?, limit, offset)` | stable | Cross-org admin list of evaluations. |
| `admin_get_evaluation(eval_id)` returns jsonb | stable | Detail with scores. |
| `admin_list_decisions(request_id?, offer_id?, status?, limit, offset)` | stable | Cross-org admin list of decisions. |
| `admin_get_decision(decision_id)` returns jsonb | stable | Detail with events. |
| `admin_list_decision_events(decision_id)` returns table | stable | Audit trail. |

**19 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`.

## Validation Summary

### Migration apply

```
Applying migration 20260622090022_offer_evaluation_foundation.sql...
Finished supabase db reset on branch main.
```

All 22 migrations apply cleanly. No mid-implementation fixes were required.

### Verification queries (snapshot)

- 5 `evaluation.*` tables, all `relrowsecurity = t`
- 0 INSERT/UPDATE/DELETE direct grants on `evaluation.*`
- 19 RPCs across buyer/supplier/admin namespaces
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 9 stable + 10 volatile (split matches read/write intent)
- 0 `buyer_*` RPCs accept `p_buyer_organization_id`
- 0 `supplier_*` RPCs accept `p_supplier_id`
- Single distinct owner across all evaluation RPCs

### pgTAP suite

```
================================================================
Files: 37 passed, 0 failed
Assertions: 209 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–032 | 174 | CC-05 through CC-10 (incl. acceptance) |
| **033 evaluation RLS, grants, RPC metadata** | **11** | **CC-11** |
| **034 buyer evaluation lifecycle** (create → score×2 → upsert dedupe → update → complete → get → snapshot) | **7** | **CC-11** |
| **035 evaluation scope + integrity** (cross-buyer block, draft offer block, completed lock, supplier role block, duplicate active rejection) | **5** | **CC-11** |
| **036 buyer decision lifecycle** (shortlist→reject→select_for_contract, offer.status sync semantics, events count) | **7** | **CC-11** |
| **037 supplier visibility** (own-decision visible, get-decision detail, foreign-supplier sees 0, foreign-supplier blocked 42501, evaluation rows invisible) | **5** | **CC-11** |
| **CC-11 new** | **35** | |
| **Suite total** | **209** | **across 37 files** |

### Frontend

CC-11 adds no frontend code. The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` does not yet expose the `evaluation` schema to PostgREST — must be added before any UI calls evaluation RPCs.

## Known limitations / handoff notes for CC-12

1. **`supabase/config.toml`** does not yet expose `evaluation` (or `offer`) to PostgREST. Future CC must add both to `[api].schemas` before frontend can call these RPCs.
2. **No contract generation.** `selected_for_contract` is the boundary — the next CC introduces contract preparation tables / RPCs from the selected decision.
3. **No multi-evaluator workflow.** The unique partial index allows one active evaluation per `(offer, evaluator_user_id)`, which inherently supports multiple evaluators per offer; however there is no aggregation, no approval workflow, no committee model. Score aggregation across evaluators is a future addition.
4. **No file storage for evaluation attachments.** Notes are text only.
5. **Comparison snapshots** are pure jsonb blobs. There is no schema validation on `snapshot_data`. UI is expected to define and version the snapshot shape.
6. **No award workflow / contract / shipment / pricing / settlement / escrow / payment / negotiation.** Same boundaries as CC-10.
7. **Decision history is mutable forward.** A decision row's `decision_status` field changes in place; the full history lives in `offer_decision_events`. UI should always render the decision history from events, not from the current decision row.
8. **`selected_for_contract` does NOT lock the offer.** A buyer can flip back to `rejected` or `shortlisted` (and the offer status will sync accordingly). The terminal "award" semantics are not yet introduced.
9. **No `Database` type entry for `evaluation`** in the frontend types file. Will be added when buyer evaluation UI lands.
10. **Cross-domain offer status sync** is one-way only (decision → offer). The reverse (admin force-changing offer.status without going through evaluation) does not touch decisions. This is intentional but should be revisited if admin overrides become common.
11. **No `expired` evaluation transition.** Evaluations don't expire; only the underlying offer can become expired (CC-10's `expired` status).

---

# Security Acceptance Addendum (v1.1)

Performed after CC-11 was provisionally complete, before any CC-12 (contract / award / shipment / pricing / settlement / escrow / payment / negotiation) work began. **No migration changes** — every check was verification-only. Migrations 0001–0022 untouched.

## 1. RLS verification on all 5 evaluation tables — ✅ PASS

| Table | `relrowsecurity` | `relforcerowsecurity` |
|-------|------------------|----------------------|
| evaluation.offer_evaluations          | t | f |
| evaluation.offer_evaluation_scores    | t | f |
| evaluation.offer_comparison_snapshots | t | f |
| evaluation.offer_decisions            | t | f |
| evaluation.offer_decision_events      | t | f |

All 5 tables have RLS enabled in standard (non-forced) mode — consistent with CC-03 through CC-10. `relforcerowsecurity = f` means table owner and superuser bypass; every other role is gated. Same posture as supplier/commodity/rfq/offer schemas.

## 2. Grants matrix — ✅ PASS

```
anon          → evaluation.offer_evaluations            SELECT
                evaluation.offer_evaluation_scores      SELECT
                evaluation.offer_decisions              SELECT

authenticated → evaluation.offer_evaluations            SELECT
                evaluation.offer_evaluation_scores      SELECT
                evaluation.offer_comparison_snapshots   SELECT
                evaluation.offer_decisions              SELECT
                evaluation.offer_decision_events        SELECT
```

`evaluation.offer_comparison_snapshots` and `evaluation.offer_decision_events` are intentionally NOT exposed to `anon` — comparison snapshots are buyer-private working artefacts and decision events are the immutable audit trail. Both are authenticated-only at the grant level (and further restricted by RLS).

## 3. No direct INSERT/UPDATE/DELETE grants — ✅ PASS

```sql
select count(*) from information_schema.role_table_grants
 where table_schema = 'evaluation'
   and grantee in ('anon', 'authenticated')
   and privilege_type in ('INSERT', 'UPDATE', 'DELETE');
-- 0
```

All mutations route through the 19 SECURITY DEFINER RPCs.

## 4. RPC metadata verification — ✅ PASS

All 19 evaluation `buyer_*` / `supplier_*` / `admin_*` RPCs:

| Property | Value |
|----------|-------|
| Distinct owners | 1 (`postgres`) |
| `security_definer = true` | 19 / 19 |
| `search_path` config | `search_path=""` on every function |
| Stable functions (reads) | 9 — `buyer_list_evaluations`, `buyer_get_evaluation`, `supplier_list_my_decisions`, `supplier_get_my_decision`, `admin_list_evaluations`, `admin_get_evaluation`, `admin_list_decisions`, `admin_get_decision`, `admin_list_decision_events` |
| Volatile functions (mutations) | 10 — `buyer_create_evaluation`, `buyer_update_evaluation`, `buyer_upsert_score`, `buyer_remove_score`, `buyer_complete_evaluation`, `buyer_cancel_evaluation`, `buyer_create_comparison_snapshot`, `buyer_shortlist_offer`, `buyer_reject_offer`, `buyer_select_for_contract` |

Internal helpers (`fn_audit`, `fn_record_decision_event`, `fn_sync_offer_status_for_decision`, `fn_record_decision`) are also SECURITY DEFINER with `search_path=""` but are not part of the buyer/supplier/admin surface count.

## 5. Buyer RPC safety — no `p_buyer_organization_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'evaluation'
   and p.proname like 'buyer_%'
   and p.proargnames is not null
   and 'p_buyer_organization_id' = any(p.proargnames);
-- 0
```

No `evaluation.buyer_*` RPC accepts a caller-supplied `p_buyer_organization_id`. The buyer organization is derived exclusively from `identity.current_organization_id()` (JWT), and verified against the parent RFQ owner inside `fn_assert_buyer_for_offer` / `fn_assert_buyer_for_request`.

## 6. Supplier RPC safety — no `p_supplier_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'evaluation'
   and p.proname like 'supplier_%'
   and p.proargnames is not null
   and 'p_supplier_id' = any(p.proargnames);
-- 0
```

No `evaluation.supplier_*` RPC accepts a caller-supplied `p_supplier_id`. The supplier is derived exclusively from `supplier.fn_portal_supplier_id()` (CC-07).

## 7. Buyer evaluation lifecycle verification — ✅ PASS

Covered by pgTAP test `034_evaluation_buyer_lifecycle.sql`:

```
ok 1 - buyer_create_evaluation creates evaluation with status=draft
ok 2 - two distinct dimension scores recorded
ok 3 - duplicate dimension upsert keeps count at 2 (idempotent on dimension)
ok 4 - buyer_update_evaluation patches overall_notes
ok 5 - buyer_complete_evaluation moves draft → completed
ok 6 - buyer_get_evaluation returns scores array of length 2
ok 7 - buyer_create_comparison_snapshot persists the snapshot row
```

End-to-end buyer flow: create draft → upsert two scores → re-upsert same dimension (idempotent) → patch notes → complete → read back via `buyer_get_evaluation` → snapshot.

## 8. Evaluation scope + integrity verification — ✅ PASS

Covered by pgTAP test `035_evaluation_scope_and_integrity.sql`:

```
ok 1 - buyer B cannot create evaluation on buyer A's offer (42501)
ok 2 - evaluation on a draft (not submitted) offer is rejected (P0001)
ok 3 - completed evaluation is locked from update (P0001)
ok 4 - supplier user cannot call buyer_create_evaluation (42501)
ok 5 - duplicate active evaluation for same evaluator+offer is rejected (23505)
```

`fn_assert_buyer_for_offer` is the load-bearing cross-org gate. `fn_assert_offer_actionable` blocks evaluation on non-actionable offer states (`draft`, `withdrawn`, `expired`, `accepted`). `fn_assert_evaluation_editable` blocks edits after `completed` / `cancelled`. Role gate blocks supplier-only users from buyer RPCs. Partial unique index `(offer_id, evaluator_user_id) WHERE deleted_at IS NULL` is the structural guard against duplicate active evaluations.

## 9. Decision lifecycle verification — ✅ PASS

Covered by pgTAP test `036_evaluation_decision_lifecycle.sql`:

```
ok 1 - buyer_shortlist_offer creates decision with status=shortlisted
ok 2 - shortlist syncs offer.status -> shortlisted
ok 3 - buyer_reject_offer transitions decision -> rejected
ok 4 - reject syncs offer.status -> rejected
ok 5 - buyer_select_for_contract transitions decision -> selected_for_contract
ok 6 - select_for_contract does NOT change offer.status
ok 7 - decision_events count = 3 (initial + 2 transitions)
```

Three buyer decision RPCs share `fn_record_decision`, which creates the decision row on first call and updates it in place on subsequent calls, always writing a `decision_events` row for state changes. The complete forward + sideways history lives in `offer_decision_events`.

## 10. Offer status sync boundaries — ✅ PASS

The sync rule lives in `evaluation.fn_sync_offer_status_for_decision`:

| Decision status | Offer status sync | Decision RPC |
|-----------------|-------------------|--------------|
| `shortlisted`            | offer.status → `shortlisted` | `buyer_shortlist_offer` |
| `rejected`               | offer.status → `rejected`    | `buyer_reject_offer`    |
| `selected_for_contract`  | **no change** to offer.status | `buyer_select_for_contract` |

Confirmed:

- **Shortlist/reject may sync offer status.** Tests 036/3, 036/4 verify the bidirectional mirror (`shortlisted` → `shortlisted`, then `rejected` → `rejected`).
- **`select_for_contract` must NOT create a contract.** No contract tables exist in this migration. The RPC writes a decision row and a decision_events row only. No new schema, no new tables, no contract semantics introduced.
- **`selected_for_contract` must NOT set offer status to `accepted`.** Test 036/6 verifies that `offer.status` remains the pre-existing value (`rejected` in the test scenario) after `buyer_select_for_contract` is called — i.e. the offer is never auto-promoted to `accepted`. The `accepted` status remains a placeholder reserved for the future contract / award foundation.
- **Sync gate is conservative.** `fn_sync_offer_status_for_decision` returns early if the offer's current status is not in `(submitted, shortlisted, rejected)`, so an admin-forced terminal state (`withdrawn`, `expired`, `accepted`) is never overwritten by a buyer decision.

## 11. Supplier decision visibility verification — ✅ PASS

Covered by pgTAP test `037_evaluation_supplier_visibility.sql`:

```
ok 1 - supplier X sees their own decision via supplier_list_my_decisions
ok 2 - supplier_get_my_decision returns decision_status=shortlisted
ok 3 - supplier Y sees 0 decisions (none of their offers)
ok 4 - supplier Y cannot read supplier X's decision (42501)
ok 5 - supplier cannot see evaluation rows via direct SELECT (RLS blocks)
```

Suppliers see decisions on offers they own (status + reason), and only those. They CANNOT see evaluation rows, scores, or comparison snapshots — evaluation is buyer-private. RLS on `evaluation.offer_evaluations` returns 0 rows to a supplier-only user even via direct SELECT.

## 12. Frontend validation — ✅ PASS

CC-11 added no frontend code. The frontend remains at its CC-07 surface (22 routes).

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

`supabase/config.toml` still does not expose the `evaluation` (or `offer`) schema to PostgREST — must be added before any UI calls these RPCs.

## 13. Suite totals — Before / After CC-11

| Metric | Pre-CC-11 (CC-10 v1.1 acceptance) | Post-CC-11 (acceptance addendum) |
|--------|-----------------------------------|----------------------------------|
| pgTAP files | 32 | **37** |
| pgTAP assertions | 174 | **209** |
| Migrations | 21 | 22 |
| Schemas | identity, organization, audit, supplier, commodity, rfq, offer | identity, organization, audit, supplier, commodity, rfq, offer, **evaluation** |
| Backend RPCs (admin + portal/buyer/supplier surfaces) | 90 | **109** (+19 evaluation) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 14. Final status

**CC-11 is FULLY ACCEPTED.**

- ✅ RLS verified on all 5 evaluation tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE
- ✅ RPC ownership consistent (single owner `postgres`), all `security_definer`, all `search_path=""`
- ✅ Buyer RPC safety — no `p_buyer_organization_id` argument
- ✅ Supplier RPC safety — no `p_supplier_id` argument
- ✅ Buyer evaluation lifecycle provable by pgTAP (test 034)
- ✅ Evaluation scope + cross-org block + state locks + duplicate rejection provable (test 035)
- ✅ Decision lifecycle (shortlist → reject → select_for_contract) provable (test 036)
- ✅ Offer status sync boundaries verified — shortlist/reject sync; `select_for_contract` does NOT, does NOT create a contract, does NOT promote offer to `accepted`
- ✅ Supplier decision visibility provable (test 037) — supplier sees own decisions only, cannot read evaluation rows
- ✅ Frontend typecheck + build + route guards green
- ✅ pgTAP suite 209 / 209 across 37 files
- ✅ No new business domain code introduced
- ✅ No CC-12 work started (no contract / award / shipment / pricing / settlement / escrow / payment / negotiation)
