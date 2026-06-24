-- CC-05 / Migration 0015
-- pgTAP test extension, tests schema + helpers, hook converted to volatile +
-- audit-write, and identity.record_logout().
--
-- Migration 0014 (table grants) is the reserved slot; CC-05 starts at 0015.
-- Migrations 0001-0014 are not modified.

-- 1. pgTAP -------------------------------------------------------------------
create extension if not exists pgtap with schema extensions;

-- 2. tests schema and helpers -----------------------------------------------
create schema if not exists tests;

-- Helpers are usable only by privileged roles. Do NOT grant to anon or
-- authenticated — exposing role-impersonation helpers to clients would leak
-- the JWT-claim escape hatch.
grant usage on schema tests to postgres, service_role;

-- Sets request.jwt.claims and request.jwt.claim.sub for the current
-- transaction. Does NOT switch the PostgreSQL role — the caller must
-- `set local role authenticated` (or other) themselves.
create or replace function tests.authenticate_as(
  p_user_id          uuid,
  p_tenant_id        uuid default null,
  p_organization_id  uuid default null
) returns void
language plpgsql
as $$
declare
  v_claims jsonb;
begin
  v_claims := jsonb_build_object(
    'sub',  p_user_id::text,
    'role', 'authenticated'
  );
  if p_tenant_id is not null then
    v_claims := jsonb_set(v_claims, '{tenant_id}', to_jsonb(p_tenant_id::text));
  end if;
  if p_organization_id is not null then
    v_claims := jsonb_set(v_claims, '{organization_id}', to_jsonb(p_organization_id::text));
  end if;
  perform set_config('request.jwt.claims',    v_claims::text,        true);
  perform set_config('request.jwt.claim.sub', p_user_id::text,       true);
end;
$$;

comment on function tests.authenticate_as(uuid, uuid, uuid) is
  'Test helper: set JWT claims for current transaction. Caller still must SET LOCAL ROLE authenticated.';

create or replace function tests.set_anon() returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims',    null, true);
  perform set_config('request.jwt.claim.sub', null, true);
end;
$$;

comment on function tests.set_anon() is
  'Test helper: clear JWT claims. Caller still must SET LOCAL ROLE anon.';

-- 3. Hook → volatile + audit write -----------------------------------------
-- CC-04's hook was stable (no side effects). To write an audit row per
-- invocation we make it volatile. Audit failures are swallowed by a nested
-- exception block so sign-in is never blocked.

drop function if exists identity.custom_access_token_hook(jsonb);

create function identity.custom_access_token_hook(event jsonb)
  returns jsonb
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_user_id  uuid;
  v_claims   jsonb;
  v_profile  record;
  v_roles    text[];
  v_method   text;
  v_action   text;
begin
  v_user_id := nullif(event ->> 'user_id', '')::uuid;
  v_claims  := coalesce(event -> 'claims', '{}'::jsonb);
  v_method  := coalesce(event ->> 'authentication_method', 'unknown');

  if v_user_id is null then
    return event;
  end if;

  select tenant_id, primary_organization_id
    into v_profile
    from identity.user_profiles
   where id = v_user_id and deleted_at is null;

  if found then
    if v_profile.tenant_id is not null then
      v_claims := jsonb_set(v_claims, '{tenant_id}', to_jsonb(v_profile.tenant_id::text));
    end if;
    if v_profile.primary_organization_id is not null then
      v_claims := jsonb_set(v_claims, '{organization_id}', to_jsonb(v_profile.primary_organization_id::text));
    end if;
  end if;

  select coalesce(array_agg(distinct r.code::text), array[]::text[])
    into v_roles
    from identity.user_roles ur
    join identity.roles r on r.id = ur.role_id
   where ur.user_id = v_user_id
     and ur.revoked_at is null
     and ur.deleted_at is null;

  v_claims := jsonb_set(v_claims, '{user_roles}', to_jsonb(v_roles));

  -- Audit. Nested block so audit failures never block sign-in.
  begin
    v_action := case when v_method = 'token_refresh' then 'token_refresh' else 'login' end;
    insert into audit.audit_event (
      tenant_id, organization_id, actor_user_id, action_code,
      payload, occurred_at
    ) values (
      v_profile.tenant_id,
      v_profile.primary_organization_id,
      v_user_id,
      v_action,
      jsonb_build_object('authentication_method', v_method),
      now()
    );
  exception when others then
    null;
  end;

  return jsonb_set(event, '{claims}', v_claims);
exception when others then
  return event;
end;
$$;

comment on function identity.custom_access_token_hook(jsonb) is
  'Volatile: stamps JWT claims AND writes login/token_refresh event to audit.audit_event. Never throws — sign-in must not fail because of the hook.';

-- Re-apply grants (the DROP cleared them).
grant execute on function identity.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function identity.custom_access_token_hook(jsonb) from authenticated, anon, public;

-- 4. identity.record_logout() ----------------------------------------------
create or replace function identity.record_logout()
  returns void
  language plpgsql
  volatile
  security definer
  set search_path = ''
as $$
declare
  v_user_id uuid;
  v_profile record;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    return;
  end if;

  select tenant_id, primary_organization_id
    into v_profile
    from identity.user_profiles
   where id = v_user_id and deleted_at is null;

  begin
    insert into audit.audit_event (
      tenant_id, organization_id, actor_user_id, action_code,
      payload, occurred_at
    ) values (
      v_profile.tenant_id,
      v_profile.primary_organization_id,
      v_user_id,
      'logout',
      jsonb_build_object('source', 'sign_out_action'),
      now()
    );
  exception when others then
    null;
  end;
end;
$$;

comment on function identity.record_logout() is
  'Called from the sign-out server action. Writes a logout event for the current authenticated user. Never throws.';

grant execute on function identity.record_logout() to authenticated;
