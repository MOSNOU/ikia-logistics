# CC-08 — Phase 2.1 Commodity Foundation, Schema Notes

Version: 1.1 (DRAFT — acceptance addendum)
Scope: Second business domain — commodity categories, products, specifications, document requirements, supplier product capabilities
Migration: `23-DATABASE/migrations/0019_commodity_foundation.sql` (single, append-only). No new migration in v1.1.
Acceptance: **FULLY ACCEPTED** (see Security Acceptance Addendum at end)

## Mission

CC-08 introduces the **commodity catalog** that every downstream business module (RFQ, offer, contract, logistics, inspection, settlement) will reference. The design prioritises structure over breadth: a small set of seed products, tight RPC surface, full security parity with CC-07. No business workflow logic beyond the supplier ↔ product capability mapping.

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single migration `0019_commodity_foundation.sql`. | CC-08 prompt |
| 2 | New schema `commodity`; CC-07 supplier schema unchanged. | CC-08 prompt |
| 3 | RPC namespace `commodity.admin_*` + `commodity.portal_*`. | CC-08 prompt |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-08 prompt #9 |
| 5 | search_path = '' on every SECURITY DEFINER function. | CC-08 prompt |
| 6 | Portal RPCs derive supplier_id from `supplier.fn_portal_supplier_id()` — never accept `p_supplier_id`. | CC-08 prompt #12 |
| 7 | Lookup tables (categories, products, aliases, specs, doc-reqs) authenticated-only — NOT anon (consistent with `supplier.categories` in CC-07). | Schema design |
| 8 | `supplier_product_capabilities` SELECT to anon (RLS returns 0) + authenticated (RLS filters by org). | Schema design |
| 9 | Specifications and document requirements are soft-removed via `is_active=false`; capabilities use `deleted_at` soft-delete with partial unique index allowing revive. | Schema design |
| 10 | Seed practical but minimal: 9 categories, 10 products, 45 doc requirements, 5 specifications. | CC-08 prompt #13 |
| 11 | No frontend changes in CC-08. Future UI work lives in CC-09+ commodity portal. | CC-08 prompt #15 |

## Tables (6)

| Table | Purpose |
|-------|---------|
| `commodity.categories` | Hierarchical commodity category catalog (parent_category_id self-FK) |
| `commodity.products` | Master product catalog with HS/CAS, physical form, unit of trade, status |
| `commodity.product_aliases` | Synonyms / alternate names per product |
| `commodity.product_specifications` | Per-product spec definitions (RFQ-matching ready) |
| `commodity.product_document_requirements` | Per-product mandatory / recommended / optional documents |
| `commodity.supplier_product_capabilities` | Supplier ↔ product capability declarations (tenant-scoped) |

## Enums (6)

- `commodity.product_status` — `draft, active, inactive, deprecated`
- `commodity.physical_form` — `solid, liquid, gas, granule, powder, viscous, pellet, sheet, bar, other`
- `commodity.spec_data_type` — `number, integer, text, enum, boolean, range`
- `commodity.document_requirement_level` — `mandatory, recommended, optional`
- `commodity.document_kind` — `tds, msds_sds, coa, product_sheet, packing_list, certificate_of_origin, inspection_certificate, quality_certificate, customs_document, other`
- `commodity.capability_status` — `active, paused, suspended, withdrawn`

## Security model

### RLS

All 6 tables have RLS enabled (`relrowsecurity = t`).

- Lookup tables (categories, products, aliases, specs, doc-reqs): `select using (auth.role() = 'authenticated')`; modify only by `is_platform_admin()` (backstop — RPCs bypass via SECURITY DEFINER).
- `supplier_product_capabilities`:
  - `*_select` — visible to platform_admin OR active member of organization_id
  - `*_select_deleted` — visible to platform_admin OR compliance_officer
  - `*_admin_modify` — platform_admin only (backstop)

### Grants

| Table | anon | authenticated |
|-------|------|---------------|
| categories | — | SELECT |
| products | — | SELECT |
| product_aliases | — | SELECT |
| product_specifications | — | SELECT |
| product_document_requirements | — | SELECT |
| supplier_product_capabilities | SELECT | SELECT |

**No INSERT/UPDATE/DELETE direct grants.** Mutations only via the 18 RPCs.

### RPC inventory (18)

**Admin (13 — platform_admin only):**

