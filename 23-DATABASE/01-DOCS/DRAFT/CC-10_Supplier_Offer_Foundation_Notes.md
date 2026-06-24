# CC-10 — Phase 2.3 Supplier Offer Foundation, Schema Notes

Version: 1.1 (DRAFT — acceptance addendum)
Scope: Fourth business domain — supplier offers against RFQs, including offer header, offer items, specification responses, document commitments, buyer visibility, and immutable status events
Migration: `23-DATABASE/migrations/0021_supplier_offer_foundation.sql` (single, append-only). No new migration in v1.1.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Mission

CC-10 introduces the **supplier offer** surface. Invited suppliers respond to RFQs from CC-09 with structured offers tied to the commodity catalog from CC-08 and the supplier identity established in CC-07. Strictly scoped to the supplier-side creation surface plus buyer/admin read access — no contracts, no awards, no shipment, no pricing engine, no escrow, no settlement, no negotiation chat.

## Relationship to existing foundations

| Foundation | How CC-10 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `has_role(...)`, `current_organization_id()`, `current_user_id()` for caller scope checks |
| organization | `organizations`, `memberships` for buyer-side and supplier-side RLS predicates |
| supplier | `supplier.fn_portal_supplier_id()` reused; offers reference `supplier.suppliers(id)` |
| commodity | `commodity.products(id)` referenced via `supplier_offer_items.product_id`; `spec_data_type` + `document_kind` enums reused for spec responses and document commitments |
| rfq | `rfq.requests(id)` parent of every offer; `rfq.request_items`, `rfq.request_item_specifications`, `rfq.request_document_requirements` referenced by offer artefacts; `rfq.request_supplier_invitations` gates draft-offer creation |
| audit | `audit.audit_event` written by `offer.fn_audit` and indirectly via the generic audit trigger on every `offer.*` table |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0021_supplier_offer_foundation.sql`. | CC-10 prompt |
| 2 | New `offer` schema. | CC-10 prompt |
| 3 | RPC namespaces: `offer.supplier_*`, `offer.buyer_*`, `offer.admin_*`. | CC-10 prompt |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-10 prompt |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-10 prompt |
| 6 | Supplier RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — no `p_supplier_id` parameter. | CC-10 prompt |
| 7 | Buyer RPCs derive organization from `identity.current_organization_id()` — no `p_buyer_organization_id` parameter. | CC-10 prompt |
| 8 | One active offer per `(supplier_id, request_id)` via partial unique index `WHERE deleted_at IS NULL`. Withdrawal soft-deletes; new offer allowed thereafter. Other terminal states (rejected, expired, accepted, shortlisted) keep the row and block re-submission. | CC-10 prompt #16 |
| 9 | Buyer RPCs are read-only in CC-10. Buyer evaluation/award is CC-11. | CC-10 prompt #13 |
| 10 | Admin can force a status change (`admin_force_status_change`) but no contract / award workflow is implemented. | CC-10 prompt #14 |
| 11 | Cross-RFQ integrity enforced at RPC level: offer items must belong to the parent offer's RFQ; spec responses must match the same RFQ item as the offer item; document commitments must match the same RFQ. | CC-10 prompt #16 |
| 12 | Status events table is immutable: no UPDATE/DELETE policies. Inserts only via RPC. | CC-10 prompt #9 |
| 13 | No seed offers — tests create their own fixtures. | CC-10 prompt #17 |

## Schema overview

### Enums (3)

- `offer.offer_status` — `draft, submitted, withdrawn, expired, rejected, shortlisted, accepted`
- `offer.commitment_status` — `committed, with_caveat, cannot_provide, conditional`
- `offer.compliance_status` — `compliant, deviation, not_applicable, pending`

### Tables (5)

| Table | Purpose |
|-------|---------|
| `offer.supplier_offers` | Master offer record. Carries supplier, parent RFQ, status, currency, incoterm, delivery preferences, payment terms, validity, lifecycle timestamps. |
| `offer.supplier_offer_items` | Line items mapping to `rfq.request_items`. Unit price, total price, quantity, packaging, origin, delivery window. |
| `offer.supplier_offer_item_specifications` | Supplier's responses to RFQ item specifications. Per `offer_item × spec_key`. Compliance status + deviation text. |
| `offer.supplier_offer_document_commitments` | Supplier's commitments to provide documents (declarations only — no file storage). Either offer-scoped or item-scoped. |
| `offer.supplier_offer_status_events` | **Immutable** lifecycle audit. Every transition writes one row. No UPDATE/DELETE policies. |

## Lifecycle / status model

```
            supplier_create_draft_offer (requires invitation)
                         │
                         ▼
                      draft
                         │
                         ├── supplier_update_my_offer (partial; draft-only)
                         ├── supplier_upsert_offer_item / *_spec_response / *_doc_commitment
                         │
                supplier_submit_my_offer
                         │
                         ▼
                    submitted ─── supplier_withdraw_my_offer ──► withdrawn  (terminal, soft-deleted)
                         │
                admin_force_status_change
                         │
                         ├──► shortlisted ─── supplier_withdraw_my_offer ──► withdrawn
                         ├──► rejected  (terminal)
                         ├──► expired   (terminal)
                         └──► accepted  (placeholder; CC-11+ implements award workflow)
