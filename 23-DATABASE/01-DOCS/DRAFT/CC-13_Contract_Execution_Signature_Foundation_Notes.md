# CC-13 — Phase 2.6 Contract Execution / Signature Foundation, Schema Notes

Version: 1.1 (DRAFT — acceptance addendum)
Scope: Seventh business domain step — formal contract execution and signature workflow built atop CC-12, including executed contracts, executed items, executed clauses, contract parties, signature requests, immutable signature events, immutable execution snapshots, and immutable contract lifecycle events
Migration: `23-DATABASE/migrations/0024_contract_execution_signature_foundation.sql` (single, append-only). No new migration in v1.1.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Mission

CC-13 promotes a `ready_for_contract` preparation into a formal executable contract record. The contract carries its own normalized items and clauses (copied from CC-12 preparation), its parties (buyer + supplier auto-added, plus any extras), and a structured signature-request workflow that drives the contract to `executed` once every required signer has signed. Strictly scoped to **execution and signatures** — no shipment, no pricing engine, no settlement, no escrow, no payment, no invoice, no accounting, no negotiation.

## Relationship to existing foundations

| Foundation | How CC-13 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` for caller scope checks |
| organization | `organizations`, `memberships` for buyer/supplier RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` for supplier-side signature visibility; `supplier.suppliers(id)` FK |
| commodity | `commodity.products(id)` referenced via `executed_contract_items.product_id` |
| rfq | `rfq.requests(id)` parent of every contract |
| offer | `offer.supplier_offers(id)` is the source offer |
| evaluation | `evaluation.offer_decisions(id)` is the source decision |
| contract (CC-12) | `contract.contract_preparations(id)` with `status='ready_for_contract'` is the **only** valid trigger for execution. Items and clauses are copied from preparation rows. |
| audit | `audit.audit_event` written by `contract.fn_audit_contract` and indirectly via the generic audit trigger on every new contract execution table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0024_contract_execution_signature_foundation.sql`. | CC-13 prompt |
| 2 | Extends existing `contract` schema. No new schema. | CC-13 prompt #2 |
| 3 | RPC namespaces reuse: `contract.buyer_*`, `contract.supplier_*`, `contract.admin_*`. | CC-13 prompt #14 |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-13 prompt #13 |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-13 prompt #13 |
| 6 | Buyer RPCs derive organization from `identity.current_organization_id()` — no `p_buyer_organization_id` parameter. | CC-13 prompt #15 |
| 7 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — no `p_supplier_id` parameter. | CC-13 prompt #16 |
| 8 | Executed contract creation requires preparation with `status='ready_for_contract'`. | CC-13 prompt #18 |
| 9 | One active executed contract per `preparation_id` (partial unique index `WHERE deleted_at IS NULL AND status <> 'superseded'`). | CC-13 prompt #18 |
| 10 | Items + clauses are **copied** from preparation at creation time (preparation_item_id / preparation_clause_id back-pointers). | CC-13 prompt #6, #7 |
| 11 | Buyer + supplier parties are auto-added at creation (both `is_required_signer = true`, signing_order 1/2). | CC-13 design |
| 12 | One active signature request per `(contract, party)` via partial unique index. Once `signed/declined/cancelled/expired`, the slot frees up. | CC-13 prompt #9 |
| 13 | Contract auto-promotes to `executed` when *every* required signer has signed. `partially_signed` when ≥1 required signer has signed but not all. | CC-13 prompt #18 |
| 14 | Decline records a signature event but does **not** auto-cancel the contract. | CC-13 prompt #21 |
| 15 | Signature events, contract events, and snapshots are immutable: no UPDATE/DELETE policies, no UPDATE/DELETE grants. | CC-13 prompt #10, #11, #12 |
| 16 | `executed` does **not** create a shipment, payment, settlement, escrow, invoice, accounting, or negotiation record. | CC-13 prompt #18 |

## Schema overview

### Enums (4 new)

- `contract.contract_status` — `draft_execution, pending_signatures, partially_signed, executed, cancelled, voided, superseded`
- `contract.party_type` — `buyer, supplier, platform, witness, other`
- `contract.signature_status` — `pending, viewed, signed, declined, cancelled, expired`
- `contract.executed_snapshot_type` — `initial_from_preparation, pending_signature_snapshot, executed_snapshot, voided_snapshot`

(In addition to the CC-12 enums: `preparation_status`, `preparation_contract_type`, `preparation_clause_type`, `preparation_snapshot_type`.)

### Tables (8 new)

| Table | Purpose |
|-------|---------|
| `contract.executed_contracts` | Master executable contract record per preparation. Commercial/legal text, contract_type/currency/incoterm, lifecycle timestamps. |
| `contract.executed_contract_items` | Line items copied from `contract_preparation_items` (back-pointer `preparation_item_id`). |
| `contract.executed_contract_clauses` | Clauses copied from `contract_preparation_clauses` (back-pointer `preparation_clause_id`). |
| `contract.contract_parties` | Parties to the contract with signer role, signing order, and `is_required_signer` flag. |
| `contract.contract_signature_requests` | Platform-controlled signature requests per party. |
| `contract.contract_signature_events` | **Immutable** signature transition trail. No UPDATE/DELETE policies. |
| `contract.executed_contract_snapshots` | **Immutable** snapshots at lifecycle checkpoints. No UPDATE/DELETE policies. |
| `contract.executed_contract_events` | **Immutable** contract lifecycle trail. No UPDATE/DELETE policies. |

## Execution lifecycle

```
            buyer_create_executed_contract  (preparation must be ready_for_contract)
                              │  ↳ copy items, copy clauses, add buyer+supplier parties,
                              │    write initial_from_preparation snapshot, event(null→draft_execution)
                              ▼
                       draft_execution
                              │ buyer_update_executed_contract / buyer_add_party /
                              │ buyer_create_signature_request / buyer_create_executed_snapshot
                              │
                  buyer_mark_pending_signatures   (requires ≥1 pending signature request)
                              │
                              ▼
                     pending_signatures
                              │
                              │ supplier_sign_signature_request / buyer_sign_signature_request
                              │  ↳ fn_try_promote_to_executed runs after each sign
                              │
                ┌─────────────┴─────────────┐
                │                           │
       some_required_signed         all_required_signed
                │                           │
                ▼                           ▼
        partially_signed              executed (locked)
                │
       supplier/buyer signs remaining
                │
                ▼
             executed