| Function | Volatility | Purpose |
|----------|-----------|---------|
| `admin_list_categories(p_active)` | stable | List categories with product counts |
| `admin_create_category(...)` | volatile | Create a category |
| `admin_update_category(...)` | volatile | Update a category |
| `admin_list_products(category, status, limit, offset)` | stable | Paginated product list |
| `admin_get_product(uuid)` | stable | Single product detail |
| `admin_create_product(...)` | volatile | Create a product |
| `admin_update_product(...)` | volatile | Partial update of a product |
| `admin_upsert_product_specification(...)` | volatile | Insert/update a spec by (product, spec_key) |
| `admin_remove_product_specification(uuid)` | volatile | Soft-remove (is_active=false) |
| `admin_upsert_product_document_requirement(...)` | volatile | Insert/update a doc requirement |
| `admin_remove_product_document_requirement(uuid)` | volatile | Soft-remove |
| `admin_list_supplier_capabilities(supplier, product, status, limit, offset)` | stable | Admin review |
| `admin_set_capability_status(uuid, status)` | volatile | Override capability status |

**Portal (5 — supplier_admin / organization_admin / platform_admin):**

| Function | Volatility | Purpose |
|----------|-----------|---------|
| `portal_list_categories()` | stable | List active categories |
| `portal_list_products(category?)` | stable | List active products |
| `portal_get_product(uuid)` | stable | Product detail with specs + doc reqs aggregated as JSONB |
| `portal_upsert_my_capability(product, ...)` | volatile | Idempotent revive-or-upsert of own supplier's capability |
| `portal_remove_my_capability(product)` | volatile | Soft-delete own supplier's capability for that product |

**Internal helper (1):**

- `commodity.fn_audit(action, resource_id, supplier_id?, payload)` — writes `audit.audit_event`; exception-wrapped so audit failures never block.

Portal RPCs reuse **`supplier.fn_portal_supplier_id()`** (defined in CC-07) for authorization + supplier lookup. No new helper introduced.

## Audit triggers

`identity.set_updated_at` and `audit.fn_audit_entity` are attached to every `commodity.*` base table via DO blocks in the migration — same pattern as CC-07.

Each lifecycle / mutation RPC writes a domain audit event with `action_code = 'commodity.<event>'`:

```
commodity.category_created / category_updated
commodity.product_created / product_updated
commodity.product_spec_upserted / product_spec_removed
commodity.product_doc_req_upserted / product_doc_req_removed
commodity.capability_upserted / capability_removed
commodity.capability_status_set
```

## Seed data

- **Categories (9):** Petrochemicals, Bitumen, Fuels, Fertilizers, Polymers, Metals, Minerals, Agricultural, Industrial Chemicals (FA + EN, sort_order 10..90)
- **Products (10):** Bitumen 60/70, Bitumen 80/100, Methanol, Urea, Ammonia, Polyethylene, Polypropylene, Base Oil, Fuel Oil, Diesel EN590 — each with HS code, physical_form, unit_of_trade='ton', status='active'
- **Document requirements (45):**
  - COA mandatory on every active product (10)
  - TDS mandatory on every active product (10)
  - MSDS_SDS mandatory on petrochemicals/industrial_chemicals/fuels products (5)
  - Certificate of Origin recommended on every active product (10)
  - Packing List optional on every active product (10)
- **Specifications (5, illustrative):**
  - Bitumen 60/70: penetration (60–70, 0.1mm), softening_point (49–56 °C), flash_point (≥230 °C)
  - Methanol: purity (≥99.85 %), water_content (≤0.1 %)

Seed pattern: `INSERT ... SELECT ... ON CONFLICT (...) DO NOTHING` for idempotency on re-runs.

## Validation summary

### Migration apply

```
Applying migration 20260622090019_commodity_foundation.sql...
Finished supabase db reset on branch main.
```

All 19 migrations apply cleanly.

### Verification queries (snapshot)

- 6 commodity tables, all `relrowsecurity = t`
- 0 INSERT/UPDATE/DELETE direct grants on `commodity.*`
- 18 RPCs (13 admin + 5 portal), single owner `postgres`, all `security_definer = true`, `search_path = ""`
- 3 stable functions (`admin_list_categories`, `admin_get_product`, `admin_list_products`, `admin_list_supplier_capabilities`, `portal_list_categories`, `portal_list_products`, `portal_get_product`) — reads
- 11 volatile functions — mutations
- Seed counts: 9 categories, 10 products, 45 doc requirements, 5 specifications

### pgTAP suite

