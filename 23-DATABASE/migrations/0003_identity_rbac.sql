-- CC-03 / Migration 0003
-- Data-driven RBAC: roles, permissions, junctions.
-- roles + permissions + role_permissions are global lookup tables.
-- user_roles is identity-scoped; tenant/org context is captured in scope_type + scope_id.

create type identity.role_scope as enum ('platform', 'tenant', 'organization', 'business_unit');

create table identity.roles (
  id           uuid primary key default gen_random_uuid(),
  code         citext not null unique,
  scope        identity.role_scope not null,
  label_fa     text not null,
  label_en     text not null,
  description  text,
  is_system    boolean not null default false,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table identity.roles is
  'RBAC role registry. Global lookup. is_system rows are seeded by CC-03 and protected.';

create table identity.permissions (
  id           uuid primary key default gen_random_uuid(),
  code         citext not null unique,
  domain       text not null,
  action       text not null,
  label_fa     text,
  label_en     text,
  description  text,
  created_at   timestamptz not null default now()
);

comment on table identity.permissions is
  'Permission registry. Codes follow domain.action convention. Global lookup.';

create table identity.role_permissions (
  role_id       uuid not null references identity.roles(id) on delete cascade,
  permission_id uuid not null references identity.permissions(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (role_id, permission_id)
);

comment on table identity.role_permissions is
  'Many-to-many between roles and permissions. Data-driven; do not hard-code role grants in app code.';

create table identity.user_roles (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  role_id      uuid not null references identity.roles(id) on delete restrict,
  scope_type   identity.role_scope not null,
  scope_id     uuid,
  granted_by   uuid references auth.users(id),
  granted_at   timestamptz not null default now(),
  revoked_at   timestamptz,
  created_by   uuid references auth.users(id),
  created_at   timestamptz not null default now(),
  updated_by   uuid references auth.users(id),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  version      integer not null default 1,
  constraint user_roles_scope_id_required check (
    (scope_type = 'platform' and scope_id is null)
    or (scope_type <> 'platform' and scope_id is not null)
  )
);

comment on table identity.user_roles is
  'Role assignments. Scope captured by scope_type + scope_id. Exempt from tenant_id/organization_id columns.';

create unique index user_roles_unique_active
  on identity.user_roles(
    user_id,
    role_id,
    scope_type,
    coalesce(scope_id, '00000000-0000-0000-0000-000000000000'::uuid)
  )
  where revoked_at is null and deleted_at is null;

create index user_roles_user_idx
  on identity.user_roles(user_id)
  where revoked_at is null and deleted_at is null;
