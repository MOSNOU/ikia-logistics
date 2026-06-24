# CC-12 — Phase 2.5 Contract Preparation Foundation, Schema Notes

Version: 1.1 (DRAFT — acceptance addendum)
Scope: Sixth business domain — buyer-side contract preparation derived from `selected_for_contract` decisions, including preparation header, preparation items, structured clauses, immutable snapshots, immutable lifecycle events, and supplier read-visibility into preparations connected to their own selected offer
Migration: `23-DATABASE/migrations/0023_contract_preparation_foundation.sql` (single, append-only). No new migration in v1.1.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Mission

CC-12 introduces the **contract preparation** surface. Once a buyer organization records a `selected_for_contract` decision in CC-11, an authorized buyer user can build a structured contract-preparation package: a preparation header carrying commercial/legal terms, line items derived from the selected supplier offer, clause rows organized by clause type, immutable preparation snapshots, and an immutable transition trail. Strictly scoped to **preparation** — no formal contract execution, no e-signature, no payment, no shipment, no pricing engine, no escrow, no settlement, no invoice, no negotiation chat.

## Relationship to existing foundations

| Foundation | How CC-12 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` for caller scope checks |
| organization | `organizations`, `memberships` for buyer/supplier RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` for supplier-side visibility; `supplier.suppliers(id)` FK |
| commodity | `commodity.products(id)` referenced via `contract_preparation_items.product_id` |
| rfq | `rfq.requests(id)` parent of every preparation; `rfq.request_items(id)` referenced by preparation items |
| offer | `offer.supplier_offers(id)` is the selected offer; `offer.supplier_offer_items(id)` is the source of preparation items |
| evaluation | `evaluation.offer_decisions(id)` with `decision_status = 'selected_for_contract'` is the **only** valid trigger for creating a preparation |
| audit | `audit.audit_event` written by `contract.fn_audit` and indirectly via the generic audit trigger on every `contract.*` table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0023_contract_preparation_foundation.sql`. | CC-12 prompt |
| 2 | New `contract` schema. | CC-12 prompt |
| 3 | RPC namespaces: `contract.buyer_*`, `contract.supplier_*`, `contract.admin_*`. | CC-12 prompt |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-12 prompt |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-12 prompt |
| 6 | Buyer RPCs derive organization from `identity.current_organization_id()` — no `p_buyer_organization_id` parameter. | CC-12 prompt |
| 7 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — no `p_supplier_id` parameter. | CC-12 prompt |
| 8 | Preparation creation requires a decision with `decision_status='selected_for_contract'`. | CC-12 prompt #15 |
| 9 | One active preparation per `decision_id` (partial unique index `WHERE deleted_at IS NULL AND status <> 'superseded'`). | CC-12 prompt #15 |
| 10 | `ready_for_contract` is a state label only — no contract / signature / payment / shipment is created. | CC-12 prompt #5, #15 |
| 11 | Preparation items are **derived** from the selected offer items at creation time (copy semantics, then editable). | CC-12 prompt #16 |
| 12 | Cross-domain integrity (request_id ↔ offer.request_id ↔ decision.request_id ↔ buyer org) is asserted in `fn_assert_buyer_for_decision`. | CC-12 prompt #16 |
| 13 | Snapshots and events tables are immutable: no UPDATE/DELETE policies, no UPDATE/DELETE grants. | CC-12 prompt #8, #9 |
| 14 | Clauses are buyer-private. Suppliers cannot read clause rows. | CC-12 design |

## Schema overview

### Enums (4)

- `contract.preparation_status` — `draft, under_review, ready_for_contract, cancelled, superseded`
- `contract.preparation_contract_type` — `spot, framework, term, other`
- `contract.preparation_clause_type` — `payment, delivery, inspection, quality, documents, force_majeure, dispute_resolution, governing_law, special_conditions, other`
- `contract.preparation_snapshot_type` — `initial_from_offer, review_snapshot, ready_for_contract_snapshot`

### Tables (5)

| Table | Purpose |
|-------|---------|
| `contract.contract_preparations` | Preparation header per selected decision. Carries commercial/legal text fields, contract_type, currency, incoterm, delivery, status lifecycle, prepared_by user, supplier+supplier_organization references. |
| `contract.contract_preparation_items` | Line items derived from the selected offer's items (offer_item_id is the source pointer). Editable while preparation is draft/under_review. |
| `contract.contract_preparation_clauses` | Structured clauses per (preparation, clause_type, clause_key). Bilingual title_fa/en + body_fa/en. Buyer-private. |
| `contract.contract_preparation_snapshots` | **Immutable** preparation snapshots (initial / review / ready). No UPDATE/DELETE policies. |
| `contract.contract_preparation_events` | **Immutable** lifecycle event trail. Every transition writes one row. No UPDATE/DELETE policies. |

## Preparation lifecycle

```
       buyer_create_preparation (decision must be selected_for_contract)
                         │
                         ▼
                       draft
                         │ buyer_update_preparation / buyer_upsert_clause /
                         │ buyer_remove_clause / buyer_create_snapshot
                         │
              buyer_move_to_under_review
                         │
                         ▼
                    under_review
                         │ buyer_update_preparation still allowed
                         │
              buyer_mark_ready_for_contract
                         │
                         ▼
              ready_for_contract  (locked from normal edits)
                         │
                         │ admin_force_cancel_preparation         admin_supersede_preparation
                         ▼                                                  ▼
                     cancelled                                         superseded
