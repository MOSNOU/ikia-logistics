-- CC-68 — Rule-to-Workflow Evaluation Bridge
--
-- Connects the CC-67 Rule Engine to the CC-66 Workflow Engine v2 by letting
-- rules *recommend* workflow templates for a shipment. This bridge is
-- recommendation-only:
--
--   * It does NOT start workflows (no workflow.*_start_workflow calls).
--   * It does NOT generate execution.shipment_tasks.
--   * It does NOT mutate workflow.workflow_instances.
--   * It does NOT mutate shipment / booking / dispatch / settlement /
--     invoice / payment / marketplace records.
--   * It only reads ACTIVE workflow templates and persists / returns
--     workflow recommendations plus an immutable recommendation event ledger.
--
-- "accepted" means an operator/buyer marked a recommendation accepted. A
-- future CC may convert an accepted recommendation into a workflow instance.
-- CC-68 itself never does that.
--
-- Additive only. No existing migration is mutated. All write paths flow
-- through SECURITY DEFINER RPCs. Tables are RLS-protected.
-- workflow_recommendation_events is append-only.

begin;

-- ===========================================================================
-- 1. rules.workflow_recommendations
-- ===========================================================================
create table if not exists rules.workflow_recommendations (
  id                  uuid primary key default extensions.gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  shipment_id         uuid not null references shipment.shipments(id) on delete cascade,
  evaluation_id       uuid references rules.rule_evaluations(id) on delete set null,
  rule_id             uuid references rules.rules(id) on delete set null,
  template_id         uuid not null references workflow.workflow_templates(id) on delete restrict,
  recommendation_code text not null,
  confidence_score    numeric not null default 0,
  reason              text,
  status              text not null default 'open',
  metadata            jsonb not null default '{}'::jsonb,
  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  dismissed_by        uuid references auth.users(id),
  dismissed_at        timestamptz,
  dismissal_reason    text,

  constraint workflow_recommendations_code_not_blank
    check (length(btrim(recommendation_code)) > 0),
  constraint workflow_recommendations_confidence_range
    check (confidence_score >= 0 and confidence_score <= 100),
  constraint workflow_recommendations_status_valid
    check (status in ('open', 'dismissed', 'accepted')),
  constraint workflow_recommendations_dismissed_at_required
    check (status <> 'dismissed' or dismissed_at is not null),
  constraint workflow_recommendations_dismissal_reason_required
    check (status <> 'dismissed'
           or (dismissal_reason is not null and length(btrim(dismissal_reason)) > 0))
);

comment on table rules.workflow_recommendations is
  'CC-68: a persisted workflow-template recommendation generated from rule evaluation. Recommendation-only: never starts a workflow nor generates tasks. Lifecycle: open -> accepted | dismissed.';

create index if not exists workflow_recommendations_shipment_status_idx
  on rules.workflow_recommendations(shipment_id, status);
create index if not exists workflow_recommendations_template_status_idx
  on rules.workflow_recommendations(template_id, status);
create index if not exists workflow_recommendations_evaluation_idx
  on rules.workflow_recommendations(evaluation_id);

-- At most one OPEN recommendation per (shipment, template, rule).
create unique index if not exists workflow_recommendations_open_unique
  on rules.workflow_recommendations(shipment_id, template_id, rule_id)
  where status = 'open';

-- ===========================================================================
-- 2. rules.workflow_recommendation_events  (immutable append-only ledger)
-- ===========================================================================
create table if not exists rules.workflow_recommendation_events (
  id                 uuid primary key default extensions.gen_random_uuid(),
  tenant_id          uuid not null references identity.tenants(id) on delete restrict,
  recommendation_id  uuid not null references rules.workflow_recommendations(id) on delete cascade,
  event_type         text not null,
  actor_user_id      uuid references auth.users(id),
  payload            jsonb not null default '{}'::jsonb,
  created_at         timestamptz not null default now()
);

comment on table rules.workflow_recommendation_events is
  'CC-68: immutable workflow-recommendation lifecycle event ledger. No UPDATE / DELETE. Insert only through rules.fn_record_workflow_recommendation_event() (SECURITY DEFINER).';

create index if not exists workflow_recommendation_events_rec_created_idx
  on rules.workflow_recommendation_events(recommendation_id, created_at);

