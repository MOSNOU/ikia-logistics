-- CC-66 — Workflow Engine v2 Foundation
--
-- Adds the reusable workflow template layer on top of the CC-65 execution
-- engine. Workflow templates describe an ordered, dependency-graphed
-- list of steps. Starting a template against a shipment instantiates one
-- execution.shipment_tasks row per step, plus matching execution
-- task_dependencies. The workflow layer never mutates shipment / booking
-- / dispatch / settlement / invoice records itself — it only emits
-- operational tasks that are subsequently driven through the CC-65 RPCs.
--
-- Additive only. No existing migration is mutated. All write paths flow
-- through SECURITY DEFINER RPCs scoped to platform-admin / buyer /
-- carrier / supplier. Tables are RLS-protected. workflow_events is
-- append-only.

begin;

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
create schema if not exists workflow;
grant usage on schema workflow to anon, authenticated, service_role;
comment on schema workflow is
  'iKIA CC-66 — Reusable workflow template layer. Defines workflow templates, ordered steps, and step dependencies. Starting a template against a shipment instantiates execution.shipment_tasks rows and execution.task_dependencies. Never mutates shipment / booking / dispatch / settlement / invoice records.';

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'workflow' and t.typname = 'workflow_template_status') then
    create type workflow.workflow_template_status as enum (
      'draft', 'active', 'archived'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'workflow' and t.typname = 'workflow_instance_status') then
    create type workflow.workflow_instance_status as enum (
      'draft', 'running', 'completed', 'cancelled', 'failed'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'workflow' and t.typname = 'workflow_step_type') then
    create type workflow.workflow_step_type as enum (
      'task', 'approval', 'checkpoint', 'document', 'system'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'workflow' and t.typname = 'workflow_event_type') then
    create type workflow.workflow_event_type as enum (
      'template_created', 'template_activated', 'template_archived',
      'instance_started', 'step_generated',
      'instance_completed', 'instance_cancelled', 'instance_failed'
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 1. workflow.workflow_templates
-- ---------------------------------------------------------------------------
create table if not exists workflow.workflow_templates (
  id              uuid primary key default extensions.gen_random_uuid(),
  tenant_id       uuid not null references identity.tenants(id) on delete restrict,
  template_code   text not null,
  name            text not null,
  description     text,
  status          workflow.workflow_template_status not null default 'draft',
  domain          text not null default 'shipment',
  applies_to      text not null default 'shipment',
  metadata        jsonb not null default '{}'::jsonb,
  created_by      uuid references auth.users(id),
  created_at      timestamptz not null default now(),
  updated_by      uuid references auth.users(id),
  updated_at      timestamptz not null default now(),
  archived_at     timestamptz,

  constraint workflow_templates_code_unique
    unique (tenant_id, template_code),
  constraint workflow_templates_name_not_blank
    check (length(btrim(name)) > 0),
  constraint workflow_templates_code_not_blank
    check (length(btrim(template_code)) > 0),
  constraint workflow_templates_archived_at_required
    check ((status <> 'archived') or (archived_at is not null)),
  constraint workflow_templates_archived_at_only_when_archived
    check (archived_at is null or status = 'archived')
);

comment on table workflow.workflow_templates is
  'CC-66: reusable workflow template. Lifecycle is draft -> active -> archived. Only active templates may be instantiated.';

create index if not exists workflow_templates_tenant_status_idx
  on workflow.workflow_templates(tenant_id, status);
create index if not exists workflow_templates_domain_idx
  on workflow.workflow_templates(domain);

-- ---------------------------------------------------------------------------
-- 2. workflow.workflow_steps
-- ---------------------------------------------------------------------------
create table if not exists workflow.workflow_steps (
  id                       uuid primary key default extensions.gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  template_id              uuid not null references workflow.workflow_templates(id) on delete cascade,

  step_code                text not null,
  title                    text not null,
  description              text,
  step_type                workflow.workflow_step_type not null default 'task',
  sort_order               int  not null default 100,

  owner_type               execution.task_owner_type not null default 'buyer',
  owner_organization_id    uuid references organization.organizations(id) on delete set null,
  priority                 execution.task_priority not null default 'normal',
  default_due_offset_hours int,

  condition                jsonb not null default '{}'::jsonb,
  metadata                 jsonb not null default '{}'::jsonb,

  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,

  constraint workflow_steps_code_unique
    unique (template_id, step_code),
  constraint workflow_steps_title_not_blank
    check (length(btrim(title)) > 0),
  constraint workflow_steps_code_not_blank
    check (length(btrim(step_code)) > 0),
  constraint workflow_steps_due_offset_nonneg
    check (default_due_offset_hours is null or default_due_offset_hours >= 0)
);

comment on table workflow.workflow_steps is
  'CC-66: an ordered step inside a workflow template. Translates 1:1 into an execution.shipment_tasks row at instantiation time.';

create index if not exists workflow_steps_template_sort_idx
  on workflow.workflow_steps(template_id, sort_order);
create index if not exists workflow_steps_template_alive_idx
  on workflow.workflow_steps(template_id) where deleted_at is null;

-- ---------------------------------------------------------------------------
-- 3. workflow.workflow_step_dependencies
-- ---------------------------------------------------------------------------
create table if not exists workflow.workflow_step_dependencies (
  id                  uuid primary key default extensions.gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  template_id         uuid not null references workflow.workflow_templates(id) on delete cascade,
  step_id             uuid not null references workflow.workflow_steps(id) on delete cascade,
  depends_on_step_id  uuid not null references workflow.workflow_steps(id) on delete cascade,
  dependency_type     text not null default 'finish_to_start',

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),

  constraint workflow_step_dependencies_no_self
    check (step_id <> depends_on_step_id),
  constraint workflow_step_dependencies_unique
    unique (step_id, depends_on_step_id)
);

comment on table workflow.workflow_step_dependencies is
  'CC-66: finish-to-start dependency between two steps in the same template. Translates to execution.task_dependencies on instantiation. Same-template + no 2-node cycle enforced via trigger.';

create index if not exists workflow_step_deps_template_idx
  on workflow.workflow_step_dependencies(template_id);
create index if not exists workflow_step_deps_step_idx
  on workflow.workflow_step_dependencies(step_id);
create index if not exists workflow_step_deps_depends_idx
  on workflow.workflow_step_dependencies(depends_on_step_id);