```

- `draft_execution` is the only fully editable state.
- `pending_signatures` and `partially_signed` permit signature operations + snapshots but block normal `buyer_update_executed_contract`.
- `executed`, `cancelled`, `voided`, `superseded` are terminal and locked.
- `cancelled` is reachable from `draft_execution / pending_signatures / partially_signed` via `buyer_cancel_executed_contract` or `admin_force_cancel_contract`. `executed` cannot be cancelled — it can be `voided` or `superseded` by admin.
- `voided` (admin) preserves the row; `superseded` (admin) frees the unique-active slot for a new contract on the same preparation.

## Signature lifecycle

```
       buyer_create_signature_request
                  │
                  ▼
              pending
                  │ supplier_view_signature_request
                  ▼
              viewed
                  │
   ┌──────────────┼──────────────┐
   │              │              │
supplier_sign  buyer_sign   supplier/buyer_decline
   │              │              │
   ▼              ▼              ▼
 signed         signed        declined
   │              │              │
   ▼              ▼              ▼ (no auto-cancel of contract)
fn_try_promote_to_executed runs
```

- Every state change writes one row to `contract.contract_signature_events`.
- `signed`, `declined`, `cancelled`, `expired` are terminal for the signature request (and free the partial unique slot so the buyer can request again if appropriate).
- A required signer's decline writes the event but does **not** auto-cancel the contract; the buyer can choose to cancel manually.

## Security model

### RLS

All 8 new tables have RLS enabled. The audience predicate is one of:

- **Buyer-side** — members of the buyer organization (`executed_contracts.organization_id`).
- **Supplier-side** — members of the supplier organization (resolved via `executed_contracts.supplier_id → supplier.suppliers.organization_id`).
- **Platform admin** — always.

Snapshots (`executed_contract_snapshots`) are buyer + admin only — supplier-side is not exposed. All other tables (header, items, clauses, parties, signature requests, signature events, contract events) are visible to both buyer and supplier of the contract.

Backstop `*_admin_modify` policies on the mutable tables (`executed_contracts`, `executed_contract_items`, `executed_contract_clauses`, `contract_parties`, `contract_signature_requests`) allow only `platform_admin`. RPCs bypass via SECURITY DEFINER. Snapshots and events have no INSERT/UPDATE/DELETE policies — append-only via RPC.

### Grants

```
anon          → executed_contracts, executed_contract_items                       SELECT (RLS returns 0)

