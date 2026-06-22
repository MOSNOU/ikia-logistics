# CC-09 — Phase 2.2 RFQ Foundation, Schema Notes

Version: 1.1 (DRAFT — acceptance addendum)
Scope: Third business domain — Request for Quotation (RFQ) lifecycle, request items, item specifications, document requirements, supplier invitations, and status events
Migration: `23-DATABASE/migrations/0020_rfq_foundation.sql` (single, append-only). No new migration in v1.1.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Mission

CC-09 introduces the **RFQ catalog** that allows buyer-side organizations to create structured requests against the commodity catalog from CC-08 and dispatch invitations to suppliers from CC-07. Strictly scoped to the buyer + invitation surface: no supplier bids/offers, no contract generation, no pricing engine, no settlement.

## Relationship to existing foundations

| Foundation | How CC-09 uses it |
|------------|-------------------|
| identity   | `tenants`, `current_organization_id()`, `is_platform_admin()`, `has_role(...)` for caller scope checks |
| organization | `organizations`, `memberships` for buyer-side RLS predicates |
| supplier   | `suppliers.id` referenced by `request_supplier_invitations.supplier_id`; `supplier.fn_portal_supplier_id()` reused by supplier RPCs |
| commodity  | `products.id` referenced by `request_items.product_id`; `product_specifications` referenced (nullable) by item specifications; `product_document_requirements` referenced (nullable) by RFQ doc requirements |
| audit      | `audit.audit_event` written by `rfq.fn_audit` and indirectly via the generic audit trigger on every `rfq.*` table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0020_rfq_foundation.sql`. | CC-09 prompt |
| 2 | New `rfq` schema. | CC-09 prompt |
| 3 | RPC namespaces: `rfq.buyer_*`, `rfq.supplier_*`, `rfq.admin_*`. | CC-09 prompt |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-09 prompt |
| 5 | `search_path = ''` on every SECURITY DEFINER function; PG stores as `search_path=""`. | CC-09 prompt |
| 6 | Buyer RPCs derive organization from `identity.current_organization_id()`; no `p_buyer_organization_id`. | CC-09 prompt |
| 7 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()`; no `p_supplier_id`. | CC-09 prompt |
| 8 | Buyer mutation RPCs assert `status='draft'` via `rfq.fn_assert_request_editable()` — submitted/published/invited RFQs are immutable except via explicit transition RPCs. | CC-09 prompt #16 |
| 9 | `rfq.request_status_events` is immutable: no UPDATE/DELETE policies, inserts only via RPC. | CC-09 prompt #10 |
| 10 | Supplier RPCs are `stable` (read-only). View-tracking / invitation acknowledgement deferred to CC-10. | CC-09 design |
| 11 | No supplier offer/bid tables, no pricing, no contracts — CC-10+. | CC-09 prompt #16 |
| 12 | No seed RFQs; tests create their own fixtures. | CC-09 prompt #17 |

## Schema overview

### Enums (4)

- `rfq.request_status` — `draft, submitted, published, invited, closed, cancelled, expired`
- `rfq.visibility_model` — `private_invited, organization, public`
- `rfq.invitation_status` — `invited, viewed, accepted, declined, withdrawn, expired`
- `rfq.document_scope` — `request, item`

### Tables (6)

| Table | Purpose |
|-------|---------|
| `rfq.requests` | RFQ master record. Carries buyer org, requester, code, title, status, deadlines, delivery preferences, payment terms, lifecycle timestamps. |
| `rfq.request_items` | Line items. References `commodity.products`. Quantity / unit / packaging / origin preference / delivery window. |
| `rfq.request_item_specifications` | Buyer-defined spec values per item. References `commodity.product_specifications` (nullable — supports custom specs). |
| `rfq.request_document_requirements` | Doc requirements. Either request-level (scope='request') or item-level (scope='item'). May derive from `commodity.product_document_requirements` via `source_doc_req_id`. |
| `rfq.request_supplier_invitations` | Invited suppliers. References `supplier.suppliers`. Status: invited/viewed/accepted/declined/withdrawn/expired. |
| `rfq.request_status_events` | **Immutable** lifecycle audit. Every state transition writes one row. No UPDATE/DELETE policies. |

## Lifecycle / status model

```
                  buyer_create_rfq
                         │
                         ▼
                      draft ─── buyer_cancel_rfq ──► cancelled (terminal)
                         │
            buyer_submit_rfq
                         │
                         ▼
                    submitted ─── buyer_cancel_rfq ──► cancelled
                         │
        buyer_invite_suppliers (or admin)
                         │
                         ▼
                     invited ─── buyer_cancel_rfq ──► cancelled
                         │
                buyer_close_rfq
                         │
                         ▼
                      closed (terminal)
```