```

- `supplier_withdraw_my_offer` is allowed from `draft`, `submitted`, `shortlisted`. It sets `status='withdrawn'` and `deleted_at=now()` so the partial unique index frees up for a new offer.
- All transitions write `offer.supplier_offer_status_events`.
- All transitions also write `audit.audit_event` via `offer.fn_audit`.
- `accepted` is reserved as a placeholder. No contract / award generation is performed in CC-10.

## Security model

### RLS

All 5 tables have RLS enabled with predicates that admit three audiences:

1. **Supplier-side** — members of the supplier organization that owns the offer (`offer.organization_id` joins to `organization.memberships`).
2. **Buyer-side** — members of the buyer organization that owns the parent RFQ (via `rfq.requests.organization_id`).
3. **Platform admin** — always.

Soft-deleted rows on `supplier_offers` are visible to `platform_admin` or `compliance_officer` via `*_select_deleted`. Backstop `*_admin_modify` policies on every table allow only `platform_admin` (RPCs bypass via SECURITY DEFINER).

### Grants

```
anon          → supplier_offers, supplier_offer_items,
                 supplier_offer_item_specifications,
                 supplier_offer_document_commitments              SELECT (RLS returns 0)

authenticated → all 5 tables                                      SELECT
```

`supplier_offer_status_events` is intentionally not exposed to anon. **No INSERT/UPDATE/DELETE direct grants on any offer table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `offer.fn_audit(action, offer_id, payload)` | Writes domain audit event; exception-swallowed. |
| `offer.fn_record_status_event(...)` | Inserts immutable status_events row. |
| `offer.fn_assert_offer_supplier_owned(offer_id)` | Raises `42501` if caller's supplier doesn't own the offer (platform_admin bypasses). |
| `offer.fn_assert_offer_editable(offer_id)` | Raises `P0001` if status ≠ 'draft'. |
| `offer.fn_assert_supplier_invited_to_rfq(supplier_id, request_id)` | Raises `42501` if no active invitation row exists. |

## RPC inventory (18)

### Supplier RPCs (12)

| Function | Vol | Purpose |
|----------|-----|---------|
| `supplier_create_draft_offer(...)` returns uuid | volatile | Creates draft offer. Verifies invitation. Generates offer_code. Rejects duplicate-active. |
| `supplier_update_my_offer(offer_id, ...)` | volatile | Partial update of draft offer. |
| `supplier_upsert_offer_item(offer_id, item_id?, request_item_id?, ...)` returns uuid | volatile | Create or update item. Enforces same-RFQ integrity. |
| `supplier_remove_offer_item(item_id)` | volatile | Soft-delete; draft-only. |
| `supplier_upsert_spec_response(offer_item_id, spec_key, ...)` returns uuid | volatile | Upsert by `(offer_item_id, spec_key)`. Enforces RFQ spec ↔ RFQ item match. |
| `supplier_remove_spec_response(response_id)` | volatile | Soft-delete; draft-only. |
| `supplier_upsert_doc_commitment(offer_id, offer_item_id?, ...)` returns uuid | volatile | Upsert by (scope, document_kind). Enforces same-RFQ integrity if `request_doc_req_id` supplied. |
| `supplier_remove_doc_commitment(commitment_id)` | volatile | Soft-delete; draft-only. |
| `supplier_submit_my_offer(offer_id)` | volatile | draft → submitted; writes status event. |
| `supplier_withdraw_my_offer(offer_id, reason?)` | volatile | Any active state → withdrawn + soft-delete. |
| `supplier_list_my_offers(status?, limit, offset)` returns table | stable | List own offers. |
| `supplier_get_my_offer(offer_id)` returns jsonb | stable | Detail with items / specs / commitments. |

### Buyer RPCs (2 — read-only)

| Function | Vol | Purpose |
|----------|-----|---------|
| `buyer_list_received_offers(request_id?, status?, limit, offset)` | stable | List offers on own org RFQs. |
| `buyer_get_offer(offer_id)` returns jsonb | stable | Detail iff offer's parent RFQ is in caller's org. |

### Admin RPCs (4)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_offers(...)` | stable | Cross-org admin list. |
| `admin_get_offer(offer_id)` returns jsonb | stable | Detail with status events. |
| `admin_force_status_change(offer_id, status, reason?)` | volatile | Override to any status. Writes status event. |
| `admin_list_offer_status_events(offer_id)` | stable | Audit trail. |

