-- CC-03 / Migration 0002
-- Tenant root and user profile (1:1 with auth.users).
-- user_profiles.primary_organization_id FK is attached in 0004 once organizations exists.

create type identity.tenant_status as enum ('active', 'pending', 'suspended', 'closed');
create type identity.user_status   as enum ('active', 'pending', 'suspended', 'deactivated');
create type identity.locale        as enum ('fa', 'en');

create table identity.tenants (
  id              uuid primary key default gen_random_uuid(),
  code            citext not null unique,
  name_fa         text not null,
  name_en         text not null,
  country_code    char(2) not null default 'IR',
  status          identity.tenant_status not null default 'active',
  created_by      uuid references auth.users(id),
  created_at      timestamptz not null default now(),
  updated_by      uuid references auth.users(id),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  version         integer not null default 1
);

comment on table identity.tenants is
  'Top-level tenant partition. Each tenant owns its own organizations and data. Exempt from mandatory tenant_id/organization_id columns.';

create table identity.user_profiles (
  id                      uuid primary key references auth.users(id) on delete cascade,
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  primary_organization_id uuid,  -- FK attached in 0004
  full_name               text,
  locale                  identity.locale not null default 'fa',
  avatar_url              text,
  phone_e164              text,
  status                  identity.user_status not null default 'active',
  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_by              uuid references auth.users(id),
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz,
  version                 integer not null default 1
);

comment on table identity.user_profiles is
  '1:1 platform profile keyed by auth.users.id. Credentials remain in auth.users. organization_id mandatory column policy relaxed (primary_organization_id nullable).';

create index user_profiles_tenant_idx      on identity.user_profiles(tenant_id);
create index user_profiles_primary_org_idx on identity.user_profiles(primary_organization_id);