authenticated → all 8 new tables                                                   SELECT
```

`executed_contract_clauses`, `contract_parties`, `contract_signature_requests`, `contract_signature_events`, `executed_contract_snapshots`, `executed_contract_events` are intentionally not exposed to `anon`. **No INSERT/UPDATE/DELETE direct grants on any contract table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `contract.fn_audit_contract(action, contract_id, payload)` | Writes domain audit event; exception-swallowed. |
| `contract.fn_record_executed_contract_event(...)` | Inserts immutable contract events row. |
| `contract.fn_record_signature_event(...)` | Inserts immutable signature events row. |
| `contract.fn_next_contract_code(tenant)` | Generates `CON-YYYY-XXXXXXXX` codes (tenant-unique via partial unique index). |
| `contract.fn_assert_buyer_for_preparation(prep)` | Verifies role + caller org + preparation status `ready_for_contract`. Returns the cross-domain identifiers. |
| `contract.fn_assert_executed_contract_owned(contract)` | Raises `42501` if caller's org doesn't own the contract. |
| `contract.fn_assert_executed_contract_editable(contract)` | Raises `P0001` if status ≠ `draft_execution`. |
| `contract.fn_try_promote_to_executed(contract)` | After each sign, auto-promote contract to `executed` (all required signed) or `partially_signed` (some required signed). |
| `contract.fn_assert_supplier_for_signature(sr)` | Verifies signature request is on caller's supplier party. |
| `contract.fn_assert_buyer_for_signature(sr)` | Verifies signature request is on caller's buyer org party. |

## RPC inventory (24 new in CC-13, 42 total in contract schema)

### Buyer RPCs (11 new)

| Function | Vol | Purpose |
|----------|-----|---------|
| `buyer_create_executed_contract(preparation_id, title?, effective_date?, expiry_date?)` returns uuid | volatile | Creates draft from ready_for_contract preparation. Copies items + clauses. Auto-adds buyer + supplier parties. Auto-creates `initial_from_preparation` snapshot. Writes initial event. |
| `buyer_update_executed_contract(contract_id, ...)` | volatile | Partial update; draft_execution only. |
| `buyer_add_party(contract_id, party_type, display_name, ...)` returns uuid | volatile | Add witness / platform / extra party. |
| `buyer_create_signature_request(contract_id, party_id, requested_to_user?, requested_to_email?, due_at?)` returns uuid | volatile | Create pending signature request. |
| `buyer_mark_pending_signatures(contract_id)` | volatile | draft_execution → pending_signatures. Requires ≥1 pending signature request. |
| `buyer_create_executed_snapshot(contract_id, snapshot_type, title, data?, notes?)` returns uuid | volatile | Append-only snapshot. |
| `buyer_cancel_executed_contract(contract_id, reason?)` | volatile | Any non-terminal → cancelled. |
| `buyer_list_executed_contracts(...)` | stable | List own org contracts. |
| `buyer_get_executed_contract(contract_id)` returns jsonb | stable | Detail with items / clauses / parties / signature_requests. |
| `buyer_sign_signature_request(sr_id, metadata?)` | volatile | Buyer party signature. Calls `fn_try_promote_to_executed` after. |
| `buyer_decline_signature_request(sr_id, reason?)` | volatile | Buyer party decline; writes signature event, no contract auto-cancel. |

### Supplier RPCs (6 new — 8 total in contract schema)

| Function | Vol | Purpose |
|----------|-----|---------|
| `supplier_list_my_executed_contracts(status?, limit, offset)` | stable | List own contracts. |
| `supplier_get_my_executed_contract(contract_id)` returns jsonb | stable | Detail (no clauses / no snapshots — buyer-private). |
| `supplier_list_my_signature_requests(status?, limit, offset)` | stable | List own signature requests. |
| `supplier_view_signature_request(sr_id)` | volatile | pending → viewed. |
| `supplier_sign_signature_request(sr_id, metadata?)` | volatile | Supplier party signature. Calls `fn_try_promote_to_executed`. |
| `supplier_decline_signature_request(sr_id, reason?)` | volatile | Supplier party decline; writes signature event, no contract auto-cancel. |

### Admin RPCs (7 new — 12 total in contract schema)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_executed_contracts(...)` | stable | Cross-org admin list. |
| `admin_get_executed_contract(contract_id)` returns jsonb | stable | Detail with counts. |
| `admin_list_executed_contract_events(contract_id)` | stable | Contract event trail. |
| `admin_list_signature_events(contract_id?, sr_id?)` | stable | Signature event trail. |
| `admin_force_cancel_contract(contract_id, reason?)` | volatile | Cancel from any non-terminal, non-`executed` state. |
| `admin_void_contract(contract_id, reason?)` | volatile | Void at any non-`superseded` state (including `executed`). |
| `admin_supersede_contract(contract_id, reason?)` | volatile | Supersede; frees unique-active slot. |