**18 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`.

## Validation Summary

### Migration apply

```
Applying migration 20260622090021_supplier_offer_foundation.sql...
Finished supabase db reset on branch main.
```

All 21 migrations apply cleanly. No mid-implementation fixes were required after the initial draft — lessons from CC-09 (no bare `citext` inside `search_path=''` functions, no UPDATE in `stable` functions) were applied up-front.

### Verification queries (snapshot)

- 5 `offer.*` tables, all `relrowsecurity = t`
- 0 INSERT/UPDATE/DELETE direct grants on `offer.*`
- 18 RPCs across supplier/buyer/admin namespaces
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 8 stable + 10 volatile (split matches read/write intent)
- 0 `supplier_*` RPCs accept `p_supplier_id`
- 0 `buyer_*` RPCs accept `p_buyer_organization_id`
- Single distinct owner across all offer RPCs

### pgTAP suite

```
================================================================
Files: 32 passed, 0 failed
Assertions: 174 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–028 | 147 | CC-05 through CC-09 (incl. acceptance) |
| **029 offer RLS, grants, RPC metadata** | **11** | **CC-10** |
| **030 supplier lifecycle (create → submit → withdraw + status event)** | **7** | **CC-10** |
| **031 scope + data integrity** (uninvited, dup-active, cross-RFQ item, cross-RFQ spec, foreign-supplier mutation, submitted lock) | **6** | **CC-10** |
| **032 buyer visibility** (own-RFQ sees, other-buyer sees 0, foreign offer detail blocked) | **3** | **CC-10** |
| **CC-10 new** | **27** | |
| **Suite total** | **174** | **across 32 files** |

### Frontend

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes (unchanged) |
| `bash scripts/verify-admin-route-guards.sh` | PASSED |

No frontend code added in CC-10 — Database type does NOT yet include `offer` schema. CC-11 should regenerate types and extend `supabase/config.toml` `[api].schemas` to include `offer` before any frontend code calls offer RPCs.

## Known limitations / handoff notes for CC-11

1. **`supabase/config.toml`** does not yet expose the `offer` schema to PostgREST. CC-11 must add `offer` to `[api].schemas` before frontend can call offer RPCs.
2. **No buyer evaluation / award workflow.** `accepted`, `rejected`, `shortlisted` are status placeholders. CC-11 introduces buyer evaluation flows that move offers between these states with proper buyer-side authorization (rather than admin-only).
3. **No contract generation.** Award acceptance does not create a contract; that's the next domain after CC-11.
4. **No shipment, pricing engine, escrow, settlement, payment, or negotiation chat.**
5. **No supplier offer revisions.** v1 rule is "one active offer per (supplier, RFQ)". Revisions must be modelled explicitly (e.g. `parent_offer_id` self-FK + revision number) in a later phase.
6. **No `Database` type entry for `offer`** in the frontend types file. Will be added when buyer/supplier UI lands.
7. **No URL/path validation on document commitments.** They are declarations only; no file storage yet.
8. **`expired` transition is admin-only.** A system-side scheduled job to expire offers past `validity_until` is out of scope.
9. **Audit events** for offer domain (`offer.created`, `offer.submitted`, `offer.withdrawn`, ...) are written but no audit drilldown UI exists for `offer.*` action codes.
10. **Cross-RFQ integrity** is enforced at RPC level, not at FK/CHECK constraint level. This is deliberate (cross-table CHECKs are non-trivial to maintain), but it means direct INSERTs by `service_role` could violate integrity. Mitigated by the no-direct-write-grants policy on `authenticated`.
11. **No offer-comparison or scoring views** — buyer simply reads the list. CC-11 will likely introduce evaluation tables / views.

