# CC-07 — Phase 2.0 Supplier Foundation, Schema Notes

Version: 1.2 (DRAFT — security acceptance addendum)
Scope: First business domain — supplier profile, categories, documents (metadata), lifecycle, admin + portal RPCs + acceptance verification
Migration: `23-DATABASE/migrations/0018_supplier_foundation.sql` (single, append-only). No new migration in v1.2.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Locked decisions (final, after v1.1 corrections)

| # | Decision | Source |
|---|----------|--------|
| 1 | Single migration `0018_supplier_foundation.sql`. | User approval |
| 2 | Trigger-based auto-shell on `organization.organizations` AFTER INSERT when `type='supplier'`. Idempotent via `ON CONFLICT (organization_id) DO NOTHING`. | User approval |
| 3 | RPC namespace `supplier.admin_*` (9) + `supplier.portal_*` (6). | User approval |
| 4 | `external_reference` is free text (no URL validation in CC-07). | User approval |
| 5 | Categories are seed-only — no admin CRUD UI. | User approval |
| 6 | Reuse CC-06 `admin_assign_role` for `supplier_admin` role assignment. | User approval |
| A | `portal_remove_my_category` is SOFT-DELETE (set `deleted_at` + `updated_by`). Partial unique index `(supplier_id, category_id) WHERE deleted_at IS NULL` allows revive. | Correction A |
| B | `supplier.categories` SELECT grant: **authenticated only**, NOT anon. | Correction B |
| C | Portal RPCs accept `supplier_admin` OR `organization_admin` OR `platform_admin` for the active organization. | Correction C |
| D | Route guard script verifies `/admin/suppliers`, `/admin/suppliers/[supplierId]`, `/supplier/profile`, `/supplier/categories`, `/supplier/documents`. | Correction D |
| E | Exposure tests cover anon, no-org authenticated, unrelated-org authenticated, and category visibility per grant decision. | Correction E |
| F | RPC ownership verified — single owner `postgres`, all `security_definer=true`, search_path `''`, correct volatility per read/write intent. | Correction F |
| G | Final assertion count reported actual: **64 across 16 files** (not forced). | Correction G |

## Schema overview

```
supplier
├── suppliers          (1:1 with org type='supplier'; trigger-created shell)
├── categories         (~12 seeded; authenticated-only SELECT)
├── supplier_categories (junction; soft-delete only)
└── supplier_documents (metadata only; external_reference free text)
```

## Status lifecycle

```
draft ──portal_submit──▶ submitted ──admin_start_review──▶ under_review
                                              ├──admin_approve──▶ approved
                                              └──admin_reject──▶ rejected
                                  approved ──admin_suspend──▶ suspended
                                  suspended ──admin_reactivate──▶ approved
```

Each transition RPC checks the current state and raises `'invalid_transition'` (errcode `P0001`) on mismatch. Each transition writes an `audit.audit_event` row with `action_code = 'supplier.<event>'`.

`verification_status` is independent of `status` — managed via `admin_set_verification_status`.

## RPC inventory (15)

### Admin (9 — platform_admin only)

| Function | Volatility |
|----------|------------|
| `admin_list_suppliers(int, int, supplier_status, verification_status)` | stable |
| `admin_get_supplier(uuid)` | stable |
| `admin_start_review(uuid)` | volatile |
| `admin_approve_supplier(uuid)` | volatile |
| `admin_reject_supplier(uuid, text)` | volatile |
| `admin_suspend_supplier(uuid, text)` | volatile |
| `admin_reactivate_supplier(uuid)` | volatile |
| `admin_set_verification_status(uuid, verification_status, text)` | volatile |
| `admin_set_document_status(uuid, document_status, text)` | volatile |

### Portal (6 — supplier_admin / organization_admin / platform_admin)

| Function | Volatility |
|----------|------------|
| `portal_upsert_my_profile(text, text, text, citext, text, char(2), int)` | volatile |
| `portal_add_my_category(uuid)` | volatile |
| `portal_remove_my_category(uuid)` | volatile (soft-delete) |
| `portal_add_my_document(document_type, text, text, text, date, date)` returns uuid | volatile |
| `portal_remove_my_document(uuid)` | volatile (soft-delete) |
| `portal_submit_my_profile_for_review()` | volatile |

### Internal helpers (3)

- `supplier.fn_create_supplier_shell()` — AFTER INSERT trigger function on `organization.organizations`
- `supplier.fn_audit(uuid, text, jsonb)` — writes a `supplier.*` audit event; wrapped in caller's nested begin/exception
- `supplier.fn_portal_supplier_id()` — verifies portal authorization and returns the supplier_id for the caller's active org

## Grants matrix (after 0018)

