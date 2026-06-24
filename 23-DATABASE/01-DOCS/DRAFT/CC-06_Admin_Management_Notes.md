# CC-06 — Phase 1.8 Admin User Management, Schema Notes

Version: 1.2 (DRAFT — security acceptance addendum)
Scope: 8 SECURITY DEFINER admin RPCs + UI + tests + security acceptance checks
Migration: `23-DATABASE/migrations/0017_admin_management.sql` (no migration changes from v1.1)
Acceptance status: **FULLY ACCEPTED** — see Security Acceptance Addendum at end.

## Locked decisions (final, after v1.1 corrections)

| # | Decision | Source |
|---|----------|--------|
| 1 | All administrative mutations via SECURITY DEFINER RPCs. No new INSERT/UPDATE grants on `organization.organizations`, `organization.memberships`, `identity.user_roles`, or `identity.user_profiles`. | User approval |
| 2 | Admin RPCs live in `identity.*`. | User approval |
| 3 | `auth.users` reads via `identity.admin_list_users()` / `admin_get_user()` only. PostgREST does not expose the `auth` schema. | User approval |
| 4 | `audit.*` reads via `identity.admin_list_audit_events()` only. PostgREST does not expose `audit`. | User approval |
| 5 | `admin_list_audit_events`: `platform_admin` sees all; `compliance_officer` sees only `tenant_id = current_tenant_id()`. Silent zero rows if JWT carries no tenant. | User approval |
| 6 | Defense in depth: UI `requireRole(PLATFORM_ADMIN)` + RPC `is_platform_admin()` + RLS backstop. | User approval |
| 7 | `admin_approve_user` is idempotent: pre-checks `user_roles` before INSERT (does not rely on duplicate-failure). | User approval |
| 8 | `admin_get_user(uuid)` added for clean detail-page semantics. Total RPCs: **8**. | User approval |
| 9 | Tenant CRUD remains OUT of scope. Read-only tenant lookup only. | User approval |
| 10 | Native HTML `<select>` for dropdowns. No new shadcn/Radix dependencies. | v1.0 approved |
| 11 | Migration 0017 is the only CC-06 migration. Append-only. | User approval |

## The 8 admin RPCs

| Function | Volatility | Reads from | Writes to | Authorization |
|----------|------------|-----------|-----------|---------------|
| `identity.admin_list_users(int, int, text)` | stable | `auth.users`, `identity.user_profiles` | — | `is_platform_admin()` |
| `identity.admin_get_user(uuid)` | stable | `auth.users`, `identity.user_profiles` | — | `is_platform_admin()` |
| `identity.admin_list_audit_events(int, int, timestamptz)` | stable | `audit.audit_event` | — | `is_platform_admin()` OR `has_role('compliance_officer')` (tenant-scoped) |
| `identity.admin_create_organization(...)` | volatile | — | `organization.organizations` | `is_platform_admin()` |
| `identity.admin_add_membership(uuid, uuid, text)` | volatile | `organization.organizations`, `identity.roles` | `organization.memberships` | `is_platform_admin()` |
| `identity.admin_approve_user(uuid, uuid, uuid, text, text, locale)` | volatile | `identity.roles`, `identity.user_roles` | `identity.user_profiles`, `organization.memberships`, `identity.user_roles` | `is_platform_admin()` |
| `identity.admin_set_user_status(uuid, identity.user_status)` | volatile | — | `identity.user_profiles` | `is_platform_admin()` |
| `identity.admin_assign_role(uuid, text, identity.role_scope, uuid)` | volatile | `identity.roles` | `identity.user_roles` | `is_platform_admin()` |

All `set search_path = ''`, all schema-qualified, all `security definer`. Failure mode for unauthorized callers: `RAISE EXCEPTION ... USING ERRCODE = '42501'`.

## Idempotency of `admin_approve_user`

```sql
if not exists (
  select 1 from identity.user_roles
   where user_id    = p_user_id
     and role_id    = v_role_id
     and scope_type = 'organization'
     and scope_id   = p_organization_id
     and revoked_at is null
     and deleted_at is null
) then
  insert into identity.user_roles (...) values (...);
end if;
```

The `user_profiles` insert uses `ON CONFLICT (id) DO UPDATE`; the `memberships` insert uses `ON CONFLICT (organization_id, user_id, role_id) DO NOTHING`. Re-calling the RPC for the same `(user, tenant, org, role)` tuple is a no-op (idempotent), not a duplicate-key failure.

## `admin_list_audit_events` scoping rule

```sql
where (p_since is null or e.occurred_at >= p_since)
  and (
    v_is_admin
    or (v_is_compliance and e.tenant_id = v_tenant)
  )
```

If a `compliance_officer` signs in without a tenant claim in their JWT (no profile yet, or `primary_organization_id` NULL), `v_tenant` is NULL and the WHERE clause matches **zero rows**. Silent zero — no exception, no JWT-shape leak to the UI.

## Grants matrix — unchanged from post-0014

