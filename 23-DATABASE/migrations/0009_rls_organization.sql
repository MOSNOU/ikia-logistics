-- CC-03 / Migration 0009
-- Row Level Security policies on organization.* tables.

alter table organization.organizations  enable row level security;
alter table organization.business_units enable row level security;
alter table organization.memberships    enable row level security;

-- organizations -------------------------------------------------------------
drop policy if exists organizations_select on organization.organizations;
create policy organizations_select on organization.organizations
  for select
  using (
    identity.is_platform_admin()
    or id = identity.current_organization_id()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = organization.organizations.id
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

drop policy if exists organizations_admin_modify on organization.organizations;
create policy organizations_admin_modify on organization.organizations
  for all
  using (
    identity.is_platform_admin()
    or (
      id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  )
  with check (
    identity.is_platform_admin()
    or (
      id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  );

-- business_units ------------------------------------------------------------
drop policy if exists business_units_select on organization.business_units;
create policy business_units_select on organization.business_units
  for select
  using (
    identity.is_platform_admin()
    or organization_id = identity.current_organization_id()
  );

drop policy if exists business_units_admin_modify on organization.business_units;
create policy business_units_admin_modify on organization.business_units
  for all
  using (
    identity.is_platform_admin()
    or (
      organization_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  )
  with check (
    identity.is_platform_admin()
    or (
      organization_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  );

-- memberships ---------------------------------------------------------------
drop policy if exists memberships_select on organization.memberships;
create policy memberships_select on organization.memberships
  for select
  using (
    user_id = identity.current_user_id()
    or identity.is_platform_admin()
    or (
      organization_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  );

drop policy if exists memberships_admin_modify on organization.memberships;
create policy memberships_admin_modify on organization.memberships
  for all
  using (
    identity.is_platform_admin()
    or (
      organization_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  )
  with check (
    identity.is_platform_admin()
    or (
      organization_id = identity.current_organization_id()
      and identity.has_role('organization_admin')
    )
  );