-- ---------------------------------------------------------------------------
-- 4. workflow.workflow_instances
-- ---------------------------------------------------------------------------
create table if not exists workflow.workflow_instances (
  id              uuid primary key default extensions.gen_random_uuid(),
  tenant_id       uuid not null references identity.tenants(id) on delete restrict,
  template_id     uuid not null references workflow.workflow_templates(id) on delete restrict,
  shipment_id     uuid not null references shipment.shipments(id) on delete cascade,

  status          workflow.workflow_instance_status not null default 'running',

  started_by      uuid references auth.users(id),
  started_at      timestamptz not null default now(),
  completed_at    timestamptz,
  cancelled_at    timestamptz,
  failure_reason  text,
  metadata        jsonb not null default '{}'::jsonb,

  constraint workflow_instances_completed_at_required
    check ((status <> 'completed') or (completed_at is not null)),
  constraint workflow_instances_cancelled_at_required
    check ((status <> 'cancelled') or (cancelled_at is not null)),
  constraint workflow_instances_failure_reason_required
    check ((status <> 'failed') or (failure_reason is not null and length(btrim(failure_reason)) > 0))
);

comment on table workflow.workflow_instances is
  'CC-66: one running execution of a workflow template against a single shipment. At most one active instance per (template, shipment).';

create index if not exists workflow_instances_template_idx
  on workflow.workflow_instances(template_id);
create index if not exists workflow_instances_shipment_idx
  on workflow.workflow_instances(shipment_id);
create index if not exists workflow_instances_status_idx
  on workflow.workflow_instances(status);

create unique index if not exists workflow_instances_template_shipment_active_uq
  on workflow.workflow_instances (template_id, shipment_id)
  where status in ('draft', 'running');

-- ---------------------------------------------------------------------------
-- 5. workflow.workflow_instance_tasks (instance step -> execution task)
-- ---------------------------------------------------------------------------
create table if not exists workflow.workflow_instance_tasks (
  id            uuid primary key default extensions.gen_random_uuid(),
  tenant_id     uuid not null references identity.tenants(id) on delete restrict,
  instance_id   uuid not null references workflow.workflow_instances(id) on delete cascade,
  step_id       uuid not null references workflow.workflow_steps(id) on delete restrict,
  task_id       uuid not null references execution.shipment_tasks(id) on delete cascade,
  created_at    timestamptz not null default now(),

  constraint workflow_instance_tasks_step_unique
    unique (instance_id, step_id),
  constraint workflow_instance_tasks_task_unique
    unique (task_id)
);

comment on table workflow.workflow_instance_tasks is
  'CC-66: bidirectional mapping from (workflow instance + template step) to the generated execution.shipment_tasks row.';

create index if not exists workflow_instance_tasks_instance_idx
  on workflow.workflow_instance_tasks(instance_id);

-- ---------------------------------------------------------------------------
-- 6. workflow.workflow_events  (immutable append-only ledger)
-- ---------------------------------------------------------------------------
create table if not exists workflow.workflow_events (
  id             uuid primary key default extensions.gen_random_uuid(),
  tenant_id      uuid not null references identity.tenants(id) on delete restrict,
  template_id    uuid references workflow.workflow_templates(id) on delete cascade,
  instance_id    uuid references workflow.workflow_instances(id) on delete cascade,
  event_type     workflow.workflow_event_type not null,
  actor_user_id  uuid references auth.users(id),
  payload        jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);

comment on table workflow.workflow_events is
  'CC-66: immutable workflow lifecycle event ledger. No UPDATE / DELETE. Insert only through workflow.fn_record_event() (SECURITY DEFINER).';

create index if not exists workflow_events_template_idx
  on workflow.workflow_events(template_id, created_at);
create index if not exists workflow_events_instance_idx
  on workflow.workflow_events(instance_id, created_at);

-- Block direct UPDATE/DELETE on workflow_events at row level.
create or replace function workflow.fn_block_event_mutation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  raise exception 'workflow: workflow_events is append-only' using errcode = '42501';
end;
$$;

drop trigger if exists trg_workflow_events_no_update on workflow.workflow_events;
create trigger trg_workflow_events_no_update
  before update on workflow.workflow_events
  for each row execute function workflow.fn_block_event_mutation();

drop trigger if exists trg_workflow_events_no_delete on workflow.workflow_events;
create trigger trg_workflow_events_no_delete
  before delete on workflow.workflow_events
  for each row execute function workflow.fn_block_event_mutation();

-- ===========================================================================
-- Internal helpers
-- ===========================================================================

