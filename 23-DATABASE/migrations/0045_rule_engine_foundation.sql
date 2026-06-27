-- CC-67 — Rule Engine Foundation
--
-- Adds a reusable rules layer that can evaluate shipment / workflow / task
-- context and return rule decisions.  CC-67 is evaluation-only: it does
-- NOT mutate shipments, workflows, tasks, bookings, dispatches,
-- settlements, invoices, or payments.
--
-- Future CCs will use this Rule Engine to drive automatic task generation,
-- compliance requirements, document requirements, SLA escalation,
-- workflow branching, risk detection, pricing guardrails, and operational
-- exception handling.  CC-67 just lays the deterministic, RLS-protected,
-- SECURITY-DEFINER-only evaluation foundation.

begin;

-- ---------------------------------------------------------------------------
-- Schema
-- ---------------------------------------------------------------------------
create schema if not exists rules;
grant usage on schema rules to anon, authenticated, service_role;
comment on schema rules is
  'iKIA CC-67 — Reusable rule engine. Defines rule sets, rules with a safe JSON condition DSL, persisted evaluations, evaluation results, and an immutable event ledger. Evaluation only; no automatic mutation of business records.';

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'rules' and t.typname = 'rule_status') then
    create type rules.rule_status as enum ('draft', 'active', 'archived');
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'rules' and t.typname = 'rule_scope') then
    create type rules.rule_scope as enum (
      'shipment', 'workflow', 'task', 'document',
      'finance', 'marketplace', 'dispatch'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'rules' and t.typname = 'rule_effect_type') then
    create type rules.rule_effect_type as enum (
      'requirement', 'warning', 'block', 'escalation',
      'recommendation', 'classification'
    );
  end if;
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'rules' and t.typname = 'rule_eval_status') then
    create type rules.rule_eval_status as enum (
      'matched', 'not_matched', 'skipped', 'error'
    );
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 1. rules.rule_sets
-- ---------------------------------------------------------------------------
create table if not exists rules.rule_sets (
  id            uuid primary key default extensions.gen_random_uuid(),
  tenant_id     uuid not null references identity.tenants(id) on delete restrict,
  rule_set_code text not null,
  name          text not null,
  description   text,
  scope         rules.rule_scope not null default 'shipment',
  status        rules.rule_status not null default 'draft',
  priority      int not null default 100,
  metadata      jsonb not null default '{}'::jsonb,
  created_by    uuid references auth.users(id),
  created_at    timestamptz not null default now(),
  updated_by    uuid references auth.users(id),
  updated_at    timestamptz not null default now(),
  archived_at   timestamptz,

  constraint rule_sets_code_unique
    unique (tenant_id, rule_set_code),
  constraint rule_sets_name_not_blank
    check (length(btrim(name)) > 0),
  constraint rule_sets_code_not_blank
    check (length(btrim(rule_set_code)) > 0),
  constraint rule_sets_priority_nonneg
    check (priority >= 0),
  constraint rule_sets_archived_at_required
    check ((status <> 'archived') or (archived_at is not null)),
  constraint rule_sets_archived_at_only_when_archived
    check (archived_at is null or status = 'archived')
);

comment on table rules.rule_sets is
  'CC-67: a group of related rules. Lifecycle is draft -> active -> archived. Only active rule sets contribute to evaluation.';

create index if not exists rule_sets_tenant_status_scope_idx
  on rules.rule_sets(tenant_id, status, scope);

-- ---------------------------------------------------------------------------
-- 2. rules.rules
-- ---------------------------------------------------------------------------
create table if not exists rules.rules (
  id            uuid primary key default extensions.gen_random_uuid(),
  tenant_id     uuid not null references identity.tenants(id) on delete restrict,
  rule_set_id   uuid not null references rules.rule_sets(id) on delete cascade,
  rule_code     text not null,
  name          text not null,
  description   text,
  status        rules.rule_status not null default 'draft',
  scope         rules.rule_scope not null default 'shipment',
  effect_type   rules.rule_effect_type not null default 'recommendation',
  priority      int not null default 100,
  condition     jsonb not null default '{}'::jsonb,
  effect        jsonb not null default '{}'::jsonb,
  metadata      jsonb not null default '{}'::jsonb,
  created_by    uuid references auth.users(id),
  created_at    timestamptz not null default now(),
  updated_by    uuid references auth.users(id),
  updated_at    timestamptz not null default now(),
  archived_at   timestamptz,

  constraint rules_code_unique
    unique (rule_set_id, rule_code),
  constraint rules_name_not_blank
    check (length(btrim(name)) > 0),
  constraint rules_code_not_blank
    check (length(btrim(rule_code)) > 0),
  constraint rules_priority_nonneg
    check (priority >= 0),
  constraint rules_archived_at_required
    check ((status <> 'archived') or (archived_at is not null)),
  constraint rules_archived_at_only_when_archived
    check (archived_at is null or status = 'archived')
);

