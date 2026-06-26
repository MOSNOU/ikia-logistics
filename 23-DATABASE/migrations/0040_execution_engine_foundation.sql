-- CC-65 — Execution Engine Foundation
--
-- Adds the operational task layer beside shipments:
--   • execution.shipment_tasks       — one executable task per shipment row
--   • execution.task_dependencies    — finish-to-start dependency graph
--   • execution.task_events          — immutable lifecycle ledger
--   • execution.task_escalations     — escalation trail
--
-- Additive only. No existing migration is mutated. No shipment / booking /
-- dispatch / settlement / invoice records are created. All mutations flow
-- through SECURITY DEFINER RPCs scoped to buyer / carrier / supplier /
-- admin roles. Tables are RLS-protected; the event ledger is append-only
-- and never granted to authenticated.

begin;

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
create schema if not exists execution;
grant usage on schema execution to anon, authenticated, service_role;
comment on schema execution is
  'iKIA CC-65 — Shipment task execution engine. Operational task layer beside shipments: ownership, assignment, status, priority, due dates, dependencies, escalations, and immutable lifecycle events. Does not mutate shipment, booking, dispatch, or settlement records.';

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'execution' and t.typname = 'task_status') then
    create type execution.task_status as enum (
      'draft', 'open', 'in_progress', 'blocked', 'completed', 'cancelled'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'execution' and t.typname = 'task_priority') then
    create type execution.task_priority as enum (
      'low', 'normal', 'high', 'urgent'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'execution' and t.typname = 'task_owner_type') then
    create type execution.task_owner_type as enum (
      'buyer', 'carrier', 'supplier', 'admin', 'system'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'execution' and t.typname = 'escalation_status') then
    create type execution.escalation_status as enum (
      'none', 'pending', 'escalated', 'resolved', 'dismissed'
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 1. execution.shipment_tasks
-- ---------------------------------------------------------------------------
create table if not exists execution.shipment_tasks (
  id                         uuid primary key default gen_random_uuid(),
  tenant_id                  uuid not null references identity.tenants(id) on delete restrict,
  shipment_id                uuid not null references shipment.shipments(id) on delete cascade,

  task_code                  text not null,
  title                      text not null,
  description                text,

  owner_type                 execution.task_owner_type not null,
  owner_organization_id      uuid references organization.organizations(id) on delete set null,
  assigned_user_id           uuid references auth.users(id) on delete set null,

  status                     execution.task_status not null default 'open',
  priority                   execution.task_priority not null default 'normal',
  escalation_status          execution.escalation_status not null default 'none',

  due_at                     timestamptz,
  started_at                 timestamptz,
  completed_at               timestamptz,
  cancelled_at               timestamptz,
  blocked_reason             text,
  completion_note            text,

  metadata                   jsonb not null default '{}'::jsonb,

  created_by                 uuid references auth.users(id),
  created_at                 timestamptz not null default now(),
  updated_by                 uuid references auth.users(id),
  updated_at                 timestamptz not null default now(),
  deleted_at                 timestamptz,

  constraint shipment_tasks_code_unique unique (tenant_id, task_code),
  constraint shipment_tasks_completed_at_required
    check ((status <> 'completed') or (completed_at is not null)),
  constraint shipment_tasks_cancelled_at_required
    check ((status <> 'cancelled') or (cancelled_at is not null)),
  constraint shipment_tasks_blocked_reason_required
    check ((status <> 'blocked') or (blocked_reason is not null and length(btrim(blocked_reason)) > 0)),
  constraint shipment_tasks_completed_at_only_when_completed
    check (completed_at is null or status = 'completed'),
  constraint shipment_tasks_cancelled_at_only_when_cancelled
    check (cancelled_at is null or status = 'cancelled')
);

comment on table execution.shipment_tasks is
  'CC-65: executable operational task tied to a shipment. Lifecycle is open → in_progress → completed (terminal) with side branches into blocked / cancelled. All mutations via SECURITY DEFINER RPCs.';

create index if not exists shipment_tasks_shipment_status_idx
  on execution.shipment_tasks(shipment_id, status);
create index if not exists shipment_tasks_owner_org_status_idx
  on execution.shipment_tasks(owner_organization_id, status);
create index if not exists shipment_tasks_assigned_user_status_idx
  on execution.shipment_tasks(assigned_user_id, status);
create index if not exists shipment_tasks_due_at_idx
  on execution.shipment_tasks(due_at);
create index if not exists shipment_tasks_escalation_status_idx
  on execution.shipment_tasks(escalation_status);

-- ---------------------------------------------------------------------------
-- 2. execution.task_dependencies
-- ---------------------------------------------------------------------------
create table if not exists execution.task_dependencies (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references identity.tenants(id) on delete restrict,
  task_id               uuid not null references execution.shipment_tasks(id) on delete cascade,
  depends_on_task_id    uuid not null references execution.shipment_tasks(id) on delete cascade,
  dependency_type       text not null default 'finish_to_start',

  created_by            uuid references auth.users(id),
  created_at            timestamptz not null default now(),

  constraint task_dependencies_no_self
    check (task_id <> depends_on_task_id),
  constraint task_dependencies_unique
    unique (task_id, depends_on_task_id)
);

comment on table execution.task_dependencies is
  'CC-65: finish-to-start task dependency graph inside a shipment. Tasks must share the same shipment; insertion blocked otherwise.';

create index if not exists task_dependencies_task_idx
  on execution.task_dependencies(task_id);
create index if not exists task_dependencies_depends_idx
  on execution.task_dependencies(depends_on_task_id);

-- ---------------------------------------------------------------------------
-- 3. execution.task_events  (immutable append-only ledger)
-- ---------------------------------------------------------------------------
create table if not exists execution.task_events (
  id                 uuid primary key default gen_random_uuid(),
  tenant_id          uuid not null references identity.tenants(id) on delete restrict,
  task_id            uuid not null references execution.shipment_tasks(id) on delete cascade,

  event_type         text not null,
  from_status        execution.task_status,
  to_status          execution.task_status,

  actor_user_id      uuid references auth.users(id),
  actor_owner_type   execution.task_owner_type,

  payload            jsonb not null default '{}'::jsonb,
  created_at         timestamptz not null default now()
);

comment on table execution.task_events is
  'CC-65: immutable task lifecycle event ledger. No UPDATE / DELETE. Insert only through execution.fn_record_task_event() (SECURITY DEFINER).';

create index if not exists task_events_task_created_idx
  on execution.task_events(task_id, created_at);

-- Block direct UPDATE/DELETE at the row level via trigger.
create or replace function execution.fn_block_task_event_mutation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  raise exception 'execution: task_events is append-only' using errcode = '42501';
end;
$$;

drop trigger if exists trg_task_events_no_update on execution.task_events;
create trigger trg_task_events_no_update
  before update on execution.task_events
  for each row execute function execution.fn_block_task_event_mutation();

drop trigger if exists trg_task_events_no_delete on execution.task_events;
create trigger trg_task_events_no_delete
  before delete on execution.task_events
  for each row execute function execution.fn_block_task_event_mutation();

-- ---------------------------------------------------------------------------
-- 4. execution.task_escalations
-- ---------------------------------------------------------------------------
create table if not exists execution.task_escalations (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  task_id             uuid not null references execution.shipment_tasks(id) on delete cascade,

  escalation_reason   text not null,
  severity            execution.task_priority not null default 'high',
  status              execution.escalation_status not null default 'pending',

  raised_by           uuid references auth.users(id),
  raised_at           timestamptz not null default now(),
  resolved_by         uuid references auth.users(id),
  resolved_at         timestamptz,
  resolution_note     text,

  constraint task_escalations_resolved_at_required
    check ((status not in ('resolved','dismissed')) or (resolved_at is not null)),
  constraint task_escalations_resolution_note_required
    check ((status not in ('resolved','dismissed'))
           or (resolution_note is not null and length(btrim(resolution_note)) > 0))
);

comment on table execution.task_escalations is
  'CC-65: escalation trail for overdue / blocked / urgent / manually escalated tasks. Raised and resolved by platform admins only.';

create index if not exists task_escalations_task_status_idx
  on execution.task_escalations(task_id, status);

-- ===========================================================================
-- Internal helpers
-- ===========================================================================

-- Visibility: can the caller see a shipment? Membership in buyer / supplier /
-- carrier organisation OR platform admin. Mirrors the established CC-37
-- (control tower) / CC-45 (telematics) pattern.
create or replace function execution.fn_assert_can_view_shipment(p_shipment_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid; v_supplier uuid; v_carrier uuid;
  v_user  uuid := identity.current_user_id();
begin
  select organization_id, supplier_organization_id, carrier_organization_id
    into v_buyer, v_supplier, v_carrier
    from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'execution: shipment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'execution: shipment not visible' using errcode = '42501';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id in (v_buyer, v_supplier, v_carrier)
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  raise exception 'execution: shipment not visible to caller' using errcode = '42501';
end;
$$;

-- Visibility: can the caller see a task? Either shipment visibility OR
-- task is owned/assigned to caller's organisation OR assigned to the
-- caller themselves.
create or replace function execution.fn_assert_can_view_task(p_task_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_shipment uuid; v_owner_org uuid; v_assigned uuid;
  v_user uuid := identity.current_user_id();
begin
  select shipment_id, owner_organization_id, assigned_user_id
    into v_shipment, v_owner_org, v_assigned
    from execution.shipment_tasks
   where id = p_task_id and deleted_at is null;
  if v_shipment is null then
    raise exception 'execution: task not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'execution: task not visible' using errcode = '42501';
  end if;
  if v_assigned = v_user then return; end if;
  if v_owner_org is not null and exists (
    select 1 from organization.memberships m
     where m.user_id = v_user and m.organization_id = v_owner_org
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  -- Fall back to shipment-level visibility.
  perform execution.fn_assert_can_view_shipment(v_shipment);
end;
$$;

-- Mutation: caller can mutate a task only when assigned to it, member of
-- the owning organisation, or platform admin. Buyer-owned tasks also
-- allow buyer org members to mutate even without being explicitly assigned.
create or replace function execution.fn_assert_can_mutate_task(p_task_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_shipment uuid; v_owner_org uuid; v_owner_type execution.task_owner_type;
  v_assigned uuid; v_buyer uuid;
  v_user uuid := identity.current_user_id();
begin
  select t.shipment_id, t.owner_organization_id, t.owner_type, t.assigned_user_id,
         s.organization_id
    into v_shipment, v_owner_org, v_owner_type, v_assigned, v_buyer
    from execution.shipment_tasks t
    join shipment.shipments s on s.id = t.shipment_id
   where t.id = p_task_id and t.deleted_at is null;
  if v_shipment is null then
    raise exception 'execution: task not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'execution: task not mutable' using errcode = '42501';
  end if;
  if v_assigned = v_user then return; end if;
  if v_owner_org is not null and exists (
    select 1 from organization.memberships m
     where m.user_id = v_user and m.organization_id = v_owner_org
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  -- Buyer-owned tasks: any active buyer-org member may mutate.
  if v_owner_type = 'buyer' and exists (
    select 1 from organization.memberships m
     where m.user_id = v_user and m.organization_id = v_buyer
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  raise exception 'execution: task not mutable by caller' using errcode = '42501';
end;
$$;

-- Insert into the immutable event ledger. SECURITY DEFINER bypass for the
-- direct-insert guard. Internal only.
create or replace function execution.fn_record_task_event(
  p_task_id          uuid,
  p_event_type       text,
  p_from_status      execution.task_status default null,
  p_to_status        execution.task_status default null,
  p_actor_owner_type execution.task_owner_type default null,
  p_payload          jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_id     uuid;
begin
  select tenant_id into v_tenant
    from execution.shipment_tasks where id = p_task_id;
  if v_tenant is null then
    raise exception 'execution: task not found' using errcode = 'P0002';
  end if;
  insert into execution.task_events (
    tenant_id, task_id, event_type, from_status, to_status,
    actor_user_id, actor_owner_type, payload
  ) values (
    v_tenant, p_task_id, p_event_type, p_from_status, p_to_status,
    identity.current_user_id(), p_actor_owner_type, coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- Are all task dependencies completed?
create or replace function execution.fn_task_dependencies_satisfied(p_task_id uuid)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare v_unmet int;
begin
  select count(*) into v_unmet
    from execution.task_dependencies d
    join execution.shipment_tasks t on t.id = d.depends_on_task_id
   where d.task_id = p_task_id
     and (t.status <> 'completed' or t.deleted_at is not null);
  return v_unmet = 0;
end;
$$;

-- Caller-org organization id (org membership preferred over JWT claim).
create or replace function execution.fn_caller_org()
returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare v uuid;
begin
  v := identity.current_organization_id();
  return v;
end;
$$;

-- Validate dependency insert: same shipment + no simple 2-node cycle.
create or replace function execution.fn_trg_validate_dependency()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_ship_a uuid; v_ship_b uuid;
begin
  select shipment_id into v_ship_a from execution.shipment_tasks where id = new.task_id;
  select shipment_id into v_ship_b from execution.shipment_tasks where id = new.depends_on_task_id;
  if v_ship_a is null or v_ship_b is null then
    raise exception 'execution: dependency tasks must exist' using errcode = 'P0002';
  end if;
  if v_ship_a <> v_ship_b then
    raise exception 'execution: dependency must stay within same shipment'
      using errcode = '22023';
  end if;
  -- No simple 2-node cycle: depends_on_task_id must not already depend on task_id.
  if exists (
    select 1 from execution.task_dependencies
     where task_id = new.depends_on_task_id and depends_on_task_id = new.task_id
  ) then
    raise exception 'execution: dependency would create a 2-node cycle'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_task_dependencies_validate on execution.task_dependencies;
create trigger trg_task_dependencies_validate
  before insert on execution.task_dependencies
  for each row execute function execution.fn_trg_validate_dependency();

-- ===========================================================================
-- Buyer RPCs
-- ===========================================================================

create or replace function execution.buyer_create_task(
  p_shipment_id              uuid,
  p_title                    text,
  p_description              text default null,
  p_owner_type               execution.task_owner_type default 'buyer',
  p_owner_organization_id    uuid default null,
  p_assigned_user_id         uuid default null,
  p_priority                 execution.task_priority default 'normal',
  p_due_at                   timestamptz default null,
  p_metadata                 jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_buyer uuid; v_tenant uuid; v_user uuid := identity.current_user_id();
  v_org uuid := execution.fn_caller_org(); v_id uuid;
begin
  if v_user is null then
    raise exception 'execution: anonymous cannot create task' using errcode = '42501';
  end if;
  if p_title is null or length(btrim(p_title)) = 0 then
    raise exception 'execution: title required' using errcode = '22023';
  end if;
  select organization_id, tenant_id into v_buyer, v_tenant
    from shipment.shipments where id = p_shipment_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'execution: shipment not found' using errcode = 'P0002';
  end if;
  -- Caller must be an active member of the buyer organisation.
  if not exists (
    select 1 from organization.memberships m
     where m.user_id = v_user and m.organization_id = v_buyer
       and m.deleted_at is null and m.status = 'active'
  ) then
    raise exception 'execution: only buyer-org members may create tasks here'
      using errcode = '42501';
  end if;
  insert into execution.shipment_tasks (
    tenant_id, shipment_id, task_code, title, description,
    owner_type, owner_organization_id, assigned_user_id,
    priority, due_at, metadata, created_by, updated_by
  ) values (
    v_tenant, p_shipment_id,
    'TSK-' || replace(extensions.gen_random_uuid()::text, '-', ''),
    p_title, p_description,
    p_owner_type, coalesce(p_owner_organization_id, v_org), p_assigned_user_id,
    p_priority, p_due_at, coalesce(p_metadata, '{}'::jsonb),
    v_user, v_user
  )
  returning id into v_id;
  perform execution.fn_record_task_event(v_id, 'task.created', null, 'open',
    'buyer'::execution.task_owner_type,
    jsonb_build_object('shipment_id', p_shipment_id, 'title', p_title));
  return v_id;
end;
$$;

create or replace function execution.buyer_list_tasks(
  p_shipment_id uuid default null,
  p_status      execution.task_status default null,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'execution: anonymous' using errcode = '42501';
  end if;
  return query
    select t.*
      from execution.shipment_tasks t
      join shipment.shipments s on s.id = t.shipment_id
     where t.deleted_at is null
       and s.deleted_at is null
       and (p_shipment_id is null or t.shipment_id = p_shipment_id)
       and (p_status is null or t.status = p_status)
       and exists (
         select 1 from organization.memberships m
          where m.user_id = v_user
            and m.organization_id = s.organization_id
            and m.deleted_at is null and m.status = 'active'
       )
     order by t.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function execution.buyer_get_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v execution.shipment_tasks;
begin
  perform execution.fn_assert_can_view_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  return v;
end;
$$;

create or replace function execution.buyer_start_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from not in ('open','blocked') then
    raise exception 'execution: cannot start from status %', v_from using errcode = '22023';
  end if;
  if not execution.fn_task_dependencies_satisfied(p_task_id) then
    raise exception 'execution: dependencies not satisfied' using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'in_progress',
         started_at = coalesce(started_at, now()),
         blocked_reason = null,
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.started', v_from, 'in_progress',
    'buyer'::execution.task_owner_type, '{}'::jsonb);
  return v;
end;
$$;

create or replace function execution.buyer_complete_task(
  p_task_id uuid,
  p_completion_note text default null
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from <> 'in_progress' then
    raise exception 'execution: cannot complete from status %', v_from using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'completed',
         completed_at = now(),
         completion_note = p_completion_note,
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.completed', v_from, 'completed',
    'buyer'::execution.task_owner_type,
    jsonb_build_object('completion_note', p_completion_note));
  return v;
end;
$$;

create or replace function execution.buyer_block_task(
  p_task_id uuid,
  p_blocked_reason text
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  if p_blocked_reason is null or length(btrim(p_blocked_reason)) = 0 then
    raise exception 'execution: blocked_reason required' using errcode = '22023';
  end if;
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from not in ('open','in_progress') then
    raise exception 'execution: cannot block from status %', v_from using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'blocked',
         blocked_reason = p_blocked_reason,
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.blocked', v_from, 'blocked',
    'buyer'::execution.task_owner_type,
    jsonb_build_object('reason', p_blocked_reason));
  return v;
end;
$$;

create or replace function execution.buyer_cancel_task(
  p_task_id uuid,
  p_reason  text default null
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from in ('completed','cancelled') then
    raise exception 'execution: cannot cancel from terminal status %', v_from
      using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'cancelled',
         cancelled_at = now(),
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.cancelled', v_from, 'cancelled',
    'buyer'::execution.task_owner_type,
    jsonb_build_object('reason', p_reason));
  return v;
end;
$$;

-- ===========================================================================
-- Carrier RPCs
-- ===========================================================================

create or replace function execution.carrier_list_tasks(
  p_shipment_id uuid default null,
  p_status      execution.task_status default null,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'execution: anonymous' using errcode = '42501';
  end if;
  return query
    select t.*
      from execution.shipment_tasks t
      join shipment.shipments s on s.id = t.shipment_id
     where t.deleted_at is null and s.deleted_at is null
       and (p_shipment_id is null or t.shipment_id = p_shipment_id)
       and (p_status is null or t.status = p_status)
       and (
         t.assigned_user_id = v_user
         or exists (
           select 1 from organization.memberships m
            where m.user_id = v_user
              and m.organization_id = t.owner_organization_id
              and m.deleted_at is null and m.status = 'active'
         )
         or exists (
           select 1 from organization.memberships m
            where m.user_id = v_user
              and m.organization_id = s.carrier_organization_id
              and m.deleted_at is null and m.status = 'active'
         )
       )
     order by t.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function execution.carrier_get_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v execution.shipment_tasks;
begin
  perform execution.fn_assert_can_view_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  return v;
end;
$$;

create or replace function execution.carrier_start_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from not in ('open','blocked') then
    raise exception 'execution: cannot start from status %', v_from using errcode = '22023';
  end if;
  if not execution.fn_task_dependencies_satisfied(p_task_id) then
    raise exception 'execution: dependencies not satisfied' using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'in_progress',
         started_at = coalesce(started_at, now()),
         blocked_reason = null,
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.started', v_from, 'in_progress',
    'carrier'::execution.task_owner_type, '{}'::jsonb);
  return v;
end;
$$;

create or replace function execution.carrier_complete_task(
  p_task_id uuid, p_completion_note text default null
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from <> 'in_progress' then
    raise exception 'execution: cannot complete from status %', v_from using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'completed', completed_at = now(),
         completion_note = p_completion_note,
         updated_by = identity.current_user_id(), updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.completed', v_from, 'completed',
    'carrier'::execution.task_owner_type,
    jsonb_build_object('completion_note', p_completion_note));
  return v;
end;
$$;

create or replace function execution.carrier_block_task(
  p_task_id uuid, p_blocked_reason text
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  if p_blocked_reason is null or length(btrim(p_blocked_reason)) = 0 then
    raise exception 'execution: blocked_reason required' using errcode = '22023';
  end if;
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from not in ('open','in_progress') then
    raise exception 'execution: cannot block from status %', v_from using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'blocked', blocked_reason = p_blocked_reason,
         updated_by = identity.current_user_id(), updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.blocked', v_from, 'blocked',
    'carrier'::execution.task_owner_type,
    jsonb_build_object('reason', p_blocked_reason));
  return v;
end;
$$;

-- ===========================================================================
-- Supplier RPCs
-- ===========================================================================

create or replace function execution.supplier_list_tasks(
  p_shipment_id uuid default null,
  p_status      execution.task_status default null,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'execution: anonymous' using errcode = '42501';
  end if;
  return query
    select t.*
      from execution.shipment_tasks t
      join shipment.shipments s on s.id = t.shipment_id
     where t.deleted_at is null and s.deleted_at is null
       and (p_shipment_id is null or t.shipment_id = p_shipment_id)
       and (p_status is null or t.status = p_status)
       and (
         t.assigned_user_id = v_user
         or (t.owner_organization_id is not null and exists (
             select 1 from organization.memberships m
              where m.user_id = v_user
                and m.organization_id = t.owner_organization_id
                and m.deleted_at is null and m.status = 'active'
         ))
         or (s.supplier_organization_id is not null and exists (
             select 1 from organization.memberships m
              where m.user_id = v_user
                and m.organization_id = s.supplier_organization_id
                and m.deleted_at is null and m.status = 'active'
         ))
       )
     order by t.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function execution.supplier_get_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v execution.shipment_tasks;
begin
  perform execution.fn_assert_can_view_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  return v;
end;
$$;

create or replace function execution.supplier_start_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from not in ('open','blocked') then
    raise exception 'execution: cannot start from status %', v_from using errcode = '22023';
  end if;
  if not execution.fn_task_dependencies_satisfied(p_task_id) then
    raise exception 'execution: dependencies not satisfied' using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'in_progress',
         started_at = coalesce(started_at, now()),
         blocked_reason = null,
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.started', v_from, 'in_progress',
    'supplier'::execution.task_owner_type, '{}'::jsonb);
  return v;
end;
$$;

create or replace function execution.supplier_complete_task(
  p_task_id uuid, p_completion_note text default null
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from <> 'in_progress' then
    raise exception 'execution: cannot complete from status %', v_from using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'completed', completed_at = now(),
         completion_note = p_completion_note,
         updated_by = identity.current_user_id(), updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.completed', v_from, 'completed',
    'supplier'::execution.task_owner_type,
    jsonb_build_object('completion_note', p_completion_note));
  return v;
end;
$$;

create or replace function execution.supplier_block_task(
  p_task_id uuid, p_blocked_reason text
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  if p_blocked_reason is null or length(btrim(p_blocked_reason)) = 0 then
    raise exception 'execution: blocked_reason required' using errcode = '22023';
  end if;
  perform execution.fn_assert_can_mutate_task(p_task_id);
  select * into v from execution.shipment_tasks where id = p_task_id;
  v_from := v.status;
  if v_from not in ('open','in_progress') then
    raise exception 'execution: cannot block from status %', v_from using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'blocked', blocked_reason = p_blocked_reason,
         updated_by = identity.current_user_id(), updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.blocked', v_from, 'blocked',
    'supplier'::execution.task_owner_type,
    jsonb_build_object('reason', p_blocked_reason));
  return v;
end;
$$;

-- ===========================================================================
-- Admin RPCs
-- ===========================================================================

create or replace function execution.admin_create_task(
  p_shipment_id              uuid,
  p_title                    text,
  p_description              text default null,
  p_owner_type               execution.task_owner_type default 'admin',
  p_owner_organization_id    uuid default null,
  p_assigned_user_id         uuid default null,
  p_priority                 execution.task_priority default 'normal',
  p_due_at                   timestamptz default null,
  p_metadata                 jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_tenant uuid; v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  if p_title is null or length(btrim(p_title)) = 0 then
    raise exception 'execution: title required' using errcode = '22023';
  end if;
  select tenant_id into v_tenant from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_tenant is null then
    raise exception 'execution: shipment not found' using errcode = 'P0002';
  end if;
  insert into execution.shipment_tasks (
    tenant_id, shipment_id, task_code, title, description,
    owner_type, owner_organization_id, assigned_user_id,
    priority, due_at, metadata, created_by, updated_by
  ) values (
    v_tenant, p_shipment_id,
    'TSK-' || replace(extensions.gen_random_uuid()::text, '-', ''),
    p_title, p_description,
    p_owner_type, p_owner_organization_id, p_assigned_user_id,
    p_priority, p_due_at, coalesce(p_metadata, '{}'::jsonb),
    identity.current_user_id(), identity.current_user_id()
  )
  returning id into v_id;
  perform execution.fn_record_task_event(v_id, 'task.created', null, 'open',
    'admin'::execution.task_owner_type,
    jsonb_build_object('shipment_id', p_shipment_id, 'title', p_title));
  return v_id;
end;
$$;

create or replace function execution.admin_list_tasks(
  p_shipment_id uuid default null,
  p_status      execution.task_status default null,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  return query
    select * from execution.shipment_tasks
     where deleted_at is null
       and (p_shipment_id is null or shipment_id = p_shipment_id)
       and (p_status is null or status = p_status)
     order by created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function execution.admin_get_task(p_task_id uuid)
returns execution.shipment_tasks
language plpgsql stable security definer set search_path = ''
as $$
declare v execution.shipment_tasks;
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  select * into v from execution.shipment_tasks where id = p_task_id;
  return v;
end;
$$;

create or replace function execution.admin_cancel_task(
  p_task_id uuid, p_reason text default null
) returns execution.shipment_tasks
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.shipment_tasks; v_from execution.task_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  select * into v from execution.shipment_tasks where id = p_task_id;
  if v.id is null then
    raise exception 'execution: task not found' using errcode = 'P0002';
  end if;
  v_from := v.status;
  if v_from in ('completed','cancelled') then
    raise exception 'execution: cannot cancel terminal status %', v_from
      using errcode = '22023';
  end if;
  update execution.shipment_tasks
     set status = 'cancelled', cancelled_at = now(),
         updated_by = identity.current_user_id(), updated_at = now()
   where id = p_task_id
  returning * into v;
  perform execution.fn_record_task_event(p_task_id, 'task.cancelled', v_from, 'cancelled',
    'admin'::execution.task_owner_type,
    jsonb_build_object('reason', p_reason));
  return v;
end;
$$;

create or replace function execution.admin_raise_escalation(
  p_task_id uuid,
  p_reason  text,
  p_severity execution.task_priority default 'high'
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_tenant uuid; v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  if p_reason is null or length(btrim(p_reason)) = 0 then
    raise exception 'execution: reason required' using errcode = '22023';
  end if;
  select tenant_id into v_tenant from execution.shipment_tasks where id = p_task_id;
  if v_tenant is null then
    raise exception 'execution: task not found' using errcode = 'P0002';
  end if;
  insert into execution.task_escalations (
    tenant_id, task_id, escalation_reason, severity, status, raised_by
  ) values (
    v_tenant, p_task_id, p_reason, p_severity, 'pending', identity.current_user_id()
  ) returning id into v_id;
  update execution.shipment_tasks
     set escalation_status = 'escalated',
         priority = greatest(priority, p_severity),
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = p_task_id;
  perform execution.fn_record_task_event(p_task_id, 'task.escalated', null, null,
    'admin'::execution.task_owner_type,
    jsonb_build_object('reason', p_reason, 'severity', p_severity, 'escalation_id', v_id));
  return v_id;
end;
$$;

create or replace function execution.admin_resolve_escalation(
  p_escalation_id uuid,
  p_status        execution.escalation_status,
  p_resolution_note text
) returns execution.task_escalations
language plpgsql volatile security definer set search_path = ''
as $$
declare v execution.task_escalations; v_task uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  if p_status not in ('resolved','dismissed') then
    raise exception 'execution: invalid resolution status %', p_status
      using errcode = '22023';
  end if;
  if p_resolution_note is null or length(btrim(p_resolution_note)) = 0 then
    raise exception 'execution: resolution_note required' using errcode = '22023';
  end if;
  update execution.task_escalations
     set status = p_status,
         resolved_by = identity.current_user_id(),
         resolved_at = now(),
         resolution_note = p_resolution_note
   where id = p_escalation_id
  returning * into v;
  if v.id is null then
    raise exception 'execution: escalation not found' using errcode = 'P0002';
  end if;
  v_task := v.task_id;
  update execution.shipment_tasks
     set escalation_status = p_status,
         updated_by = identity.current_user_id(),
         updated_at = now()
   where id = v_task;
  perform execution.fn_record_task_event(v_task,
    case when p_status = 'resolved' then 'task.escalation_resolved'
         else 'task.escalation_dismissed' end,
    null, null,
    'admin'::execution.task_owner_type,
    jsonb_build_object('escalation_id', p_escalation_id, 'note', p_resolution_note));
  return v;
end;
$$;

create or replace function execution.admin_task_summary()
returns table (status execution.task_status, count bigint)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'execution: admin only' using errcode = '42501';
  end if;
  return query
    select t.status, count(*)::bigint
      from execution.shipment_tasks t
     where t.deleted_at is null
     group by t.status
     order by t.status;
end;
$$;

-- ===========================================================================
-- Row-level security
-- ===========================================================================

alter table execution.shipment_tasks   enable row level security;
alter table execution.task_dependencies enable row level security;
alter table execution.task_events       enable row level security;
alter table execution.task_escalations  enable row level security;

drop policy if exists shipment_tasks_select on execution.shipment_tasks;
create policy shipment_tasks_select on execution.shipment_tasks
  for select using (
    deleted_at is null and (
      identity.is_platform_admin()
      or assigned_user_id = identity.current_user_id()
      or (owner_organization_id is not null and exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = execution.shipment_tasks.owner_organization_id
           and m.deleted_at is null and m.status = 'active'
      ))
      or exists (
        select 1 from shipment.shipments s
         where s.id = execution.shipment_tasks.shipment_id
           and s.deleted_at is null
           and exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id in (
                  s.organization_id, s.supplier_organization_id, s.carrier_organization_id
                )
                and m.deleted_at is null and m.status = 'active'
           )
      )
    )
  );

drop policy if exists task_dependencies_select on execution.task_dependencies;
create policy task_dependencies_select on execution.task_dependencies
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from execution.shipment_tasks t
       where t.id = execution.task_dependencies.task_id
         and t.deleted_at is null
         and (
           t.assigned_user_id = identity.current_user_id()
           or (t.owner_organization_id is not null and exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = t.owner_organization_id
                and m.deleted_at is null and m.status = 'active'
           ))
         )
    )
  );

drop policy if exists task_events_select on execution.task_events;
create policy task_events_select on execution.task_events
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from execution.shipment_tasks t
       where t.id = execution.task_events.task_id
         and t.deleted_at is null
         and (
           t.assigned_user_id = identity.current_user_id()
           or (t.owner_organization_id is not null and exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = t.owner_organization_id
                and m.deleted_at is null and m.status = 'active'
           ))
         )
    )
  );

drop policy if exists task_escalations_select on execution.task_escalations;
create policy task_escalations_select on execution.task_escalations
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from execution.shipment_tasks t
       where t.id = execution.task_escalations.task_id
         and t.deleted_at is null
         and (
           t.assigned_user_id = identity.current_user_id()
           or (t.owner_organization_id is not null and exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = t.owner_organization_id
                and m.deleted_at is null and m.status = 'active'
           ))
         )
    )
  );

-- ===========================================================================
-- Notification integration — emit category 'other' for key lifecycle events.
-- ===========================================================================
create or replace function notify.fn_trg_from_execution_event()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_emit boolean;
begin
  v_emit := new.event_type in (
    'task.created', 'task.started', 'task.completed',
    'task.blocked', 'task.cancelled', 'task.escalated'
  );
  if not v_emit then return new; end if;
  begin
    perform notify.fn_materialize_event(
      new.event_type,
      'shipment_task',
      new.task_id,
      new.id,
      'other'::notify.notification_category,
      jsonb_build_object(
        'task_id', new.task_id,
        'event_type', new.event_type,
        'from_status', new.from_status,
        'to_status', new.to_status,
        'actor_owner_type', new.actor_owner_type
      ),
      new.tenant_id
    );
  exception when others then
    -- swallow notify errors; ledger insert must succeed
    null;
  end;
  return new;
end;
$$;

drop trigger if exists trg_task_event_notify on execution.task_events;
create trigger trg_task_event_notify
  after insert on execution.task_events
  for each row execute function notify.fn_trg_from_execution_event();

-- ===========================================================================
-- Grants
-- ===========================================================================

-- Read tables (RLS-gated).
grant select on execution.shipment_tasks    to authenticated;
grant select on execution.task_dependencies to authenticated;
grant select on execution.task_events       to authenticated;
grant select on execution.task_escalations  to authenticated;

-- Buyer RPCs.
grant execute on function execution.buyer_create_task(uuid, text, text,
  execution.task_owner_type, uuid, uuid, execution.task_priority, timestamptz, jsonb) to authenticated;
grant execute on function execution.buyer_list_tasks(uuid, execution.task_status, int, int) to authenticated;
grant execute on function execution.buyer_get_task(uuid) to authenticated;
grant execute on function execution.buyer_start_task(uuid) to authenticated;
grant execute on function execution.buyer_complete_task(uuid, text) to authenticated;
grant execute on function execution.buyer_block_task(uuid, text) to authenticated;
grant execute on function execution.buyer_cancel_task(uuid, text) to authenticated;

-- Carrier RPCs.
grant execute on function execution.carrier_list_tasks(uuid, execution.task_status, int, int) to authenticated;
grant execute on function execution.carrier_get_task(uuid) to authenticated;
grant execute on function execution.carrier_start_task(uuid) to authenticated;
grant execute on function execution.carrier_complete_task(uuid, text) to authenticated;
grant execute on function execution.carrier_block_task(uuid, text) to authenticated;

-- Supplier RPCs.
grant execute on function execution.supplier_list_tasks(uuid, execution.task_status, int, int) to authenticated;
grant execute on function execution.supplier_get_task(uuid) to authenticated;
grant execute on function execution.supplier_start_task(uuid) to authenticated;
grant execute on function execution.supplier_complete_task(uuid, text) to authenticated;
grant execute on function execution.supplier_block_task(uuid, text) to authenticated;

-- Admin RPCs.
grant execute on function execution.admin_create_task(uuid, text, text,
  execution.task_owner_type, uuid, uuid, execution.task_priority, timestamptz, jsonb) to authenticated;
grant execute on function execution.admin_list_tasks(uuid, execution.task_status, int, int) to authenticated;
grant execute on function execution.admin_get_task(uuid) to authenticated;
grant execute on function execution.admin_cancel_task(uuid, text) to authenticated;
grant execute on function execution.admin_raise_escalation(uuid, text, execution.task_priority) to authenticated;
grant execute on function execution.admin_resolve_escalation(uuid, execution.escalation_status, text) to authenticated;
grant execute on function execution.admin_task_summary() to authenticated;

commit;