-- Insert a workflow event row.  SECURITY DEFINER bypass of the append-only
-- guard; internal only.
create or replace function workflow.fn_record_event(
  p_tenant_id   uuid,
  p_template_id uuid,
  p_instance_id uuid,
  p_event_type  workflow.workflow_event_type,
  p_payload     jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  insert into workflow.workflow_events (
    tenant_id, template_id, instance_id, event_type,
    actor_user_id, payload
  ) values (
    p_tenant_id, p_template_id, p_instance_id, p_event_type,
    identity.current_user_id(), coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- Read access to templates: platform admin sees all, authenticated users
-- can see any template in their tenant.
create or replace function workflow.fn_assert_can_view_template(p_template_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_user   uuid := identity.current_user_id();
begin
  select tenant_id into v_tenant
    from workflow.workflow_templates where id = p_template_id;
  if v_tenant is null then
    raise exception 'workflow: template not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'workflow: template not visible' using errcode = '42501';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.tenant_id = v_tenant
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  raise exception 'workflow: template not visible to caller' using errcode = '42501';
end;
$$;

-- Manage access: platform admin only.
create or replace function workflow.fn_assert_can_manage_template(p_template_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: template management requires platform admin'
      using errcode = '42501';
  end if;
  if p_template_id is not null and not exists (
    select 1 from workflow.workflow_templates where id = p_template_id
  ) then
    raise exception 'workflow: template not found' using errcode = 'P0002';
  end if;
end;
$$;

-- Instance visibility: admin / buyer-org / carrier-org / supplier-org all
-- on the underlying shipment.  Supplier and carrier may also see an
-- instance whenever any generated execution task is owned by their
-- organisation.
create or replace function workflow.fn_assert_can_view_instance(p_instance_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_shipment uuid;
  v_user     uuid := identity.current_user_id();
  v_buyer    uuid; v_supplier uuid; v_carrier uuid;
begin
  select shipment_id into v_shipment
    from workflow.workflow_instances where id = p_instance_id;
  if v_shipment is null then
    raise exception 'workflow: instance not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'workflow: instance not visible' using errcode = '42501';
  end if;
  select organization_id, supplier_organization_id, carrier_organization_id
    into v_buyer, v_supplier, v_carrier
    from shipment.shipments
   where id = v_shipment and deleted_at is null;
  if v_buyer is null then
    raise exception 'workflow: shipment not found' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id in (v_buyer, v_supplier, v_carrier)
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  -- Fallback: any generated task owned by the caller's org grants visibility.
  if exists (
    select 1
      from workflow.workflow_instance_tasks wit
      join execution.shipment_tasks t on t.id = wit.task_id
      join organization.memberships m
        on m.organization_id = t.owner_organization_id
       and m.user_id = v_user
       and m.deleted_at is null and m.status = 'active'
     where wit.instance_id = p_instance_id
  ) then return; end if;
  raise exception 'workflow: instance not visible to caller' using errcode = '42501';
end;
$$;

-- Caller may start a workflow against this shipment when they are an
-- active member of the buyer organisation (or platform admin).
create or replace function workflow.fn_assert_can_start_workflow_for_shipment(p_shipment_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid;
  v_user  uuid := identity.current_user_id();
begin
  select organization_id into v_buyer
    from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'workflow: shipment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'workflow: anonymous cannot start workflow' using errcode = '42501';
  end if;
  if not exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id = v_buyer
       and m.deleted_at is null and m.status = 'active'
  ) then
    raise exception 'workflow: only buyer-org members may start workflow on this shipment'
      using errcode = '42501';
  end if;
end;
$$;

-- Validate step-dependency insert: both steps in same template + no
-- simple 2-node cycle.
create or replace function workflow.fn_trg_validate_step_dependency()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_tpl_a uuid; v_tpl_b uuid;
begin
  select template_id into v_tpl_a
    from workflow.workflow_steps where id = new.step_id;
  select template_id into v_tpl_b
    from workflow.workflow_steps where id = new.depends_on_step_id;
  if v_tpl_a is null or v_tpl_b is null then
    raise exception 'workflow: step-dependency rows must reference existing steps'
      using errcode = 'P0002';
  end if;
  if v_tpl_a <> v_tpl_b then
    raise exception 'workflow: step dependency must stay within same template'
      using errcode = '22023';
  end if;
  if new.template_id <> v_tpl_a then
    raise exception 'workflow: step dependency template_id mismatch'
      using errcode = '22023';
  end if;
  if exists (
    select 1 from workflow.workflow_step_dependencies
     where step_id = new.depends_on_step_id
       and depends_on_step_id = new.step_id
  ) then
    raise exception 'workflow: step dependency would create a 2-node cycle'
      using errcode = '22023';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_workflow_step_deps_validate on workflow.workflow_step_dependencies;
create trigger trg_workflow_step_deps_validate
  before insert on workflow.workflow_step_dependencies
  for each row execute function workflow.fn_trg_validate_step_dependency();

-- Generate execution tasks + dependencies + mapping rows for an instance.
-- Internal helper used by both admin_start_workflow and buyer_start_workflow.
create or replace function workflow.fn_generate_tasks_for_instance(
  p_instance_id      uuid,
  p_actor_owner_type execution.task_owner_type default 'system'
) returns int
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_instance   workflow.workflow_instances%rowtype;
  v_template   workflow.workflow_templates%rowtype;
  v_user       uuid := identity.current_user_id();
  v_count      int  := 0;
  v_step       record;
  v_dep        record;
  v_task_id    uuid;
  v_src_task   uuid;
  v_dst_task   uuid;
begin
  select * into v_instance from workflow.workflow_instances where id = p_instance_id;
  if v_instance.id is null then
    raise exception 'workflow: instance not found' using errcode = 'P0002';
  end if;
  select * into v_template from workflow.workflow_templates where id = v_instance.template_id;

  for v_step in
    select * from workflow.workflow_steps
     where template_id = v_instance.template_id
       and deleted_at is null
     order by sort_order, step_code
  loop
    insert into execution.shipment_tasks (
      tenant_id, shipment_id, task_code, title, description,
      owner_type, owner_organization_id,
      priority, due_at, metadata, created_by, updated_by
    ) values (
      v_instance.tenant_id,
      v_instance.shipment_id,
      'WF-' || replace(extensions.gen_random_uuid()::text, '-', ''),
      v_step.title,
      v_step.description,
      v_step.owner_type,
      v_step.owner_organization_id,
      v_step.priority,
      case
        when v_step.default_due_offset_hours is null then null
        else now() + (v_step.default_due_offset_hours * interval '1 hour')
      end,
      jsonb_build_object(
        'workflow_instance_id', v_instance.id,
        'workflow_step_id',     v_step.id,
        'workflow_template_id', v_instance.template_id,
        'step_type',            v_step.step_type,
        'condition',            v_step.condition
      ) || coalesce(v_step.metadata, '{}'::jsonb),
      v_user, v_user
    )
    returning id into v_task_id;

    insert into workflow.workflow_instance_tasks (
      tenant_id, instance_id, step_id, task_id
    ) values (
      v_instance.tenant_id, v_instance.id, v_step.id, v_task_id
    );

    perform execution.fn_record_task_event(
      v_task_id, 'task.created', null, 'open',
      p_actor_owner_type,
      jsonb_build_object(
        'workflow_instance_id', v_instance.id,
        'workflow_step_id',     v_step.id,
        'workflow_template_id', v_instance.template_id
      )
    );

    perform workflow.fn_record_event(
      v_instance.tenant_id, v_instance.template_id, v_instance.id,
      'step_generated'::workflow.workflow_event_type,
      jsonb_build_object('step_id', v_step.id, 'task_id', v_task_id)
    );

    v_count := v_count + 1;
  end loop;

  -- Translate step-dependency edges into task-dependency edges.
  for v_dep in
    select d.step_id, d.depends_on_step_id, d.dependency_type
      from workflow.workflow_step_dependencies d
     where d.template_id = v_instance.template_id
  loop
    select task_id into v_src_task
      from workflow.workflow_instance_tasks
     where instance_id = v_instance.id and step_id = v_dep.step_id;
    select task_id into v_dst_task
      from workflow.workflow_instance_tasks
     where instance_id = v_instance.id and step_id = v_dep.depends_on_step_id;
    if v_src_task is not null and v_dst_task is not null then
      insert into execution.task_dependencies (
        tenant_id, task_id, depends_on_task_id, dependency_type, created_by
      ) values (
        v_instance.tenant_id, v_src_task, v_dst_task,
        coalesce(v_dep.dependency_type, 'finish_to_start'), v_user
      )
      on conflict do nothing;
    end if;
  end loop;

  return v_count;
end;
$$;

-- ===========================================================================
-- Admin template RPCs
-- ===========================================================================

create or replace function workflow.admin_create_template(
  p_template_code text,
  p_name          text,
  p_description   text default null,
  p_domain        text default 'shipment',
  p_applies_to    text default 'shipment',
  p_metadata      jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user   uuid := identity.current_user_id();
  v_tenant uuid;
  v_id     uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  if v_user is null then
    raise exception 'workflow: anonymous' using errcode = '42501';
  end if;
  if p_template_code is null or length(btrim(p_template_code)) = 0 then
    raise exception 'workflow: template_code required' using errcode = '22023';
  end if;
  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'workflow: name required' using errcode = '22023';
  end if;
  v_tenant := identity.current_tenant_id();
  if v_tenant is null then
    select id into v_tenant from identity.tenants order by created_at limit 1;
  end if;
  if v_tenant is null then
    raise exception 'workflow: no tenant context' using errcode = '22023';
  end if;
  insert into workflow.workflow_templates (
    tenant_id, template_code, name, description, status,
    domain, applies_to, metadata, created_by, updated_by
  ) values (
    v_tenant, p_template_code, p_name, p_description, 'draft',
    coalesce(p_domain, 'shipment'),
    coalesce(p_applies_to, 'shipment'),
    coalesce(p_metadata, '{}'::jsonb),
    v_user, v_user
  )
  returning id into v_id;
  perform workflow.fn_record_event(
    v_tenant, v_id, null,
    'template_created'::workflow.workflow_event_type,
    jsonb_build_object('template_code', p_template_code, 'name', p_name)
  );
  return v_id;
end;
$$;

create or replace function workflow.admin_update_template(
  p_template_id uuid,
  p_name        text default null,
  p_description text default null,
  p_metadata    jsonb default null
) returns workflow.workflow_templates
language plpgsql volatile security definer set search_path = ''
as $$
declare v workflow.workflow_templates;
begin
  perform workflow.fn_assert_can_manage_template(p_template_id);
  update workflow.workflow_templates
     set name        = coalesce(p_name, name),
         description = coalesce(p_description, description),
         metadata    = coalesce(p_metadata, metadata),
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_template_id
  returning * into v;
  return v;
end;
$$;

create or replace function workflow.admin_activate_template(p_template_id uuid)
returns workflow.workflow_templates
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v workflow.workflow_templates;
  v_steps int;
begin
  perform workflow.fn_assert_can_manage_template(p_template_id);
  select count(*)::int into v_steps
    from workflow.workflow_steps
   where template_id = p_template_id and deleted_at is null;
  if v_steps = 0 then
    raise exception 'workflow: cannot activate template with zero steps'
      using errcode = '22023';
  end if;
  update workflow.workflow_templates
     set status      = 'active',
         archived_at = null,
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_template_id
  returning * into v;
  perform workflow.fn_record_event(
    v.tenant_id, v.id, null,
    'template_activated'::workflow.workflow_event_type,
    jsonb_build_object('step_count', v_steps)
  );
  return v;
end;
$$;

create or replace function workflow.admin_archive_template(p_template_id uuid)
returns workflow.workflow_templates
language plpgsql volatile security definer set search_path = ''
as $$
declare v workflow.workflow_templates;
begin
  perform workflow.fn_assert_can_manage_template(p_template_id);
  update workflow.workflow_templates
     set status      = 'archived',
         archived_at = now(),
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_template_id
  returning * into v;
  perform workflow.fn_record_event(
    v.tenant_id, v.id, null,
    'template_archived'::workflow.workflow_event_type,
    '{}'::jsonb
  );
  return v;
end;
$$;

create or replace function workflow.admin_add_step(
  p_template_id              uuid,
  p_step_code                text,
  p_title                    text,
  p_description              text default null,
  p_step_type                workflow.workflow_step_type default 'task',
  p_sort_order               int default 100,
  p_owner_type               execution.task_owner_type default 'buyer',
  p_owner_organization_id    uuid default null,
  p_priority                 execution.task_priority default 'normal',
  p_default_due_offset_hours int default null,
  p_condition                jsonb default '{}'::jsonb,
  p_metadata                 jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user   uuid := identity.current_user_id();
  v_tenant uuid;
  v_status workflow.workflow_template_status;
  v_id     uuid;
begin
  perform workflow.fn_assert_can_manage_template(p_template_id);
  select tenant_id, status into v_tenant, v_status
    from workflow.workflow_templates where id = p_template_id;
  if v_status = 'archived' then
    raise exception 'workflow: cannot add step to archived template'
      using errcode = '22023';
  end if;
  if p_step_code is null or length(btrim(p_step_code)) = 0 then
    raise exception 'workflow: step_code required' using errcode = '22023';
  end if;
  if p_title is null or length(btrim(p_title)) = 0 then
    raise exception 'workflow: title required' using errcode = '22023';
  end if;
  insert into workflow.workflow_steps (
    tenant_id, template_id, step_code, title, description, step_type,
    sort_order, owner_type, owner_organization_id, priority,
    default_due_offset_hours, condition, metadata, created_by, updated_by
  ) values (
    v_tenant, p_template_id, p_step_code, p_title, p_description,
    coalesce(p_step_type, 'task'::workflow.workflow_step_type),
    coalesce(p_sort_order, 100),
    coalesce(p_owner_type, 'buyer'::execution.task_owner_type),
    p_owner_organization_id,
    coalesce(p_priority, 'normal'::execution.task_priority),
    p_default_due_offset_hours,
    coalesce(p_condition, '{}'::jsonb),
    coalesce(p_metadata, '{}'::jsonb),
    v_user, v_user
  )
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function workflow.admin_update_step(
  p_step_id                  uuid,
  p_title                    text default null,
  p_description              text default null,
  p_sort_order               int default null,
  p_owner_type               execution.task_owner_type default null,
  p_owner_organization_id    uuid default null,
  p_priority                 execution.task_priority default null,
  p_default_due_offset_hours int default null,
  p_condition                jsonb default null,
  p_metadata                 jsonb default null
) returns workflow.workflow_steps
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_template uuid;
  v_status workflow.workflow_template_status;
  v workflow.workflow_steps;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  select template_id into v_template
    from workflow.workflow_steps where id = p_step_id and deleted_at is null;
  if v_template is null then
    raise exception 'workflow: step not found' using errcode = 'P0002';
  end if;
  select status into v_status
    from workflow.workflow_templates where id = v_template;
  if v_status = 'archived' then
    raise exception 'workflow: cannot update step on archived template'
      using errcode = '22023';
  end if;
  update workflow.workflow_steps
     set title                    = coalesce(p_title, title),
         description              = coalesce(p_description, description),
         sort_order               = coalesce(p_sort_order, sort_order),
         owner_type               = coalesce(p_owner_type, owner_type),
         owner_organization_id    = coalesce(p_owner_organization_id, owner_organization_id),
         priority                 = coalesce(p_priority, priority),
         default_due_offset_hours = coalesce(p_default_due_offset_hours, default_due_offset_hours),
         condition                = coalesce(p_condition, condition),
         metadata                 = coalesce(p_metadata, metadata),
         updated_by               = identity.current_user_id(),
         updated_at               = now()
   where id = p_step_id
  returning * into v;
  return v;
end;
$$;

create or replace function workflow.admin_add_step_dependency(
  p_step_id            uuid,
  p_depends_on_step_id uuid,
  p_dependency_type    text default 'finish_to_start'
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant   uuid;
  v_template uuid;
  v_status   workflow.workflow_template_status;
  v_id       uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  if p_step_id = p_depends_on_step_id then
    raise exception 'workflow: step cannot depend on itself' using errcode = '22023';
  end if;
  select tenant_id, template_id into v_tenant, v_template
    from workflow.workflow_steps where id = p_step_id and deleted_at is null;
  if v_tenant is null then
    raise exception 'workflow: step not found' using errcode = 'P0002';
  end if;
  select status into v_status
    from workflow.workflow_templates where id = v_template;
  if v_status = 'archived' then
    raise exception 'workflow: cannot add dependency on archived template'
      using errcode = '22023';
  end if;
  insert into workflow.workflow_step_dependencies (
    tenant_id, template_id, step_id, depends_on_step_id,
    dependency_type, created_by
  ) values (
    v_tenant, v_template, p_step_id, p_depends_on_step_id,
    coalesce(p_dependency_type, 'finish_to_start'),
    identity.current_user_id()
  )
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function workflow.admin_list_templates(
  p_status workflow.workflow_template_status default null,
  p_limit  int default 50,
  p_offset int default 0
) returns setof workflow.workflow_templates
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  return query
    select t.*
      from workflow.workflow_templates t
     where (p_status is null or t.status = p_status)
     order by t.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function workflow.admin_get_template(p_template_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_tpl   workflow.workflow_templates;
  v_steps jsonb;
  v_deps  jsonb;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  select * into v_tpl from workflow.workflow_templates where id = p_template_id;
  if v_tpl.id is null then
    raise exception 'workflow: template not found' using errcode = 'P0002';
  end if;
  select coalesce(jsonb_agg(row_to_json(s)::jsonb order by s.sort_order, s.step_code), '[]'::jsonb)
    into v_steps
    from workflow.workflow_steps s
   where s.template_id = p_template_id and s.deleted_at is null;
  select coalesce(jsonb_agg(row_to_json(d)::jsonb), '[]'::jsonb)
    into v_deps
    from workflow.workflow_step_dependencies d
   where d.template_id = p_template_id;
  return jsonb_build_object(
    'template',     row_to_json(v_tpl)::jsonb,
    'steps',        v_steps,
    'dependencies', v_deps
  );
end;
$$;

-- ===========================================================================
-- Admin instance RPCs
-- ===========================================================================

create or replace function workflow.admin_start_workflow(
  p_template_id uuid,
  p_shipment_id uuid,
  p_metadata    jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user        uuid := identity.current_user_id();
  v_tenant      uuid;
  v_tpl_status  workflow.workflow_template_status;
  v_ship_tenant uuid;
  v_instance_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  select tenant_id, status into v_tenant, v_tpl_status
    from workflow.workflow_templates where id = p_template_id;
  if v_tenant is null then
    raise exception 'workflow: template not found' using errcode = 'P0002';
  end if;
  if v_tpl_status <> 'active' then
    raise exception 'workflow: only active templates can be instantiated'
      using errcode = '22023';
  end if;
  select tenant_id into v_ship_tenant
    from shipment.shipments where id = p_shipment_id and deleted_at is null;
  if v_ship_tenant is null then
    raise exception 'workflow: shipment not found' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from workflow.workflow_instances
     where template_id = p_template_id and shipment_id = p_shipment_id
       and status in ('draft','running')
  ) then
    raise exception 'workflow: an active instance already exists for this template+shipment'
      using errcode = '23505';
  end if;
  insert into workflow.workflow_instances (
    tenant_id, template_id, shipment_id, status, started_by, metadata
  ) values (
    v_ship_tenant, p_template_id, p_shipment_id, 'running', v_user,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_instance_id;
  perform workflow.fn_record_event(
    v_ship_tenant, p_template_id, v_instance_id,
    'instance_started'::workflow.workflow_event_type,
    jsonb_build_object('shipment_id', p_shipment_id, 'actor', 'admin')
  );
  perform workflow.fn_generate_tasks_for_instance(
    v_instance_id, 'admin'::execution.task_owner_type
  );
  return v_instance_id;
end;
$$;

create or replace function workflow.admin_list_instances(
  p_status     workflow.workflow_instance_status default null,
  p_shipment_id uuid default null,
  p_limit      int default 50,
  p_offset     int default 0
) returns setof workflow.workflow_instances
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  return query
    select i.*
      from workflow.workflow_instances i
     where (p_status is null or i.status = p_status)
       and (p_shipment_id is null or i.shipment_id = p_shipment_id)
     order by i.started_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function workflow.admin_get_instance(p_instance_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_inst  workflow.workflow_instances;
  v_tasks jsonb;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  select * into v_inst from workflow.workflow_instances where id = p_instance_id;
  if v_inst.id is null then
    raise exception 'workflow: instance not found' using errcode = 'P0002';
  end if;
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'step_id',    wit.step_id,
      'task_id',    wit.task_id,
      'task_status', t.status,
      'title',      t.title,
      'owner_type', t.owner_type,
      'due_at',     t.due_at
    )
  ), '[]'::jsonb)
    into v_tasks
    from workflow.workflow_instance_tasks wit
    join execution.shipment_tasks t on t.id = wit.task_id
   where wit.instance_id = p_instance_id;
  return jsonb_build_object(
    'instance', row_to_json(v_inst)::jsonb,
    'tasks',    v_tasks
  );
end;
$$;

create or replace function workflow.admin_cancel_instance(
  p_instance_id uuid,
  p_reason      text default null
) returns workflow.workflow_instances
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v workflow.workflow_instances;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  select * into v from workflow.workflow_instances where id = p_instance_id;
  if v.id is null then
    raise exception 'workflow: instance not found' using errcode = 'P0002';
  end if;
  if v.status not in ('draft','running') then
    raise exception 'workflow: cannot cancel instance in status %', v.status
      using errcode = '22023';
  end if;
  update workflow.workflow_instances
     set status       = 'cancelled',
         cancelled_at = now(),
         metadata     = coalesce(metadata, '{}'::jsonb)
                        || jsonb_build_object('cancel_reason', coalesce(p_reason, ''))
   where id = p_instance_id
  returning * into v;
  perform workflow.fn_record_event(
    v.tenant_id, v.template_id, v.id,
    'instance_cancelled'::workflow.workflow_event_type,
    jsonb_build_object('reason', coalesce(p_reason, ''))
  );
  return v;
end;
$$;

create or replace function workflow.admin_recalculate_instance_status(p_instance_id uuid)
returns workflow.workflow_instances
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v workflow.workflow_instances;
  v_total int; v_done int; v_cancelled int;
begin
  if not identity.is_platform_admin() then
    raise exception 'workflow: admin only' using errcode = '42501';
  end if;
  select * into v from workflow.workflow_instances where id = p_instance_id;
  if v.id is null then
    raise exception 'workflow: instance not found' using errcode = 'P0002';
  end if;
  if v.status not in ('draft','running') then
    return v;
  end if;
  select count(*)::int,
         count(*) filter (where t.status = 'completed')::int,
         count(*) filter (where t.status = 'cancelled')::int
    into v_total, v_done, v_cancelled
    from workflow.workflow_instance_tasks wit
    join execution.shipment_tasks t on t.id = wit.task_id
   where wit.instance_id = p_instance_id
     and t.deleted_at is null;
  if v_total > 0 and (v_done + v_cancelled) = v_total then
    update workflow.workflow_instances
       set status = 'completed', completed_at = now()
     where id = p_instance_id
    returning * into v;
    perform workflow.fn_record_event(
      v.tenant_id, v.template_id, v.id,
      'instance_completed'::workflow.workflow_event_type,
      jsonb_build_object(
        'total', v_total, 'completed', v_done, 'cancelled', v_cancelled
      )
    );
  end if;
  return v;
end;
$$;

-- ===========================================================================
-- Buyer RPCs
-- ===========================================================================

create or replace function workflow.buyer_list_available_templates(
  p_limit  int default 50,
  p_offset int default 0
) returns setof workflow.workflow_templates
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'workflow: anonymous' using errcode = '42501';
  end if;
  return query
    select t.*
      from workflow.workflow_templates t
     where t.status = 'active'
       and (
         identity.is_platform_admin()
         or exists (
           select 1 from organization.memberships m
            where m.user_id = v_user
              and m.tenant_id = t.tenant_id
              and m.deleted_at is null and m.status = 'active'
         )
       )
     order by t.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function workflow.buyer_start_workflow(
  p_template_id uuid,
  p_shipment_id uuid,
  p_metadata    jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user        uuid := identity.current_user_id();
  v_tenant      uuid;
  v_tpl_status  workflow.workflow_template_status;
  v_ship_tenant uuid;
  v_instance_id uuid;
begin
  if v_user is null then
    raise exception 'workflow: anonymous cannot start workflow' using errcode = '42501';
  end if;
  perform workflow.fn_assert_can_start_workflow_for_shipment(p_shipment_id);
  select tenant_id, status into v_tenant, v_tpl_status
    from workflow.workflow_templates where id = p_template_id;
  if v_tenant is null then
    raise exception 'workflow: template not found' using errcode = 'P0002';
  end if;
  if v_tpl_status <> 'active' then
    raise exception 'workflow: only active templates can be instantiated'
      using errcode = '22023';
  end if;
  select tenant_id into v_ship_tenant
    from shipment.shipments where id = p_shipment_id and deleted_at is null;
  if v_ship_tenant is null then
    raise exception 'workflow: shipment not found' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from workflow.workflow_instances
     where template_id = p_template_id and shipment_id = p_shipment_id
       and status in ('draft','running')
  ) then
    raise exception 'workflow: an active instance already exists for this template+shipment'
      using errcode = '23505';
  end if;
  insert into workflow.workflow_instances (
    tenant_id, template_id, shipment_id, status, started_by, metadata
  ) values (
    v_ship_tenant, p_template_id, p_shipment_id, 'running', v_user,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into v_instance_id;
  perform workflow.fn_record_event(
    v_ship_tenant, p_template_id, v_instance_id,
    'instance_started'::workflow.workflow_event_type,
    jsonb_build_object('shipment_id', p_shipment_id, 'actor', 'buyer')
  );
  perform workflow.fn_generate_tasks_for_instance(
    v_instance_id, 'buyer'::execution.task_owner_type
  );
  return v_instance_id;
end;
$$;

create or replace function workflow.buyer_list_instances(
  p_status     workflow.workflow_instance_status default null,
  p_shipment_id uuid default null,
  p_limit      int default 50,
  p_offset     int default 0
) returns setof workflow.workflow_instances
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'workflow: anonymous' using errcode = '42501';
  end if;
  return query
    select i.*
      from workflow.workflow_instances i
      join shipment.shipments s on s.id = i.shipment_id
     where s.deleted_at is null
       and (p_status is null or i.status = p_status)
       and (p_shipment_id is null or i.shipment_id = p_shipment_id)
       and exists (
         select 1 from organization.memberships m
          where m.user_id = v_user
            and m.organization_id = s.organization_id
            and m.deleted_at is null and m.status = 'active'
       )
     order by i.started_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function workflow.buyer_get_instance(p_instance_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_inst  workflow.workflow_instances;
  v_tasks jsonb;
begin
  perform workflow.fn_assert_can_view_instance(p_instance_id);
  select * into v_inst from workflow.workflow_instances where id = p_instance_id;
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'step_id', wit.step_id,
      'task_id', wit.task_id,
      'task_status', t.status,
      'title', t.title,
      'owner_type', t.owner_type,
      'due_at', t.due_at
    )
  ), '[]'::jsonb)
    into v_tasks
    from workflow.workflow_instance_tasks wit
    join execution.shipment_tasks t on t.id = wit.task_id
   where wit.instance_id = p_instance_id;
  return jsonb_build_object(
    'instance', row_to_json(v_inst)::jsonb,
    'tasks',    v_tasks
  );
end;
$$;

-- ===========================================================================
-- Carrier RPCs
-- ===========================================================================

create or replace function workflow.carrier_list_instances(
  p_status     workflow.workflow_instance_status default null,
  p_shipment_id uuid default null,
  p_limit      int default 50,
  p_offset     int default 0
) returns setof workflow.workflow_instances
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'workflow: anonymous' using errcode = '42501';
  end if;
  return query
    select distinct i.*
      from workflow.workflow_instances i
      join shipment.shipments s on s.id = i.shipment_id
     where s.deleted_at is null
       and (p_status is null or i.status = p_status)
       and (p_shipment_id is null or i.shipment_id = p_shipment_id)
       and (
         exists (
           select 1 from organization.memberships m
            where m.user_id = v_user
              and m.organization_id = s.carrier_organization_id
              and m.deleted_at is null and m.status = 'active'
         )
         or exists (
           select 1
             from workflow.workflow_instance_tasks wit
             join execution.shipment_tasks t on t.id = wit.task_id
             join organization.memberships m
               on m.organization_id = t.owner_organization_id
              and m.user_id = v_user
              and m.deleted_at is null and m.status = 'active'
            where wit.instance_id = i.id
         )
       )
     order by i.started_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function workflow.carrier_get_instance(p_instance_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_inst  workflow.workflow_instances;
  v_tasks jsonb;
begin
  perform workflow.fn_assert_can_view_instance(p_instance_id);
  select * into v_inst from workflow.workflow_instances where id = p_instance_id;
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'step_id', wit.step_id,
      'task_id', wit.task_id,
      'task_status', t.status,
      'title', t.title,
      'owner_type', t.owner_type,
      'due_at', t.due_at
    )
  ), '[]'::jsonb)
    into v_tasks
    from workflow.workflow_instance_tasks wit
    join execution.shipment_tasks t on t.id = wit.task_id
   where wit.instance_id = p_instance_id;
  return jsonb_build_object(
    'instance', row_to_json(v_inst)::jsonb,
    'tasks',    v_tasks
  );
end;
$$;

-- ===========================================================================
-- Supplier RPCs
-- ===========================================================================

create or replace function workflow.supplier_list_instances(
  p_status     workflow.workflow_instance_status default null,
  p_shipment_id uuid default null,
  p_limit      int default 50,
  p_offset     int default 0
) returns setof workflow.workflow_instances
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'workflow: anonymous' using errcode = '42501';
  end if;
  return query
    select distinct i.*
      from workflow.workflow_instances i
      join shipment.shipments s on s.id = i.shipment_id
     where s.deleted_at is null
       and (p_status is null or i.status = p_status)
       and (p_shipment_id is null or i.shipment_id = p_shipment_id)
       and (
         exists (
           select 1 from organization.memberships m
            where m.user_id = v_user
              and m.organization_id = s.supplier_organization_id
              and m.deleted_at is null and m.status = 'active'
         )
         or exists (
           select 1
             from workflow.workflow_instance_tasks wit
             join execution.shipment_tasks t on t.id = wit.task_id
             join organization.memberships m
               on m.organization_id = t.owner_organization_id
              and m.user_id = v_user
              and m.deleted_at is null and m.status = 'active'
            where wit.instance_id = i.id
         )
       )
     order by i.started_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function workflow.supplier_get_instance(p_instance_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_inst  workflow.workflow_instances;
  v_tasks jsonb;
begin
  perform workflow.fn_assert_can_view_instance(p_instance_id);
  select * into v_inst from workflow.workflow_instances where id = p_instance_id;
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'step_id', wit.step_id,
      'task_id', wit.task_id,
      'task_status', t.status,
      'title', t.title,
      'owner_type', t.owner_type,
      'due_at', t.due_at
    )
  ), '[]'::jsonb)
    into v_tasks
    from workflow.workflow_instance_tasks wit
    join execution.shipment_tasks t on t.id = wit.task_id
   where wit.instance_id = p_instance_id;
  return jsonb_build_object(
    'instance', row_to_json(v_inst)::jsonb,
    'tasks',    v_tasks
  );
end;
$$;

-- ===========================================================================
-- Row-level security
-- ===========================================================================

alter table workflow.workflow_templates         enable row level security;
alter table workflow.workflow_steps             enable row level security;
alter table workflow.workflow_step_dependencies enable row level security;
alter table workflow.workflow_instances         enable row level security;
alter table workflow.workflow_instance_tasks    enable row level security;
alter table workflow.workflow_events            enable row level security;

drop policy if exists workflow_templates_select on workflow.workflow_templates;
create policy workflow_templates_select on workflow.workflow_templates
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.tenant_id = workflow.workflow_templates.tenant_id
         and m.deleted_at is null and m.status = 'active'
    )
  );

drop policy if exists workflow_steps_select on workflow.workflow_steps;
create policy workflow_steps_select on workflow.workflow_steps
  for select using (
    deleted_at is null and (
      identity.is_platform_admin()
      or exists (
        select 1 from workflow.workflow_templates tpl
         where tpl.id = workflow.workflow_steps.template_id
           and exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.tenant_id = tpl.tenant_id
                and m.deleted_at is null and m.status = 'active'
           )
      )
    )
  );

