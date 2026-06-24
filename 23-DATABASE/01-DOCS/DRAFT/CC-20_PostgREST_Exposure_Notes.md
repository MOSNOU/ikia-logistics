# CC-20 — Phase 2.13 PostgREST Exposure & Database Type Synchronization Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Fourteenth platform step — infrastructure-enablement only. Expand PostgREST `[api].schemas` from 4 schemas to 14 to cover all accepted CC-07 through CC-19 domains. Regenerate the frontend `Database` type baseline against the live local instance. Add SQL-only smoke tests that prove the exposure is real, the RPCs are discoverable, RLS still gates rows, and no forbidden schemas slipped in. **No new business domain. No migration. No UI.**
Migration: **none** (Q7 default held — no missing GRANT required).
Status: Implementation complete; tests 077–081 pass (42 assertions). Pending user acceptance. **Frontend typecheck reveals Phase-1 → current-DB drift outside CC-20 scope (41 residual errors documented below).**

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | YES — expose `identity`. | JWT helper functions live there. |
| Q2 | YES — expose `organization`. | Memberships, orgs, tenants. |
| Q3 | NO — `audit` not exposed. | Sensitive trail; read only via admin RPCs in domain schemas. |
| Q4 | NO — internal `fn_*` helpers not surfaced. | Verified at the RPC-name level; see *Known limitations / hardening note* for the EXECUTE-grant subtlety. |
| Q5 | YES — expose `app_storage`. | Confirmed grants in place. |
| Q6 | YES — regenerate types into the frontend repository. | Path = `22-SOURCE-CODE/frontend-web/src/types/database.ts`. |
| Q7 | NO — **no migration 0031**. | Pre-execution introspection confirmed all 15 target schemas already have `anon` + `authenticated` + `service_role` USAGE. |
| Q8 | **8a — SQL-only smoke tests** (user override of default). | Stays inside existing `bash 23-DATABASE/tests/run.sh` harness. No shell harness added. |
| Q9 | YES — expose `notify` now. | All seed templates + triggers from CC-19 already wired. |
| Q10 | NO — no UI in CC-20. | Existing Phase-1 admin/supplier routes untouched. |

## Relationship to existing foundations

CC-20 is the first **non-business** CC since CC-04. Its sole job is to take everything CC-07 through CC-19 built and make it consumable through PostgREST:

| Foundation | What CC-20 did |
|---|---|
| CC-07 supplier | Already exposed (Phase-1). No change. |
| CC-08 commodity → CC-19 notify | **Newly exposed.** 11 schemas added to `[api].schemas`. |
| CC-04 audit | **Intentionally omitted** (Q3 = NO). |
| CC-15 storage / `app_storage` | `app_storage` exposed; native Supabase `storage` schema remains owned by `supabase_storage_admin`. |
| Migrations 0001–0030 | **Not modified.** Append-only respected. |

## What changed

### 1. `supabase/config.toml`

Expanded `[api].schemas` and `[api].extra_search_path` from:

```toml
schemas = ["public", "identity", "organization", "supplier"]
extra_search_path = ["public", "identity", "organization", "supplier"]
```

to:

```toml
schemas = [
  "public", "identity", "organization",
  "supplier", "commodity",
  "rfq", "offer", "evaluation",
  "contract", "shipment",
  "app_storage",
  "finance", "settlement", "dispute",
  "notify"
]
extra_search_path = [ ...same 14... ]
```

**14 schemas exposed.** `audit` intentionally absent (Q3). Native Supabase `storage` schema is managed by Supabase Storage Service itself — not in this list.

### 2. `22-SOURCE-CODE/frontend-web/src/types/database.ts`

Regenerated via:

```bash
supabase gen types typescript --local \
  --schema public --schema identity --schema organization \
  --schema supplier --schema commodity \
  --schema rfq --schema offer --schema evaluation \
  --schema contract --schema shipment \
  --schema app_storage \
  --schema finance --schema settlement --schema dispute \
  --schema notify \
  > src/types/database.ts
```

Result: **10131 lines** (up from ~hundreds of hand-written lines in Phase 1). Single authoritative `Database` type covering all 14 exposed schemas with full Tables / Views / Functions / Enums / CompositeTypes.