```

- `draft` and `under_review` are the only editable states.
- `ready_for_contract`, `cancelled`, and `superseded` are terminal/locked for normal buyer edits.
- `cancelled` can be set by buyer (`buyer_cancel_preparation`) from any non-cancelled/non-superseded state, or by admin (`admin_force_cancel_preparation`).
- `superseded` is admin-only (`admin_supersede_preparation`); it removes the row from the "active per decision" uniqueness slot so a new preparation can be created for the same decision.
- Every transition writes one `contract_preparation_events` row and one `audit.audit_event` row.

## Security model

### RLS

All 5 tables have RLS enabled with predicates that admit three audiences:

1. **Buyer-side** — members of the buyer organization that owns the parent RFQ. Applies to all 5 tables.
2. **Supplier-side (preparations + items + events only)** — members of the supplier organization that owns the selected offer. **Not** to `contract_preparation_clauses` or `contract_preparation_snapshots` — those are buyer-private working artefacts.
3. **Platform admin** — always.

Backstop `*_admin_modify` policies on the mutable tables (`contract_preparations`, `contract_preparation_items`, `contract_preparation_clauses`) allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Snapshots and events have no INSERT/UPDATE/DELETE policies — append-only via RPC.

### Grants

```
anon          → contract_preparations, contract_preparation_items                 SELECT (RLS returns 0 for anon)

