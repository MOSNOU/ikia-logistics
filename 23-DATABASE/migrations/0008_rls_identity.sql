-- CC-03 / Migration 0008
-- Row Level Security policies on identity.* tables.
-- All policies route through identity.* helpers — no inline auth.jwt() calls.

alter table identity.tenants          enable row level security;
alter table identity.user_profiles    enable row level security;
alter table identity.roles            enable row level security;
alter table identity.permissions      enable row level security;
alter table identity.role_permissions enable row level security;
alter table identity.user_roles       enable row level security;

-- tenants -------------------------------------------------------------------
drop policy if exists tenants_select on identity.tenants;
create policy tenants_select on identity.tenants
  for select
  using (
    identity.is_platform_admin()
    or id = identity.current_tenant_id()
  );

drop policy if exists tenants_modify on identity.tenants;
create policy tenants_modify on identity.tenants
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- user_profiles -------------------------------------------------------------
drop policy if exists user_profiles_select on identity.user_profiles;
create policy user_profiles_select on identity.user_profiles
  for select
  using (
    id = identity.current_user_id()
    or identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.user_profiles.id
         and m.organization_id = identity.current_organization_id()
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

drop policy if exists user_profiles_self_update on identity.user_profiles;
create policy user_profiles_self_update on identity.user_profiles
  for update
  using (id = identity.current_user_id() or identity.is_platform_admin())
  with check (id = identity.current_user_id() or identity.is_platform_admin());

drop policy if exists user_profiles_admin_insert on identity.user_profiles;
create policy user_profiles_admin_insert on identity.user_profiles
  for insert
  with check (identity.is_platform_admin());

-- roles ---------------------------------------------------------------------
drop policy if exists roles_select on identity.roles;
create policy roles_select on identity.roles
  for select
  using (auth.role() = 'authenticated');

drop policy if exists roles_modify on identity.roles;
create policy roles_modify on identity.roles
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- permissions ---------------------------------------------------------------
drop policy if exists permissions_select on identity.permissions;
create policy permissions_select on identity.permissions
  for select
  using (auth.role() = 'authenticated');

drop policy if exists permissions_modify on identity.permissions;
create policy permissions_modify on identity.permissions
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- role_permissions ----------------------------------------------------------
drop policy if exists role_permissions_select on identity.role_permissions;
create policy role_permissions_select on identity.role_permissions
  for select
  using (auth.role() = 'authenticated');

drop policy if exists role_permissions_modify on identity.role_permissions;
create policy role_permissions_modify on identity.role_permissions
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- user_roles ----------------------------------------------------------------
drop policy if exists user_roles_select on identity.user_roles;
create policy user_roles_select on identity.user_roles
  for select
  using (
    user_id = identity.current_user_id()
    or identity.is_platform_admin()
    or (
      scope_type = 'organization'
      and scope_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  );

drop policy if exists user_roles_admin_modify on identity.user_roles;
create policy user_roles_admin_modify on identity.user_roles
  for all
  using (
    identity.is_platform_admin()
    or (
      scope_type = 'organization'
      and scope_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  )
  with check (
    identity.is_platform_admin()
    or (
      scope_type = 'organization'
      and scope_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  );
