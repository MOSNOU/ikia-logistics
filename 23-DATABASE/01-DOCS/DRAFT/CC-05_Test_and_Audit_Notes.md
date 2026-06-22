# CC-05 — Phase 1.7 RLS Test Suite + Auth Event Audit, Schema Notes

Version: 1.0 (DRAFT)
Scope: pgTAP install, tests schema + helpers, hook → volatile + audit, record_logout, 5 pgTAP files, runner, sign-out wiring
Migrations: `23-DATABASE/migrations/0015` (CC-05) and `0016` (helper bug fix)

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | pgTAP installed in `extensions` schema. | User approval |
| 2 | Hook recreated as `volatile`. Required to write `audit.audit_event` from inside. | User approval |
| 3 | Failed-login and sign-up tracking deferred. | User approval |
| 4 | Test runner is plain Bash + psql, no pg_prove. | User approval |
| 5 | CC-05 migration numbered `0015` (not `0014` — `0014` reserved for table grants). | User approval |
| 6 | `0016_fix_jwt_helpers.sql` added as append-only bug fix for the latent CC-03 helper bug surfaced by `tests.set_anon()`. | User approval |

## tests schema

```sql
tests.authenticate_as(user_id uuid, tenant_id uuid default null, organization_id uuid default null) returns void
tests.set_anon() returns void
```

Both helpers manipulate JWT claim GUCs via `set_config(..., true)` (transaction-local).

**Important gotcha:** neither helper changes the PostgreSQL role. The caller MUST issue `set local role authenticated` (or `anon`) themselves. Helpers only manage the JWT claim side of the channel.

`tests` schema is granted `usage` to `postgres, service_role` only. Never grant to `anon` or `authenticated` — that would expose role-impersonation primitives.

## Hook changes (CC-04 → CC-05)

| Aspect | CC-04 | CC-05 |
|--------|-------|-------|
| Volatility | `stable` | `volatile` |
| Side effects | none | INSERT one row to `audit.audit_event` |
| `action_code` | n/a | `'login'` for password / `'token_refresh'` for refresh |
| Exception handling | outer try/return event | outer try/return event, PLUS inner block around the audit INSERT so audit failure never blocks sign-in |

Grants preserved across the `drop + recreate`:

```
grant execute on function identity.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function identity.custom_access_token_hook(jsonb) from authenticated, anon, public;
```

## record_logout

```sql
identity.record_logout() returns void
  language plpgsql volatile security definer set search_path = ''
```

Reads `auth.uid()`. If no user, returns silently. Reads `user_profiles` for tenant/org. Inserts one `audit.audit_event` row with `action_code = 'logout'` and payload `{"source": "sign_out_action"}`. Granted EXECUTE to `authenticated`.

Called from `signOut` server action BEFORE `supabase.auth.signOut()`:

```ts
await supabase.schema("identity").rpc("record_logout");
await supabase.auth.signOut();
```

## CC-03 helper bug — surfaced and fixed

### Symptom

Test 001 (`anon_isolation`) failed with:

```
ERROR: invalid input syntax for type json
DETAIL: The input string ended unexpectedly.
SQL function "current_tenant_id" statement 1
```

### Root cause

The CC-03 helpers `identity.current_tenant_id()` and `identity.current_organization_id()` (migration `0006`) cast the claims GUC directly to `jsonb`:

```sql
select nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id', '')::uuid;
```

`current_setting('request.jwt.claims', true)` returns:
- **NULL** when the GUC was never set — `NULL::jsonb` is NULL — works.
- **`''`** (empty string) when the GUC has been reset via `set_config(..., NULL, true)` (custom GUCs default to empty string, not NULL) — `''::jsonb` raises `invalid input syntax for type json`.

The bug stayed latent through CC-03 and CC-04 because no code path ever explicitly reset the claims. CC-05's `tests.set_anon()` is the first caller that does, and it tripped the helper.

### Fix — `0016_fix_jwt_helpers.sql`

`nullif(...)` is applied to the GUC *before* the `::jsonb` cast. Empty-string becomes NULL — `NULL::jsonb` is NULL — `NULL ->> 'x'` is NULL — propagates safely:

```sql
select nullif(
  nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'tenant_id',
  ''
)::uuid;
```

Migration `0016` is append-only. Migrations `0001`–`0015` are unchanged. Both `identity.current_tenant_id()` and `identity.current_organization_id()` are recreated via `create or replace` with identical signatures, volatility (`stable`), `security definer`, and `set search_path = ''`.

`identity.current_user_id()` was not affected — it uses `auth.uid()`, not a jsonb cast.

## Manual validation checklist

```sql
-- 1. Helpers no longer error on reset claims.
begin;
select set_config('request.jwt.claims', null, true);
set local role anon;
select identity.current_tenant_id();         -- expect NULL, not error
select identity.current_organization_id();   -- expect NULL, not error
rollback;

-- 2. Hook produces a login audit row.
select identity.custom_access_token_hook(
  jsonb_build_object(
    'user_id', '<user-uuid>',
    'claims',  jsonb_build_object('sub','<user-uuid>','role','authenticated'),
    'authentication_method', 'password'
  )
);
select count(*) from audit.audit_event
 where actor_user_id = '<user-uuid>' and action_code = 'login';
-- expect ≥ 1

-- 3. record_logout produces a logout audit row when called as authenticated.
begin;
select tests.authenticate_as('<user-uuid>', '<tenant>', '<org>');
set local role authenticated;
select identity.record_logout();
reset role;
select count(*) from audit.audit_event
 where actor_user_id = '<user-uuid>' and action_code = 'logout';
-- expect 1
rollback;

-- 4. Full pgTAP suite (15 assertions across 5 files).
\! bash 23-DATABASE/tests/run.sh
-- expect: Files 5 passed, 0 failed / Assertions 15 passed, 0 failed
```

## Final CC-05 test result

```
=== 001_rls_anon_isolation.sql ===         4/4 PASS
=== 002_rls_tenant_isolation.sql ===       3/3 PASS
=== 003_rls_admin_and_compliance.sql ===   3/3 PASS
=== 004_jwt_hook_claims.sql ===            3/3 PASS
=== 005_audit_login_and_logout.sql ===     2/2 PASS

Files: 5 passed, 0 failed
Assertions: 15 passed, 0 failed
```

Both the production-shape checks (anon sees nothing, tenant isolation, admin escape valve, JWT enrichment) and the new audit-event writes are verified end-to-end.

## Known follow-ups (deferred from CC-05 to CC-06+)

1. **Failed-login auditing.** Requires a trigger on `auth.audit_log_entries` (Supabase-managed schema).
2. **Sign-up auditing.** Conflicts with CC-04 Locked Decision 2 (no `auth.users` insert trigger).
3. **Admin user-management UI.** Invite, approve, assign role, deactivate. Service_role provisioning is still SQL-only.
4. **Soft-delete enforcement on tables without `deleted_at`.** Out of scope — those tables (`identity.roles`, `identity.permissions`, `identity.role_permissions`, `audit.*`) shouldn't ever soft-delete.
5. **pgTAP coverage expansion.** Currently 15 assertions. Add per-domain RLS proofs as each business domain lands.
6. **CI integration.** Run `23-DATABASE/tests/run.sh` from GitHub Actions against a throwaway Supabase container.
7. **Audit retention policy.** `audit.*` will grow unbounded; need archival/rotation.