- `published` is reserved for future open-RFQ flow (no buyer RPC exposes it in CC-09; admin only).
- `expired` is a future system-side transition (not exposed in CC-09).
- Each transition writes `rfq.request_status_events` via `rfq.fn_record_status_event`.
- Each transition also writes `audit.audit_event` via `rfq.fn_audit`.

## Security model

### RLS (6 tables)

| Table | Select policy |
|-------|---------------|
| `requests` | platform_admin OR active member of buyer org OR member of a supplier org that has an active invitation |
| `request_items` | same as requests |
| `request_item_specifications` | same |
| `request_document_requirements` | same |
| `request_supplier_invitations` | platform_admin OR buyer org members (all invitations on their RFQs) OR supplier org members (only their supplier's invitation row) |
| `request_status_events` | platform_admin OR buyer org members. **Not** visible to suppliers. |

All tables also have:
- `*_select_deleted` (where applicable) admitting platform_admin or compliance_officer
- `*_admin_modify` backstop admitting only platform_admin (RPCs bypass via SECURITY DEFINER)

### Grants

| Table | anon | authenticated |
|-------|------|---------------|
| requests | SELECT | SELECT |
| request_items | SELECT | SELECT |
| request_item_specifications | SELECT | SELECT |
| request_document_requirements | SELECT | SELECT |
| request_supplier_invitations | SELECT | SELECT |
| request_status_events | — | SELECT |

**No INSERT/UPDATE/DELETE direct grants.** All mutations route through the SECURITY DEFINER RPCs.

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `rfq.fn_audit(action, request_id, payload)` | Writes domain audit event; exception-swallowed. |
| `rfq.fn_buyer_organization_id()` | Returns caller's active org if caller is buyer_admin/organization_admin/platform_admin; else `42501`. |
| `rfq.fn_assert_request_buyer_owned(request_id)` | Raises `42501` if caller is not buyer of the request's org and not platform_admin. |
| `rfq.fn_assert_request_editable(request_id)` | Raises `P0001` if status ≠ 'draft'. |
| `rfq.fn_record_status_event(...)` | Inserts an immutable transition row. |
| `rfq.fn_supplier_can_see_request(request_id)` | Boolean: does caller belong to a supplier org with an active invitation? Used in RLS predicates. |

## RPC inventory

### Buyer RPCs (14, all `SECURITY DEFINER`, `search_path=''`)

| # | Function | Vol | Purpose |
|---|----------|-----|---------|
| 1 | `buyer_create_rfq(...)` returns uuid | volatile | Creates a draft RFQ; generates rfq_code; emits status event 'created'. |
| 2 | `buyer_update_rfq(request_id, ...)` | volatile | Partial update of draft RFQ only. |
| 3 | `buyer_upsert_rfq_item(request_id, item_id?, product_id?, ...)` returns uuid | volatile | Create (item_id null) or update an item; draft-only. |
| 4 | `buyer_remove_rfq_item(item_id)` | volatile | Soft-delete; draft-only. |
| 5 | `buyer_upsert_item_specification(request_item_id, spec_key, ...)` returns uuid | volatile | Upsert by (request_item_id, spec_key) partial unique index; draft-only. |
| 6 | `buyer_remove_item_specification(spec_id)` | volatile | Soft-delete; draft-only. |
| 7 | `buyer_upsert_doc_requirement(request_id, request_item_id?, document_kind, ...)` returns uuid | volatile | Upsert by (scope, document_kind) partial unique; revives soft-removed; draft-only. |
| 8 | `buyer_remove_doc_requirement(doc_req_id)` | volatile | Soft-delete; draft-only. |
| 9 | `buyer_submit_rfq(request_id)` | volatile | draft → submitted; writes status event. |
| 10 | `buyer_invite_suppliers(request_id, supplier_ids[], message?)` returns integer | volatile | Adds invitations; transitions submitted/published → invited (idempotent on re-invite). |
| 11 | `buyer_cancel_rfq(request_id, reason?)` | volatile | any non-terminal → cancelled. |
| 12 | `buyer_close_rfq(request_id)` | volatile | invited/published → closed. |
| 13 | `buyer_list_rfqs(status?, limit, offset)` returns table | stable | List own org RFQs with item/invitation counts. |
| 14 | `buyer_get_rfq(request_id)` returns jsonb | stable | Detail with items, specs, doc requirements, invitations. |

### Supplier RPCs (2, read-only)

| # | Function | Vol | Purpose |
|---|----------|-----|---------|
| 1 | `supplier_list_rfq_invitations(status?, limit, offset)` returns table | stable | List invitations targeting caller's supplier. |
| 2 | `supplier_get_rfq(request_id)` returns jsonb | stable | Returns RFQ detail iff caller's supplier has an active invitation, else `P0002`. Pure read; no view-tracking (deferred to CC-10). |

### Admin RPCs (5)

| # | Function | Vol | Purpose |
|---|----------|-----|---------|
| 1 | `admin_list_rfqs(status?, organization_id?, limit, offset)` returns table | stable | Cross-org admin list. |
| 2 | `admin_get_rfq(request_id)` returns jsonb | stable | Detail including status events. |
| 3 | `admin_force_cancel_rfq(request_id, reason?)` | volatile | Override cancellation. |
| 4 | `admin_force_close_rfq(request_id, reason?)` | volatile | Override close. |
| 5 | `admin_list_invitations(request_id?, supplier_id?, status?, limit, offset)` returns table | stable | Admin invitation search. |

**21 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`.

## Validation Summary

### Migration apply

```
Applying migration 20260622090020_rfq_foundation.sql...
Finished supabase db reset on branch main.
```

All 20 migrations applied cleanly. Required one mid-implementation fix: a local `v_code citext` declaration inside `buyer_create_rfq` was changed to `v_code text` because the function's `search_path=''` excludes `public` where the `citext` extension lives — and `v_code` is a generated code string with no need for case-insensitive semantics.

### Verification queries (snapshot)

| Check | Result |
|-------|--------|
| 6 `rfq.*` tables, all `relrowsecurity=t` | ✅ |
| 0 INSERT/UPDATE/DELETE direct grants on `rfq.*` | ✅ |
| 21 RPCs across buyer/supplier/admin namespaces | ✅ |
| All RPCs `owner=postgres`, `security_definer=t`, `search_path=""` | ✅ |
| 4 stable + 17 volatile (split matches read/write intent) | ✅ |
| 0 `buyer_*` RPCs accept `p_buyer_organization_id` | ✅ |
| 0 `supplier_*` RPCs accept `p_supplier_id` | ✅ |
| Single distinct owner across all RFQ RPCs | ✅ |

### pgTAP suite

```
================================================================
Files: 28 passed, 0 failed
Assertions: 147 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–020 | 90 | CC-05/06/07 + acceptance |
| 021–024 | 28 | CC-08 commodity |
| **025 rfq RLS, grants, metadata** | **12** | **CC-09** |
| **026 rfq buyer lifecycle (create→submit + status event)** | **7** | **CC-09** |
| **027 rfq cross-org isolation + transition rules** | **5** | **CC-09** |
| **028 rfq invitation visibility (invited vs unrelated supplier)** | **5** | **CC-09** |
| **CC-09 new** | **29** | |
| **Suite total** | **147** | **across 28 files** |

### Frontend

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes (unchanged) |
| `bash scripts/verify-admin-route-guards.sh` | PASSED |

No frontend code added — Database type does NOT yet include `rfq` schema. CC-10 should regenerate types and extend `supabase/config.toml` `[api].schemas` to include `rfq` before any UI work.

## Known limitations / handoff notes for CC-10

1. **`supabase/config.toml`** does not yet expose the `rfq` schema to PostgREST. CC-10 must add `rfq` to `[api].schemas` before frontend can call RFQ RPCs.
2. **No supplier offer / bid tables.** `rfq.request_supplier_invitations.responded_at` exists but no response artefact is stored. CC-10 introduces `offer` domain.
3. **No view-tracking on `supplier_get_rfq`.** A future `supplier_acknowledge_invitation` volatile RPC will update `viewed_at` and `status='viewed'`.
4. **No `expired` status transitions.** A future scheduled job / function will move RFQs past `submission_deadline` to `expired`.
5. **No `published` exposure beyond the enum value.** Open RFQs are reserved for a later phase; current buyer flow uses invitation-based RFQs only.
6. **No invitation withdraw or acceptance.** Buyer can implicitly withdraw by soft-deleting via re-running `buyer_invite_suppliers` (idempotent revive). A dedicated `buyer_withdraw_invitation` RPC will arrive in CC-10.
7. **No item-level vs request-level doc-requirement validation against commodity.** `source_doc_req_id` is nullable and not enforced.
8. **No pricing currency validation.** `preferred_currency` is free text; recommend ISO 4217 enforcement in CC-10.
9. **No `Database` type entry for `rfq`** in `22-SOURCE-CODE/frontend-web/src/types/database.ts`. Will be added in CC-10 when buyer/supplier UI lands.
10. **No multi-supplier-per-product enforcement.** `unique(request_id, product_id) where deleted_at is null` permits exactly one item per product per RFQ. Future buyers may want multiple grades — relax in CC-10 if needed.
11. **Audit events** for RFQ domain (`rfq.created`, `rfq.submitted`, `rfq.cancelled`, ...) are written but no audit drilldown UI exists for `rfq.*` action codes.

---

# Security Acceptance Addendum (v1.1)

Performed after CC-09 was provisionally complete, before any CC-10 (offer / bid / contract / shipment / pricing / settlement / escrow / negotiation) work began. **No migration changes** — every check was verification-only. Migrations 0001–0020 untouched.

## 1. RLS verification on all 6 RFQ tables — ✅ PASS

| Table | `relrowsecurity` | `relforcerowsecurity` |
|-------|------------------|----------------------|
| rfq.requests | t | f |
| rfq.request_items | t | f |
| rfq.request_item_specifications | t | f |
| rfq.request_document_requirements | t | f |
| rfq.request_supplier_invitations | t | f |
| rfq.request_status_events | t | f |

All 6 tables have RLS enabled in standard (non-forced) mode — consistent with CC-03/04/05/06/07/08. `relforcerowsecurity = f` means the table owner and superuser bypass RLS; every other role is gated. Same posture as the supplier and commodity schemas.

## 2. Grants matrix — ✅ PASS

```
anon          → rfq.requests                       SELECT
                rfq.request_items                  SELECT
                rfq.request_item_specifications    SELECT
                rfq.request_document_requirements  SELECT
                rfq.request_supplier_invitations   SELECT

authenticated → rfq.requests                       SELECT
                rfq.request_items                  SELECT
                rfq.request_item_specifications    SELECT
                rfq.request_document_requirements  SELECT
                rfq.request_supplier_invitations   SELECT
                rfq.request_status_events          SELECT
```

`rfq.request_status_events` is intentionally NOT exposed to `anon` — the lifecycle audit trail is buyer/admin-only at the grant level. Sanity check returns **0** rows for `INSERT/UPDATE/DELETE` direct grants on any `rfq.*` table for either role.

## 3. No direct INSERT/UPDATE/DELETE grants — ✅ PASS

```sql
select count(*) from information_schema.role_table_grants
 where table_schema = 'rfq'
   and grantee in ('anon', 'authenticated')
   and privilege_type in ('INSERT', 'UPDATE', 'DELETE');
-- 0
```

All mutations route through the 21 SECURITY DEFINER RPCs.

## 4. RPC metadata verification — ✅ PASS

All 21 RFQ `buyer_*` / `supplier_*` / `admin_*` RPCs:

| Property | Value |
|----------|-------|
| Distinct owners | 1 (`postgres`) |
| `security_definer = true` | 21 / 21 |
| `search_path` config | `search_path=""` on every function |
| Stable functions (reads) | 4 — `buyer_list_rfqs`, `buyer_get_rfq`, `supplier_list_rfq_invitations`, `supplier_get_rfq`; plus 3 admin reads (`admin_list_rfqs`, `admin_get_rfq`, `admin_list_invitations`) = **7 stable** total |
| Volatile functions (mutations) | 14 — all `buyer_*` mutations + `admin_force_cancel_rfq` + `admin_force_close_rfq` |

## 5. Buyer RPC safety — no `p_buyer_organization_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'rfq'
   and p.proname like 'buyer_%'
   and p.proargnames is not null
   and 'p_buyer_organization_id' = any(p.proargnames);
-- 0
```

No `rfq.buyer_*` RPC accepts a caller-supplied `p_buyer_organization_id`. The buyer organization is derived exclusively from `rfq.fn_buyer_organization_id()` → `identity.current_organization_id()` (JWT).

## 6. Supplier RPC safety — no `p_supplier_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'rfq'
   and p.proname like 'supplier_%'
   and p.proargnames is not null
   and 'p_supplier_id' = any(p.proargnames);
-- 0
```

No `rfq.supplier_*` RPC accepts a caller-supplied `p_supplier_id`. The supplier is derived exclusively from `supplier.fn_portal_supplier_id()` (CC-07).

## 7. Buyer lifecycle verification — ✅ PASS

Covered by pgTAP test `026_rfq_buyer_lifecycle.sql`:

```
ok 1 - buyer_create_rfq creates RFQ with status=draft
ok 2 - buyer_update_rfq edits draft title
ok 3 - buyer_upsert_rfq_item adds exactly one item to RFQ
ok 4 - buyer_upsert_item_specification adds exactly one spec
ok 5 - buyer_upsert_doc_requirement adds one doc requirement
ok 6 - buyer_submit_rfq moves status draft → submitted
ok 7 - buyer_submit_rfq writes one status event draft → submitted
```

Status events are immutable (no UPDATE/DELETE policies). Every transition is captured.

## 8. Cross-organization isolation — ✅ PASS

Covered by pgTAP test `027_rfq_cross_org_and_transitions.sql`:

```
ok 1 - buyer in org A cannot mutate org B RFQ (42501)
ok 2 - buyer_list_rfqs returns only caller org RFQs (1, not 2)
```

A buyer in tenant A cannot mutate or list a tenant B RFQ even by parameter manipulation — the buyer organization is derived from JWT, not passed in. `rfq.fn_assert_request_buyer_owned()` raises `42501` if the caller's org doesn't match the request's owning org.

## 9. Status transition enforcement — ✅ PASS

Covered by pgTAP test `027_rfq_cross_org_and_transitions.sql`:

```
ok 3 - buyer_submit_rfq from submitted raises invalid_transition (P0001)
ok 4 - buyer_update_rfq on submitted RFQ raises invalid_transition (P0001)
ok 5 - buyer_cancel_rfq from cancelled raises invalid_transition (P0001)
```

Each transition RPC verifies current state before mutating; invalid transitions raise `P0001` `'invalid_transition'`. Buyer mutations are draft-only via `rfq.fn_assert_request_editable()`.

## 10. Supplier invitation visibility — ✅ PASS

Covered by pgTAP test `028_rfq_invitation_visibility.sql`:

```
ok 1 - buyer_invite_suppliers creates exactly one invitation for supplier X
ok 2 - invited supplier X can fetch the RFQ via supplier_get_rfq
ok 3 - invited supplier X sees own invitation in supplier_list_rfq_invitations
ok 4 - unrelated supplier Y raises P0002 from supplier_get_rfq (not invited)
ok 5 - unrelated supplier Y sees 0 rows from supplier_list_rfq_invitations
```

The invitation predicate in `rfq.fn_supplier_can_see_request()` is the load-bearing gate. RLS on `rfq.request_supplier_invitations` lets a supplier org see only their own supplier's row, never other invited suppliers' rows.

## 11. Frontend validation — ✅ PASS

CC-09 added no frontend code. The frontend remains at its CC-07 surface (22 routes).

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

## 12. Suite totals — Before / After CC-09

| Metric | Pre-CC-09 (CC-08 v1.1 acceptance) | Post-CC-09 (acceptance addendum) |
|--------|------------------------------------|----------------------------------|
| pgTAP files | 24 | **28** |
| pgTAP assertions | 118 | **147** |
| Migrations | 19 | 20 |
| Schemas | identity, organization, audit, supplier, commodity | identity, organization, audit, supplier, commodity, **rfq** |
| Backend RPCs (admin + portal/buyer/supplier surfaces) | 18 admin (CC-06) + 15 supplier (CC-07) + 18 commodity (CC-08) = 51 | 51 + **21 rfq** = **72** |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 13. Final status

**CC-09 is FULLY ACCEPTED.**

- ✅ RLS verified on all 6 RFQ tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE
- ✅ RPC ownership consistent (single owner `postgres`), all `security_definer`, all `search_path=""`
- ✅ Buyer RPC safety — no `p_buyer_organization_id` argument
- ✅ Supplier RPC safety — no `p_supplier_id` argument
- ✅ Buyer lifecycle (create, edit, submit, status event) provable by pgTAP (test 026)
- ✅ Cross-organization isolation provable by pgTAP (test 027)
- ✅ Status transition rules enforced and tested (test 027)
- ✅ Supplier invitation visibility provable by pgTAP (test 028)
- ✅ Frontend typecheck + build + route guards green
- ✅ pgTAP suite 147 / 147 across 28 files
- ✅ No new business domain code introduced
- ✅ No CC-10 work started (no offers / bids / contracts / shipment / pricing / settlement / escrow / negotiation)