drop policy if exists workflow_step_deps_select on workflow.workflow_step_dependencies;
create policy workflow_step_deps_select on workflow.workflow_step_dependencies
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from workflow.workflow_templates tpl
       where tpl.id = workflow.workflow_step_dependencies.template_id
         and exists (
           select 1 from organization.memberships m
            where m.user_id = identity.current_user_id()
              and m.tenant_id = tpl.tenant_id
              and m.deleted_at is null and m.status = 'active'
         )
    )
  );

-- Visibility on instances + mappings is gated to active org membership on
-- the related shipment (buyer / supplier / carrier).  The richer
-- "task-owner fallback" lives in the SECURITY DEFINER RPCs to avoid
-- mutual-recursive policy references between workflow_instances and
-- workflow_instance_tasks.
drop policy if exists workflow_instances_select on workflow.workflow_instances;
create policy workflow_instances_select on workflow.workflow_instances
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from shipment.shipments s
       where s.id = workflow.workflow_instances.shipment_id
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
  );

drop policy if exists workflow_instance_tasks_select on workflow.workflow_instance_tasks;
create policy workflow_instance_tasks_select on workflow.workflow_instance_tasks
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from execution.shipment_tasks t
       where t.id = workflow.workflow_instance_tasks.task_id
         and t.deleted_at is null
         and (
           t.assigned_user_id = identity.current_user_id()
           or (t.owner_organization_id is not null and exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = t.owner_organization_id
                and m.deleted_at is null and m.status = 'active'
           ))
           or exists (
             select 1 from shipment.shipments s
              where s.id = t.shipment_id
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
    )
  );

