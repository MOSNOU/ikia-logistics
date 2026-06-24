# CC-03 — Phase 1 Database Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: identity, organization, audit
Migrations: `23-DATABASE/migrations/0001` through `0011`

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Credentials live only in `auth.users`. `identity.user_profiles` keys 1:1 by `auth.users.id`. | User approval, CC-03 prompt |
| 2 | Permissions are data-driven via `identity.permissions` + `identity.role_permissions`. No hard-coded grants in TS. | User approval |
| 3 | `organization.business_units` exists from Phase 1; UI integration deferred. | User approval |
| 4 | `audit` schema and audit triggers ship in Phase 1, not deferred. | User approval |
| 5 | All six organization types reserved in the enum: `buyer`, `supplier`, `carrier`, `broker`, `government`, `platform`. | User approval |
| 6 | Tenant root lives in `identity.tenants`. No `tenancy` schema. | User approval (architecture-silent) |
| 7 | RLS helpers live under `identity.*` and are schema-qualified in policies. No move to `public`. | User approval (architecture-silent) |

## Mandatory column policy

Every tenant-scoped business table carries:

```
id              uuid        primary key default gen_random_uuid()
tenant_id       uuid        not null references identity.tenants(id)
organization_id uuid        not null references organization.organizations(id)
created_by      uuid        not null references auth.users(id)
created_at      timestamptz not null default now()
updated_by      uuid                 references auth.users(id)
updated_at      timestamptz not null default now()
deleted_at      timestamptz
version         integer     not null default 1
```

`updated_at`, `updated_by`, and `version` are maintained by the trigger `identity.set_updated_at()`. The trigger attaches automatically in `0007_audit_triggers.sql` to every `identity.*` and `organization.*` table that has an `updated_at` column.

### Exemptions (documented in-line in each migration)

| Table | Exemption | Reason |
|-------|-----------|--------|
| `identity.tenants` | No `tenant_id`, no `organization_id`. `created_by` nullable. | Bootstrap row, self-references via `id`. |
| `identity.user_profiles` | `organization_id` is replaced by nullable `primary_organization_id`. `created_by` nullable. | A user can have no primary org; the first user is created at sign-up before any platform admin exists. |
| `identity.roles`, `identity.permissions`, `identity.role_permissions` | Global lookup. No tenancy columns, no audit columns beyond `created_at`/`updated_at`. | Phase 1 system seed; never tenant-scoped. |
| `identity.user_roles` | Scope captured by `scope_type` + `scope_id`. No `tenant_id` / `organization_id` columns. | Avoid redundancy with scope; RLS routes via scope_id. |
| `organization.organizations` | `organization_id` IS `id`. | Self-referential. |
| `audit.*` | `tenant_id`, `organization_id` nullable. No `created_by`/`updated_by` (use `actor_user_id`). | Append-only, immutable. |

## JWT claim shape

RLS depends on the request JWT carrying `tenant_id` and `organization_id` claims. The Supabase Auth hook (or an edge function on sign-in) must populate these from `organization.memberships` + the user's primary tenant.

Helpers in `identity.*`:

```
identity.current_user_id()         → auth.uid()
identity.current_tenant_id()       → JWT claim tenant_id
identity.current_organization_id() → JWT claim organization_id
identity.user_role_codes(uuid)     → text[]
identity.has_role(text)            → boolean
identity.is_platform_admin()       → boolean
identity.set_updated_at()          → trigger function
```

Until the auth hook is wired (a later step), `current_tenant_id()` and `current_organization_id()` return `NULL` for signed-in users — only platform admins (whose `is_platform_admin()` resolves via `user_roles` directly, not JWT) can read tenant/org tables. Document follow-up below.

## RLS policy pattern

Read:

```sql
create policy <table>_select on <schema>.<table>
  for select using (
    organization_id = identity.current_organization_id()
    or identity.is_platform_admin()
  );
```

Write:

```sql
create policy <table>_modify on <schema>.<table>
  for all
  using (
    identity.is_platform_admin()
    or (organization_id = identity.current_organization_id()
        and identity.has_role('organization_admin'))
  )
  with check (... same ...);
```