**24 new RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`.

## Validation Summary

### Migration apply

```
Applying migration 20260622090024_contract_execution_signature_foundation.sql...
Finished supabase db reset on branch main.
```

All 24 migrations apply cleanly. No mid-implementation fixes were required.

### Verification queries (snapshot)

- 8 new `contract.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `contract.*`
- 42 RPCs total in contract schema (CC-12 + CC-13): 22 buyer + 8 supplier + 12 admin
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 17 stable + 25 volatile (split matches read/write intent)
- 0 `buyer_*` RPCs accept `p_buyer_organization_id`
- 0 `supplier_*` RPCs accept `p_supplier_id`
- Single distinct owner across all contract RPCs

### pgTAP suite

```
================================================================
Files: 47 passed, 0 failed
Assertions: 292 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–042 | 246 | CC-05 through CC-12 (incl. acceptance) |
| **043 contract execution RLS, grants, RPC metadata** | **14** | **CC-13** |
| **044 buyer executed contract lifecycle** (create → items/clauses/parties/snapshot derived → update → add party → signature request → pending → snapshot → lock) | **11** | **CC-13** |
| **045 scope + integrity** (cross-buyer block, draft/under_review/cancelled preparation block, duplicate active rejection, no forbidden side-effect schemas) | **6** | **CC-13** |
| **046 signature lifecycle** (supplier view → sign, cross-party block, contract → partially_signed → executed, executed lock, immutable events) | **8** | **CC-13** |
| **047 supplier visibility + decline** (own visible, foreign 0/42501, signature request listing, decline writes event, contract not auto-executed on decline) | **7** | **CC-13** |
| **CC-13 new** | **46** | |
| **Suite total** | **292** | **across 47 files** |

### Frontend

CC-13 added no frontend code. The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` does not yet expose the `contract` schema to PostgREST — must be added before any UI calls these RPCs.

## Known limitations / handoff notes for CC-14