drop policy if exists workflow_events_select on workflow.workflow_events;
create policy workflow_events_select on workflow.workflow_events
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from workflow.workflow_instances i
        join shipment.shipments s on s.id = i.shipment_id
       where i.id = workflow.workflow_events.instance_id
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
  );

-- ===========================================================================
-- Notification integration — emit category 'other' for key lifecycle events.
-- ===========================================================================
create or replace function notify.fn_trg_from_workflow_event()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_emit boolean;
  v_subject_id uuid;
  v_subject_type text;
begin
  v_emit := new.event_type in (
    'instance_started', 'instance_completed',
    'instance_cancelled', 'instance_failed',
    'template_activated'
  );
  if not v_emit then return new; end if;

  if new.instance_id is not null then
    v_subject_id := new.instance_id;
    v_subject_type := 'workflow_instance';
  else
    v_subject_id := new.template_id;
    v_subject_type := 'workflow_template';
  end if;
  if v_subject_id is null then
    return new;
  end if;
  begin
    perform notify.fn_materialize_event(
      ('workflow.' || new.event_type::text),
      v_subject_type,
      v_subject_id,
      new.id,
      'other'::notify.notification_category,
      jsonb_build_object(
        'event_type', new.event_type,
        'template_id', new.template_id,
        'instance_id', new.instance_id
      ),
      new.tenant_id
    );
  exception when others then
    null;
  end;
  return new;