authenticated → all 5 tables                                                       SELECT
```

`contract_preparation_clauses`, `contract_preparation_snapshots`, and `contract_preparation_events` are intentionally not exposed to anon. **No INSERT/UPDATE/DELETE direct grants on any contract table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `contract.fn_audit(action, preparation_id, payload)` | Writes domain audit event; exception-swallowed. |
| `contract.fn_record_preparation_event(...)` | Inserts immutable events row for a transition. |
| `contract.fn_assert_buyer_for_decision(decision_id)` | Verifies role + caller org + decision is `selected_for_contract` + decision's RFQ is owned by caller's org. Returns `(buyer_org_id, request_id, offer_id, supplier_id, supplier_organization_id, decision_status)`. |
| `contract.fn_assert_preparation_owned(preparation_id)` | Raises `42501` if caller's org doesn't own the preparation. |
| `contract.fn_assert_preparation_editable(preparation_id)` | Raises `P0001` if status not in `(draft, under_review)`. |
| `contract.fn_next_preparation_code(tenant_id)` | Generates `PREP-YYYY-XXXXXXXX` codes. Tenant-scoped uniqueness via the table's partial unique index. |

## RPC inventory (18)

### Buyer RPCs (11)

| Function | Vol | Purpose |
|----------|-----|---------|
| `buyer_create_preparation(decision_id, title, ...)` returns uuid | volatile | Creates draft preparation from a selected_for_contract decision. Copies offer items into preparation_items. Auto-creates `initial_from_offer` snapshot. Writes initial event (null → draft). |
| `buyer_update_preparation(preparation_id, ...)` | volatile | Partial update of draft/under_review preparation. |
| `buyer_upsert_clause(preparation_id, clause_type, clause_key?, title_fa?, title_en?, body_fa?, body_en?, source?, is_required?, sort_order?)` returns uuid | volatile | Upsert by `(preparation_id, clause_type, lower(clause_key))`. |
| `buyer_remove_clause(clause_id)` | volatile | Soft-delete a clause. |
| `buyer_create_snapshot(preparation_id, snapshot_type, title, snapshot_data?, notes?)` returns uuid | volatile | Append-only snapshot. |
| `buyer_move_to_under_review(preparation_id)` | volatile | draft → under_review. Writes event. |
| `buyer_mark_ready_for_contract(preparation_id)` | volatile | draft/under_review → ready_for_contract. Writes event. **Does NOT create any formal contract.** |
| `buyer_cancel_preparation(preparation_id, reason?)` | volatile | Any non-terminal state → cancelled. Writes event. |
| `buyer_list_preparations(request_id?, status?, limit, offset)` | stable | List own org preparations. |
| `buyer_get_preparation(preparation_id)` returns jsonb | stable | Detail with items / clauses / snapshots. |
| `buyer_list_preparation_events(preparation_id)` returns table | stable | Audit trail for own preparation. |

### Supplier RPCs (2 — read-only)

| Function | Vol | Purpose |
|----------|-----|---------|
| `supplier_list_my_preparations(status?, limit, offset)` returns table | stable | List preparations on caller's own selected offers. |
| `supplier_get_my_preparation(preparation_id)` returns jsonb | stable | Detail iff preparation is on caller's supplier offer. Excludes clauses (buyer-private). |

### Admin RPCs (5)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_preparations(request_id?, offer_id?, supplier_id?, status?, limit, offset)` | stable | Cross-org admin list. |
| `admin_get_preparation(preparation_id)` returns jsonb | stable | Detail with items / clauses / events. |
| `admin_list_preparation_events(preparation_id)` returns table | stable | Audit trail. |
| `admin_force_cancel_preparation(preparation_id, reason?)` | volatile | Admin override to `cancelled`. Writes event. |
| `admin_supersede_preparation(preparation_id, reason?)` | volatile | Admin override to `superseded`. Frees the unique-active slot for a new preparation. |

**18 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`.

## Validation Summary

### Migration apply

```
Applying migration 20260622090023_contract_preparation_foundation.sql...
Finished supabase db reset on branch main.
```

All 23 migrations apply cleanly. No mid-implementation fixes were required.

### Verification queries (snapshot)

- 5 `contract.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `contract.*`
- 18 RPCs across buyer/supplier/admin namespaces (11 buyer + 2 supplier + 5 admin)
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 8 stable + 10 volatile (split matches read/write intent)
- 0 `buyer_*` RPCs accept `p_buyer_organization_id`
- 0 `supplier_*` RPCs accept `p_supplier_id`
- Single distinct owner across all contract RPCs

### pgTAP suite

```
================================================================
Files: 42 passed, 0 failed
Assertions: 246 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–037 | 209 | CC-05 through CC-11 (incl. acceptance) |
| **038 contract RLS, grants, RPC metadata** | **11** | **CC-12** |
| **039 buyer preparation lifecycle** (create → items derived → snapshot → update → clause upsert/dedupe/remove → manual snapshot → under_review → ready_for_contract → locked) | **11** | **CC-12** |
| **040 scope + integrity** (cross-buyer block, shortlisted block, rejected block, duplicate active rejection, no cross-domain side-effect schemas) | **5** | **CC-12** |
| **041 transitions + events immutability** (under_review event, ready event, offer not auto-accepted, direct UPDATE/DELETE on events blocked) | **5** | **CC-12** |
| **042 supplier visibility** (own preparation visible, get-detail returns row, foreign supplier sees 0, foreign supplier blocked 42501, clauses invisible to supplier) | **5** | **CC-12** |
| **CC-12 new** | **37** | |
| **Suite total** | **246** | **across 42 files** |

### Frontend

CC-12 added no frontend code. The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` does not yet expose the `contract` (or `evaluation`, or `offer`) schema to PostgREST — must be added before any UI calls these RPCs.

## Known limitations / handoff notes for CC-13