comment on table rules.rules is
  'CC-67: a single rule inside a rule set. Conditions follow the safe JSON DSL (all / any with eq / neq / in / not_in / exists / not_exists / gte / lte).';

create index if not exists rules_rule_set_status_priority_idx
  on rules.rules(rule_set_id, status, priority);
create index if not exists rules_scope_status_effect_idx
  on rules.rules(scope, status, effect_type);

-- ---------------------------------------------------------------------------
-- 3. rules.rule_evaluations
-- ---------------------------------------------------------------------------
create table if not exists rules.rule_evaluations (
  id            uuid primary key default extensions.gen_random_uuid(),
  tenant_id     uuid not null references identity.tenants(id) on delete restrict,
  scope         rules.rule_scope not null,
  subject_id    uuid not null,
  evaluated_by  uuid references auth.users(id),
  evaluated_at  timestamptz not null default now(),
  context       jsonb not null default '{}'::jsonb,
  summary       jsonb not null default '{}'::jsonb,
  metadata      jsonb not null default '{}'::jsonb
);

comment on table rules.rule_evaluations is
  'CC-67: a persisted snapshot of a rule-engine evaluation against a single subject. Read-only after insert.';

create index if not exists rule_evaluations_scope_subject_idx
  on rules.rule_evaluations(scope, subject_id, evaluated_at);
create index if not exists rule_evaluations_tenant_evaluated_idx
  on rules.rule_evaluations(tenant_id, evaluated_at);

-- ---------------------------------------------------------------------------
-- 4. rules.rule_evaluation_results
-- ---------------------------------------------------------------------------
create table if not exists rules.rule_evaluation_results (
  id            uuid primary key default extensions.gen_random_uuid(),
  tenant_id     uuid not null references identity.tenants(id) on delete restrict,
  evaluation_id uuid not null references rules.rule_evaluations(id) on delete cascade,
  rule_set_id   uuid references rules.rule_sets(id) on delete set null,
  rule_id       uuid references rules.rules(id) on delete set null,
  status        rules.rule_eval_status not null,
  effect_type   rules.rule_effect_type,
  score         numeric,
  reason        text,
  effect        jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),

  constraint rule_evaluation_results_score_range
    check (score is null or (score >= 0 and score <= 100))
);

comment on table rules.rule_evaluation_results is
  'CC-67: per-rule result row of an evaluation. Persisted at evaluation time and read-only afterwards.';

create index if not exists rule_evaluation_results_eval_idx
  on rules.rule_evaluation_results(evaluation_id);

-- ---------------------------------------------------------------------------
-- 5. rules.rule_events  (immutable append-only ledger)
-- ---------------------------------------------------------------------------
create table if not exists rules.rule_events (
  id             uuid primary key default extensions.gen_random_uuid(),
  tenant_id      uuid not null references identity.tenants(id) on delete restrict,
  rule_set_id    uuid references rules.rule_sets(id) on delete cascade,
  rule_id        uuid references rules.rules(id) on delete cascade,
  evaluation_id  uuid references rules.rule_evaluations(id) on delete cascade,
  event_type     text not null,
  actor_user_id  uuid references auth.users(id),
  payload        jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);

comment on table rules.rule_events is
  'CC-67: immutable rule-engine lifecycle event ledger. No UPDATE / DELETE. Insert only through rules.fn_record_event() (SECURITY DEFINER).';

create index if not exists rule_events_rule_set_created_idx
  on rules.rule_events(rule_set_id, created_at);
create index if not exists rule_events_evaluation_created_idx
  on rules.rule_events(evaluation_id, created_at);

-- Block direct UPDATE/DELETE at row level.
create or replace function rules.fn_block_event_mutation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  raise exception 'rules: rule_events is append-only' using errcode = '42501';
end;
$$;

drop trigger if exists trg_rule_events_no_update on rules.rule_events;
create trigger trg_rule_events_no_update
  before update on rules.rule_events
  for each row execute function rules.fn_block_event_mutation();

drop trigger if exists trg_rule_events_no_delete on rules.rule_events;
create trigger trg_rule_events_no_delete
  before delete on rules.rule_events
  for each row execute function rules.fn_block_event_mutation();

-- ===========================================================================
-- Internal helpers
-- ===========================================================================