end;
$$;

drop trigger if exists trg_workflow_event_notify on workflow.workflow_events;
create trigger trg_workflow_event_notify
  after insert on workflow.workflow_events
  for each row execute function notify.fn_trg_from_workflow_event();

-- ===========================================================================
-- Grants
-- ===========================================================================

-- Read tables (RLS-gated).
grant select on workflow.workflow_templates         to authenticated;
grant select on workflow.workflow_steps             to authenticated;
grant select on workflow.workflow_step_dependencies to authenticated;
grant select on workflow.workflow_instances         to authenticated;
grant select on workflow.workflow_instance_tasks    to authenticated;
grant select on workflow.workflow_events            to authenticated;

-- Lock down public/anon on all RPCs and grant execute to authenticated.
revoke all on function workflow.admin_create_template(text, text, text, text, text, jsonb) from public, anon;
grant execute on function workflow.admin_create_template(text, text, text, text, text, jsonb) to authenticated;

revoke all on function workflow.admin_update_template(uuid, text, text, jsonb) from public, anon;
grant execute on function workflow.admin_update_template(uuid, text, text, jsonb) to authenticated;

revoke all on function workflow.admin_activate_template(uuid) from public, anon;
grant execute on function workflow.admin_activate_template(uuid) to authenticated;

revoke all on function workflow.admin_archive_template(uuid) from public, anon;
grant execute on function workflow.admin_archive_template(uuid) to authenticated;

