-- CC-03 / Migration 0006
-- JWT-claim helpers and shared trigger functions.
-- All helpers live in identity.* and are schema-qualified in policies.

create or replace function identity.current_user_id()
  returns uuid
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select auth.uid();
$$;

comment on function identity.current_user_id() is
  'Wraps auth.uid() for centralized access from RLS policies.';

create or replace function identity.current_tenant_id()
  returns uuid
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'tenant_id', '')::uuid;
$$;

comment on function identity.current_tenant_id() is
  'Extracts tenant_id from the request JWT. Returns NULL when no JWT or claim missing.';

create or replace function identity.current_organization_id()
  returns uuid
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'organization_id', '')::uuid;
$$;

comment on function identity.current_organization_id() is
  'Extracts active organization_id from the request JWT. Set per-session at sign-in.';

create or replace function identity.user_role_codes(p_user_id uuid)
  returns text[]
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select coalesce(array_agg(distinct r.code::text), array[]::text[])
    from identity.user_roles ur
    join identity.roles r on r.id = ur.role_id
   where ur.user_id = p_user_id
     and ur.revoked_at is null
     and ur.deleted_at is null;
$$;

create or replace function identity.has_role(p_code text)
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select p_code = any(identity.user_role_codes(identity.current_user_id()));
$$;

create or replace function identity.is_platform_admin()
  returns boolean
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select identity.has_role('platform_admin');
$$;

-- Shared updated_at + version trigger.
create or replace function identity.set_updated_at()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
begin
  new.updated_at := now();
  if new.updated_by is null then
    new.updated_by := identity.current_user_id();
  end if;
  if tg_op = 'UPDATE' and new.version = old.version then
    new.version := old.version + 1;
  end if;
  return new;
end;
$$;

comment on function identity.set_updated_at() is
  'Maintains updated_at, updated_by and version on every UPDATE.';