```
================================================================
Files: 24 passed, 0 failed
Assertions: 118 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–016 | 64 | CC-05 to CC-07 |
| 017–020 | 26 | CC-07 security acceptance |
| **021 commodity RLS+grants** | **12** | **CC-08** |
| **022 commodity RPC metadata** | **5** | **CC-08** |
| **023 commodity portal scope** | **4** | **CC-08** |
| **024 commodity seed consistency** | **7** | **CC-08** |
| **CC-08 new** | **28** | |
| **Suite total** | **118** | **across 24 files** |

### Frontend

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes (unchanged) |
| `bash scripts/verify-admin-route-guards.sh` | PASSED |

No frontend code added in CC-08 — typecheck and build only confirm the existing surface still compiles after the schema additions (which Database type doesn't yet cover; that ships in CC-09 when commodity UI lands).

## Known limitations / handoff notes for CC-09

1. **Database type** (`src/types/database.ts`) does NOT yet include the `commodity` schema. CC-09 should regenerate via `supabase gen types typescript --local --schema public --schema identity --schema organization --schema supplier --schema supplier --schema commodity` (or manually extend) before any frontend code calls `supabase.schema("commodity")`.
2. **`supabase/config.toml`** does not yet list `commodity` under `[api].schemas`. CC-09 must add it before PostgREST exposes commodity RPCs.
3. **No frontend pages** for commodity catalog or supplier capability management. CC-09 / later may add `/admin/commodity/...` and `/supplier/capabilities` flows.
4. **Category CRUD UI** is deferred — categories are seed-managed and only mutable via admin RPCs.
5. **Specifications coverage** is intentionally thin (5 seeded specs across 2 products). CC-09 should expand or use admin RPCs to define the full per-product spec set.
6. **Capability search / discovery** for buyers (the actual RFQ flow) is the next foundation step — capabilities are queryable but no buyer-facing surface exists yet.
7. **No URL validation** on `external_reference` in CC-07 documents; commodity documents themselves are catalog metadata only (no file references in CC-08).
8. **No storage buckets / file upload** introduced. Documents in commodity domain are *requirement definitions* (what must be supplied later), not actual files.
9. **No commodity certification / inspection workflow** — those are downstream of CC-09 RFQ work.
10. **Audit events** for commodity domain are written but no audit drilldown UI exists for `commodity.*` action codes.

---

# Security Acceptance Addendum (v1.1)

Performed after CC-08 was provisionally complete, before any CC-09 (RFQ / offer / contract / logistics / pricing / settlement) work began. **No migration changes** — every check was verification-only. Migrations 0001–0019 untouched.

## 1. RLS verification on all 6 commodity tables — ✅ PASS

| Table | `relrowsecurity` | `relforcerowsecurity` |
|-------|------------------|----------------------|
| commodity.categories | t | f |
| commodity.products | t | f |
| commodity.product_aliases | t | f |
| commodity.product_specifications | t | f |
| commodity.product_document_requirements | t | f |
| commodity.supplier_product_capabilities | t | f |

All 6 tables have RLS enabled in standard (non-forced) mode — consistent with CC-03/04/05/06/07 tables. `relforcerowsecurity = f` means table owner and superuser bypass RLS; every other role is gated. Same posture as the supplier schema.

## 2. Grants matrix — ✅ PASS

```
anon           → commodity.supplier_product_capabilities  SELECT

authenticated  → commodity.categories                      SELECT
                 commodity.products                        SELECT
                 commodity.product_aliases                 SELECT
                 commodity.product_specifications          SELECT
                 commodity.product_document_requirements   SELECT
                 commodity.supplier_product_capabilities   SELECT
```

Sanity check returns **0** rows for `INSERT/UPDATE/DELETE` direct grants on any `commodity.*` table for `anon` or `authenticated`. All mutations route through the 18 SECURITY DEFINER RPCs.

## 3. No direct INSERT/UPDATE/DELETE grants — ✅ PASS

```sql
select count(*) from information_schema.role_table_grants
 where table_schema='commodity'
   and grantee in ('anon','authenticated')
   and privilege_type in ('INSERT','UPDATE','DELETE');