revoke all on function workflow.admin_add_step(uuid, text, text, text,
  workflow.workflow_step_type, int, execution.task_owner_type, uuid,
  execution.task_priority, int, jsonb, jsonb) from public, anon;
grant execute on function workflow.admin_add_step(uuid, text, text, text,
  workflow.workflow_step_type, int, execution.task_owner_type, uuid,
  execution.task_priority, int, jsonb, jsonb) to authenticated;

revoke all on function workflow.admin_update_step(uuid, text, text, int,
  execution.task_owner_type, uuid, execution.task_priority, int, jsonb, jsonb) from public, anon;
grant execute on function workflow.admin_update_step(uuid, text, text, int,
  execution.task_owner_type, uuid, execution.task_priority, int, jsonb, jsonb) to authenticated;

revoke all on function workflow.admin_add_step_dependency(uuid, uuid, text) from public, anon;
grant execute on function workflow.admin_add_step_dependency(uuid, uuid, text) to authenticated;

revoke all on function workflow.admin_list_templates(workflow.workflow_template_status, int, int) from public, anon;
grant execute on function workflow.admin_list_templates(workflow.workflow_template_status, int, int) to authenticated;

revoke all on function workflow.admin_get_template(uuid) from public, anon;
grant execute on function workflow.admin_get_template(uuid) to authenticated;