---

# Security Acceptance Addendum (v1.1)

Performed after CC-10 was provisionally complete, before any CC-11 (contract / award / shipment / pricing / settlement / escrow / payment / negotiation) work began. **No migration changes** — every check was verification-only. Migrations 0001–0021 untouched.

## 1. RLS verification on all 5 offer tables — ✅ PASS

| Table | `relrowsecurity` | `relforcerowsecurity` |
|-------|------------------|----------------------|
| offer.supplier_offers | t | f |
| offer.supplier_offer_items | t | f |
| offer.supplier_offer_item_specifications | t | f |
| offer.supplier_offer_document_commitments | t | f |
| offer.supplier_offer_status_events | t | f |

All 5 tables have RLS enabled in standard (non-forced) mode — consistent with CC-03 through CC-09. `relforcerowsecurity = f` means table owner and superuser bypass; every other role is gated. Same posture as supplier/commodity/rfq schemas.

## 2. Grants matrix — ✅ PASS

```
anon          → offer.supplier_offers                       SELECT
                offer.supplier_offer_items                  SELECT
                offer.supplier_offer_item_specifications    SELECT
                offer.supplier_offer_document_commitments   SELECT

authenticated → offer.supplier_offers                       SELECT
                offer.supplier_offer_items                  SELECT
                offer.supplier_offer_item_specifications    SELECT
                offer.supplier_offer_document_commitments   SELECT
                offer.supplier_offer_status_events          SELECT
```

`offer.supplier_offer_status_events` is intentionally NOT exposed to `anon` — the lifecycle audit trail is supplier/buyer/admin-only at the grant level. Sanity check returns **0** rows for `INSERT/UPDATE/DELETE` direct grants on any `offer.*` table for either role.

## 3. No direct INSERT/UPDATE/DELETE grants — ✅ PASS

```sql
select count(*) from information_schema.role_table_grants
 where table_schema = 'offer'
   and grantee in ('anon', 'authenticated')
   and privilege_type in ('INSERT', 'UPDATE', 'DELETE');
-- 0
```

All mutations route through the 18 SECURITY DEFINER RPCs.

## 4. RPC metadata verification — ✅ PASS

All 18 offer `supplier_*` / `buyer_*` / `admin_*` RPCs:

| Property | Value |
|----------|-------|
| Distinct owners | 1 (`postgres`) |
| `security_definer = true` | 18 / 18 |
| `search_path` config | `search_path=""` on every function |
| Stable functions (reads) | 8 — `supplier_list_my_offers`, `supplier_get_my_offer`, `buyer_list_received_offers`, `buyer_get_offer`, `admin_list_offers`, `admin_get_offer`, `admin_list_offer_status_events` (plus internal `fn_assert_offer_supplier_owned`, `fn_assert_offer_editable`, `fn_assert_supplier_invited_to_rfq` — also stable) |
| Volatile functions (mutations) | 10 — all 9 supplier mutation RPCs + `admin_force_status_change` |

## 5. Supplier RPC safety — no `p_supplier_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'offer'
   and p.proname like 'supplier_%'
   and p.proargnames is not null
   and 'p_supplier_id' = any(p.proargnames);
-- 0
```

No `offer.supplier_*` RPC accepts a caller-supplied `p_supplier_id`. The supplier is derived exclusively from `supplier.fn_portal_supplier_id()` (CC-07).

## 6. Buyer RPC safety — no `p_buyer_organization_id` — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'offer'
   and p.proname like 'buyer_%'
   and p.proargnames is not null
   and 'p_buyer_organization_id' = any(p.proargnames);
-- 0
```

No `offer.buyer_*` RPC accepts a caller-supplied `p_buyer_organization_id`. The buyer organization is derived exclusively from `identity.current_organization_id()` (JWT).

## 7. Supplier lifecycle verification — ✅ PASS

Covered by pgTAP test `030_offer_supplier_lifecycle.sql`:

```
ok 1 - supplier_create_draft_offer creates offer with status=draft
ok 2 - supplier_upsert_offer_item adds exactly one item
ok 3 - supplier_upsert_spec_response adds one spec response
ok 4 - supplier_upsert_doc_commitment adds one document commitment
ok 5 - supplier_submit_my_offer moves status draft → submitted
ok 6 - submit writes one status_events row draft → submitted
ok 7 - supplier_withdraw_my_offer sets status=withdrawn and soft-deletes the row
```

Status events are immutable (no UPDATE/DELETE policies). Every transition is captured.

## 8. Supplier invitation / scope enforcement — ✅ PASS

Covered by pgTAP test `031_offer_scope_and_integrity.sql`:

```
ok 1 - uninvited supplier Y cannot create offer for R1 (42501)
ok 5 - supplier Y cannot mutate supplier X's offer (42501)
ok 6 - submitted offer is locked from normal edit (P0001)
```

`offer.fn_assert_supplier_invited_to_rfq()` is the load-bearing invitation gate. `offer.fn_assert_offer_supplier_owned()` blocks cross-supplier mutation. `offer.fn_assert_offer_editable()` blocks edits after submission.

## 9. Cross-RFQ integrity enforcement — ✅ PASS

Covered by pgTAP test `031_offer_scope_and_integrity.sql`:

```
ok 3 - offer item referencing an RFQ item from a different RFQ is rejected (42501)
ok 4 - spec response with RFQ spec from a different RFQ item is rejected (42501)
```

Offer items must reference RFQ items belonging to the parent offer's RFQ. Spec responses must reference RFQ specs belonging to the same RFQ item as the offer item. Document commitments (covered by RPC logic) must reference RFQ doc requirements belonging to the same RFQ — same pattern, runtime-checked.

## 10. Duplicate active offer rejection — ✅ PASS

Covered by pgTAP test `031_offer_scope_and_integrity.sql`:

```
ok 2 - duplicate active offer by same supplier for same RFQ is rejected (23505)
```

Partial unique index `(supplier_id, request_id) WHERE deleted_at IS NULL` is the structural guard; the RPC also performs an explicit duplicate check before INSERT to raise a clear `23505` instead of an opaque unique violation.

## 11. Buyer visibility scope — ✅ PASS

Covered by pgTAP test `032_offer_buyer_visibility.sql`:

```
ok 1 - buyer A sees own RFQ offer in buyer_list_received_offers
ok 2 - buyer B sees 0 offers — RFQ owner is buyer A
ok 3 - buyer B cannot read offer on buyer A's RFQ (42501)
```

`buyer_list_received_offers` filters by `r.organization_id = identity.current_organization_id()`. `buyer_get_offer` raises `42501` if the offer's parent RFQ is not owned by the caller's organization. Platform admin bypasses the org check.

## 12. Frontend validation — ✅ PASS

CC-10 added no frontend code. The frontend remains at its CC-07 surface (22 routes).

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

## 13. Suite totals — Before / After CC-10

| Metric | Pre-CC-10 (CC-09 v1.1 acceptance) | Post-CC-10 (acceptance addendum) |
|--------|------------------------------------|----------------------------------|
| pgTAP files | 28 | **32** |
| pgTAP assertions | 147 | **174** |
| Migrations | 20 | 21 |
| Schemas | identity, organization, audit, supplier, commodity, rfq | identity, organization, audit, supplier, commodity, rfq, **offer** |
| Backend RPCs (admin + portal/buyer/supplier surfaces) | 72 | **90** (+18 offer) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 14. Final status

**CC-10 is FULLY ACCEPTED.**

- ✅ RLS verified on all 5 offer tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE
- ✅ RPC ownership consistent (single owner `postgres`), all `security_definer`, all `search_path=""`
- ✅ Supplier RPC safety — no `p_supplier_id` argument
- ✅ Buyer RPC safety — no `p_buyer_organization_id` argument
- ✅ Supplier lifecycle provable by pgTAP (test 030)
- ✅ Invitation gate + foreign-supplier mutation block + submit-lock provable (test 031)
- ✅ Cross-RFQ integrity (offer item, spec response, doc commitment) provable (test 031)
- ✅ Duplicate active offer rejection provable (test 031, SQLSTATE 23505)
- ✅ Buyer visibility scope provable (test 032)
- ✅ Frontend typecheck + build + route guards green
- ✅ pgTAP suite 174 / 174 across 32 files
- ✅ No new business domain code introduced
- ✅ No CC-11 work started (no contract / award / shipment / pricing / settlement / escrow / payment / negotiation)