-- 0
```

## 4. RPC metadata verification — ✅ PASS

All 18 commodity `admin_*` / `portal_*` RPCs:

| Property | Value |
|----------|-------|
| Distinct owners | 1 (`postgres`) |
| `security_definer = true` | 18 / 18 |
| `search_path` config | `search_path=""` on every function |
| Stable functions (reads) | 7 — `admin_list_categories`, `admin_list_products`, `admin_get_product`, `admin_list_supplier_capabilities`, `portal_list_categories`, `portal_list_products`, `portal_get_product` |
| Volatile functions (mutations) | 11 — `admin_create_category`, `admin_update_category`, `admin_create_product`, `admin_update_product`, `admin_upsert_product_specification`, `admin_remove_product_specification`, `admin_upsert_product_document_requirement`, `admin_remove_product_document_requirement`, `admin_set_capability_status`, `portal_upsert_my_capability`, `portal_remove_my_capability` |

## 5. Portal RPC safety — no `p_supplier_id` parameter — ✅ PASS

```sql
select count(*) from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'commodity'
   and p.proname like 'portal_%'
   and p.proargnames is not null
   and 'p_supplier_id' = any(p.proargnames);
-- 0
```

No `commodity.portal_*` RPC accepts a caller-supplied `p_supplier_id`. The supplier is derived exclusively from `supplier.fn_portal_supplier_id()` (CC-07), which in turn derives it from `identity.current_organization_id()` (JWT) + `supplier.suppliers.organization_id`. The ID-manipulation attack surface is structurally absent.

## 6. Supplier capability mutation scope — ✅ PASS

Covered by pgTAP test `023_commodity_portal_scope.sql`:

```
ok 1 - supplier_admin A creates exactly one capability row for supplier A
ok 2 - portal_remove_my_capability soft-deletes only own supplier A; B untouched
ok 3 - unauthorized user rejected by portal_upsert_my_capability
ok 4 - portal_upsert_my_capability errors P0002 when JWT org has no supplier profile
```

A supplier_admin in tenant A cannot mutate a capability in tenant B even by exhausting input parameters — there is no input parameter that targets a foreign supplier, and the membership-derived scope filter ensures any pre-existing capability on another supplier is left untouched. Soft-delete via `deleted_at` is asymmetric per supplier (A's row deleted, B's row untouched).

## 7. Seed data consistency — ✅ PASS

| Item | Expected | Actual |
|------|----------|--------|
| `commodity.categories` | 9 | 9 |
| `commodity.products` (active) | 10 | 10 |
| `commodity.product_document_requirements` (active) | 45 | 45 |
| `commodity.product_specifications` (active) | 5 | 5 |

Document requirement composition (45 = 10 COA + 10 TDS + 5 MSDS_SDS + 10 Cert of Origin + 10 Packing List).

Covered by pgTAP test `024_commodity_seed_consistency.sql` — 7 / 7 assertions including:

```
ok 1 - 9 expected commodity categories seeded
ok 2 - 10 active commodity products seeded
ok 3 - every seeded product has at least one document requirement
ok 4 - every seeded product has at least 2 mandatory document requirements
ok 5 - every petrochemicals/chemicals/fuels product carries mandatory MSDS_SDS
ok 6 - Bitumen 60/70 has at least 3 active specifications
ok 7 - every seeded product references an existing category
```

## 8. Frontend validation — ✅ PASS

CC-08 added no frontend code. The frontend remains at its CC-07 surface (22 routes).

| Check | Result |
|-------|--------|
| `npm run typecheck` | exit 0 |
| `npm run build` | exit 0, 22 routes |
| `bash scripts/verify-admin-route-guards.sh` | PASSED (14 checks) |

## 9. Suite totals — Before / After CC-08

| Metric | Pre-CC-08 (CC-07 v1.2 acceptance) | Post-CC-08 (acceptance addendum) |
|--------|-----------------------------------|----------------------------------|
| pgTAP files | 20 | **24** |
| pgTAP assertions | 90 | **118** |
| Migrations | 18 | 19 |
| Schemas | identity, organization, audit, supplier | identity, organization, audit, supplier, **commodity** |
| Tables exposed via PostgREST schemas (when CC-09 wires) | 12 | 18 (+6 commodity) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 10. Final status

**CC-08 is FULLY ACCEPTED.**

- ✅ RLS verified on all 6 commodity tables
- ✅ Grants matrix verified — no direct INSERT/UPDATE/DELETE
- ✅ RPC ownership consistent (single owner `postgres`), all `security_definer`, all `search_path=""`
- ✅ Portal RPC safety — no `p_supplier_id` argument
- ✅ Supplier capability mutation scope provable by pgTAP (test 023)
- ✅ Seed data consistent and verifiable by pgTAP (test 024)
- ✅ Frontend typecheck + build + route guards green
- ✅ pgTAP suite 118 / 118 across 24 files
- ✅ No new business domain code introduced
- ✅ No CC-09 work started (no RFQ / offer / contract / logistics / pricing / settlement)
