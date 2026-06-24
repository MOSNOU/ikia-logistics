-- CC-04 / Migration 0012
-- Custom Access Token Hook: stamps tenant_id, organization_id, user_roles
-- into the JWT claims on every sign-in and token refresh.
--
-- Registered in supabase/config.toml under [auth.hook.custom_access_token].
-- Called by Supabase Auth as the supabase_auth_admin role.

create or replace function identity.custom_access_token_hook(event jsonb)
  returns jsonb
  language plpgsql
  stable
  security definer
  set search_path = ''
as $$
declare
  v_user_id  uuid;
  v_claims   jsonb;
  v_profile  record;
  v_roles    text[];
begin
  v_user_id := nullif(event ->> 'user_id', '')::uuid;
  v_claims  := coalesce(event -> 'claims', '{}'::jsonb);

  if v_user_id is null then
    return event;
  end if;

  -- Profile lookup (may be absent for unprovisioned users).
  select tenant_id, primary_organization_id
    into v_profile
    from identity.user_profiles
   where id = v_user_id
     and deleted_at is null;

  if found then
    if v_profile.tenant_id is not null then
      v_claims := jsonb_set(
        v_claims, '{tenant_id}', to_jsonb(v_profile.tenant_id::text)
      );
    end if;
    if v_profile.primary_organization_id is not null then
      v_claims := jsonb_set(
        v_claims, '{organization_id}', to_jsonb(v_profile.primary_organization_id::text)
      );
    end if;
  end if;

  -- Roles snapshot — always present (empty array if none).
  select coalesce(array_agg(distinct r.code::text), array[]::text[])
    into v_roles
    from identity.user_roles ur
    join identity.roles r on r.id = ur.role_id
   where ur.user_id = v_user_id
     and ur.revoked_at is null
     and ur.deleted_at is null;

  v_claims := jsonb_set(v_claims, '{user_roles}', to_jsonb(v_roles));

  return jsonb_set(event, '{claims}', v_claims);
exception when others then
  -- Defensive: never block sign-in due to hook failure.
  return event;
end;
$$;

comment on function identity.custom_access_token_hook(jsonb) is
  'Supabase Custom Access Token Hook. Stamps tenant_id, organization_id, user_roles into JWT claims. Idempotent on retry; never throws.';

-- Grants ---------------------------------------------------------------------
grant usage on schema identity to supabase_auth_admin;

grant select on identity.user_profiles to supabase_auth_admin;
grant select on identity.user_roles    to supabase_auth_admin;
grant select on identity.roles         to supabase_auth_admin;

grant execute on function identity.custom_access_token_hook(jsonb) to supabase_auth_admin;
revoke execute on function identity.custom_access_token_hook(jsonb) from authenticated, anon, public;