```
Table                          anon            authenticated
─────────────────────────────  ──────────────  ───────────────
supplier.suppliers              SELECT          SELECT
supplier.supplier_categories    SELECT          SELECT
supplier.supplier_documents     SELECT          SELECT
supplier.categories             —               SELECT      ← correction B
```

**No INSERT/UPDATE/DELETE** grants on any supplier.* table. All writes flow through the 15 SECURITY DEFINER RPCs. Defense in depth retained via RLS backstop modify policies.

## RLS pattern

For each tenant-scoped supplier table:

```sql
-- Active rows: platform_admin OR active member of organization_id
*_select where deleted_at is null and (is_platform_admin() or exists (memberships ...))

-- Soft-deleted rows: platform_admin OR compliance_officer
*_select_deleted where deleted_at is not null and (is_platform_admin() or has_role('compliance_officer'))

-- Backstop modify: platform_admin only (RPCs bypass via SECURITY DEFINER)
*_admin_modify for all using (is_platform_admin()) with check (is_platform_admin())
```

`supplier.categories` follows the lookup pattern (`auth.role() = 'authenticated'` for select, platform_admin for modify).

## Validation Summary (acceptance evidence)

### Migration apply

```
Applying migration 20260622090018_supplier_foundation.sql...
Finished supabase db reset on branch main.
```

All 18 migrations applied cleanly.

### RPC ownership verification (correction F)

```
function                         owner     definer  volatility  search_path
admin_approve_supplier           postgres  t        volat       ""
admin_get_supplier               postgres  t        stable      ""
admin_list_suppliers             postgres  t        stable      ""
admin_reactivate_supplier        postgres  t        volat       ""
admin_reject_supplier            postgres  t        volat       ""
admin_set_document_status        postgres  t        volat       ""
admin_set_verification_status    postgres  t        volat       ""
admin_start_review               postgres  t        volat       ""
admin_suspend_supplier           postgres  t        volat       ""
fn_audit                         postgres  t        volat       ""
fn_create_supplier_shell         postgres  t        volat       ""
fn_portal_supplier_id            postgres  t        stable      ""
portal_add_my_category           postgres  t        volat       ""
portal_add_my_document           postgres  t        volat       ""
portal_remove_my_category        postgres  t        volat       ""
portal_remove_my_document        postgres  t        volat       ""
portal_submit_my_profile_for_review postgres t      volat       ""
portal_upsert_my_profile         postgres  t        volat       ""

distinct owners: 1
```

18 functions in supplier schema (15 RPCs + 3 helpers). All `postgres`-owned, all `security_definer=t`, all `search_path=""`, volatility correct.

### Grants matrix (correction B)

```
anon:           supplier_categories, supplier_documents, suppliers          (SELECT only)
authenticated:  categories, supplier_categories, supplier_documents, suppliers (SELECT)
                — UPDATE on identity.user_profiles preserved from 0014 for switchOrganization
```

`supplier.categories` is authenticated-only (correction B); audit.* still has zero grants.

### pgTAP suite

```
================================================================
Files: 16 passed, 0 failed
Assertions: 64 passed, 0 failed
================================================================
```

| File | Assertions | Domain |
|------|------------|--------|
| 001–005 | 15 | CC-05 baseline |
| 006–010 | 16 | CC-06 admin management |
| 011–012 | 6 | CC-06 security acceptance (auth/audit non-exposure) |
| 013_supplier_rls_isolation | 7 | Anon, no-context auth, unrelated auth, supplier_admin, platform_admin, categories anon/auth |
| 014_supplier_admin_guards | 9 | Every `admin_*` rejects non-admin (42501) |
| 015_supplier_portal_guards | 7 | Every `portal_*` rejects unauthorized; org_admin positive (correction C) |
| 016_supplier_status_lifecycle | 4 | Trigger → submit → start_review → approve |
| **Total** | **64** | |

### Route guard verification (correction D)

```
=== CC-06/07 route-guard verification ===

--- Admin portal ---
OK:   src/app/admin/layout.tsx exists
OK:   admin layout calls requireRole(ROLES.PLATFORM_ADMIN)
OK:   no nested layout.tsx under src/app/admin/
OK:   /admin/users/page.tsx exists
OK:   /admin/organizations/page.tsx exists
OK:   /admin/audit/page.tsx exists
OK:   /admin/suppliers/page.tsx exists
OK:   /admin/suppliers/[supplierId]/page.tsx exists

--- Supplier portal ---
OK:   src/app/supplier/layout.tsx exists
OK:   supplier layout calls requireRole([SUPPLIER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN])
OK:   no nested layout.tsx under src/app/supplier/
OK:   /supplier/profile/page.tsx exists
OK:   /supplier/categories/page.tsx exists
OK:   /supplier/documents/page.tsx exists

VERIFICATION PASSED
```