1. **`supabase/config.toml`** does not expose `contract` / `evaluation` / `offer` to PostgREST. Future CC must add these to `[api].schemas` before frontend can call these RPCs.
2. **`ready_for_contract` is a state label only.** No contract execution, no signature workflow, no payment, no shipment, no invoice are created by the RPC. The next CC is expected to introduce the formal-contract module that consumes `ready_for_contract` preparations.
3. **No e-signature, no notarization, no PDF rendering.** Clauses are structured text only.
4. **Preparation items are a one-shot copy from offer items.** Edits on offer items after preparation creation do not propagate. Re-sync is out of scope — `superseded` + new preparation is the intended path for major source changes.
5. **No multi-supplier preparation.** Each preparation targets exactly one selected offer (one supplier). Multi-party agreements are not modeled.
6. **No revision/versioning beyond `superseded`.** A superseded preparation frees the unique-active slot but there is no explicit `parent_preparation_id` self-FK. Add if version trees become a requirement.
7. **No supplier counter-edit surface.** Suppliers have read-only visibility; they cannot propose changes to the preparation. Negotiation chat / counter-edit is out of scope (CC-12 prompt explicitly excludes negotiation).
8. **Clauses are buyer-private.** A "share-with-supplier" toggle on clauses is not modeled. UI/UX for showing/hiding clauses to the supplier is a future addition.
9. **Cross-domain integrity is RPC-enforced, not FK-enforced.** `preparation.request_id` matching `offer.request_id` matching `decision.request_id` is checked in `fn_assert_buyer_for_decision`. Direct INSERTs by `service_role` bypassing RPCs could violate the invariants; mitigated by no-direct-write-grants on `authenticated`.
10. **`ready_for_contract` does not auto-promote `offer.status` to `accepted`.** This is intentional: `accepted` remains reserved for the future contract-execution module. Test 041/3 verifies this.
11. **Snapshot schema is unvalidated jsonb.** Snapshot rendering / diff UI is a future concern.
12. **No `Database` type entry for `contract`** in the frontend types file. Will be added when buyer preparation UI lands.

---

# Security Acceptance Addendum (v1.1)

Performed after CC-12 was provisionally complete, before any CC-13 (final contract execution / e-signature / shipment / pricing engine / settlement / escrow / payment / invoice / negotiation) work began. **No migration changes** — every check was verification-only. Migrations 0001–0023 untouched.

## 1. RLS verification on all 5 contract tables — ✅ PASS

| Table | `relrowsecurity` | `relforcerowsecurity` |
|-------|------------------|----------------------|
| contract.contract_preparations          | t | f |
| contract.contract_preparation_items     | t | f |
| contract.contract_preparation_clauses   | t | f |
| contract.contract_preparation_snapshots | t | f |
| contract.contract_preparation_events    | t | f |

All 5 tables have RLS enabled in standard (non-forced) mode — consistent with CC-03 through CC-11. `relforcerowsecurity = f` means table owner and superuser bypass; every other role is gated. Same posture as supplier/commodity/rfq/offer/evaluation schemas.

## 2. Grants matrix — ✅ PASS

```
anon          → contract.contract_preparations         SELECT
                contract.contract_preparation_items    SELECT

authenticated → contract.contract_preparations         SELECT
                contract.contract_preparation_items    SELECT
                contract.contract_preparation_clauses  SELECT
                contract.contract_preparation_snapshots SELECT
                contract.contract_preparation_events   SELECT
```

`contract_preparation_clauses` (buyer-private), `contract_preparation_snapshots` (working artefacts), and `contract_preparation_events` (audit trail) are intentionally NOT exposed to `anon`. All five tables are restricted further by RLS so the SELECT grant alone never reveals unauthorized rows.

## 3. No direct INSERT/UPDATE/DELETE grants — ✅ PASS

```sql
select count(*) from information_schema.role_table_grants
 where table_schema = 'contract'
   and grantee in ('anon', 'authenticated')
   and privilege_type in ('INSERT', 'UPDATE', 'DELETE');
-- 0
```

All mutations route through the 18 SECURITY DEFINER RPCs.

## 4. RPC metadata verification — ✅ PASS

All 18 contract `buyer_*` / `supplier_*` / `admin_*` RPCs:

