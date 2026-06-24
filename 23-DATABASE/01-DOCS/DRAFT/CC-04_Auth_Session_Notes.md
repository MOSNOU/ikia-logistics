# CC-04 — Phase 1.5 Auth Session Hardening, Schema Notes

Version: 1.0 (DRAFT)
Scope: JWT enrichment, soft-delete RLS, welcome/profile pages, org switching
Migrations: `23-DATABASE/migrations/0012` and `0013`

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Hook at `identity.custom_access_token_hook`. Grants to `supabase_auth_admin` only. | User approval |
| 2 | No `auth.users` insert trigger. Users without profiles are routed to `/welcome`. | User approval |
| 3 | Active organization = `identity.user_profiles.primary_organization_id`. No separate `active_organization_id`. | User approval |
| 4 | pgTAP and auth-event mirroring deferred to CC-05. | User approval |
| 5 | Soft-delete enforced at RLS via `deleted_at is null` on every CC-03 select policy. Parallel `*_select_deleted` policies grant access to `platform_admin` and `compliance_officer`. | CC-04 spec |

## JWT claims shape (after CC-04)

```json
{
  "sub":             "<auth.users.id>",
  "email":           "<auth.users.email>",
  "role":            "authenticated",
  "tenant_id":       "<identity.user_profiles.tenant_id>",       // omitted if no profile
  "organization_id": "<identity.user_profiles.primary_organization_id>", // omitted if null
  "user_roles":      ["platform_admin", "buyer_admin", ...]      // always present, may be []
}
```

Helpers from CC-03 read these without change:

- `identity.current_tenant_id()` → JWT `tenant_id` (NULL if missing)
- `identity.current_organization_id()` → JWT `organization_id` (NULL if missing)
- `identity.has_role(code)` → reads `identity.user_roles` directly, **not** the JWT (defense in depth)

## Hook function contract

Event payload from Supabase Auth:

```json
{
  "user_id":               "<uuid>",
  "claims":                { "sub": "...", "email": "...", "role": "authenticated", ... },
  "authentication_method": "password" | "token_refresh" | "..."
}
```

The hook returns the same payload with a mutated `claims` object. Any internal error is caught — the function returns the input event unmodified, so sign-in never fails because of the hook.

## Soft-delete RLS

Each affected table now has two select policies:

| Table | Active policy | Deleted policy |
|-------|---------------|----------------|
| `identity.tenants` | `tenants_select` (deleted_at IS NULL) | `tenants_select_deleted` (admin or compliance) |
| `identity.user_profiles` | `user_profiles_select` | `user_profiles_select_deleted` |
| `identity.user_roles` | `user_roles_select` | `user_roles_select_deleted` |
| `organization.organizations` | `organizations_select` | `organizations_select_deleted` |
| `organization.business_units` | `business_units_select` | `business_units_select_deleted` |
| `organization.memberships` | `memberships_select` | `memberships_select_deleted` |

Tables without `deleted_at` (`identity.roles`, `identity.permissions`, `identity.role_permissions`, `audit.*`) are not touched.

## Switch-organization design

1. User picks a target org from the switcher (only rendered when `memberships.length >= 2`).
2. Server action verifies the user is an active member of the target org (anti-forgery).
3. Server action updates `identity.user_profiles.primary_organization_id`.
4. Server action calls `supabase.auth.refreshSession()` — Supabase re-invokes the hook, which re-reads `primary_organization_id` and writes the new `organization_id` into the JWT.
5. Server action `revalidatePath("/", "layout")` and `redirect("/dashboard")`.

Why no separate `active_organization_id`: a user's "active" and "default" are the same in Phase 1.5. Splitting them creates two truths that drift. If product later needs separation, add `active_organization_id` then.

## /welcome routing

Middleware redirects authenticated users to `/welcome` when:

- `user_profiles` row is missing, OR
- `primary_organization_id` is NULL

Bypassed paths (no redirect):

```
/ /login /welcome /unauthorized /api/* /_next/*
```

`/dashboard`, `/admin/*`, `/buyer/*`, `/supplier/*`, `/carrier/*`, `/profile` all trigger the redirect.

## Supabase config

`supabase/config.toml` (created by CC-04) registers:

```toml
[api]
schemas = ["public", "identity", "organization"]
extra_search_path = ["public", "identity", "organization"]

[auth.hook.custom_access_token]
enabled = true
uri = "pg-functions://postgres/identity/custom_access_token_hook"
```

The file also sets `enable_signup = true`, `enable_refresh_token_rotation = true`, and other Supabase defaults. Merge with anything `supabase init` may have created.

## Manual validation checklist

```sql
-- 1. Hook exists, grant intact, no public execute.
\df identity.custom_access_token_hook
select has_function_privilege('supabase_auth_admin',
  'identity.custom_access_token_hook(jsonb)', 'execute');             -- t
select has_function_privilege('authenticated',
  'identity.custom_access_token_hook(jsonb)', 'execute');             -- f

-- 2. Hook smoke test for the seeded dev admin.
select identity.custom_access_token_hook(
  jsonb_build_object(
    'user_id', (select id from auth.users order by created_at limit 1),
    'claims',  jsonb_build_object('role', 'authenticated')
  )
);
-- expect claims.user_roles to include 'platform_admin'
-- expect claims.tenant_id and claims.organization_id present after dev seed.

-- 3. Soft-delete RLS rewritten.
select policyname, cmd
  from pg_policies
 where schemaname in ('identity', 'organization')
   and policyname like '%_select%'
 order by 1;
-- expect *_select and *_select_deleted pairs on 6 tables.

-- 4. Active-org switch.
update identity.user_profiles set primary_organization_id = '<other-org-uuid>'
 where id = '<user-uuid>';
-- after the next refreshSession, JWT.organization_id reflects the new value.
```

## Known follow-ups (deferred from CC-04)

1. **pgTAP RLS test suite** — CC-05.
2. **Auth event mirroring to `audit.audit_event`** — CC-05.
3. **Admin user-management UI** — invite, approve, assign role, deactivate.
4. **Email-domain-to-tenant mapping or invitation token flow** so sign-up creates a profile shell automatically.
5. **`primary_organization_id` defaulting** — the hook does not pick "first active membership" when `primary_organization_id` is NULL; we keep users on `/welcome` instead.
6. **Profile editing** — `/profile` is read-only in CC-04.
7. **Role-scope precision** — `role_scope = 'tenant'` is allowed by the enum but not yet enforced by any policy.
