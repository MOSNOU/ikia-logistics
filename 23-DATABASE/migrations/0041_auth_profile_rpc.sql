-- CC-68B — identity.get_current_auth_profile()
--
-- Production authorization fix. The Next.js frontend previously read
-- the caller's roles / permissions / memberships by issuing six
-- separate PostgREST queries directly against identity.user_roles,
-- identity.roles, identity.role_permissions, identity.permissions,
-- organization.memberships and organization.organizations. Several of
-- those tables have restrictive RLS (deny by default for non-admins on
-- catalog tables like identity.roles / identity.permissions) which
-- caused requireRole(platform_admin) to receive an empty roles array
-- and redirect freshly-provisioned admins to /unauthorized.
--
-- This migration introduces a single narrow SECURITY DEFINER RPC that:
--   • derives the caller from auth.uid() ONLY — no parameter,
--   • returns a single jsonb document containing the current user's
--     profile, roles, permissions and active memberships,
--   • bypasses RLS (security definer) but never accepts a user id,
--   • is callable only by the `authenticated` role.
--
-- Additive only. No table changes, no RLS changes.

begin;

create or replace function identity.get_current_auth_profile()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user        uuid := auth.uid();
  v_profile     jsonb := null;
  v_email       text  := null;
  v_roles       jsonb;
  v_permissions jsonb;
  v_memberships jsonb;
begin
  if v_user is null then
    return null;
  end if;

  -- ---- email comes from the auth schema ---------------------------------
  select u.email::text into v_email
    from auth.users u
   where u.id = v_user;

  -- ---- profile (identity.user_profiles) ---------------------------------
  select jsonb_build_object(
           'fullName',              up.full_name,
           'tenantId',              up.tenant_id,
           'primaryOrganizationId', up.primary_organization_id,
           'locale',                up.locale,
           'status',                up.status
         )
    into v_profile
    from identity.user_profiles up
   where up.id = v_user
     and up.deleted_at is null;

  -- ---- active role codes ------------------------------------------------
  select coalesce(jsonb_agg(distinct r.code::text), '[]'::jsonb)
    into v_roles
    from identity.user_roles ur
    join identity.roles r on r.id = ur.role_id
   where ur.user_id = v_user
     and ur.deleted_at is null
     and ur.revoked_at is null;

  -- ---- effective permission codes (via role_permissions) ---------------
  select coalesce(jsonb_agg(distinct p.code::text), '[]'::jsonb)
    into v_permissions
    from identity.user_roles ur
    join identity.role_permissions rp on rp.role_id = ur.role_id
    join identity.permissions p       on p.id = rp.permission_id
   where ur.user_id = v_user
     and ur.deleted_at is null
     and ur.revoked_at is null;

  -- ---- active memberships with organization + role labels --------------
  select coalesce(
           jsonb_agg(
             jsonb_build_object(
               'membershipId',       m.id,
               'organizationId',     m.organization_id,
               'organizationCode',   o.code::text,
               'organizationNameFa', o.name_fa,
               'organizationNameEn', o.name_en,
               'roleCode',           r.code::text
             )
             order by m.created_at
           ),
           '[]'::jsonb
         )
    into v_memberships
    from organization.memberships m
    join organization.organizations o on o.id = m.organization_id
    join identity.roles r             on r.id = m.role_id
   where m.user_id = v_user
     and m.status = 'active'
     and m.deleted_at is null;

  return jsonb_build_object(
    'userId',                v_user,
    'email',                 v_email,
    'fullName',              v_profile -> 'fullName',
    'tenantId',              v_profile -> 'tenantId',
    'primaryOrganizationId', v_profile -> 'primaryOrganizationId',
    'locale',                v_profile -> 'locale',
    'status',                v_profile -> 'status',
    'hasProfile',            v_profile is not null,
    'roles',                 coalesce(v_roles,       '[]'::jsonb),
    'permissions',           coalesce(v_permissions, '[]'::jsonb),
    'memberships',           coalesce(v_memberships, '[]'::jsonb)
  );
end;
$$;

comment on function identity.get_current_auth_profile() is
  'CC-68B: SECURITY DEFINER reader returning the current authenticated user''s profile, roles, permissions and active memberships as a single jsonb document. Derives the caller from auth.uid() only — no user id parameter. Bypasses RLS on identity.* / organization.* catalog tables that authenticated users cannot read directly.';

revoke all   on function identity.get_current_auth_profile() from public;
revoke all   on function identity.get_current_auth_profile() from anon;
grant execute on function identity.get_current_auth_profile() to authenticated;

commit;