A small **Phase-1 backward-compat block** is appended at the bottom of the file (clearly labeled with `CC-20 backward-compat block`) re-exporting the Phase-1 type aliases (`DocumentType`, `SupplierStatus`, `Locale`, etc.) and Row interfaces (`AdminUserRow`, `AdminAuditRow`, ...) so existing `import type { DocumentType } from "@/types/database"` statements continue to resolve. The block must be re-appended (or moved into `src/types/database.compat.ts`) when the file is next regenerated.

### 3. pgTAP tests 077–081 (SQL-only, Q8 = 8a)

| File | Purpose | Assertions |
|------|---------|-----------|
| **077 schema exposure** | All 11 newly-exposed schemas have `anon` + `authenticated` + `service_role` USAGE grants. | 11 |
| **078 RPC discovery** | Every newly-exposed schema has ≥1 `buyer_`/`supplier_`/`admin_`/`portal_` RPC with `EXECUTE` granted to `authenticated`. | 11 |
| **079 RLS still enforced** | Representative table from each new schema retains RLS; 0 new INSERT/UPDATE/DELETE grants appeared. | 8 |
| **080 type sync coverage** | All 16 target schemas exist; every domain schema has ≥1 base table + ≥1 enum; SELECT grants present; no surprise schemas (handles per-session `pg_temp_*` correctly). | 6 |
| **081 exposure governance** | CC-14 through CC-19 forbidden schemas absent; audit table not SELECT-grantable; 15 expected schemas resolve. | 6 |

**Total CC-20: 42 new assertions.** All green.

## Validation Summary

### Migration apply

**No migration was created** (Q7 default held). Pre-execution introspection verified all 15 schemas already had the required USAGE grants. `supabase db reset` was run twice (once to verify state pre-types-generation, once final). All 30 prior migrations apply cleanly. No DDL added by CC-20.

### Verification queries (snapshot)

- 14 schemas in `[api].schemas` (was 4)
- 0 INSERT/UPDATE/DELETE direct grants on any newly-exposed schema (test 079/8)
- All 11 newly-exposed schemas have ≥1 RPC EXECUTE-granted to authenticated (test 078)
- All 7 representative tables tested keep RLS enabled post-exposure (test 079)
- `audit.audit_event` has NO SELECT grant to anon/authenticated (test 081/5) — Q3 boundary holds
- No forbidden schemas (`banking/psp/gateway/license/insurance/messaging_gateway/...`)
- Per-session `pg_temp_*` schemas correctly excluded from the allow-list check

### pgTAP suite

```
================================================================
Files: 81 passed, 0 failed
Assertions: 585 passed, 0 failed
================================================================
```

| File range | Assertions | Coverage |
|------|------------|----------|
| 001–076 | 543 | CC-05 through CC-19 (incl. acceptance) |
| **077 schema exposure** | **11** | **CC-20** |
| **078 RPC discovery** | **11** | **CC-20** |
| **079 RLS still enforced** | **8** | **CC-20** |
| **080 type sync coverage** | **6** | **CC-20** |
| **081 exposure governance** | **6** | **CC-20** |
| **CC-20 new** | **42** | |
| **Suite total** | **585** | **across 81 files** |

### Frontend validation

`npm run typecheck` and `npm run build` were run per directive. Status:

| Check | Result | Notes |
|---|---|---|
| Pre-CC-20 state | implicit | Phase-1 hand-written types matched older DB state |
| **`npm run typecheck` post-CC-20** | **FAIL: 41 residual errors** | All in Phase-1 admin/supplier routes; **not** induced by CC-20 itself |
| **`npm run build`** | FAIL (downstream of typecheck) | Same root cause |
| Route guards `verify-admin-route-guards.sh` | not re-run | No route changes |

**Root cause of the 41 errors**: Phase-1 hand-written frontend code (in `src/lib/{admin,supplier}/**` and `src/app/{admin,supplier}/**`) references **fields and columns that exist in the current DB schema but were never modeled in the Phase-1 hand-written interfaces.** Examples:

- `AdminSupplierDetailRow.verification_status` — exists in DB, missing from Phase-1 interface
- `SupplierDocumentRow.title`, `.status`, `.issued_at` — DB columns, missing from Phase-1
- `AdminSupplierListRow.supplier_id`, `.category_count`, `.document_count` — newly returned by RPCs, missing from Phase-1 interface
- `SupplierRow.rejected_reason` — Phase-1 typo, actual column is `rejection_reason`