-- Block direct UPDATE/DELETE at row level.
create or replace function rules.fn_block_workflow_recommendation_event_mutation()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  raise exception 'rules: workflow_recommendation_events is append-only'
    using errcode = '42501';
end;
$$;

drop trigger if exists trg_wf_rec_events_no_update on rules.workflow_recommendation_events;
create trigger trg_wf_rec_events_no_update
  before update on rules.workflow_recommendation_events
  for each row execute function rules.fn_block_workflow_recommendation_event_mutation();

drop trigger if exists trg_wf_rec_events_no_delete on rules.workflow_recommendation_events;
create trigger trg_wf_rec_events_no_delete
  before delete on rules.workflow_recommendation_events
  for each row execute function rules.fn_block_workflow_recommendation_event_mutation();

-- ===========================================================================
-- Internal helpers
-- ===========================================================================

-- Append a recommendation event row. SECURITY DEFINER bypass of the
-- append-only guard; internal only. Tenant is derived from the recommendation.
create or replace function rules.fn_record_workflow_recommendation_event(
  p_recommendation_id uuid,
  p_event_type        text,
  p_payload           jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_id     uuid;
begin
  select tenant_id into v_tenant
    from rules.workflow_recommendations where id = p_recommendation_id;
  if v_tenant is null then
    raise exception 'rules: workflow recommendation not found' using errcode = 'P0002';
  end if;
  insert into rules.workflow_recommendation_events (
    tenant_id, recommendation_id, event_type, actor_user_id, payload
  ) values (
    v_tenant, p_recommendation_id, p_event_type,
    identity.current_user_id(), coalesce(p_payload, '{}'::jsonb)
  )
  returning id into v_id;
  return v_id;
end;
$$;

-- Resolve a rule effect JSON to an ACTIVE workflow template id, or NULL.
-- Accepted keys (in priority order):
--   workflow_template_id  (uuid)
--   template_id           (uuid)
--   workflow_template_code(text, resolved against active templates)
-- An explicit id that does not resolve to an active template yields NULL
-- (inactive / invalid template is skipped). When p_tenant_id is supplied,
-- resolution is restricted to that tenant.
create or replace function rules.fn_resolve_workflow_template_from_effect(
  p_effect    jsonb,
  p_tenant_id uuid default null
) returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_id_text  text;
  v_id       uuid;
  v_code     text;
  v_resolved uuid;
begin
  if p_effect is null or jsonb_typeof(p_effect) <> 'object' then
    return null;
  end if;

  -- 1. explicit uuid (workflow_template_id, then template_id)
  v_id_text := coalesce(p_effect ->> 'workflow_template_id',
                        p_effect ->> 'template_id');
  if v_id_text is not null and length(btrim(v_id_text)) > 0 then
    begin
      v_id := v_id_text::uuid;
    exception when others then
      v_id := null;
    end;
    if v_id is null then
      return null;  -- malformed uuid -> invalid template skipped
    end if;
    select t.id into v_resolved
      from workflow.workflow_templates t
     where t.id = v_id
       and t.status = 'active'
       and (p_tenant_id is null or t.tenant_id = p_tenant_id);
    return v_resolved;  -- NULL when inactive / not found -> skipped
  end if;

  -- 2. template code resolved against active templates
  v_code := p_effect ->> 'workflow_template_code';
  if v_code is not null and length(btrim(v_code)) > 0 then
    select t.id into v_resolved
      from workflow.workflow_templates t
     where t.template_code = v_code
       and t.status = 'active'
       and (p_tenant_id is null or t.tenant_id = p_tenant_id)
     order by t.created_at desc
     limit 1;
    return v_resolved;  -- NULL when no active template -> skipped
  end if;

  return null;
end;
$$;

-- True when the caller is a platform admin or an active member of the buyer
-- (owning) organisation of the shipment. Supplier / carrier orgs have NO
-- recommendation visibility in CC-68.
create or replace function rules.fn_buyer_can_access_shipment_recommendations(
  p_shipment_id uuid
) returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid;
  v_user  uuid := identity.current_user_id();
begin
  if identity.is_platform_admin() then
    return true;
  end if;
  if v_user is null then
    return false;
  end if;
  select organization_id into v_buyer
    from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_buyer is null then
    return false;
  end if;
  return exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id = v_buyer
       and m.deleted_at is null and m.status = 'active'
  );
end;
$$;

