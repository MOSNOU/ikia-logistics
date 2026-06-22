-- CC-04 / Migration 0013
-- Soft-delete enforcement on every CC-03 SELECT policy whose table has a deleted_at column.
-- For each affected table:
--   1. Re-create the *_select policy with `deleted_at is null` added.
--   2. Add a parallel *_select_deleted policy granting access to soft-deleted rows
--      only to platform_admin or compliance_officer.
--
-- Tables without deleted_at (identity.roles, identity.permissions,
-- identity.role_permissions, audit.*) are untouched.

-- identity.tenants ----------------------------------------------------------
drop policy if exists tenants_select on identity.tenants;
create policy tenants_select on identity.tenants
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or id = identity.current_tenant_id()
    )
  );

drop policy if exists tenants_select_deleted on identity.tenants;
create policy tenants_select_deleted on identity.tenants
  for select
  using (
    deleted_at is not null
    and (
      identity.is_platform_admin()
      or identity.has_role('compliance_officer')
    )
  );

-- identity.user_profiles ----------------------------------------------------
drop policy if exists user_profiles_select on identity.user_profiles;
create policy user_profiles_select on identity.user_profiles
  for select
  using (
    deleted_at is null
    and (
      id = identity.current_user_id()
      or identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.user_profiles.id
           and m.organization_id = identity.current_organization_id()
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists user_profiles_select_deleted on identity.user_profiles;
create policy user_profiles_select_deleted on identity.user_profiles
  for select
  using (
    deleted_at is not null
    and (
      identity.is_platform_admin()
      or identity.has_role('compliance_officer')
    )
  );

-- identity.user_roles -------------------------------------------------------
drop policy if exists user_roles_select on identity.user_roles;
create policy user_roles_select on identity.user_roles
  for select
  using (
    deleted_at is null
    and (
      user_id = identity.current_user_id()
      or identity.is_platform_admin()
      or (
        scope_type = 'organization'
        and scope_id = identity.current_organization_id()
        and identity.has_role('organization_admin')
      )
    )
  );

drop policy if exists user_roles_select_deleted on identity.user_roles;
create policy user_roles_select_deleted on identity.user_roles
  for select
  using (
    deleted_at is not null
    and (
      identity.is_platform_admin()
      or identity.has_role('compliance_officer')
    )
  );

-- organization.organizations -----------------------------------------------
drop policy if exists organizations_select on organization.organizations;
create policy organizations_select on organization.organizations
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or id = identity.current_organization_id()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = organization.organizations.id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists organizations_select_deleted on organization.organizations;
create policy organizations_select_deleted on organization.organizations
  for select
  using (
    deleted_at is not null
    and (
      identity.is_platform_admin()
      or identity.has_role('compliance_officer')
    )
  );

-- organization.business_units ----------------------------------------------
drop policy if exists business_units_select on organization.business_units;
create policy business_units_select on organization.business_units
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or organization_id = identity.current_organization_id()
    )
  );

drop policy if exists business_units_select_deleted on organization.business_units;
create policy business_units_select_deleted on organization.business_units
  for select
  using (
    deleted_at is not null
    and (
      identity.is_platform_admin()
      or identity.has_role('compliance_officer')
    )
  );

-- organization.memberships -------------------------------------------------
drop policy if exists memberships_select on organization.memberships;
create policy memberships_select on organization.memberships
  for select
  using (
    deleted_at is null
    and (
      user_id = identity.current_user_id()
      or identity.is_platform_admin()
      or (
        organization_id = identity.current_organization_id()
        and identity.has_role('organization_admin')
      )
    )
  );

drop policy if exists memberships_select_deleted on organization.memberships;
create policy memberships_select_deleted on organization.memberships
  for select
  using (
    deleted_at is not null
    and (
      identity.is_platform_admin()
      or identity.has_role('compliance_officer')
    )
  );