Lookup tables (`identity.roles`, `permissions`, `role_permissions`) are readable by every authenticated user and writable only by platform admins.

Audit tables are select-only via RLS; writes go through `audit.fn_audit_entity()` (security definer) or `service_role`.

## Migration order and dependencies

| File | Depends on |
|------|------------|
| 0001_extensions_and_schemas.sql | — |
| 0002_identity_tenants.sql | 0001 |
| 0003_identity_rbac.sql | 0001 |
| 0004_organization_core.sql | 0002, 0003 |
| 0005_audit_core.sql | 0002, 0004 |
| 0006_rls_helpers.sql | 0003 (reads from identity.user_roles, identity.roles) |
| 0007_audit_triggers.sql | 0002-0006 |
| 0008_rls_identity.sql | 0002, 0003, 0006 |
| 0009_rls_organization.sql | 0004, 0006 |
| 0010_rls_audit.sql | 0005, 0006 |
| 0011_seed_rbac.sql | 0003 |

## How to apply locally

Prerequisites: Docker, Supabase CLI.

```bash
# 1. Initialize a Supabase project at the repo root, if not done yet:
cd /Users/mostafanourabi/Desktop/iKIA-LOGISTICS
supabase init

# 2. Point Supabase at our migrations folder by symlinking or copying:
ln -s ../23-DATABASE/migrations supabase/migrations

# 3. Start the local stack:
supabase start

# 4. Apply migrations:
supabase db reset

# 5. (Optional) Apply the dev seed after a user exists in auth.users:
psql "$DATABASE_URL" -f 23-DATABASE/seeds/dev_tenant_org.sql

# 6. Regenerate types:
supabase gen types typescript --local \
  --schema public --schema identity --schema organization \
  > 22-SOURCE-CODE/frontend-web/src/types/database.ts
```

PostgREST must expose the `identity` and `organization` schemas. In `supabase/config.toml`:

```toml
[api]
schemas = ["public", "identity", "organization"]
extra_search_path = ["public", "identity", "organization"]
```

`audit.*` is intentionally not exposed to PostgREST (no client-side reads).

## Validation checklist

After `supabase db reset`:

```sql
\dn identity organization audit          -- 3 schemas
\dt identity.*                           -- 6 tables
\dt organization.*                       -- 3 tables
\dt audit.*                              -- 3 tables
select count(*) from identity.roles;     -- 9
select count(*) from identity.permissions; -- 21
select role_id, count(*) from identity.role_permissions group by role_id; -- one row per role
```

RLS smoke test:

```sql
set role anon;
select count(*) from identity.user_profiles;     -- 0
select count(*) from organization.organizations; -- 0
reset role;
```

Audit trigger smoke test (as service_role):

```sql
insert into identity.tenants (code, name_fa, name_en) values ('smoke', 'تست', 'Smoke');
select count(*) from audit.audit_entity
 where entity_table = 'tenants' and action = 'insert';
-- expect 1
```

## Known follow-ups (deferred from CC-03)

1. **JWT enrichment hook** — Supabase Auth hook that joins `organization.memberships` on sign-in and stamps `tenant_id` / `organization_id` into the JWT. Without this, `identity.current_tenant_id()` returns NULL for non-platform-admin users and they cannot read tenant-scoped rows.
2. **Audit trigger on `auth.users`** — Not attached. Sign-in / sign-out events should be logged to `audit.audit_event` via a Supabase Auth hook or edge function.
3. **Soft-delete enforcement** — `deleted_at` columns exist but RLS policies do not yet filter `where deleted_at is null` for reads. Decide whether to enforce at RLS or query layer.
4. **Multi-org JWT switching** — A user with memberships in multiple organizations needs a "switch organization" flow that re-mints the JWT with the new `organization_id`.
5. **Role scoping at tenant level** — `role_scope = 'tenant'` is in the enum but no policy currently distinguishes tenant-scoped roles from organization-scoped roles.
6. **`identity.permissions` audit trigger** — Skipped. Lookup table; revisit if compliance requires.
7. **pgTAP** — No DB tests; rely on the validation checklist above until pgTAP is introduced.