### Frontend

- `npm run typecheck` — exit 0
- `npm run build` — exit 0, **22 routes** generated (6 new admin/portal supplier routes)

## Known follow-ups (deferred from CC-07)

1. **Storage buckets / file upload UI** — `external_reference` upgraded from free text to `storage://` references once Storage phase lands.
2. **URL validation** on `external_reference` (CHECK or trigger-level).
3. **Editing supplier profile after `rejected`** — admin "reset to draft" RPC.
4. **Editing organization-bound fields after `approved`** — controlled diff workflow.
5. **Member-management UI for suppliers** — assign supplier_admin/organization_admin to an org via CC-06's existing RPCs.
6. **Category CRUD** UI for platform admin.
7. **Category hierarchy** — parent_category_id is modeled but seed is flat.
8. **Cursor-based pagination** for `admin_list_suppliers` when row count grows.
9. **Audit drilldown** including supplier-domain `action_code` filters.
10. **Email notification** on lifecycle transitions (approve/reject/suspend).

---

# Security Acceptance Addendum (v1.2)

Performed after CC-07 was provisionally accepted, before any CC-08 / commodity work began. **No migration changes** — every check was verification-only.

## 1. RLS verification — ✅ PASS

Query: `relrowsecurity` and `relforcerowsecurity` on every `supplier.*` table.

| Table | RLS enabled | RLS forced |
|-------|-------------|-----------|
| supplier.suppliers | t | f |
| supplier.categories | t | f |
| supplier.supplier_categories | t | f |
| supplier.supplier_documents | t | f |

All 4 tables have RLS enabled. `relforcerowsecurity = f` is the standard non-forced mode — superusers and the table owner bypass; every other role is gated. Consistent with CC-03/04/05/06 tables. ✅

## 2. Grants matrix — ✅ PASS

```
anon          → supplier.suppliers           SELECT
              → supplier.supplier_categories SELECT
              → supplier.supplier_documents  SELECT

authenticated → supplier.suppliers           SELECT
              → supplier.categories          SELECT  (correction B — auth-only)
              → supplier.supplier_categories SELECT
              → supplier.supplier_documents  SELECT
```

Sanity check `SELECT count(*) FROM information_schema.role_table_grants WHERE table_schema='supplier' AND grantee IN ('anon','authenticated') AND privilege_type IN ('INSERT','UPDATE','DELETE')` returned **0 rows**. No direct INSERT/UPDATE/DELETE grants exist. ✅

## 3. pgTAP exposure / grants / write-rejection — ✅ PASS

New file `23-DATABASE/tests/017_supplier_grants_and_exposure.sql`. 13/13 assertions:

```
ok 1  - anon cannot SELECT supplier.categories (no grant)
ok 2  - anon sees 0 supplier.suppliers
ok 3  - anon sees 0 supplier.supplier_categories
ok 4  - anon sees 0 supplier.supplier_documents
ok 5  - authenticated CAN SELECT supplier.categories (12 seeded)
ok 6  - authenticated with no org context sees 0 supplier.suppliers
ok 7  - authenticated in unrelated organization sees 0 supplier A rows
ok 8  - authenticated cannot INSERT supplier.suppliers (no GRANT)
ok 9  - authenticated cannot UPDATE supplier.suppliers (no GRANT)
ok 10 - authenticated cannot DELETE supplier.suppliers (no GRANT)
ok 11 - authenticated cannot INSERT supplier.supplier_documents (no GRANT)
ok 12 - authenticated cannot UPDATE supplier.supplier_documents (no GRANT)
ok 13 - authenticated cannot DELETE supplier.supplier_documents (no GRANT)
```

## 4. Supplier RPC ownership verification — ✅ PASS

| Function | Owner | Definer | Volatility | search_path |
|----------|-------|---------|------------|-------------|
| admin_approve_supplier | postgres | t | volatile | `''` |
| admin_get_supplier | postgres | t | **stable** | `''` |
| admin_list_suppliers | postgres | t | **stable** | `''` |
| admin_reactivate_supplier | postgres | t | volatile | `''` |
| admin_reject_supplier | postgres | t | volatile | `''` |
| admin_set_document_status | postgres | t | volatile | `''` |
| admin_set_verification_status | postgres | t | volatile | `''` |
| admin_start_review | postgres | t | volatile | `''` |
| admin_suspend_supplier | postgres | t | volatile | `''` |
| portal_add_my_category | postgres | t | volatile | `''` |
| portal_add_my_document | postgres | t | volatile | `''` |
| portal_remove_my_category | postgres | t | volatile | `''` |
| portal_remove_my_document | postgres | t | volatile | `''` |
| portal_submit_my_profile_for_review | postgres | t | volatile | `''` |
| portal_upsert_my_profile | postgres | t | volatile | `''` |