Migration 0017 adds **no new table grants.** Only `EXECUTE` on the 8 RPCs to `authenticated`. The post-0017 grant matrix on the 4 admin-controlled tables remains:

| Schema.Table | anon | authenticated |
|--------------|------|---------------|
| identity.user_profiles | SELECT | SELECT, UPDATE *(0014 — self switchOrganization)* |
| identity.user_roles | SELECT | SELECT |
| organization.organizations | SELECT | SELECT |
| organization.memberships | SELECT | SELECT |
| audit.* | — | — |

`UPDATE on identity.user_profiles` from migration 0014 is the **only** non-administrative direct grant. It serves the user-self-service `switchOrganization` flow from CC-04; never used by admin code paths.

## RLS implications

- No new RLS policies in 0017.
- SECURITY DEFINER bypasses RLS by design; the function's internal role check is the load-bearing authorization layer.
- Existing CC-03/CC-04 `*_admin_modify` policies remain in place as a backstop for any future code path that doesn't use the RPCs.
- `compliance_officer` row scoping for audit reads happens **inside the RPC's WHERE clause**, not via RLS. Single source of truth.

## Frontend pages

```
/admin/users
/admin/users/[userId]
/admin/organizations
/admin/organizations/new
/admin/organizations/[orgId]
/admin/organizations/[orgId]/members/new
/admin/audit
```

All under the existing `requireRole(PLATFORM_ADMIN)` gate from CC-04. Pages are server components; forms are client components that call server actions; server actions invoke the RPCs.

## pgTAP suite total after CC-06

| File | Assertions |
|------|------------|
| 001_rls_anon_isolation.sql | 4 |
| 002_rls_tenant_isolation.sql | 3 |
| 003_rls_admin_and_compliance.sql | 3 |
| 004_jwt_hook_claims.sql | 3 |
| 005_audit_login_and_logout.sql | 2 |
| 006_admin_function_guards.sql | 8 |
| 007_admin_approve_user.sql | 4 |
| 008_admin_create_organization.sql | 1 |
| 009_admin_add_membership.sql | 1 |
| 010_admin_audit_visibility.sql | 2 |
| **Total** | **31 across 10 files** |

## Defect surfaced during CC-06 testing

Test 008 v1 used a side-effect-bearing function call inside a `WHERE` clause:

```sql
select tenant_id from organization.organizations
 where id = identity.admin_create_organization(...);
```

When the table is empty (fresh test transaction), the sequential scan produces zero rows, and the function is never called — the INSERT never fires, the subquery returns NULL. Fix: call the RPC in a separate statement, then assert by looking up the row via its unique `code`.

## Manual validation checklist

```sql
-- 1. 8 admin functions exist.
\df identity.admin_*

-- 2. EXECUTE granted to authenticated, not to anon.
select routine_name, grantee
  from information_schema.routine_privileges
 where specific_schema='identity' and routine_name like 'admin_%'
   and grantee in ('anon','authenticated')
 order by 1,2;
-- expect 8 rows, all grantee=authenticated.

-- 3. Grants matrix on admin-controlled tables unchanged from post-0014.
select table_name, grantee,
       string_agg(privilege_type,',' order by privilege_type) as p
  from information_schema.role_table_grants
 where table_schema in ('identity','organization')
   and grantee in ('anon','authenticated')
   and table_name in ('user_profiles','user_roles','organizations','memberships')
 group by 1,2 order by 1,2;

-- 4. Audit table grants are still empty.
select count(*) from information_schema.role_table_grants
 where table_schema='audit' and grantee in ('anon','authenticated');
-- expect 0.

-- 5. End-to-end: pgTAP suite green.
\! bash 23-DATABASE/tests/run.sh
-- expect Files 10 passed / Assertions 31 passed.
```

## Known follow-ups (deferred from CC-06)

1. **Revocation flows** — member removal, role revocation, soft-delete UI. Companion RPCs: `admin_revoke_membership`, `admin_revoke_role`, `admin_soft_delete_user`.
2. **Editing organization metadata** — name, legal name, tax id, registration number after creation.
3. **Tenant CRUD** — admin tenant creation, soft-delete, suspension.
4. **Bulk operations** — mass approve, bulk role assignment.
5. **Email invitations + sign-up flows** — invite token RPC, email integration.
6. **Audit drilldown** — single-event detail view, payload inspection.
7. **Failed-login auditing** — from `auth.audit_log_entries`.
8. **Role-permission management UI** — currently `role_permissions` is seed-only.
9. **Pagination by cursor** instead of LIMIT/OFFSET as the table grows.
10. **Admin user search** — by email / full_name / org / tenant.

---

# Security Acceptance Addendum (v1.2)

Performed after CC-06 was provisionally accepted, before any CC-07 work began. No migration changes; only verification + two new pgTAP test files + a frontend route-guard script.

## 1. RPC ownership verification — ✅ PASS

Query:

```sql
select n.nspname, p.proname, pg_get_userbyid(p.proowner) as owner,
       p.prosecdef as security_definer, p.provolatile
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'identity' and p.proname like 'admin_%'
 order by p.proname;
```