revoke all on function workflow.admin_start_workflow(uuid, uuid, jsonb) from public, anon;
grant execute on function workflow.admin_start_workflow(uuid, uuid, jsonb) to authenticated;

revoke all on function workflow.admin_list_instances(workflow.workflow_instance_status, uuid, int, int) from public, anon;
grant execute on function workflow.admin_list_instances(workflow.workflow_instance_status, uuid, int, int) to authenticated;

revoke all on function workflow.admin_get_instance(uuid) from public, anon;
grant execute on function workflow.admin_get_instance(uuid) to authenticated;

revoke all on function workflow.admin_cancel_instance(uuid, text) from public, anon;
grant execute on function workflow.admin_cancel_instance(uuid, text) to authenticated;

revoke all on function workflow.admin_recalculate_instance_status(uuid) from public, anon;
grant execute on function workflow.admin_recalculate_instance_status(uuid) to authenticated;

revoke all on function workflow.buyer_list_available_templates(int, int) from public, anon;
grant execute on function workflow.buyer_list_available_templates(int, int) to authenticated;

revoke all on function workflow.buyer_start_workflow(uuid, uuid, jsonb) from public, anon;
grant execute on function workflow.buyer_start_workflow(uuid, uuid, jsonb) to authenticated;

revoke all on function workflow.buyer_list_instances(workflow.workflow_instance_status, uuid, int, int) from public, anon;
grant execute on function workflow.buyer_list_instances(workflow.workflow_instance_status, uuid, int, int) to authenticated;

revoke all on function workflow.buyer_get_instance(uuid) from public, anon;
grant execute on function workflow.buyer_get_instance(uuid) to authenticated;

revoke all on function workflow.carrier_list_instances(workflow.workflow_instance_status, uuid, int, int) from public, anon;
grant execute on function workflow.carrier_list_instances(workflow.workflow_instance_status, uuid, int, int) to authenticated;

revoke all on function workflow.carrier_get_instance(uuid) from public, anon;
grant execute on function workflow.carrier_get_instance(uuid) to authenticated;

revoke all on function workflow.supplier_list_instances(workflow.workflow_instance_status, uuid, int, int) from public, anon;
grant execute on function workflow.supplier_list_instances(workflow.workflow_instance_status, uuid, int, int) to authenticated;

revoke all on function workflow.supplier_get_instance(uuid) from public, anon;
grant execute on function workflow.supplier_get_instance(uuid) to authenticated;

commit;