-- Insert a rule_events row (bypasses append-only guard since SECURITY DEFINER).
create or replace function rules.fn_record_event(
  p_tenant_id     uuid,
  p_rule_set_id   uuid,
  p_rule_id       uuid,
  p_evaluation_id uuid,
  p_event_type    text,
  p_payload       jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  insert into rules.rule_events (
    tenant_id, rule_set_id, rule_id, evaluation_id, event_type,
    actor_user_id, payload
  ) values (
    p_tenant_id, p_rule_set_id, p_rule_id, p_evaluation_id, p_event_type,
    identity.current_user_id(), coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- Thin wrapper used by admin paths.
create or replace function rules.fn_audit(
  p_event_type text,
  p_subject_id uuid,
  p_payload    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  perform rules.fn_record_event(
    identity.current_tenant_id(), null, null, null, p_event_type,
    coalesce(p_payload, '{}'::jsonb) || jsonb_build_object('subject_id', p_subject_id)
  );
end;
$$;

-- Manage gate: platform admin only.
create or replace function rules.fn_assert_can_manage_rules()
returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'rules: management requires platform admin'
      using errcode = '42501';
  end if;
end;
$$;

-- Resolve a dotted JSON path against the supplied context.
-- Returns the leaf jsonb value, or NULL when any segment is missing.
create or replace function rules.fn_json_path(
  p_context jsonb,
  p_path    text
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_segments text[];
  v_cur      jsonb := p_context;
  v_seg      text;
begin
  if p_path is null or length(btrim(p_path)) = 0 then
    return p_context;
  end if;
  v_segments := string_to_array(p_path, '.');
  foreach v_seg in array v_segments loop
    if v_cur is null then
      return null;
    end if;
    if jsonb_typeof(v_cur) = 'object' then
      v_cur := v_cur -> v_seg;
    elsif jsonb_typeof(v_cur) = 'array' and v_seg ~ '^\d+$' then
      v_cur := v_cur -> v_seg::int;
    else
      return null;
    end if;
  end loop;
  return v_cur;
end;
$$;

-- Evaluate a single clause: {path, op, value}.
-- Returns true / false.  Unknown operator raises 22023.
create or replace function rules.fn_eval_clause(
  p_clause  jsonb,
  p_context jsonb
) returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_path  text := p_clause ->> 'path';
  v_op    text := p_clause ->> 'op';
  v_value jsonb := p_clause -> 'value';
  v_leaf  jsonb;
  v_leaf_text text;
  v_value_text text;
  v_leaf_num   numeric;
  v_value_num  numeric;
  v_arr_elem   jsonb;
begin
  if v_op is null or length(btrim(v_op)) = 0 then
    raise exception 'rules: clause missing op' using errcode = '22023';
  end if;
  v_leaf := rules.fn_json_path(p_context, v_path);

  case v_op
    when 'exists' then
      return v_leaf is not null and jsonb_typeof(v_leaf) <> 'null';
    when 'not_exists' then
      return v_leaf is null or jsonb_typeof(v_leaf) = 'null';
    when 'eq' then
      if v_leaf is null then return false; end if;
      return v_leaf = v_value;
    when 'neq' then
      return coalesce(v_leaf <> v_value, v_leaf is not null);
    when 'in' then
      if v_leaf is null or v_value is null
         or jsonb_typeof(v_value) <> 'array' then
        return false;
      end if;
      for v_arr_elem in select jsonb_array_elements(v_value) loop
        if v_arr_elem = v_leaf then return true; end if;
      end loop;
      return false;
    when 'not_in' then
      if v_value is null or jsonb_typeof(v_value) <> 'array' then
        return true;
      end if;
      if v_leaf is null then
        return true;
      end if;
      for v_arr_elem in select jsonb_array_elements(v_value) loop
        if v_arr_elem = v_leaf then return false; end if;
      end loop;
      return true;
    when 'gte' then
      if v_leaf is null or v_value is null then return false; end if;
      v_leaf_text  := v_leaf #>> '{}';
      v_value_text := v_value #>> '{}';
      begin
        v_leaf_num  := v_leaf_text::numeric;
        v_value_num := v_value_text::numeric;
        return v_leaf_num >= v_value_num;
      exception when others then
        return v_leaf_text >= v_value_text;
      end;
    when 'lte' then
      if v_leaf is null or v_value is null then return false; end if;
      v_leaf_text  := v_leaf #>> '{}';
      v_value_text := v_value #>> '{}';
      begin
        v_leaf_num  := v_leaf_text::numeric;
        v_value_num := v_value_text::numeric;
        return v_leaf_num <= v_value_num;
      exception when others then
        return v_leaf_text <= v_value_text;
      end;
    else
      raise exception 'rules: unknown op %', v_op using errcode = '22023';
  end case;
end;
$$;

-- Evaluate a top-level condition: { "all": [...] } or { "any": [...] }.
-- Empty condition ({}) matches.  Both keys present: all wins.
create or replace function rules.fn_eval_condition(
  p_condition jsonb,
  p_context   jsonb
) returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_clauses jsonb;
  v_clause  jsonb;
begin
  if p_condition is null or p_condition = '{}'::jsonb then
    return true;
  end if;
  if p_condition ? 'all' then
    v_clauses := p_condition -> 'all';
    if jsonb_typeof(v_clauses) <> 'array' then
      raise exception 'rules: "all" must be an array' using errcode = '22023';
    end if;
    for v_clause in select jsonb_array_elements(v_clauses) loop
      if not rules.fn_eval_clause(v_clause, p_context) then
        return false;
      end if;
    end loop;
    return true;
  elsif p_condition ? 'any' then
    v_clauses := p_condition -> 'any';
    if jsonb_typeof(v_clauses) <> 'array' then
      raise exception 'rules: "any" must be an array' using errcode = '22023';
    end if;
    for v_clause in select jsonb_array_elements(v_clauses) loop
      if rules.fn_eval_clause(v_clause, p_context) then
        return true;
      end if;
    end loop;
    return false;
  else
    -- Bare clause shape { path, op, value } at top-level.
    return rules.fn_eval_clause(p_condition, p_context);
  end if;
end;
$$;

-- Build the canonical shipment context jsonb.
create or replace function rules.fn_build_shipment_context(
  p_shipment_id uuid,
  p_context     jsonb default '{}'::jsonb
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_ship shipment.shipments;
  v_base jsonb;
begin
  select * into v_ship from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_ship.id is null then
    return coalesce(p_context, '{}'::jsonb);
  end if;
  v_base := jsonb_build_object(
    'shipment', jsonb_build_object(
      'id',                  v_ship.id,
      'status',              v_ship.status,
      'transport_mode',      v_ship.transport_mode,
      'origin_country',      v_ship.origin_country,
      'origin_city',         v_ship.origin_city,
      'destination_country', v_ship.destination_country,
      'destination_city',    v_ship.destination_city,
      'planned_pickup_at',   v_ship.planned_pickup_date,
      'planned_delivery_at', v_ship.planned_delivery_date,
      'incoterm',            v_ship.incoterm,
      'tenant_id',           v_ship.tenant_id,
      'organization_id',     v_ship.organization_id,
      'supplier_organization_id', v_ship.supplier_organization_id,
      'carrier_organization_id',  v_ship.carrier_organization_id
    )
  );
  -- Caller override merges last so values supplied by the RPC win.
  return v_base || coalesce(p_context, '{}'::jsonb);
end;
$$;

-- Visibility gate for evaluation.  Admin always passes. For shipment scope,
-- the caller must be an active member of buyer / supplier / carrier org on
-- the shipment. Other scopes are admin-only in CC-67.
create or replace function rules.fn_assert_can_evaluate_subject(
  p_scope      rules.rule_scope,
  p_subject_id uuid
) returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_user     uuid := identity.current_user_id();
  v_buyer    uuid; v_supplier uuid; v_carrier uuid;
begin
  if identity.is_platform_admin() then
    return;
  end if;
  if v_user is null then
    raise exception 'rules: anonymous cannot evaluate' using errcode = '42501';
  end if;
  if p_scope <> 'shipment' then
    raise exception 'rules: scope % is admin-only in CC-67', p_scope
      using errcode = '42501';
  end if;
  select organization_id, supplier_organization_id, carrier_organization_id
    into v_buyer, v_supplier, v_carrier
    from shipment.shipments
   where id = p_subject_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'rules: subject (shipment) not found' using errcode = 'P0002';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id in (v_buyer, v_supplier, v_carrier)
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  raise exception 'rules: subject not visible to caller'
    using errcode = '42501';
end;
$$;

-- ===========================================================================
-- Admin rule-set & rule management
-- ===========================================================================

create or replace function rules.admin_create_rule_set(
  p_rule_set_code text,
  p_name          text,
  p_description   text default null,
  p_scope         rules.rule_scope default 'shipment',
  p_priority      int default 100,
  p_metadata      jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user   uuid := identity.current_user_id();
  v_tenant uuid;
  v_id     uuid;
begin
  perform rules.fn_assert_can_manage_rules();
  if p_rule_set_code is null or length(btrim(p_rule_set_code)) = 0 then
    raise exception 'rules: rule_set_code required' using errcode = '22023';
  end if;
  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'rules: name required' using errcode = '22023';
  end if;
  v_tenant := identity.current_tenant_id();
  if v_tenant is null then
    select id into v_tenant from identity.tenants order by created_at limit 1;
  end if;
  if v_tenant is null then
    raise exception 'rules: no tenant context' using errcode = '22023';
  end if;
  insert into rules.rule_sets (
    tenant_id, rule_set_code, name, description, scope, status,
    priority, metadata, created_by, updated_by
  ) values (
    v_tenant, p_rule_set_code, p_name, p_description,
    coalesce(p_scope, 'shipment'::rules.rule_scope),
    'draft', coalesce(p_priority, 100),
    coalesce(p_metadata, '{}'::jsonb), v_user, v_user
  )
  returning id into v_id;
  perform rules.fn_record_event(
    v_tenant, v_id, null, null, 'rule_set.created',
    jsonb_build_object('rule_set_code', p_rule_set_code, 'name', p_name)
  );
  return v_id;
end;
$$;

create or replace function rules.admin_update_rule_set(
  p_rule_set_id uuid,
  p_name        text default null,
  p_description text default null,
  p_priority    int default null,
  p_metadata    jsonb default null
) returns rules.rule_sets
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.rule_sets;
begin
  perform rules.fn_assert_can_manage_rules();
  update rules.rule_sets
     set name        = coalesce(p_name, name),
         description = coalesce(p_description, description),
         priority    = coalesce(p_priority, priority),
         metadata    = coalesce(p_metadata, metadata),
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_rule_set_id
  returning * into v;
  if v.id is null then
    raise exception 'rules: rule_set not found' using errcode = 'P0002';
  end if;
  return v;
end;
$$;

create or replace function rules.admin_activate_rule_set(p_rule_set_id uuid)
returns rules.rule_sets
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.rule_sets;
begin
  perform rules.fn_assert_can_manage_rules();
  update rules.rule_sets
     set status      = 'active',
         archived_at = null,
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_rule_set_id
  returning * into v;
  if v.id is null then
    raise exception 'rules: rule_set not found' using errcode = 'P0002';
  end if;
  perform rules.fn_record_event(
    v.tenant_id, v.id, null, null, 'rule_set.activated', '{}'::jsonb
  );
  return v;
end;
$$;

create or replace function rules.admin_archive_rule_set(p_rule_set_id uuid)
returns rules.rule_sets
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.rule_sets;
begin
  perform rules.fn_assert_can_manage_rules();
  update rules.rule_sets
     set status      = 'archived',
         archived_at = now(),
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_rule_set_id
  returning * into v;
  if v.id is null then
    raise exception 'rules: rule_set not found' using errcode = 'P0002';
  end if;
  perform rules.fn_record_event(
    v.tenant_id, v.id, null, null, 'rule_set.archived', '{}'::jsonb
  );
  return v;
end;
$$;

create or replace function rules.admin_create_rule(
  p_rule_set_id uuid,
  p_rule_code   text,
  p_name        text,
  p_description text default null,
  p_scope       rules.rule_scope default 'shipment',
  p_effect_type rules.rule_effect_type default 'recommendation',
  p_priority    int default 100,
  p_condition   jsonb default '{}'::jsonb,
  p_effect      jsonb default '{}'::jsonb,
  p_metadata    jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user   uuid := identity.current_user_id();
  v_tenant uuid;
  v_status rules.rule_status;
  v_id     uuid;
begin
  perform rules.fn_assert_can_manage_rules();
  select tenant_id, status into v_tenant, v_status
    from rules.rule_sets where id = p_rule_set_id;
  if v_tenant is null then
    raise exception 'rules: rule_set not found' using errcode = 'P0002';
  end if;
  if v_status = 'archived' then
    raise exception 'rules: cannot add rule to archived rule_set'
      using errcode = '22023';
  end if;
  if p_rule_code is null or length(btrim(p_rule_code)) = 0 then
    raise exception 'rules: rule_code required' using errcode = '22023';
  end if;
  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'rules: name required' using errcode = '22023';
  end if;
  insert into rules.rules (
    tenant_id, rule_set_id, rule_code, name, description, status,
    scope, effect_type, priority, condition, effect, metadata,
    created_by, updated_by
  ) values (
    v_tenant, p_rule_set_id, p_rule_code, p_name, p_description, 'draft',
    coalesce(p_scope, 'shipment'::rules.rule_scope),
    coalesce(p_effect_type, 'recommendation'::rules.rule_effect_type),
    coalesce(p_priority, 100),
    coalesce(p_condition, '{}'::jsonb),
    coalesce(p_effect, '{}'::jsonb),
    coalesce(p_metadata, '{}'::jsonb),
    v_user, v_user
  )
  returning id into v_id;
  perform rules.fn_record_event(
    v_tenant, p_rule_set_id, v_id, null, 'rule.created',
    jsonb_build_object('rule_code', p_rule_code, 'name', p_name)
  );
  return v_id;
end;
$$;

create or replace function rules.admin_update_rule(
  p_rule_id     uuid,
  p_name        text default null,
  p_description text default null,
  p_effect_type rules.rule_effect_type default null,
  p_priority    int default null,
  p_condition   jsonb default null,
  p_effect      jsonb default null,
  p_metadata    jsonb default null
) returns rules.rules
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.rules;
begin
  perform rules.fn_assert_can_manage_rules();
  update rules.rules
     set name        = coalesce(p_name, name),
         description = coalesce(p_description, description),
         effect_type = coalesce(p_effect_type, effect_type),
         priority    = coalesce(p_priority, priority),
         condition   = coalesce(p_condition, condition),
         effect      = coalesce(p_effect, effect),
         metadata    = coalesce(p_metadata, metadata),
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_rule_id
  returning * into v;
  if v.id is null then
    raise exception 'rules: rule not found' using errcode = 'P0002';
  end if;
  return v;
end;
$$;

create or replace function rules.admin_activate_rule(p_rule_id uuid)
returns rules.rules
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.rules;
begin
  perform rules.fn_assert_can_manage_rules();
  update rules.rules
     set status      = 'active',
         archived_at = null,
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_rule_id
  returning * into v;
  if v.id is null then
    raise exception 'rules: rule not found' using errcode = 'P0002';
  end if;
  perform rules.fn_record_event(
    v.tenant_id, v.rule_set_id, v.id, null, 'rule.activated', '{}'::jsonb
  );
  return v;
end;
$$;

create or replace function rules.admin_archive_rule(p_rule_id uuid)
returns rules.rules
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.rules;
begin
  perform rules.fn_assert_can_manage_rules();
  update rules.rules
     set status      = 'archived',
         archived_at = now(),
         updated_by  = identity.current_user_id(),
         updated_at  = now()
   where id = p_rule_id
  returning * into v;
  if v.id is null then
    raise exception 'rules: rule not found' using errcode = 'P0002';
  end if;
  perform rules.fn_record_event(
    v.tenant_id, v.rule_set_id, v.id, null, 'rule.archived', '{}'::jsonb
  );
  return v;
end;
$$;

create or replace function rules.admin_list_rule_sets(
  p_status rules.rule_status default null,
  p_scope  rules.rule_scope default null,
  p_limit  int default 50,
  p_offset int default 0
) returns setof rules.rule_sets
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform rules.fn_assert_can_manage_rules();
  return query
    select rs.*
      from rules.rule_sets rs
     where (p_status is null or rs.status = p_status)
       and (p_scope  is null or rs.scope  = p_scope)
     order by rs.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function rules.admin_get_rule_set(p_rule_set_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_rs    rules.rule_sets;
  v_rules jsonb;
begin
  perform rules.fn_assert_can_manage_rules();
  select * into v_rs from rules.rule_sets where id = p_rule_set_id;
  if v_rs.id is null then
    raise exception 'rules: rule_set not found' using errcode = 'P0002';
  end if;
  select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.priority, r.rule_code), '[]'::jsonb)
    into v_rules
    from rules.rules r
   where r.rule_set_id = p_rule_set_id;
  return jsonb_build_object(
    'rule_set', row_to_json(v_rs)::jsonb,
    'rules',    v_rules
  );
end;
$$;

-- ===========================================================================
-- Evaluation
-- ===========================================================================

create or replace function rules.evaluate_context(
  p_scope      rules.rule_scope,
  p_subject_id uuid,
  p_context    jsonb default '{}'::jsonb,
  p_persist    boolean default true
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user    uuid := identity.current_user_id();
  v_tenant  uuid;
  v_context jsonb;
  v_eval    uuid;
  v_results jsonb := '[]'::jsonb;
  v_matched int := 0;
  v_total   int := 0;
  r         record;
  v_match   boolean;
  v_status  rules.rule_eval_status;
  v_reason  text;
  v_eff     jsonb;
  v_eff_t   rules.rule_effect_type;
  v_persist boolean := coalesce(p_persist, true);
begin
  if v_user is null then
    raise exception 'rules: anonymous cannot evaluate' using errcode = '42501';
  end if;
  perform rules.fn_assert_can_evaluate_subject(p_scope, p_subject_id);

  -- Build the working context.
  if p_scope = 'shipment' then
    v_context := rules.fn_build_shipment_context(p_subject_id, p_context);
  else
    v_context := coalesce(p_context, '{}'::jsonb);
  end if;

  -- Resolve the tenant for the persisted snapshot.
  if p_scope = 'shipment' then
    select tenant_id into v_tenant
      from shipment.shipments where id = p_subject_id;
  end if;
  if v_tenant is null then
    v_tenant := identity.current_tenant_id();
  end if;
  if v_tenant is null then
    select id into v_tenant from identity.tenants order by created_at limit 1;
  end if;

  if v_persist then
    insert into rules.rule_evaluations (
      tenant_id, scope, subject_id, evaluated_by, context,
      summary, metadata
    ) values (
      v_tenant, p_scope, p_subject_id, v_user, v_context,
      '{}'::jsonb, '{}'::jsonb
    )
    returning id into v_eval;
  end if;

  for r in
    select rl.id        as rule_id,
           rl.rule_code,
           rl.name,
           rl.rule_set_id,
           rl.effect_type,
           rl.priority,
           rl.condition,
           rl.effect
      from rules.rules rl
      join rules.rule_sets rs on rs.id = rl.rule_set_id
     where rl.status = 'active'
       and rs.status = 'active'
       and rl.scope = p_scope
       and rs.scope = p_scope
       and rl.tenant_id = v_tenant
     order by rs.priority, rl.priority, rl.rule_code
  loop
    v_total := v_total + 1;
    v_eff_t := r.effect_type;
    v_eff   := coalesce(r.effect, '{}'::jsonb);
    v_reason := null;
    begin
      v_match := rules.fn_eval_condition(r.condition, v_context);
      if v_match then
        v_status := 'matched';
        v_matched := v_matched + 1;
        v_reason := r.name;
      else
        v_status := 'not_matched';
      end if;
    exception when others then
      v_status := 'error';
      v_reason := SQLERRM;
    end;

    if v_persist then
      insert into rules.rule_evaluation_results (
        tenant_id, evaluation_id, rule_set_id, rule_id,
        status, effect_type, reason, effect
      ) values (
        v_tenant, v_eval, r.rule_set_id, r.rule_id,
        v_status, v_eff_t, v_reason, v_eff
      );
    end if;

    v_results := v_results || jsonb_build_array(jsonb_build_object(
      'rule_id',     r.rule_id,
      'rule_code',   r.rule_code,
      'status',      v_status,
      'effect_type', v_eff_t,
      'reason',      v_reason,
      'effect',      v_eff
    ));
  end loop;

  if v_persist and v_eval is not null then
    update rules.rule_evaluations
       set summary = jsonb_build_object(
             'matched_count', v_matched,
             'rule_count',    v_total
           )
     where id = v_eval;
    perform rules.fn_record_event(
      v_tenant, null, null, v_eval, 'evaluation.completed',
      jsonb_build_object(
        'scope',         p_scope,
        'subject_id',    p_subject_id,
        'matched_count', v_matched,
        'rule_count',    v_total
      )
    );
  end if;

  return jsonb_build_object(
    'evaluation_id', v_eval,
    'scope',         p_scope,
    'subject_id',    p_subject_id,
    'matched_count', v_matched,
    'rule_count',    v_total,
    'results',       v_results
  );
end;
$$;

-- ===========================================================================
-- Admin read RPCs
-- ===========================================================================

create or replace function rules.admin_list_evaluations(
  p_scope      rules.rule_scope default null,
  p_subject_id uuid default null,
  p_limit      int default 50,
  p_offset     int default 0
) returns setof rules.rule_evaluations
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform rules.fn_assert_can_manage_rules();
  return query
    select e.*
      from rules.rule_evaluations e
     where (p_scope      is null or e.scope      = p_scope)
       and (p_subject_id is null or e.subject_id = p_subject_id)
     order by e.evaluated_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function rules.admin_get_evaluation(p_evaluation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_eval    rules.rule_evaluations;
  v_results jsonb;
begin
  perform rules.fn_assert_can_manage_rules();
  select * into v_eval from rules.rule_evaluations where id = p_evaluation_id;
  if v_eval.id is null then
    raise exception 'rules: evaluation not found' using errcode = 'P0002';
  end if;
  select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.created_at), '[]'::jsonb)
    into v_results
    from rules.rule_evaluation_results r
   where r.evaluation_id = p_evaluation_id;
  return jsonb_build_object(
    'evaluation', row_to_json(v_eval)::jsonb,
    'results',    v_results
  );
end;
$$;

-- ===========================================================================
-- Buyer read RPCs (shipment-scoped)
-- ===========================================================================

create or replace function rules.buyer_list_shipment_evaluations(
  p_shipment_id uuid,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof rules.rule_evaluations
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'rules: anonymous' using errcode = '42501';
  end if;
  perform rules.fn_assert_can_evaluate_subject('shipment'::rules.rule_scope, p_shipment_id);
  return query
    select e.*
      from rules.rule_evaluations e
     where e.scope = 'shipment'
       and e.subject_id = p_shipment_id
     order by e.evaluated_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function rules.buyer_get_evaluation(p_evaluation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_eval    rules.rule_evaluations;
  v_results jsonb;
begin
  select * into v_eval from rules.rule_evaluations where id = p_evaluation_id;
  if v_eval.id is null then
    raise exception 'rules: evaluation not found' using errcode = 'P0002';
  end if;
  perform rules.fn_assert_can_evaluate_subject(v_eval.scope, v_eval.subject_id);
  select coalesce(jsonb_agg(row_to_json(r)::jsonb order by r.created_at), '[]'::jsonb)
    into v_results
    from rules.rule_evaluation_results r
   where r.evaluation_id = p_evaluation_id;
  return jsonb_build_object(
    'evaluation', row_to_json(v_eval)::jsonb,
    'results',    v_results
  );
end;
$$;

-- ===========================================================================
-- Row-level security
-- ===========================================================================

alter table rules.rule_sets               enable row level security;
alter table rules.rules                   enable row level security;
alter table rules.rule_evaluations        enable row level security;
alter table rules.rule_evaluation_results enable row level security;
alter table rules.rule_events             enable row level security;

drop policy if exists rule_sets_select on rules.rule_sets;
create policy rule_sets_select on rules.rule_sets
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.tenant_id = rules.rule_sets.tenant_id
         and m.deleted_at is null and m.status = 'active'
    )
  );

drop policy if exists rules_select on rules.rules;
create policy rules_select on rules.rules
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.tenant_id = rules.rules.tenant_id
         and m.deleted_at is null and m.status = 'active'
    )
  );

-- Evaluations: admin sees all; for shipment scope, buyer / supplier /
-- carrier org members on the underlying shipment see their own evals.
-- Non-shipment scopes remain admin-only in CC-67.
drop policy if exists rule_evaluations_select on rules.rule_evaluations;
create policy rule_evaluations_select on rules.rule_evaluations
  for select using (
    identity.is_platform_admin()
    or (
      scope = 'shipment'
      and exists (
        select 1 from shipment.shipments s
         where s.id = rules.rule_evaluations.subject_id
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

drop policy if exists rule_evaluation_results_select on rules.rule_evaluation_results;
create policy rule_evaluation_results_select on rules.rule_evaluation_results
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from rules.rule_evaluations e
        join shipment.shipments s on s.id = e.subject_id
       where e.id = rules.rule_evaluation_results.evaluation_id
         and e.scope = 'shipment'
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

drop policy if exists rule_events_select on rules.rule_events;
create policy rule_events_select on rules.rule_events
  for select using (
    identity.is_platform_admin()
  );

-- ===========================================================================
-- Grants
-- ===========================================================================

grant select on rules.rule_sets               to authenticated;
grant select on rules.rules                   to authenticated;
grant select on rules.rule_evaluations        to authenticated;
grant select on rules.rule_evaluation_results to authenticated;
grant select on rules.rule_events             to authenticated;

-- Lock down public/anon on all RPCs; grant execute to authenticated.
revoke all on function rules.admin_create_rule_set(text, text, text, rules.rule_scope, int, jsonb) from public, anon;
grant execute on function rules.admin_create_rule_set(text, text, text, rules.rule_scope, int, jsonb) to authenticated;

revoke all on function rules.admin_update_rule_set(uuid, text, text, int, jsonb) from public, anon;
grant execute on function rules.admin_update_rule_set(uuid, text, text, int, jsonb) to authenticated;

revoke all on function rules.admin_activate_rule_set(uuid) from public, anon;
grant execute on function rules.admin_activate_rule_set(uuid) to authenticated;

revoke all on function rules.admin_archive_rule_set(uuid) from public, anon;
grant execute on function rules.admin_archive_rule_set(uuid) to authenticated;

revoke all on function rules.admin_create_rule(uuid, text, text, text,
  rules.rule_scope, rules.rule_effect_type, int, jsonb, jsonb, jsonb) from public, anon;
grant execute on function rules.admin_create_rule(uuid, text, text, text,
  rules.rule_scope, rules.rule_effect_type, int, jsonb, jsonb, jsonb) to authenticated;

revoke all on function rules.admin_update_rule(uuid, text, text,
  rules.rule_effect_type, int, jsonb, jsonb, jsonb) from public, anon;
grant execute on function rules.admin_update_rule(uuid, text, text,
  rules.rule_effect_type, int, jsonb, jsonb, jsonb) to authenticated;

revoke all on function rules.admin_activate_rule(uuid) from public, anon;
grant execute on function rules.admin_activate_rule(uuid) to authenticated;

revoke all on function rules.admin_archive_rule(uuid) from public, anon;
grant execute on function rules.admin_archive_rule(uuid) to authenticated;

revoke all on function rules.admin_list_rule_sets(rules.rule_status, rules.rule_scope, int, int) from public, anon;
grant execute on function rules.admin_list_rule_sets(rules.rule_status, rules.rule_scope, int, int) to authenticated;

revoke all on function rules.admin_get_rule_set(uuid) from public, anon;
grant execute on function rules.admin_get_rule_set(uuid) to authenticated;

revoke all on function rules.evaluate_context(rules.rule_scope, uuid, jsonb, boolean) from public, anon;
grant execute on function rules.evaluate_context(rules.rule_scope, uuid, jsonb, boolean) to authenticated;

revoke all on function rules.admin_list_evaluations(rules.rule_scope, uuid, int, int) from public, anon;
grant execute on function rules.admin_list_evaluations(rules.rule_scope, uuid, int, int) to authenticated;

revoke all on function rules.admin_get_evaluation(uuid) from public, anon;
grant execute on function rules.admin_get_evaluation(uuid) to authenticated;

revoke all on function rules.buyer_list_shipment_evaluations(uuid, int, int) from public, anon;
grant execute on function rules.buyer_list_shipment_evaluations(uuid, int, int) to authenticated;

revoke all on function rules.buyer_get_evaluation(uuid) from public, anon;
grant execute on function rules.buyer_get_evaluation(uuid) to authenticated;

commit;