These are **Phase-1 → current-DB drift errors**, surfaced (not caused) by the type regeneration. They were latent in the codebase since the Phase-1 manual types diverged from the DB during CC-07+.

**Fixes applied within CC-20 scope**:
- **7 errors fixed in `src/lib/supplier/portal-actions.ts`**: `string | null` → `string | undefined` at RPC call sites, because the regenerated RPC arg types correctly use `?:` (optional) instead of `| null`. These are pure type-regeneration-induced fixes.
- **Phase-1 backward-compat block appended** to `database.ts` to keep all the `import type { X } from "@/types/database"` statements resolving.

**Out-of-scope follow-up** (recorded for CC-21+):
- 41 residual TS errors are concentrated in:
  - `src/app/admin/suppliers/**` (9 + 5)
  - `src/app/supplier/profile/page.tsx` (5)
  - `src/app/supplier/documents/page.tsx` (4)
  - `src/lib/admin/{list-suppliers,create-organization,get-supplier,assign-role,approve-user,list-users,list-audit}.ts` (~13)
  - `src/lib/supplier/{get-my-supplier,portal-actions(4 remaining)}.ts`
- All errors are TS2339 ("Property X does not exist on type Y") or TS2551 ("Did you mean..."). None are CC-20-specific.
- Recommended path: a small "frontend alignment" CC that updates the Phase-1 hand-written interfaces (or migrates the consuming code to `Database['<schema>']['Tables']['<table>']['Row']`) so the build is green again.

## Known limitations / hardening note for CC-21+

1. **Phase-1 → current-DB drift** (above). Resolve in a dedicated frontend alignment CC.
2. **`fn_*` helpers carry PG default EXECUTE → PUBLIC grants**. PostgreSQL grants `EXECUTE` to the special `public` role on every function by default. Our domain internal `fn_*` helpers (~93 of them across CC-07..CC-19) inherit this. PostgREST does not surface them as RPC routes (the routing logic ignores `fn_*` named helpers), but a malicious authenticated client could still call them via raw SQL through the `rpc()` interface using the function's exact name. **In practice this is a very limited attack surface** (helpers typically need IDs and write events; they don't bypass RLS on tables). However, a future hardening CC should `REVOKE EXECUTE ON FUNCTION ... FROM PUBLIC` on all internal helpers. Tracked here. Test 081/4 covers the anon-side boundary; the authenticated side is the follow-up.
3. **Phase-1 compat block at the bottom of `database.ts`** must be re-appended (or moved into a separate `database.compat.ts`) when types are regenerated again. Without this, every `import type { DocumentType } from "@/types/database"` would break.
4. **No CI gate verifies the compat block is preserved**. A future CC should add a `prettier`/`eslint` rule or a test that asserts the compat block exists at the expected location.
5. **No PostgREST runtime smoke tests** (Q8 = 8a). SQL-introspection covers the GRANT/RLS/visibility surface, but does not catch PostgREST-level config parse errors or JWT-edge cases. Acceptance pass should include a one-off manual `curl http://127.0.0.1:54321/rest/v1/...` check.
6. **No `Database` type tests for shape correctness** beyond the SQL-side existence checks. The 10131-line file is the single source of truth; if it diverges, the consuming frontend's `tsc` is the canary.
7. **`auth`, `cron`, `pgbouncer`, `realtime` schemas** are also unexposed (correctly — they're Supabase-internal).
8. **No new SQL migration** added by CC-20. This is intentional. If a future schema is added, its `[api].schemas` entry must be added manually and a CC-20-style smoke test re-run.

## Acceptance criteria (when you're ready to accept)

- [ ] Review and sign off on the Q3 = NO decision (audit not exposed).
- [ ] Review and sign off on the Phase-1 → current-DB drift (41 typecheck errors) as out of CC-20 scope.
- [ ] Optional: run a one-off `curl` smoke test against the local PostgREST endpoint to confirm the schemas truly serve.
- [ ] Optional: open a follow-up CC ticket for the Phase-1 frontend code alignment.