| Property | Value |
|----------|-------|
| Distinct owners | 1 (`postgres`) |
| `security_definer = true` | 18 / 18 |
| `search_path` config | `search_path=""` on every function |
| Stable functions (reads) | 8 — `buyer_list_preparations`, `buyer_get_preparation`, `buyer_list_preparation_events`, `supplier_list_my_preparations`, `supplier_get_my_preparation`, `admin_list_preparations`, `admin_get_preparation`, `admin_list_preparation_events` |
| Volatile functions (mutations) | 10 — `buyer_create_preparation`, `buyer_update_preparation`, `buyer_upsert_clause`, `buyer_remove_clause`, `buyer_create_snapshot`, `buyer_move_to_under_review`, `buyer_mark_ready_for_contract`, `buyer_cancel_preparation`, `admin_force_cancel_preparation`, `admin_supersede_preparation` |

Internal helpers (`fn_audit`, `fn_record_preparation_event`, `fn_assert_buyer_for_decision`, `fn_assert_preparation_owned`, `fn_assert_preparation_editable`, `fn_next_preparation_code`) are also SECURITY DEFINER with `search_path=""` but are not part of the buyer/supplier/admin surface count.

## 5. Buyer RPC safety — no `p_buyer_organization_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'contract'
   and p.proname like 'buyer_%'
   and p.proargnames is not null
   and 'p_buyer_organization_id' = any(p.proargnames);
-- 0
```

No `contract.buyer_*` RPC accepts a caller-supplied `p_buyer_organization_id`. The buyer organization is derived exclusively from `identity.current_organization_id()` (JWT) and verified against the parent RFQ owner inside `fn_assert_buyer_for_decision` / `fn_assert_preparation_owned`.

## 6. Supplier RPC safety — no `p_supplier_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'contract'
   and p.proname like 'supplier_%'
   and p.proargnames is not null
   and 'p_supplier_id' = any(p.proargnames);