-- View gate for a single recommendation (admin or buyer-org member).
create or replace function rules.fn_assert_can_view_workflow_recommendation(
  p_recommendation_id uuid
) returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_ship uuid;
begin
  select shipment_id into v_ship
    from rules.workflow_recommendations where id = p_recommendation_id;
  if v_ship is null then
    raise exception 'rules: workflow recommendation not found' using errcode = 'P0002';
  end if;
  if rules.fn_buyer_can_access_shipment_recommendations(v_ship) then
    return;
  end if;
  raise exception 'rules: workflow recommendation not visible to caller'
    using errcode = '42501';
end;
$$;

-- Mutate gate. In CC-68 buyers and admins may mutate buyer-visible
-- recommendations; identical posture to the view gate.
create or replace function rules.fn_assert_can_mutate_workflow_recommendation(
  p_recommendation_id uuid
) returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform rules.fn_assert_can_view_workflow_recommendation(p_recommendation_id);
end;
$$;

-- Insert (or return the existing OPEN) workflow recommendation for a given
-- (shipment, template, rule). Records a 'workflow_recommendation.created'
-- event only when a new row is inserted. Returns the recommendation id.
create or replace function rules.fn_upsert_workflow_recommendation(
  p_tenant_id           uuid,
  p_shipment_id         uuid,
  p_evaluation_id       uuid,
  p_rule_id             uuid,
  p_template_id         uuid,
  p_recommendation_code text,
  p_confidence_score    numeric,
  p_reason              text,
  p_metadata            jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_existing uuid;
  v_conf     numeric := least(100, greatest(0, coalesce(p_confidence_score, 0)));
  v_id       uuid;
begin
  -- Deduplicate against any OPEN recommendation for the same triple.
  select id into v_existing
    from rules.workflow_recommendations
   where shipment_id = p_shipment_id
     and template_id = p_template_id
     and status = 'open'
     and rule_id is not distinct from p_rule_id
   limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  insert into rules.workflow_recommendations (
    tenant_id, shipment_id, evaluation_id, rule_id, template_id,
    recommendation_code, confidence_score, reason, status, metadata,
    created_by
  ) values (
    p_tenant_id, p_shipment_id, p_evaluation_id, p_rule_id, p_template_id,
    p_recommendation_code, v_conf, p_reason, 'open',
    coalesce(p_metadata, '{}'::jsonb), identity.current_user_id()
  )
  returning id into v_id;

  perform rules.fn_record_workflow_recommendation_event(
    v_id, 'workflow_recommendation.created',
    jsonb_build_object(
      'shipment_id',      p_shipment_id,
      'template_id',      p_template_id,
      'rule_id',          p_rule_id,
      'evaluation_id',    p_evaluation_id,
      'confidence_score', v_conf
    )
  );
  return v_id;
end;
$$;

-- Apply accept: open -> accepted. Does NOT start a workflow (CC-68 contract).
create or replace function rules.fn_apply_accept_workflow_recommendation(
  p_recommendation_id uuid,
  p_note              text default null
) returns rules.workflow_recommendations
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.workflow_recommendations;
begin
  select * into v from rules.workflow_recommendations where id = p_recommendation_id;
  if v.id is null then
    raise exception 'rules: workflow recommendation not found' using errcode = 'P0002';
  end if;
  if v.status <> 'open' then
    raise exception 'rules: recommendation is % and can no longer be accepted', v.status
      using errcode = '22023';
  end if;
  update rules.workflow_recommendations
     set status   = 'accepted',
         metadata = coalesce(metadata, '{}'::jsonb)
                    || jsonb_build_object('accept_note', coalesce(p_note, ''))
   where id = p_recommendation_id
  returning * into v;
  -- NOTE: CC-68 deliberately does NOT call workflow.*_start_workflow here.
  perform rules.fn_record_workflow_recommendation_event(
    p_recommendation_id, 'workflow_recommendation.accepted',
    jsonb_build_object('note', coalesce(p_note, ''))
  );
  return v;
end;
$$;

-- Apply dismiss: open -> dismissed (reason required).
create or replace function rules.fn_apply_dismiss_workflow_recommendation(
  p_recommendation_id uuid,
  p_reason            text
) returns rules.workflow_recommendations
language plpgsql volatile security definer set search_path = ''
as $$
declare v rules.workflow_recommendations;
begin
  if p_reason is null or length(btrim(p_reason)) = 0 then
    raise exception 'rules: dismissal reason required' using errcode = '22023';
  end if;
  select * into v from rules.workflow_recommendations where id = p_recommendation_id;
  if v.id is null then
    raise exception 'rules: workflow recommendation not found' using errcode = 'P0002';
  end if;
  if v.status <> 'open' then
    raise exception 'rules: recommendation is % and can no longer be dismissed', v.status
      using errcode = '22023';
  end if;
  update rules.workflow_recommendations
     set status           = 'dismissed',
         dismissed_at     = now(),
         dismissed_by     = identity.current_user_id(),
         dismissal_reason = p_reason
   where id = p_recommendation_id
  returning * into v;
  perform rules.fn_record_workflow_recommendation_event(
    p_recommendation_id, 'workflow_recommendation.dismissed',
    jsonb_build_object('reason', p_reason)
  );
  return v;
end;
$$;

-- ===========================================================================
-- Evaluation bridge
-- ===========================================================================

-- Evaluate shipment-scope rules and turn matched recommendation-effect rules
-- into workflow recommendations. Recommendation-only.
create or replace function rules.evaluate_shipment_workflow_recommendations(
  p_shipment_id uuid,
  p_context     jsonb default '{}'::jsonb,
  p_persist     boolean default true
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_user      uuid := identity.current_user_id();
  v_tenant    uuid;
  v_persist   boolean := coalesce(p_persist, true);
  v_eval      jsonb;
  v_eval_id   uuid;
  v_results   jsonb;
  r           jsonb;
  v_effect    jsonb;
  v_template  uuid;
  v_tpl_code  text;
  v_tpl_name  text;
  v_rule_id   uuid;
  v_rule_code text;
  v_conf      numeric;
  v_reason    text;
  v_rec_code  text;
  v_rec_id    uuid;
  v_recs      jsonb := '[]'::jsonb;
  v_skipped   jsonb := '[]'::jsonb;
  v_count     int := 0;
begin
  if v_user is null then
    raise exception 'rules: anonymous cannot evaluate' using errcode = '42501';
  end if;
  perform rules.fn_assert_can_evaluate_subject('shipment'::rules.rule_scope, p_shipment_id);

  select tenant_id into v_tenant
    from shipment.shipments where id = p_shipment_id and deleted_at is null;
  if v_tenant is null then
    raise exception 'rules: shipment not found' using errcode = 'P0002';
  end if;

  -- Reuse the CC-67 evaluation engine for scope = shipment.
  v_eval    := rules.evaluate_context('shipment'::rules.rule_scope, p_shipment_id,
                                      coalesce(p_context, '{}'::jsonb), v_persist);
  v_eval_id := nullif(v_eval ->> 'evaluation_id', '')::uuid;
  v_results := coalesce(v_eval -> 'results', '[]'::jsonb);

  for r in select * from jsonb_array_elements(v_results)
  loop
    -- Only matched rules whose effect_type is 'recommendation'.
    if coalesce(r ->> 'status', '') <> 'matched'
       or coalesce(r ->> 'effect_type', '') <> 'recommendation' then
      continue;
    end if;

    v_effect   := coalesce(r -> 'effect', '{}'::jsonb);
    v_rule_id  := nullif(r ->> 'rule_id', '')::uuid;
    v_rule_code := r ->> 'rule_code';
    v_template := rules.fn_resolve_workflow_template_from_effect(v_effect, v_tenant);

    if v_template is null then
      -- No valid active template: evaluation still works, no recommendation.
      v_skipped := v_skipped || jsonb_build_array(jsonb_build_object(
        'rule_id',   v_rule_id,
        'rule_code', v_rule_code,
        'reason',    'no active workflow template resolved from effect'
      ));
      continue;
    end if;

    select t.template_code, t.name into v_tpl_code, v_tpl_name
      from workflow.workflow_templates t where t.id = v_template;

    v_conf := least(100, greatest(0,
      coalesce((v_effect ->> 'confidence_score')::numeric, 0)));
    v_reason := coalesce(v_effect ->> 'recommendation_reason',
                         r ->> 'reason', v_rule_code);
    v_rec_code := coalesce(v_effect ->> 'recommendation_code',
                           'wf_rec:' || coalesce(v_tpl_code, v_template::text));

    v_rec_id := null;
    if v_persist then
      v_rec_id := rules.fn_upsert_workflow_recommendation(
        v_tenant, p_shipment_id, v_eval_id, v_rule_id, v_template,
        v_rec_code, v_conf, v_reason, '{}'::jsonb
      );
    end if;

    v_recs := v_recs || jsonb_build_array(jsonb_build_object(
      'recommendation_id', v_rec_id,
      'rule_id',           v_rule_id,
      'rule_code',         v_rule_code,
      'template_id',       v_template,
      'template_code',     v_tpl_code,
      'template_name',     v_tpl_name,
      'confidence_score',  v_conf,
      'reason',            v_reason,
      'status',            'open'
    ));
    v_count := v_count + 1;
  end loop;

  return jsonb_build_object(
    'shipment_id',          p_shipment_id,
    'evaluation_id',        v_eval_id,
    'recommendation_count', v_count,
    'recommendations',      v_recs,
    'skipped',              v_skipped
  );
end;
$$;

-- ===========================================================================
-- Admin RPCs
-- ===========================================================================

create or replace function rules.admin_list_workflow_recommendations(
  p_shipment_id uuid default null,
  p_status      text default null,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof rules.workflow_recommendations
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'rules: admin only' using errcode = '42501';
  end if;
  return query
    select wr.*
      from rules.workflow_recommendations wr
     where (p_shipment_id is null or wr.shipment_id = p_shipment_id)
       and (p_status is null or wr.status = p_status)
     order by wr.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function rules.admin_get_workflow_recommendation(
  p_recommendation_id uuid
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_rec    rules.workflow_recommendations;
  v_events jsonb;
begin
  if not identity.is_platform_admin() then
    raise exception 'rules: admin only' using errcode = '42501';
  end if;
  select * into v_rec from rules.workflow_recommendations where id = p_recommendation_id;
  if v_rec.id is null then
    raise exception 'rules: workflow recommendation not found' using errcode = 'P0002';
  end if;
  select coalesce(jsonb_agg(row_to_json(e)::jsonb order by e.created_at), '[]'::jsonb)
    into v_events
    from rules.workflow_recommendation_events e
   where e.recommendation_id = p_recommendation_id;
  return jsonb_build_object(
    'recommendation', row_to_json(v_rec)::jsonb,
    'events',         v_events
  );
end;
$$;

create or replace function rules.admin_accept_workflow_recommendation(
  p_recommendation_id uuid,
  p_note              text default null
) returns rules.workflow_recommendations
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'rules: admin only' using errcode = '42501';
  end if;
  return rules.fn_apply_accept_workflow_recommendation(p_recommendation_id, p_note);
end;
$$;

create or replace function rules.admin_dismiss_workflow_recommendation(
  p_recommendation_id uuid,
  p_reason            text
) returns rules.workflow_recommendations
language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'rules: admin only' using errcode = '42501';
  end if;
  return rules.fn_apply_dismiss_workflow_recommendation(p_recommendation_id, p_reason);
end;
$$;

-- ===========================================================================
-- Buyer RPCs (shipment-scoped; buyer-org members + admin only)
-- ===========================================================================

create or replace function rules.buyer_list_workflow_recommendations(
  p_shipment_id uuid,
  p_status      text default null,
  p_limit       int default 50,
  p_offset      int default 0
) returns setof rules.workflow_recommendations
language plpgsql stable security definer set search_path = ''
as $$
declare v_user uuid := identity.current_user_id();
begin
  if v_user is null then
    raise exception 'rules: anonymous' using errcode = '42501';
  end if;
  if not rules.fn_buyer_can_access_shipment_recommendations(p_shipment_id) then
    raise exception 'rules: shipment recommendations not visible to caller'
      using errcode = '42501';
  end if;
  return query
    select wr.*
      from rules.workflow_recommendations wr
     where wr.shipment_id = p_shipment_id
       and (p_status is null or wr.status = p_status)
     order by wr.created_at desc
     limit greatest(coalesce(p_limit, 50), 1)
    offset greatest(coalesce(p_offset, 0), 0);
end;
$$;

create or replace function rules.buyer_get_workflow_recommendation(
  p_recommendation_id uuid
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_rec    rules.workflow_recommendations;
  v_events jsonb;
begin
  perform rules.fn_assert_can_view_workflow_recommendation(p_recommendation_id);
  select * into v_rec from rules.workflow_recommendations where id = p_recommendation_id;
  select coalesce(jsonb_agg(row_to_json(e)::jsonb order by e.created_at), '[]'::jsonb)
    into v_events
    from rules.workflow_recommendation_events e
   where e.recommendation_id = p_recommendation_id;
  return jsonb_build_object(
    'recommendation', row_to_json(v_rec)::jsonb,
    'events',         v_events
  );
end;
$$;

create or replace function rules.buyer_accept_workflow_recommendation(
  p_recommendation_id uuid,
  p_note              text default null
) returns rules.workflow_recommendations
language plpgsql volatile security definer set search_path = ''
as $$
begin
  perform rules.fn_assert_can_mutate_workflow_recommendation(p_recommendation_id);
  return rules.fn_apply_accept_workflow_recommendation(p_recommendation_id, p_note);
end;
$$;

create or replace function rules.buyer_dismiss_workflow_recommendation(
  p_recommendation_id uuid,
  p_reason            text
) returns rules.workflow_recommendations
language plpgsql volatile security definer set search_path = ''
as $$
begin
  perform rules.fn_assert_can_mutate_workflow_recommendation(p_recommendation_id);
  return rules.fn_apply_dismiss_workflow_recommendation(p_recommendation_id, p_reason);
end;
$$;

-- ===========================================================================
-- Row-level security
-- ===========================================================================

alter table rules.workflow_recommendations       enable row level security;
alter table rules.workflow_recommendation_events enable row level security;

-- Recommendations: admin sees all; buyer-org members on the underlying
-- shipment see their own. Supplier / carrier have no visibility in CC-68.
drop policy if exists workflow_recommendations_select on rules.workflow_recommendations;
create policy workflow_recommendations_select on rules.workflow_recommendations
  for select using (
    identity.is_platform_admin()
    or exists (
      select 1 from shipment.shipments s
       where s.id = rules.workflow_recommendations.shipment_id
         and s.deleted_at is null
         and exists (
           select 1 from organization.memberships m
            where m.user_id = identity.current_user_id()
              and m.organization_id = s.organization_id
              and m.deleted_at is null and m.status = 'active'
         )
    )
  );

-- Event ledger: admin-only direct read (buyers receive events via the
-- SECURITY DEFINER get RPC).
drop policy if exists workflow_recommendation_events_select on rules.workflow_recommendation_events;
create policy workflow_recommendation_events_select on rules.workflow_recommendation_events
  for select using (
    identity.is_platform_admin()
  );

-- ===========================================================================
-- Grants
-- ===========================================================================

grant select on rules.workflow_recommendations       to authenticated;
grant select on rules.workflow_recommendation_events  to authenticated;

revoke all on function rules.evaluate_shipment_workflow_recommendations(uuid, jsonb, boolean) from public, anon;
grant execute on function rules.evaluate_shipment_workflow_recommendations(uuid, jsonb, boolean) to authenticated;

revoke all on function rules.admin_list_workflow_recommendations(uuid, text, int, int) from public, anon;
grant execute on function rules.admin_list_workflow_recommendations(uuid, text, int, int) to authenticated;

revoke all on function rules.admin_get_workflow_recommendation(uuid) from public, anon;
grant execute on function rules.admin_get_workflow_recommendation(uuid) to authenticated;

revoke all on function rules.admin_accept_workflow_recommendation(uuid, text) from public, anon;
grant execute on function rules.admin_accept_workflow_recommendation(uuid, text) to authenticated;

revoke all on function rules.admin_dismiss_workflow_recommendation(uuid, text) from public, anon;
grant execute on function rules.admin_dismiss_workflow_recommendation(uuid, text) to authenticated;

revoke all on function rules.buyer_list_workflow_recommendations(uuid, text, int, int) from public, anon;
grant execute on function rules.buyer_list_workflow_recommendations(uuid, text, int, int) to authenticated;

revoke all on function rules.buyer_get_workflow_recommendation(uuid) from public, anon;
grant execute on function rules.buyer_get_workflow_recommendation(uuid) to authenticated;

revoke all on function rules.buyer_accept_workflow_recommendation(uuid, text) from public, anon;
grant execute on function rules.buyer_accept_workflow_recommendation(uuid, text) to authenticated;

revoke all on function rules.buyer_dismiss_workflow_recommendation(uuid, text) from public, anon;
grant execute on function rules.buyer_dismiss_workflow_recommendation(uuid, text) to authenticated;

commit;