15 supplier `admin_*` / `portal_*` RPCs. Single owner `postgres`. All `security_definer = t`. Read RPCs stable, mutation RPCs volatile. `search_path = ''` consistently. ✅

## 5. Route guard verification — ✅ PASS

`bash 22-SOURCE-CODE/frontend-web/scripts/verify-admin-route-guards.sh`:

```
--- Admin portal ---
OK: src/app/admin/layout.tsx exists
OK: admin layout calls requireRole(ROLES.PLATFORM_ADMIN)
OK: no nested layout.tsx under src/app/admin/
OK: /admin/users/page.tsx exists
OK: /admin/organizations/page.tsx exists
OK: /admin/audit/page.tsx exists
OK: /admin/suppliers/page.tsx exists
OK: /admin/suppliers/[supplierId]/page.tsx exists

--- Supplier portal ---
OK: src/app/supplier/layout.tsx exists
OK: supplier layout calls requireRole([SUPPLIER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN])
OK: no nested layout.tsx under src/app/supplier/
OK: /supplier/profile/page.tsx exists
OK: /supplier/categories/page.tsx exists
OK: /supplier/documents/page.tsx exists

VERIFICATION PASSED
```

## 6. pgTAP trigger safety — ✅ PASS

New file `23-DATABASE/tests/018_supplier_trigger_safety.sql`. 4/4 assertions:

```
ok 1 - trigger creates exactly one supplier shell on type=supplier insert
ok 2 - idempotent: ON CONFLICT DO NOTHING prevents duplicate supplier shell
ok 3 - buyer-type organization does NOT create a supplier shell
ok 4 - carrier-type organization does NOT create a supplier shell
```

## 7. pgTAP portal mutation scope — ✅ PASS

New file `23-DATABASE/tests/019_supplier_portal_scope.sql`. 5/5 assertions:

```
ok 1 - no supplier.portal_* RPC accepts a p_supplier_id parameter
ok 2 - supplier_admin updates only own supplier; unrelated supplier untouched
ok 3 - organization_admin in own supplier organization can call portal_upsert_my_profile
ok 4 - platform_admin with JWT.organization_id set to a supplier org can call portal_upsert_my_profile
ok 5 - platform_admin without current_organization_id cannot call portal_upsert_my_profile
```

The "no p_supplier_id" assertion uses `pg_proc.proargnames` introspection — a static guarantee that the portal RPCs cannot be ID-manipulated. The supplier is derived from `identity.current_organization_id()` exclusively.

**Trust model documented:** in production, `JWT.organization_id` is issued by the Custom Access Token Hook based on `user_profiles.primary_organization_id`, which can only be changed via `switchOrganization` (CC-04) — which verifies active membership before mutating. So a supplier_admin of org A cannot legitimately obtain a JWT carrying `organization_id = B` without first being granted a membership in B.

## 8. pgTAP audit event behavior — ✅ PASS

New file `23-DATABASE/tests/020_supplier_audit_events.sql`. 4/4 assertions:

```
ok 1 - portal_submit_my_profile_for_review writes one supplier.submitted event
ok 2 - admin_start_review writes one supplier.review_started event
ok 3 - admin_approve_supplier writes one supplier.approved event
ok 4 - supplier.fn_audit body contains exception handler (audit failures never block lifecycle RPCs)
```

Assertion 4 is a static inspection: `pg_get_functiondef(supplier.fn_audit) ILIKE '%exception when others%'` proves the audit-write helper swallows internal exceptions, so a failed audit insert never blocks the lifecycle RPC.

## 9. Frontend — ✅ PASS

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

## 10. Suite totals — Before / After Acceptance

| Metric | Pre-acceptance (CC-07 v1.1) | Post-acceptance (CC-07 v1.2) |
|--------|------------------------------|------------------------------|
| pgTAP files | 16 | **20** |
| pgTAP assertions | 64 | **90** |
| Migrations | 18 | 18 (unchanged) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

Per acceptance instruction G, this is the **actual** final count — not a forced target.

## 11. Final status

**CC-07 is FULLY ACCEPTED.**

- ✅ RLS verified on all 4 supplier tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE on supplier.*
- ✅ Supplier RPC ownership consistent and appropriate
- ✅ Route guards in place for /admin/suppliers and /supplier portal
- ✅ Trigger safety verified — idempotent, type-gated
- ✅ Portal mutation scope verified — no ID manipulation surface, trust model documented
- ✅ Audit event behavior verified — lifecycle events written, audit failures never block
- ✅ pgTAP suite 90/90 across 20 files
- ✅ Frontend typecheck + build green
- ✅ No new business domain code
- ✅ No CC-08 work started