1. **`supabase/config.toml`** does not expose `contract` / `evaluation` / `offer` to PostgREST. Future CC must add these to `[api].schemas` before frontend can call these RPCs.
2. **No cryptographic signature payload.** `buyer_sign_signature_request` / `supplier_sign_signature_request` accept a `metadata` jsonb blob for the signature ceremony but do not bind cryptographic material, witnesses, or notarization. PKI / e-sign integration is a future concern.
3. **No PDF rendering or document generation.** Clauses are structured text only.
4. **No external e-sign provider integration.** DocuSign / Adobe Sign / Iranian e-sign providers are out of scope.
5. **No reminders, expiry sweeper, or notification dispatch.** `due_at` is informational only — there is no scheduled job to expire overdue signature requests. CC-13 prompt explicitly excludes negotiation chat / messaging.
6. **No multi-supplier contracts.** Each contract has one supplier (carried from the source offer).
7. **No revision/versioning beyond `superseded`.** A superseded contract frees the unique-active slot but there is no explicit `parent_contract_id` self-FK. Add if version trees become a requirement.
8. **Decline does NOT auto-cancel the contract.** This is intentional (per CC-13 prompt #21). UI should surface the declined signature prominently and let the buyer choose `buyer_cancel_executed_contract` if appropriate.
9. **No automatic re-issue after decline.** Once a signature request is declined/cancelled/expired, the partial unique index frees the slot. The buyer must explicitly call `buyer_create_signature_request` again to re-issue.
10. **No shipment, pricing engine, settlement, escrow, payment, invoice, accounting, negotiation.** Same boundary as CC-12 plus the explicit CC-13 exclusions. Test 045/6 verifies that no schemas matching `payment|shipment|settlement|escrow|invoice|accounting|negotiation|pricing` were created.
11. **`executed` does NOT trigger cross-domain auto-effects.** It does not change `offer.status`, does not create shipment / payment / settlement / escrow / invoice / accounting rows.
12. **Item-level signature is not modeled.** A party either signs the whole contract or doesn't.
13. **Parties are buyer-administered.** Suppliers cannot add/remove parties themselves; this is intentional given the buyer-driven contract model.
14. **Cross-domain integrity is RPC-enforced.** `executed_contract.preparation_id → preparation.id` is the load-bearing link; `request_id / offer_id / decision_id / supplier_id` are copied from the preparation row at creation time. Direct INSERTs by `service_role` bypassing RPCs could violate the invariants; mitigated by no-direct-write-grants on `authenticated`.
15. **No `Database` type entry for the new contract execution tables** in the frontend types file. Will be added when buyer execution UI lands.

---

# Security Acceptance Addendum (v1.1)

Performed after CC-13 was provisionally complete, before any CC-14 (shipment / pricing engine / settlement / escrow / payment / invoice / accounting / negotiation) work began. **No migration changes** — every check was verification-only. Migrations 0001–0024 untouched.

## 1. RLS verification on all 8 new contract execution tables — ✅ PASS

| Table | `relrowsecurity` | `relforcerowsecurity` |
|-------|------------------|----------------------|
| contract.executed_contracts          | t | f |
| contract.executed_contract_items     | t | f |
| contract.executed_contract_clauses   | t | f |
| contract.contract_parties            | t | f |
| contract.contract_signature_requests | t | f |
| contract.contract_signature_events   | t | f |
| contract.executed_contract_snapshots | t | f |
| contract.executed_contract_events    | t | f |

All 8 new tables have RLS enabled in standard (non-forced) mode — consistent with CC-03 through CC-12. `relforcerowsecurity = f` means table owner and superuser bypass; every other role is gated. Same posture as supplier/commodity/rfq/offer/evaluation/(CC-12 contract) schemas.

## 2. Grants matrix — ✅ PASS

```
anon          → contract.executed_contracts            SELECT
                contract.executed_contract_items       SELECT

authenticated → contract.executed_contracts            SELECT
                contract.executed_contract_items       SELECT
                contract.executed_contract_clauses     SELECT
                contract.contract_parties              SELECT
                contract.contract_signature_requests   SELECT
                contract.contract_signature_events     SELECT
                contract.executed_contract_snapshots   SELECT
                contract.executed_contract_events      SELECT
```

`executed_contract_clauses`, `contract_parties`, `contract_signature_requests`, `contract_signature_events`, `executed_contract_snapshots`, `executed_contract_events` are intentionally NOT exposed to `anon`. All eight tables are further restricted by RLS so the SELECT grant alone never reveals unauthorized rows.

## 3. No direct INSERT/UPDATE/DELETE grants — ✅ PASS

```sql
select count(*) from information_schema.role_table_grants
 where table_schema = 'contract'
   and grantee in ('anon', 'authenticated')
   and privilege_type in ('INSERT', 'UPDATE', 'DELETE');
-- 0
```

All mutations route through the SECURITY DEFINER RPCs.

## 4. RPC metadata verification across the full contract schema — ✅ PASS

All 42 contract `buyer_*` / `supplier_*` / `admin_*` RPCs (CC-12 + CC-13):

| Property | Value |
|----------|-------|
| Distinct owners | 1 (`postgres`) |
| `security_definer = true` | 42 / 42 |
| `search_path` config | `search_path=""` on every function |
| Stable functions (reads) | 17 |
| Volatile functions (mutations) | 25 |
| Buyer namespace | 22 (11 from CC-12 + 11 from CC-13) |
| Supplier namespace | 8 (2 from CC-12 + 6 from CC-13) |
| Admin namespace | 12 (5 from CC-12 + 7 from CC-13) |

Internal helpers added in CC-13 (`fn_audit_contract`, `fn_record_executed_contract_event`, `fn_record_signature_event`, `fn_next_contract_code`, `fn_assert_buyer_for_preparation`, `fn_assert_executed_contract_owned`, `fn_assert_executed_contract_editable`, `fn_try_promote_to_executed`, `fn_assert_supplier_for_signature`, `fn_assert_buyer_for_signature`) are also SECURITY DEFINER with `search_path=""` but not part of the buyer/supplier/admin surface count.

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

No `contract.buyer_*` RPC (CC-12 or CC-13) accepts a caller-supplied `p_buyer_organization_id`. The buyer organization is derived exclusively from `identity.current_organization_id()` and verified against the preparation / contract owner.

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

No `contract.supplier_*` RPC accepts a caller-supplied `p_supplier_id`. The supplier is derived exclusively from `supplier.fn_portal_supplier_id()`.

## 7. Buyer execution lifecycle verification — ✅ PASS

Covered by pgTAP test `044_contract_execution_buyer_lifecycle.sql`:

```
ok 1  - buyer_create_executed_contract creates contract with status=draft_execution
ok 2  - items derived from preparation items (count=1)
ok 3  - clauses derived from preparation clauses (count=1)
ok 4  - parties auto-created: buyer + supplier (count=2)
ok 5  - initial_from_preparation snapshot is auto-created on contract create
ok 6  - buyer_update_executed_contract patches incoterm
ok 7  - buyer_add_party adds a witness party
ok 8  - buyer_create_signature_request creates pending signature request
ok 9  - buyer_mark_pending_signatures transitions draft_execution → pending_signatures
ok 10 - buyer_create_executed_snapshot persists a pending_signature_snapshot
ok 11 - pending_signatures contract is locked from update (P0001)
```

End-to-end buyer flow: create from preparation → items/clauses/parties/snapshot auto-derived → update in draft → add witness party → signature request → pending → snapshot → locked at pending_signatures.

## 8. Creation from `ready_for_contract` preparation verification — ✅ PASS

Covered by pgTAP test `044/1` (preparation is `ready_for_contract`, contract created with `status=draft_execution`) and the negative cases in test 045 below.

`fn_assert_buyer_for_preparation` raises `P0001` if `preparation.status <> 'ready_for_contract'`.

## 9. Rejection of draft / under_review / cancelled preparation — ✅ PASS

Covered by pgTAP test `045_contract_execution_scope_and_integrity.sql`:

```
ok 2 - executed contract from draft preparation is rejected (P0001)
ok 3 - executed contract from under_review preparation is rejected (P0001)
ok 4 - executed contract from cancelled preparation is rejected (P0001)
```

The only valid trigger for `buyer_create_executed_contract` is a preparation with status `ready_for_contract`.

## 10. Cross-buyer isolation verification — ✅ PASS

Covered by pgTAP test `045_contract_execution_scope_and_integrity.sql`:

```
ok 1 - buyer B cannot create executed contract from buyer A's preparation (42501)
```

`fn_assert_buyer_for_preparation` compares `identity.current_organization_id()` against the preparation's owning organization; non-matching caller orgs are rejected with `42501` before any executed_contract row can be inserted.

## 11. Executed item and clause derivation verification — ✅ PASS

Covered by pgTAP test `044/2-3`:

```
ok 2 - items derived from preparation items (count=1)
ok 3 - clauses derived from preparation clauses (count=1)
```

`buyer_create_executed_contract` performs `INSERT INTO contract.executed_contract_items ... SELECT ... FROM contract.contract_preparation_items WHERE preparation_id = ... AND deleted_at IS NULL` and the equivalent for clauses. Back-pointers `preparation_item_id` and `preparation_clause_id` are stored on every derived row.

## 12. Contract party creation verification — ✅ PASS

Covered by pgTAP tests `044/4` and `044/7`:

```
ok 4 - parties auto-created: buyer + supplier (count=2)
ok 7 - buyer_add_party adds a witness party
```

Buyer (signing_order=1) and supplier (signing_order=2) parties are auto-added at creation, both flagged `is_required_signer=true`. Additional parties (witness/platform/other) can be added via `buyer_add_party`.

## 13. Signature request lifecycle verification — ✅ PASS

Covered by pgTAP test `046_contract_execution_signature_lifecycle.sql`:

```
ok 1 - supplier_view_signature_request transitions pending → viewed
ok 3 - supplier signing 1 of 2 required moves contract to partially_signed
ok 4 - all required signed promotes contract to executed
ok 5 - executed_at is populated when contract reaches executed
```

Signature requests transition through `pending → viewed → signed` (or `declined`/`cancelled`/`expired`). Each transition writes one `contract_signature_events` row. After each sign event, `fn_try_promote_to_executed` runs and re-evaluates the contract's aggregate signature state.

## 14. Supplier signature visibility verification — ✅ PASS

Covered by pgTAP test `047_contract_execution_supplier_visibility_and_decline.sql`:

```
ok 1 - supplier X sees own executed contract via supplier_list_my_executed_contracts
ok 2 - supplier_get_my_executed_contract returns contract detail for own supplier
ok 5 - supplier X sees own signature request via supplier_list_my_signature_requests
```

Suppliers see only contracts and signature requests connected to their own `supplier_id` (resolved via `supplier.fn_portal_supplier_id()`).

## 15. Unrelated supplier signature block verification — ✅ PASS

Covered by pgTAP tests `046/2` and `047/3-4`:

```
046 ok 2 - supplier cannot sign buyer party signature request (42501)
047 ok 3 - unrelated supplier Y sees 0 contracts
047 ok 4 - unrelated supplier cannot get contract detail (42501)
```

`fn_assert_supplier_for_signature` raises `42501` if the signature request's party_type is not `supplier` or the party's supplier_id doesn't match the caller. Cross-party (supplier → buyer party) and cross-supplier attempts are both blocked.

## 16. Signature decline behavior verification — ✅ PASS

Covered by pgTAP test `047_contract_execution_supplier_visibility_and_decline.sql`:

```
ok 6 - decline writes a signature event (to_status=declined)
ok 7 - after decline, contract did NOT auto-execute (status remains pending_signatures)
```

`supplier_decline_signature_request` (and `buyer_decline_signature_request`) write a signature event row and update the signature request to `declined`. The contract status is **not** auto-changed — `fn_try_promote_to_executed` is not invoked on decline. UI is expected to surface the decline and let the buyer choose to cancel manually.

## 17. All-required-signed promotion to `executed` verification — ✅ PASS

Covered by pgTAP test `046/4-5`:

```
ok 4 - all required signed promotes contract to executed
ok 5 - executed_at is populated when contract reaches executed
```

After every sign event, `fn_try_promote_to_executed` counts required-signer parties vs. parties whose active signature request is `signed`. When `signed_required >= total_required` (and `total_required > 0`), the contract atomically transitions to `executed`, `executed_at` and `executed_by` are populated, and a contract event row is written.

## 18. Executed contract lock verification — ✅ PASS

Covered by pgTAP tests `044/11` (pending_signatures locked) and `046/6` (executed locked):

```
044 ok 11 - pending_signatures contract is locked from update (P0001)
046 ok 6  - executed contract is locked from buyer_update_executed_contract (P0001)
```

`fn_assert_executed_contract_editable` raises `P0001` if status ≠ `draft_execution`. Only `draft_execution` permits full edits; `pending_signatures`, `partially_signed`, `executed`, `cancelled`, `voided`, `superseded` all reject normal updates.

## 19. Signature event immutability verification — ✅ PASS

Covered by pgTAP test `046/7`:

```
ok 7 - direct UPDATE on signature_events row is blocked (no grant)
```

`contract.contract_signature_events` has:

- No `UPDATE` / `DELETE` policy.
- No `INSERT` / `UPDATE` / `DELETE` grants to `anon` / `authenticated`.
- An `INSERT` route via `fn_record_signature_event` (SECURITY DEFINER) only, called by every state-changing signature RPC.

`authenticated` direct UPDATE attempts raise `42501` (no grant).

## 20. Executed contract event immutability verification — ✅ PASS

Covered by pgTAP test `046/8`:

```
ok 8 - direct DELETE on executed_contract_events row is blocked (no grant)
```

`contract.executed_contract_events` has:

- No `UPDATE` / `DELETE` policy.
- No `INSERT` / `UPDATE` / `DELETE` grants to `anon` / `authenticated`.
- An `INSERT` route via `fn_record_executed_contract_event` (SECURITY DEFINER) only, called by every state-changing contract RPC (including the auto-promotion path inside `fn_try_promote_to_executed`).

`authenticated` direct DELETE attempts raise `42501` (no grant).

## 21. Forbidden side-effect boundary — ✅ PASS

`executed` is a **state label only**. CC-13 does **not** create any of the explicitly excluded domains:

| Concern | Verification | Result |
|---------|-------------|--------|
| Shipment        | No `shipment` schema exists (test 045/6). No shipment table or RPC.    | ✅ not created |
| Pricing engine  | No `pricing` schema exists (test 045/6). No pricing table or engine.    | ✅ not created |
| Settlement      | No `settlement` schema exists (test 045/6).                              | ✅ not created |
| Escrow          | No `escrow` schema exists (test 045/6).                                  | ✅ not created |
| Payment         | No `payment` schema exists (test 045/6).                                 | ✅ not created |
| Invoice         | No `invoice` schema exists (test 045/6).                                 | ✅ not created |
| Accounting      | No `accounting` schema exists (test 045/6).                              | ✅ not created |
| Negotiation     | No `negotiation` schema exists (test 045/6).                             | ✅ not created |

```sql
select count(*) from information_schema.schemata
 where schema_name in ('payment','shipment','settlement','escrow','invoice','accounting','negotiation','pricing');
-- 0
```

Additionally, `executed` does **not** auto-promote `offer.supplier_offers.status` to `accepted`, does **not** create any rows in offer/evaluation/preparation domains, and does **not** trigger any external integration. The state label transition is internal to the contract schema.

## 22. Frontend validation — ✅ PASS

CC-13 added no frontend code. The frontend remains at its CC-07 surface (22 routes). Frontend sanity checks were re-run for acceptance parity with CC-07 through CC-12:

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

`supabase/config.toml` still does not expose `contract` (nor `evaluation` / `offer`) to PostgREST — must be added before any UI calls these RPCs.

## 23. Suite totals — Before / After CC-13

| Metric | Pre-CC-13 (CC-12 v1.1 acceptance) | Post-CC-13 (acceptance addendum) |
|--------|-----------------------------------|----------------------------------|
| pgTAP files | 42 | **47** |
| pgTAP assertions | 246 | **292** |
| Migrations | 23 | 24 |
| Schemas | identity, organization, audit, supplier, commodity, rfq, offer, evaluation, contract (5 tables) | identity, organization, audit, supplier, commodity, rfq, offer, evaluation, **contract (13 tables)** |
| Backend RPCs (admin + portal/buyer/supplier surfaces) | 127 (18 contract) | **151** (42 contract: +24 in CC-13) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 24. Final status

**CC-13 is FULLY ACCEPTED.**

- ✅ RLS verified on all 8 new contract execution tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE
- ✅ RPC ownership consistent (single owner `postgres`), all `security_definer`, all `search_path=""`
- ✅ Buyer RPC safety — no `p_buyer_organization_id` argument across all 22 buyer RPCs
- ✅ Supplier RPC safety — no `p_supplier_id` argument across all 8 supplier RPCs
- ✅ Buyer execution lifecycle provable by pgTAP (test 044)
- ✅ Creation gated on `ready_for_contract` preparations only (test 044, 045)
- ✅ Rejection of draft/under_review/cancelled preparations provable — `P0001` (test 045)
- ✅ Cross-buyer isolation provable — `42501` (test 045)
- ✅ Executed item + clause derivation from preparation provable (test 044)
- ✅ Auto-creation of buyer + supplier parties + initial snapshot provable (test 044)
- ✅ Signature request lifecycle provable (test 046)
- ✅ Supplier signature visibility provable — own only (test 047)
- ✅ Unrelated supplier signature block provable — `42501` (test 046, 047)
- ✅ Signature decline writes event without auto-cancel (test 047)
- ✅ All-required-signed auto-promotion to `executed` provable (test 046)
- ✅ Executed contract lock provable — `P0001` (test 044, 046)
- ✅ Signature event immutability enforced — direct UPDATE blocked (test 046)
- ✅ Executed contract event immutability enforced — direct DELETE blocked (test 046)
- ✅ Forbidden side-effect boundary enforced — no shipment / pricing / settlement / escrow / payment / invoice / accounting / negotiation schemas (test 045)
- ✅ Frontend typecheck + build + route guards green (no frontend code added)
- ✅ pgTAP suite 292 / 292 across 47 files
- ✅ No new business domain code introduced
- ✅ No CC-14 work started (no shipment / pricing engine / settlement / escrow / payment / invoice / accounting / negotiation)
