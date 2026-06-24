-- CC-06 / Migration 0017 — Admin User Management
-- 8 SECURITY DEFINER RPCs under identity.* for admin reads + writes.
-- No table-level grants are added. Administrative mutations flow exclusively
-- through these functions. Defense in depth:
--   1. UI route: requireRole(PLATFORM_ADMIN)
--   2. RPC: internal identity.is_platform_admin() check (or compliance variant)
--   3. RLS: still in place as the final backstop for any non-RPC path
--
-- Migrations 0001-0016 are not modified.

-- =====================================================================
-- 1. identity.admin_list_users  (read)
-- =====================================================================
create or replace function identity.admin_list_users(
  p_limit         int  default 25,
  p_offset        int  default 0,
  p_status_filter text default null
)
returns table (
  user_id                 uuid,
  email                   text,
  email_created_at        timestamptz,
  full_name               text,
  tenant_id               uuid,
  primary_organization_id uuid,
  status                  text,
  has_profile             boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_users: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select u.id,
           u.email::text,
           u.created_at,
           p.full_name,
           p.tenant_id,
           p.primary_organization_id,
           coalesce(p.status::text, 'pending_profile'),
           p.id is not null
      from auth.users u
      left join identity.user_profiles p
        on p.id = u.id and p.deleted_at is null
     where p_status_filter is null
        or coalesce(p.status::text, 'pending_profile') = p_status_filter
     order by u.created_at desc
     limit p_limit offset p_offset;
end;
$$;

comment on function identity.admin_list_users(int, int, text) is
  'Admin-only. Returns auth.users joined with identity.user_profiles. status="pending_profile" for users without a profile.';

-- =====================================================================
-- 2. identity.admin_get_user  (read, single row)
-- =====================================================================
create or replace function identity.admin_get_user(p_user_id uuid)
returns table (
  user_id                 uuid,
  email                   text,
  email_created_at        timestamptz,
  full_name               text,
  tenant_id               uuid,
  primary_organization_id uuid,
  status                  text,
  has_profile             boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_user: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select u.id,
           u.email::text,
           u.created_at,
           p.full_name,
           p.tenant_id,
           p.primary_organization_id,
           coalesce(p.status::text, 'pending_profile'),
           p.id is not null
      from auth.users u
      left join identity.user_profiles p
        on p.id = u.id and p.deleted_at is null
     where u.id = p_user_id;
end;
$$;

comment on function identity.admin_get_user(uuid) is
  'Admin-only. Single-row variant of admin_list_users for the user-detail page.';

-- =====================================================================
-- 3. identity.admin_list_audit_events  (read, scope-filtered)
--    platform_admin    → all rows
--    compliance_officer → only rows where tenant_id = JWT tenant_id
--                         (silent zero rows if JWT has no tenant_id)
-- =====================================================================
create or replace function identity.admin_list_audit_events(
  p_limit  int         default 50,
  p_offset int         default 0,
  p_since  timestamptz default null
)
returns table (
  id              uuid,
  occurred_at     timestamptz,
  action_code     text,
  actor_user_id   uuid,
  tenant_id       uuid,
  organization_id uuid,
  resource_type   text,
  resource_id     uuid,
  ip_address      inet,
  payload         jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_is_admin      boolean := identity.is_platform_admin();
  v_is_compliance boolean := identity.has_role('compliance_officer');
  v_tenant        uuid    := identity.current_tenant_id();
begin
  if not (v_is_admin or v_is_compliance) then
    raise exception 'admin_list_audit_events: requires platform_admin or compliance_officer'
      using errcode = '42501';
  end if;
  return query
    select e.id, e.occurred_at, e.action_code, e.actor_user_id, e.tenant_id,
           e.organization_id, e.resource_type, e.resource_id, e.ip_address, e.payload
      from audit.audit_event e
     where (p_since is null or e.occurred_at >= p_since)
       and (
         v_is_admin
         or (v_is_compliance and e.tenant_id = v_tenant)
       )
     order by e.occurred_at desc
     limit p_limit offset p_offset;
end;
$$;

comment on function identity.admin_list_audit_events(int, int, timestamptz) is
  'platform_admin sees all tenants. compliance_officer sees only their JWT tenant; silent zero rows if JWT has no tenant_id.';

-- =====================================================================
-- 4. identity.admin_create_organization  (write)
-- =====================================================================
create or replace function identity.admin_create_organization(
  p_tenant_id           uuid,
  p_code                text,
  p_name_fa             text,
  p_name_en             text,
  p_type                organization.organization_type,
  p_status              organization.organization_status default 'pending',
  p_country_code        char(2)                          default 'IR',
  p_legal_name          text                             default null,
  p_registration_number text                             default null,
  p_tax_id              text                             default null
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_id    uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_create_organization: requires platform_admin' using errcode = '42501';
  end if;
  insert into organization.organizations (
    tenant_id, code, name_fa, name_en, type, status, country_code,
    legal_name, registration_number, tax_id, created_by, updated_by
  ) values (
    p_tenant_id, p_code, p_name_fa, p_name_en, p_type, p_status, p_country_code,
    p_legal_name, p_registration_number, p_tax_id, v_actor, v_actor
  )
  returning id into v_id;
  return v_id;
end;
$$;

comment on function identity.admin_create_organization(
  uuid, text, text, text,
  organization.organization_type,
  organization.organization_status,
  char, text, text, text
) is 'Admin-only. INSERT into organization.organizations. Returns new id.';

-- =====================================================================
-- 5. identity.admin_add_membership  (write)
--    Tenant_id is derived from the organization, not the caller.
-- =====================================================================
create or replace function identity.admin_add_membership(
  p_organization_id uuid,
  p_user_id         uuid,
  p_role_code       text
)
returns uuid
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor   uuid := auth.uid();
  v_role_id uuid;
  v_tenant  uuid;
  v_id      uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_add_membership: requires platform_admin' using errcode = '42501';
  end if;
  select id into v_role_id from identity.roles where code = p_role_code;
  if v_role_id is null then
    raise exception 'admin_add_membership: unknown role %', p_role_code using errcode = '22023';
  end if;
  select tenant_id into v_tenant
    from organization.organizations
   where id = p_organization_id;
  if v_tenant is null then
    raise exception 'admin_add_membership: organization not found' using errcode = 'P0002';
  end if;
  insert into organization.memberships (
    tenant_id, organization_id, user_id, role_id, status, joined_at,
    created_by, updated_by
  ) values (
    v_tenant, p_organization_id, p_user_id, v_role_id, 'active', now(),
    v_actor, v_actor
  )
  returning id into v_id;
  return v_id;
end;
$$;

comment on function identity.admin_add_membership(uuid, uuid, text) is
  'Admin-only. INSERT into organization.memberships. tenant_id derived from organization.';

-- =====================================================================
-- 6. identity.admin_approve_user  (write, idempotent)
--    Idempotent across repeated calls: pre-checks user_roles by (user_id,
--    role_id, scope_type='organization', scope_id, revoked_at is null,
--    deleted_at is null) and skips the insert when an equivalent active
--    assignment already exists.
-- =====================================================================
create or replace function identity.admin_approve_user(
  p_user_id         uuid,
  p_tenant_id       uuid,
  p_organization_id uuid,
  p_role_code       text,
  p_full_name       text             default null,
  p_locale          identity.locale  default 'fa'
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor   uuid := auth.uid();
  v_role_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_approve_user: requires platform_admin' using errcode = '42501';
  end if;
  select id into v_role_id from identity.roles where code = p_role_code;
  if v_role_id is null then
    raise exception 'admin_approve_user: unknown role %', p_role_code using errcode = '22023';
  end if;

  insert into identity.user_profiles (
    id, tenant_id, primary_organization_id, full_name, locale, status,
    created_by, updated_by
  ) values (
    p_user_id, p_tenant_id, p_organization_id, p_full_name, p_locale, 'active',
    v_actor, v_actor
  )
  on conflict (id) do update set
    tenant_id               = excluded.tenant_id,
    primary_organization_id = excluded.primary_organization_id,
    full_name               = coalesce(excluded.full_name, identity.user_profiles.full_name),
    locale                  = excluded.locale,
    status                  = 'active',
    updated_by              = v_actor;

  insert into organization.memberships (
    tenant_id, organization_id, user_id, role_id, status, joined_at,
    created_by, updated_by
  ) values (
    p_tenant_id, p_organization_id, p_user_id, v_role_id, 'active', now(),
    v_actor, v_actor
  )
  on conflict (organization_id, user_id, role_id) do nothing;

  -- Idempotent user_roles insert. Skip if an equivalent active assignment
  -- already exists. Do not rely on duplicate-failure for repeated approval.
  if not exists (
    select 1
      from identity.user_roles
     where user_id    = p_user_id
       and role_id    = v_role_id
       and scope_type = 'organization'
       and scope_id   = p_organization_id
       and revoked_at is null
       and deleted_at is null
  ) then
    insert into identity.user_roles (
      user_id, role_id, scope_type, scope_id, granted_by, granted_at,
      created_by, updated_by
    ) values (
      p_user_id, v_role_id, 'organization', p_organization_id, v_actor, now(),
      v_actor, v_actor
    );
  end if;
end;
$$;

comment on function identity.admin_approve_user(
  uuid, uuid, uuid, text, text, identity.locale
) is 'Admin-only. Atomic + idempotent: creates user_profiles (upsert), memberships (on conflict do nothing), user_roles (skip if active equivalent exists).';

-- =====================================================================
-- 7. identity.admin_set_user_status  (write)
-- =====================================================================
create or replace function identity.admin_set_user_status(
  p_user_id uuid,
  p_status  identity.user_status
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_set_user_status: requires platform_admin' using errcode = '42501';
  end if;
  update identity.user_profiles
     set status     = p_status,
         updated_by = v_actor
   where id = p_user_id;
  if not found then
    raise exception 'admin_set_user_status: user_profile not found for %', p_user_id
      using errcode = 'P0002';
  end if;
end;
$$;

comment on function identity.admin_set_user_status(uuid, identity.user_status) is
  'Admin-only. UPDATE identity.user_profiles.status.';

-- =====================================================================
-- 8. identity.admin_assign_role  (write)
-- =====================================================================
create or replace function identity.admin_assign_role(
  p_user_id    uuid,
  p_role_code  text,
  p_scope_type identity.role_scope default 'organization',
  p_scope_id   uuid                 default null
)
returns void
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  v_actor   uuid := auth.uid();
  v_role_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_assign_role: requires platform_admin' using errcode = '42501';
  end if;
  select id into v_role_id from identity.roles where code = p_role_code;
  if v_role_id is null then
    raise exception 'admin_assign_role: unknown role %', p_role_code using errcode = '22023';
  end if;
  insert into identity.user_roles (
    user_id, role_id, scope_type, scope_id, granted_by, granted_at,
    created_by, updated_by
  ) values (
    p_user_id, v_role_id, p_scope_type, p_scope_id, v_actor, now(),
    v_actor, v_actor
  );
end;
$$;

comment on function identity.admin_assign_role(
  uuid, text, identity.role_scope, uuid
) is 'Admin-only. INSERT into identity.user_roles. Caller specifies scope_type and scope_id.';

-- =====================================================================
-- Grants — EXECUTE only. No table-level grants are added.
-- =====================================================================
grant execute on function identity.admin_list_users(int, int, text)
  to authenticated;
grant execute on function identity.admin_get_user(uuid)
  to authenticated;
grant execute on function identity.admin_list_audit_events(int, int, timestamptz)
  to authenticated;
grant execute on function identity.admin_create_organization(
  uuid, text, text, text,
  organization.organization_type,
  organization.organization_status,
  char, text, text, text
) to authenticated;
grant execute on function identity.admin_add_membership(uuid, uuid, text)
  to authenticated;
grant execute on function identity.admin_approve_user(
  uuid, uuid, uuid, text, text, identity.locale
) to authenticated;
grant execute on function identity.admin_set_user_status(uuid, identity.user_status)
  to authenticated;
grant execute on function identity.admin_assign_role(
  uuid, text, identity.role_scope, uuid
) to authenticated;