Result:

| function | owner | security_definer | volatility |
|----------|-------|------------------|------------|
| admin_add_membership | postgres | t | volatile |
| admin_approve_user | postgres | t | volatile |
| admin_assign_role | postgres | t | volatile |
| admin_create_organization | postgres | t | volatile |
| admin_get_user | postgres | t | stable |
| admin_list_audit_events | postgres | t | stable |
| admin_list_users | postgres | t | stable |
| admin_set_user_status | postgres | t | volatile |

- 8 functions present ✅
- All `security_definer = true` ✅
- 3 stable (`admin_list_users`, `admin_get_user`, `admin_list_audit_events`) match the read intent ✅
- 5 volatile (writes) match the mutation intent ✅
- Single consistent owner (`postgres` — one distinct value) ✅
- Owner is appropriate: `postgres` is the migration-execution role and has the cross-schema privileges (`auth.users` read, `audit.audit_event` insert, `organization.*` write, `identity.*` write) the RPCs require. A future hardening pass may introduce a dedicated `app_admin_definer` role with a narrower grant set; this is acceptable for Phase 1.

## 2. `auth.users` non-exposure — ✅ PASS

Test file: `23-DATABASE/tests/011_auth_schema_not_exposed.sql`. 2 assertions.

```
ok 1 - anon cannot SELECT from auth.users
ok 2 - authenticated cannot SELECT from auth.users
```

Both produce SQLSTATE `42501` (`insufficient_privilege`). The only sanctioned read path remains `identity.admin_list_users()` / `identity.admin_get_user()`.

## 3. `audit.*` non-exposure — ✅ PASS

Test file: `23-DATABASE/tests/012_audit_schema_not_exposed.sql`. 4 assertions.

```
ok 1 - anon cannot SELECT from audit.audit_event
ok 2 - authenticated cannot SELECT from audit.audit_event
ok 3 - authenticated cannot SELECT from audit.audit_entity
ok 4 - authenticated cannot SELECT from audit.audit_access
```

All produce SQLSTATE `42501`. The only sanctioned read path remains `identity.admin_list_audit_events()`, which itself enforces `is_platform_admin()` OR `has_role('compliance_officer')` (tenant-scoped).

## 4. Admin route authorization — ✅ PASS

Playwright is not a direct dependency of `frontend-web` (only a transitive reference in `package-lock.json`). Per the user's instruction, a lightweight bash verification script was added instead of installing a heavy browser-test dependency.

Script: `22-SOURCE-CODE/frontend-web/scripts/verify-admin-route-guards.sh`.

Output:

```
=== CC-06 admin route-guard verification ===
OK:   src/app/admin/layout.tsx exists
OK:   admin layout calls requireRole(ROLES.PLATFORM_ADMIN)
OK:   no nested layout.tsx under src/app/admin/
OK:   /admin/users/page.tsx exists
OK:   /admin/organizations/page.tsx exists
OK:   /admin/audit/page.tsx exists

VERIFICATION PASSED
```

The script proves:

1. `src/app/admin/layout.tsx` exists.
2. The layout source contains `requireRole(ROLES.PLATFORM_ADMIN)`.
3. **No nested `layout.tsx`** exists under `src/app/admin/*` — important because a child layout that doesn't re-call `requireRole(...)` would still inherit the parent's gate (Next.js behavior), but a child layout that overrides client/server boundaries could mask intent. Forbidding any nested layout file removes that risk surface.
4. The required CC-06 pages exist: `/admin/users`, `/admin/organizations`, `/admin/audit`.

Runtime defense in depth remains intact:

- UI layer: `requireRole(ROLES.PLATFORM_ADMIN)` redirects non-admins to `/unauthorized`.
- RPC layer: every admin function raises `42501` for non-`platform_admin` callers (proved by test `006_admin_function_guards.sql`).
- RLS layer: `*_admin_modify` policies remain on all four tables as a backstop.

## 5. Suite totals after security acceptance pass

| Metric | Pre-acceptance (CC-06 v1.1) | Post-acceptance (CC-06 v1.2) |
|--------|------------------------------|------------------------------|
| pgTAP files | 10 | **12** |
| pgTAP assertions | 31 | **37** |
| Migrations | 17 | 17 (unchanged) |
| Frontend typecheck | ✅ | ✅ |
| Frontend build | ✅ | ✅ |

## 6. Final status

**CC-06 is FULLY ACCEPTED.**

All four security verification requirements from the acceptance brief pass:

- RPC ownership is consistent and appropriate.
- `auth.users` is not exposed to `anon` or `authenticated`.
- All three `audit.*` tables are not exposed to `anon` or `authenticated`.
- Admin routes are gated by `requireRole(ROLES.PLATFORM_ADMIN)` with no nested layout bypass.
- pgTAP suite: 37/37 across 12 files.
- Frontend build green.
- No new business domain code introduced.
- No CC-07 work started.
