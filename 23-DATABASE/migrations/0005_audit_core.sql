-- CC-03 / Migration 0005
-- Audit log: event, entity, access. Append-only via triggers + service_role.

create type audit.audit_action as enum ('insert', 'update', 'delete');
create type audit.access_type  as enum ('read', 'write', 'export', 'denied');

create table audit.audit_event (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid references identity.tenants(id),
  organization_id uuid references organization.organizations(id),
  actor_user_id   uuid references auth.users(id),
  action_code     text not null,
  resource_type   text,
  resource_id     uuid,
  occurred_at     timestamptz not null default now(),
  request_id      uuid,
  ip_address      inet,
  user_agent      text,
  payload         jsonb
);

comment on table audit.audit_event is
  'Append-only platform event log. Logins, approvals, signatures, settlements, business actions.';

create index audit_event_tenant_idx   on audit.audit_event(tenant_id);
create index audit_event_actor_idx    on audit.audit_event(actor_user_id);
create index audit_event_occurred_idx on audit.audit_event(occurred_at desc);

create table audit.audit_entity (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid references identity.tenants(id),
  organization_id uuid references organization.organizations(id),
  entity_schema   text not null,
  entity_table    text not null,
  entity_id       uuid not null,
  action          audit.audit_action not null,
  changed_columns text[],
  before_state    jsonb,
  after_state     jsonb,
  actor_user_id   uuid references auth.users(id),
  changed_at      timestamptz not null default now()
);

comment on table audit.audit_entity is
  'Append-only row-level change log. Populated by audit.fn_audit_entity trigger on every identity + organization table.';

create index audit_entity_lookup_idx  on audit.audit_entity(entity_schema, entity_table, entity_id);
create index audit_entity_changed_idx on audit.audit_entity(changed_at desc);

create table audit.audit_access (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid references identity.tenants(id),
  organization_id uuid references organization.organizations(id),
  actor_user_id   uuid references auth.users(id),
  resource_type   text,
  resource_id     uuid,
  access_type     audit.access_type not null,
  denial_reason   text,
  accessed_at     timestamptz not null default now(),
  request_id      uuid
);

comment on table audit.audit_access is
  'Append-only access log. Reads, writes, exports, and denied attempts.';

create index audit_access_actor_idx    on audit.audit_access(actor_user_id);
create index audit_access_resource_idx on audit.audit_access(resource_type, resource_id);