-- 0
```

No `contract.supplier_*` RPC accepts a caller-supplied `p_supplier_id`. The supplier is derived exclusively from `supplier.fn_portal_supplier_id()` (CC-07).

## 7. Buyer preparation lifecycle verification — ✅ PASS

Covered by pgTAP test `039_contract_buyer_lifecycle.sql`:

```
ok 1  - buyer_create_preparation creates preparation with status=draft
ok 2  - items derived from the selected offer items (count=1)
ok 3  - initial_from_offer snapshot is auto-created on preparation create
ok 4  - buyer_update_preparation patches incoterm
ok 5  - buyer_upsert_clause adds one clause
ok 6  - upsert with same (clause_type, clause_key) is idempotent — count stays at 1
ok 7  - buyer_remove_clause soft-deletes the clause
ok 8  - buyer_create_snapshot persists a review_snapshot
ok 9  - buyer_move_to_under_review transitions draft → under_review
ok 10 - buyer_mark_ready_for_contract transitions under_review → ready_for_contract
ok 11 - ready_for_contract preparation is locked from update (P0001)
```

End-to-end buyer flow: create draft (with auto offer-item copy and initial snapshot) → patch header → add clause → re-upsert same key (idempotent) → remove clause → manual snapshot → under_review → ready_for_contract → locked.

## 8. Creation from `selected_for_contract` decision verification — ✅ PASS

Covered by pgTAP test `039_contract_buyer_lifecycle.sql` step 1 (preparation with status=draft created from a `selected_for_contract` decision) and pgTAP test `040_contract_scope_and_integrity.sql` steps 2–3:

```
ok 2 - preparation from a shortlisted decision is rejected (P0001)
ok 3 - preparation from a rejected decision is rejected (P0001)
```

`fn_assert_buyer_for_decision` raises `P0001` if `decision.decision_status <> 'selected_for_contract'`. The only valid trigger for `buyer_create_preparation` is a `selected_for_contract` decision row.

## 9. Cross-buyer isolation verification — ✅ PASS

Covered by pgTAP test `040_contract_scope_and_integrity.sql`:

```
ok 1 - buyer B cannot create preparation from buyer A's decision (42501)
```

`fn_assert_buyer_for_decision` compares `identity.current_organization_id()` against the RFQ's owning organization (which is also the buyer org on the decision). Non-matching caller orgs are rejected with `42501` before any preparation row can be inserted. Platform admin bypasses the org check.

## 10. Duplicate active preparation rejection — ✅ PASS

Covered by pgTAP test `040_contract_scope_and_integrity.sql`:

```
ok 4 - duplicate active preparation for same decision is rejected (23505)
```

Partial unique index `(decision_id) WHERE deleted_at IS NULL AND status <> 'superseded'` is the structural guard; the RPC also performs an explicit duplicate check before INSERT to raise a clear `23505`.

## 11. Offer-item derivation verification — ✅ PASS

Covered by pgTAP test `039_contract_buyer_lifecycle.sql` step 2:

```
ok 2 - items derived from the selected offer items (count=1)
```

`buyer_create_preparation` performs `INSERT INTO contract.contract_preparation_items ... SELECT ... FROM offer.supplier_offer_items WHERE offer_id = v_offer_id AND deleted_at IS NULL` so every active offer item becomes one preparation item, carrying offer_item_id as a back-pointer. Editable while preparation is `draft` / `under_review`.

## 12. Clause lifecycle verification — ✅ PASS

Covered by pgTAP test `039_contract_buyer_lifecycle.sql` steps 5–7:

```
ok 5 - buyer_upsert_clause adds one clause
ok 6 - upsert with same (clause_type, clause_key) is idempotent — count stays at 1
ok 7 - buyer_remove_clause soft-deletes the clause
```

Partial unique index `(preparation_id, clause_type, coalesce(lower(clause_key), '')) WHERE deleted_at IS NULL` enforces the upsert key; ON CONFLICT clause updates in place. Soft-delete frees the slot for a new clause of the same key.

## 13. Snapshot immutability verification — ✅ PASS

`contract.contract_preparation_snapshots` has:

- No `UPDATE` policy.
- No `DELETE` policy.
- No INSERT/UPDATE/DELETE grants to `anon` / `authenticated`.
- An `INSERT` route via `buyer_create_snapshot` (SECURITY DEFINER) only.

Snapshot rows are therefore append-only by both grant and policy. The `initial_from_offer` snapshot is auto-created by `buyer_create_preparation`; subsequent snapshots are created via `buyer_create_snapshot` (test 039 step 8 verifies `review_snapshot` persistence).

## 14. Event immutability verification — ✅ PASS

Covered by pgTAP test `041_contract_transitions_and_events.sql` steps 4–5:

```
ok 4 - direct UPDATE on events row is blocked (no grant)
ok 5 - direct DELETE on events row is blocked (no grant)
```

`contract.contract_preparation_events` has:

- No `UPDATE` / `DELETE` policy.
- No `INSERT` / `UPDATE` / `DELETE` grants to `anon` / `authenticated`.
- An `INSERT` route via `fn_record_preparation_event` (SECURITY DEFINER) only, called by every state-changing RPC.

`authenticated` direct UPDATE / DELETE attempts raise `42501` (no grant). Every transition `(draft → under_review → ready_for_contract → cancelled / superseded)` writes exactly one event row.

## 15. `ready_for_contract` transition verification — ✅ PASS

Covered by pgTAP test `041_contract_transitions_and_events.sql` steps 1–2:

```
ok 1 - draft → under_review transition writes one event row
ok 2 - under_review → ready_for_contract transition writes one event row
```

`buyer_mark_ready_for_contract` transitions `draft` / `under_review` → `ready_for_contract`, sets `ready_at` + `ready_by`, writes one `contract_preparation_events` row, and writes one `audit.audit_event` row. Subsequent normal-edit RPCs raise `P0001`.

## 16. `ready_for_contract` boundary — ✅ PASS

`ready_for_contract` is a **state label only**. It does **not** create any cross-domain side effects:

| Concern | Verification | Result |
|---------|-------------|--------|
| Formal contract execution | No `execution` schema exists (test 040/5). No contract-execution table, no RPC that creates one. | ✅ not created |
| Signatures               | No `signature` schema exists (test 040/5). No signature table.                                  | ✅ not created |
| Shipment                 | No `shipment` schema exists (test 040/5).                                                       | ✅ not created |
| Pricing engine           | No `pricing` table / engine introduced.                                                          | ✅ not created |
| Settlement               | No `settlement` schema exists (test 040/5).                                                      | ✅ not created |
| Escrow                   | No `escrow` schema exists (test 040/5).                                                          | ✅ not created |
| Payment                  | No `payment` schema exists (test 040/5).                                                         | ✅ not created |
| Invoice                  | No `invoice` schema exists (test 040/5).                                                         | ✅ not created |
| Negotiation              | No `negotiation` schema exists (test 040/5).                                                     | ✅ not created |

Additionally:

```
ok 3 - ready_for_contract does not promote offer to accepted (no auto-execution)
```

`buyer_mark_ready_for_contract` does **not** mutate `offer.supplier_offers.status`. The `accepted` value remains reserved for the future contract-execution module. CC-12 introduces no cross-domain auto-promotion. `offer.status` after `ready_for_contract` remains whichever value it held when `buyer_select_for_contract` was called (typically `submitted` / `shortlisted` / `rejected`).

## 17. Supplier preparation visibility — ✅ PASS

Covered by pgTAP test `042_contract_supplier_visibility.sql`:

```
ok 1 - supplier X sees their own preparation via supplier_list_my_preparations
ok 2 - supplier_get_my_preparation returns the preparation title
ok 3 - supplier Y sees 0 preparations (none of their offers)
ok 4 - supplier Y cannot read supplier X's preparation (42501)
ok 5 - supplier cannot see buyer-private clauses (RLS blocks)
```

Suppliers see only preparations connected to their own selected offer. They CANNOT see clauses (buyer-private working artefacts). `supplier_get_my_preparation` excludes clauses from the returned jsonb shape entirely.

## 18. Frontend validation — ✅ PASS

CC-12 added no frontend code. The frontend remains at its CC-07 surface (22 routes). Frontend sanity checks were re-run for acceptance parity with CC-07 through CC-11:

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

`supabase/config.toml` still does not expose `contract` (nor `evaluation` / `offer`) to PostgREST — must be added before any UI calls these RPCs.

## 19. Suite totals — Before / After CC-12

| Metric | Pre-CC-12 (CC-11 v1.1 acceptance) | Post-CC-12 (acceptance addendum) |
|--------|-----------------------------------|----------------------------------|
| pgTAP files | 37 | **42** |
| pgTAP assertions | 209 | **246** |
| Migrations | 22 | 23 |
| Schemas | identity, organization, audit, supplier, commodity, rfq, offer, evaluation | identity, organization, audit, supplier, commodity, rfq, offer, evaluation, **contract** |
| Backend RPCs (admin + portal/buyer/supplier surfaces) | 109 | **127** (+18 contract) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 20. Final status

**CC-12 is FULLY ACCEPTED.**

- ✅ RLS verified on all 5 contract tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE
- ✅ RPC ownership consistent (single owner `postgres`), all `security_definer`, all `search_path=""`
- ✅ Buyer RPC safety — no `p_buyer_organization_id` argument
- ✅ Supplier RPC safety — no `p_supplier_id` argument
- ✅ Buyer preparation lifecycle provable by pgTAP (test 039)
- ✅ Creation gated on `selected_for_contract` decisions (tests 039, 040)
- ✅ Cross-buyer isolation provable — `42501` (test 040)
- ✅ Duplicate active preparation rejection provable — `23505` (test 040)
- ✅ Offer-item derivation provable (test 039)
- ✅ Clause upsert / dedupe / soft-delete provable (test 039)
- ✅ Snapshot immutability enforced by grant + policy (no UPDATE/DELETE surface)
- ✅ Event immutability provable — direct UPDATE/DELETE blocked (test 041)
- ✅ `ready_for_contract` transitions write events (test 041)
- ✅ `ready_for_contract` boundary enforced — no cross-domain side effects: no execution / signature / shipment / pricing / settlement / escrow / payment / invoice / negotiation schema or auto-promotion (test 040, test 041)
- ✅ Supplier preparation visibility provable — own only, clauses hidden (test 042)
- ✅ Frontend typecheck + build + route guards green (no frontend code added)
- ✅ pgTAP suite 246 / 246 across 42 files
- ✅ No new business domain code introduced
- ✅ No CC-13 work started (no final contract execution / e-signature / shipment / pricing engine / settlement / escrow / payment / invoice / negotiation)
