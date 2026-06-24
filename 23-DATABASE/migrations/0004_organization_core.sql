-- CC-03 / Migration 0004
-- Organizations, business units, memberships. Closes the user_profiles FK loop.

create type organization.organization_type as enum (
  'buyer', 'supplier', 'carrier', 'broker', 'government', 'platform'
);

create type organization.organization_status as enum (
  'active', 'pending', 'suspended', 'closed'
);

create type organization.business_unit_status as enum (
  'active', 'suspended', 'closed'
);

create type organization.membership_status as enum (
  'active', 'invited', 'suspended', 'revoked'
);

comment on type organization.organization_type is
  'Six reserved org types. Phase 1 wires UI for buyer/supplier/carrier/platform; broker and government reserved.';

create table organization.organizations (
  id                     uuid primary key default gen_random_uuid(),
  tenant_id              uuid not null references identity.tenants(id) on delete restrict,
  code                   citext not null,
  name_fa                text not null,
  name_en                text not null,
  legal_name             text,
  registration_number    text,
  tax_id                 text,
  type                   organization.organization_type not null,
  parent_organization_id uuid references organization.organizations(id) on delete set null,
  status                 organization.organization_status not null default 'pending',
  country_code           char(2) not null default 'IR',
  created_by             uuid references auth.users(id),
  created_at             timestamptz not null default now(),
  updated_by             uuid references auth.users(id),
  updated_at             timestamptz not null default now(),
  deleted_at             timestamptz,
  version                integer not null default 1,
  unique (tenant_id, code)
);

comment on table organization.organizations is
  'Organization registry. Single table with type discriminator. Mandatory organization_id column policy satisfied by id (self-reference).';

create index organizations_tenant_idx on organization.organizations(tenant_id);
create index organizations_type_idx   on organization.organizations(type);
create index organizations_parent_idx on organization.organizations(parent_organization_id);

create table organization.business_units (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  organization_id          uuid not null references organization.organizations(id) on delete cascade,
  code                     citext not null,
  name_fa                  text not null,
  name_en                  text not null,
  parent_business_unit_id  uuid references organization.business_units(id) on delete set null,
  status                   organization.business_unit_status not null default 'active',
  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1,
  unique (organization_id, code)
);

comment on table organization.business_units is
  'Sub-divisions within an organization. Reserved for hierarchy compliance; UI integration deferred to a later phase.';

create index business_units_org_idx on organization.business_units(organization_id);

create table organization.memberships (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null references identity.tenants(id) on delete restrict,
  organization_id   uuid not null references organization.organizations(id) on delete cascade,
  user_id           uuid not null references auth.users(id) on delete cascade,
  role_id           uuid not null references identity.roles(id) on delete restrict,
  business_unit_id  uuid references organization.business_units(id) on delete set null,
  status            organization.membership_status not null default 'active',
  joined_at         timestamptz,
  created_by        uuid references auth.users(id),
  created_at        timestamptz not null default now(),
  updated_by        uuid references auth.users(id),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  version           integer not null default 1,
  unique (organization_id, user_id, role_id)
);

comment on table organization.memberships is
  'User to organization assignment with role context. A user may belong to multiple organizations.';

create index memberships_user_idx on organization.memberships(user_id);
create index memberships_org_idx  on organization.memberships(organization_id);

alter table identity.user_profiles
  add constraint user_profiles_primary_org_fk
  foreign key (primary_organization_id)
  references organization.organizations(id)
  deferrable initially deferred;
