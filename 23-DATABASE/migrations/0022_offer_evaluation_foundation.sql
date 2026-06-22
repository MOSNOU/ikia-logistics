-- CC-11 / Migration 0022 — Offer Evaluation / Buyer Decision Foundation
-- Fifth business domain (after supplier, commodity, rfq, offer).
-- Append-only over migrations 0001-0021.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists evaluation;
grant usage on schema evaluation to anon, authenticated, service_role;
comment on schema evaluation is
  'iKIA Phase 2 — buyer-side offer evaluation and decision domain.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type evaluation.evaluation_status as enum (
  'draft', 'in_review', 'completed', 'cancelled'
);

create type evaluation.decision_status as enum (
  'shortlisted', 'rejected', 'selected_for_contract'
);

-- ===========================================================================
-- 3. Tables (5)
-- ===========================================================================

-- 3.1 offer_evaluations ------------------------------------------------------
create table evaluation.offer_evaluations (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  request_id          uuid not null references rfq.requests(id) on delete restrict,
  offer_id            uuid not null references offer.supplier_offers(id) on delete restrict,
  evaluator_user_id   uuid not null references auth.users(id),

  status              evaluation.evaluation_status not null default 'draft',
  technical_notes     text,
  commercial_notes    text,
  risk_notes          text,
  overall_notes       text,
  metadata            jsonb not null default '{}'::jsonb,

  completed_at        timestamptz,
  completed_by        uuid references auth.users(id),
  cancelled_at        timestamptz,
  cancelled_by        uuid references auth.users(id),
  cancelled_reason    text,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table evaluation.offer_evaluations is
  'Buyer evaluation of a supplier offer. One active evaluation per (offer, evaluator).';

create unique index offer_evaluations_unique_active
  on evaluation.offer_evaluations(offer_id, evaluator_user_id)
  where deleted_at is null;

create index offer_evaluations_request_idx on evaluation.offer_evaluations(request_id);
create index offer_evaluations_offer_idx   on evaluation.offer_evaluations(offer_id);
create index offer_evaluations_status_idx  on evaluation.offer_evaluations(status);

-- 3.2 offer_evaluation_scores ----------------------------------------------
create table evaluation.offer_evaluation_scores (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  evaluation_id       uuid not null references evaluation.offer_evaluations(id) on delete cascade,

  dimension           text not null,
  score_value         numeric,
  max_score           numeric,
  weight              numeric,
  weighted_score      numeric,
  notes               text,
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table evaluation.offer_evaluation_scores is
  'Per-dimension score rows. Suggested dimensions: price, delivery, technical_compliance, document_readiness, supplier_reliability, payment_terms, risk, overall.';

create unique index offer_evaluation_scores_unique_active
  on evaluation.offer_evaluation_scores(evaluation_id, lower(dimension))
  where deleted_at is null;

create index offer_evaluation_scores_eval_idx on evaluation.offer_evaluation_scores(evaluation_id);

-- 3.3 offer_comparison_snapshots (immutable) -------------------------------
create table evaluation.offer_comparison_snapshots (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  request_id          uuid not null references rfq.requests(id) on delete restrict,

  title               text not null,
  snapshot_data       jsonb not null default '{}'::jsonb,
  notes               text,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now()
);

comment on table evaluation.offer_comparison_snapshots is
  'Immutable buyer-side snapshot of RFQ comparison data. No UPDATE/DELETE policies.';

create index offer_comparison_snapshots_request_idx
  on evaluation.offer_comparison_snapshots(request_id, created_at desc);

-- 3.4 offer_decisions ------------------------------------------------------
create table evaluation.offer_decisions (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  request_id          uuid not null references rfq.requests(id) on delete restrict,
  offer_id            uuid not null references offer.supplier_offers(id) on delete restrict,

  decision_status     evaluation.decision_status not null,
  reason              text,
  decision_notes      text,
  decided_by          uuid references auth.users(id),
  decided_at          timestamptz not null default now(),
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table evaluation.offer_decisions is
  'Buyer decision record per offer. One active decision per offer; status can be updated via decision RPCs and tracked via decision_events.';

create unique index offer_decisions_unique_active
  on evaluation.offer_decisions(offer_id)
  where deleted_at is null;

create index offer_decisions_request_idx on evaluation.offer_decisions(request_id);
create index offer_decisions_status_idx  on evaluation.offer_decisions(decision_status);

-- 3.5 offer_decision_events (immutable) ------------------------------------
create table evaluation.offer_decision_events (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references identity.tenants(id) on delete restrict,
  organization_id       uuid not null references organization.organizations(id) on delete cascade,
  decision_id           uuid not null references evaluation.offer_decisions(id) on delete cascade,
  offer_id              uuid not null references offer.supplier_offers(id) on delete restrict,
  request_id            uuid not null references rfq.requests(id) on delete restrict,

  from_status           evaluation.decision_status,
  to_status             evaluation.decision_status not null,
  actor_user_id         uuid references auth.users(id),
  actor_organization_id uuid references organization.organizations(id),
  reason                text,
  payload               jsonb not null default '{}'::jsonb,
  created_at            timestamptz not null default now()
);

comment on table evaluation.offer_decision_events is
  'Immutable audit trail of buyer decision transitions. No UPDATE/DELETE policies.';

create index offer_decision_events_decision_idx
  on evaluation.offer_decision_events(decision_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function evaluation.fn_audit(
  p_action_code text,
  p_resource_id uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_o uuid;
begin
  -- Lookup tenant/org from offer_evaluations or offer_decisions or snapshot.
  select tenant_id, organization_id into v_t, v_o
    from evaluation.offer_evaluations where id = p_resource_id;
  if v_t is null then
    select tenant_id, organization_id into v_t, v_o
      from evaluation.offer_decisions where id = p_resource_id;
  end if;
  if v_t is null then
    select tenant_id, organization_id into v_t, v_o
      from evaluation.offer_comparison_snapshots where id = p_resource_id;
  end if;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'evaluation', p_resource_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_assert_buyer_for_offer --------------------------------------------
create or replace function evaluation.fn_assert_buyer_for_offer(p_offer_id uuid)
returns table(buyer_org_id uuid, request_id uuid)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org  uuid;
  v_request_id uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'evaluation: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;

  select r.organization_id, r.id
    into v_buyer_org, v_request_id
    from offer.supplier_offers so
    join rfq.requests r on r.id = so.request_id
   where so.id = p_offer_id and so.deleted_at is null;
  if v_buyer_org is null then
    raise exception 'evaluation: offer not found' using errcode = 'P0002';
  end if;

  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'evaluation: offer is not on caller''s RFQ' using errcode = '42501';
    end if;
  end if;

  return query select v_buyer_org, v_request_id;
end;
$$;

-- 4.3 fn_assert_buyer_for_request ------------------------------------------
create or replace function evaluation.fn_assert_buyer_for_request(p_request_id uuid)
returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org  uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'evaluation: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  select r.organization_id into v_buyer_org
    from rfq.requests r where r.id = p_request_id and r.deleted_at is null;
  if v_buyer_org is null then
    raise exception 'evaluation: rfq not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'evaluation: rfq is not in caller''s organization' using errcode = '42501';
    end if;
  end if;
  return v_buyer_org;
end;
$$;

-- 4.4 fn_assert_offer_actionable -------------------------------------------
-- Offer must be in submitted/shortlisted/rejected — never draft/withdrawn/expired/accepted.
create or replace function evaluation.fn_assert_offer_actionable(p_offer_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status offer.offer_status;
begin
  select status into v_status from offer.supplier_offers
   where id = p_offer_id and deleted_at is null;
  if v_status is null then
    raise exception 'evaluation: offer not found' using errcode = 'P0002';
  end if;
  if v_status not in ('submitted', 'shortlisted', 'rejected') then
    raise exception 'evaluation: offer status % is not actionable', v_status
      using errcode = 'P0001';
  end if;
end;
$$;

-- 4.5 fn_assert_evaluation_owned -------------------------------------------
create or replace function evaluation.fn_assert_evaluation_owned(p_evaluation_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_org from evaluation.offer_evaluations
   where id = p_evaluation_id and deleted_at is null;
  if v_org is null then
    raise exception 'evaluation: not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'evaluation: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'evaluation: not owned by caller organization' using errcode = '42501';
  end if;
end;
$$;

-- 4.6 fn_assert_evaluation_editable ----------------------------------------
create or replace function evaluation.fn_assert_evaluation_editable(p_evaluation_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status evaluation.evaluation_status;
begin
  select status into v_status from evaluation.offer_evaluations
   where id = p_evaluation_id and deleted_at is null;
  if v_status is null then
    raise exception 'evaluation: not found' using errcode = 'P0002';
  end if;
  if v_status not in ('draft', 'in_review') then
    raise exception 'evaluation: locked (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- 4.7 fn_record_decision_event ---------------------------------------------
create or replace function evaluation.fn_record_decision_event(
  p_decision_id uuid,
  p_offer_id    uuid,
  p_request_id  uuid,
  p_from        evaluation.decision_status,
  p_to          evaluation.decision_status,
  p_reason      text default null,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from evaluation.offer_decisions where id = p_decision_id;
  insert into evaluation.offer_decision_events (
    tenant_id, organization_id, decision_id, offer_id, request_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_decision_id, p_offer_id, p_request_id,
    p_from, p_to, auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 4.8 fn_sync_offer_status_for_decision ------------------------------------
-- Optional: sync offer.supplier_offers.status to mirror decision for
-- 'shortlisted' and 'rejected' only. 'selected_for_contract' does NOT change
-- offer status — that semantic stays inside the evaluation domain until the
-- contract foundation exists.
create or replace function evaluation.fn_sync_offer_status_for_decision(
  p_offer_id uuid,
  p_status   evaluation.decision_status
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current offer.offer_status;
  v_target  offer.offer_status;
begin
  if p_status not in ('shortlisted', 'rejected') then
    return;
  end if;
  v_target := case p_status
                when 'shortlisted' then 'shortlisted'::offer.offer_status
                when 'rejected'    then 'rejected'::offer.offer_status
              end;
  select status into v_current from offer.supplier_offers
   where id = p_offer_id and deleted_at is null;
  if v_current is null then
    return;
  end if;
  -- Only sync from non-terminal active states.
  if v_current not in ('submitted', 'shortlisted', 'rejected') then
    return;
  end if;
  if v_current = v_target then
    return;
  end if;
  update offer.supplier_offers
     set status         = v_target,
         shortlisted_at = case when v_target = 'shortlisted' then now() else shortlisted_at end,
         shortlisted_by = case when v_target = 'shortlisted' then auth.uid() else shortlisted_by end,
         rejected_at    = case when v_target = 'rejected'    then now() else rejected_at end,
         rejected_by    = case when v_target = 'rejected'    then auth.uid() else rejected_by end,
         updated_by     = auth.uid()
   where id = p_offer_id;
  -- Mirror an offer status_events row for traceability on the offer side.
  insert into offer.supplier_offer_status_events (
    tenant_id, organization_id, offer_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason
  )
  select so.tenant_id, so.organization_id, so.id,
         v_current, v_target, auth.uid(), so.organization_id, 'buyer_decision_sync'
    from offer.supplier_offers so where so.id = p_offer_id;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table evaluation.offer_evaluations           enable row level security;
alter table evaluation.offer_evaluation_scores     enable row level security;
alter table evaluation.offer_comparison_snapshots  enable row level security;
alter table evaluation.offer_decisions             enable row level security;
alter table evaluation.offer_decision_events       enable row level security;

-- 5.1 offer_evaluations: buyer org + platform_admin (no supplier visibility).
drop policy if exists offer_evaluations_select on evaluation.offer_evaluations;
create policy offer_evaluations_select on evaluation.offer_evaluations
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = evaluation.offer_evaluations.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists offer_evaluations_admin_modify on evaluation.offer_evaluations;
create policy offer_evaluations_admin_modify on evaluation.offer_evaluations
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 offer_evaluation_scores: same as parent eval (buyer org + admin).
drop policy if exists offer_evaluation_scores_select on evaluation.offer_evaluation_scores;
create policy offer_evaluation_scores_select on evaluation.offer_evaluation_scores
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = evaluation.offer_evaluation_scores.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists offer_evaluation_scores_admin_modify on evaluation.offer_evaluation_scores;
create policy offer_evaluation_scores_admin_modify on evaluation.offer_evaluation_scores
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 offer_comparison_snapshots: buyer org + admin.
drop policy if exists offer_comparison_snapshots_select on evaluation.offer_comparison_snapshots;
create policy offer_comparison_snapshots_select on evaluation.offer_comparison_snapshots
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = evaluation.offer_comparison_snapshots.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

-- No INSERT/UPDATE/DELETE policies on snapshots — append-only via RPC.

-- 5.4 offer_decisions: buyer org members + supplier (only own offers) + admin.
drop policy if exists offer_decisions_select on evaluation.offer_decisions;
create policy offer_decisions_select on evaluation.offer_decisions
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = evaluation.offer_decisions.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from offer.supplier_offers so
         join supplier.suppliers s on s.id = so.supplier_id
         join organization.memberships m on m.organization_id = s.organization_id
        where so.id = evaluation.offer_decisions.offer_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists offer_decisions_admin_modify on evaluation.offer_decisions;
create policy offer_decisions_admin_modify on evaluation.offer_decisions
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.5 offer_decision_events: same visibility as parent decision.
drop policy if exists offer_decision_events_select on evaluation.offer_decision_events;
create policy offer_decision_events_select on evaluation.offer_decision_events
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = evaluation.offer_decision_events.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
    or exists (
      select 1 from offer.supplier_offers so
       join supplier.suppliers s on s.id = so.supplier_id
       join organization.memberships m on m.organization_id = s.organization_id
      where so.id = evaluation.offer_decision_events.offer_id
        and m.user_id = identity.current_user_id()
        and m.deleted_at is null
        and m.status = 'active'
    )
  );

-- No INSERT/UPDATE/DELETE policies on decision_events — append-only via RPC.

-- ===========================================================================
-- 6. Buyer RPCs (12)
-- ===========================================================================

-- 6.1 buyer_create_evaluation ----------------------------------------------
create or replace function evaluation.buyer_create_evaluation(
  p_offer_id          uuid,
  p_evaluator_user_id uuid default null,
  p_technical_notes   text default null,
  p_commercial_notes  text default null,
  p_risk_notes        text default null,
  p_overall_notes     text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_evaluator uuid := coalesce(p_evaluator_user_id, v_actor);
  v_buyer_org uuid; v_request_id uuid;
  v_tenant uuid;
  v_id uuid;
begin
  select buyer_org_id, request_id into v_buyer_org, v_request_id
    from evaluation.fn_assert_buyer_for_offer(p_offer_id);
  perform evaluation.fn_assert_offer_actionable(p_offer_id);

  if exists (
    select 1 from evaluation.offer_evaluations
     where offer_id = p_offer_id and evaluator_user_id = v_evaluator and deleted_at is null
  ) then
    raise exception 'evaluation: active evaluation already exists for this evaluator and offer'
      using errcode = '23505';
  end if;

  select r.tenant_id into v_tenant from rfq.requests r where r.id = v_request_id;

  insert into evaluation.offer_evaluations (
    tenant_id, organization_id, request_id, offer_id, evaluator_user_id,
    status, technical_notes, commercial_notes, risk_notes, overall_notes,
    created_by, updated_by
  ) values (
    v_tenant, v_buyer_org, v_request_id, p_offer_id, v_evaluator,
    'draft', p_technical_notes, p_commercial_notes, p_risk_notes, p_overall_notes,
    v_actor, v_actor
  ) returning id into v_id;

  perform evaluation.fn_audit('evaluation.created', v_id,
    jsonb_build_object('offer_id', p_offer_id::text));
  return v_id;
end;
$$;

-- 6.2 buyer_update_evaluation ----------------------------------------------
create or replace function evaluation.buyer_update_evaluation(
  p_evaluation_id     uuid,
  p_technical_notes   text default null,
  p_commercial_notes  text default null,
  p_risk_notes        text default null,
  p_overall_notes     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform evaluation.fn_assert_evaluation_owned(p_evaluation_id);
  perform evaluation.fn_assert_evaluation_editable(p_evaluation_id);

  update evaluation.offer_evaluations
     set technical_notes  = coalesce(p_technical_notes,  technical_notes),
         commercial_notes = coalesce(p_commercial_notes, commercial_notes),
         risk_notes       = coalesce(p_risk_notes,       risk_notes),
         overall_notes    = coalesce(p_overall_notes,    overall_notes),
         updated_by       = v_actor
   where id = p_evaluation_id;

  perform evaluation.fn_audit('evaluation.updated', p_evaluation_id);
end;
$$;

-- 6.3 buyer_upsert_score ---------------------------------------------------
create or replace function evaluation.buyer_upsert_score(
  p_evaluation_id uuid,
  p_dimension     text,
  p_score_value   numeric default null,
  p_max_score     numeric default null,
  p_weight        numeric default null,
  p_weighted_score numeric default null,
  p_notes         text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform evaluation.fn_assert_evaluation_owned(p_evaluation_id);
  perform evaluation.fn_assert_evaluation_editable(p_evaluation_id);

  select tenant_id, organization_id into v_tenant, v_org
    from evaluation.offer_evaluations where id = p_evaluation_id;

  insert into evaluation.offer_evaluation_scores (
    tenant_id, organization_id, evaluation_id, dimension,
    score_value, max_score, weight, weighted_score, notes,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_evaluation_id, p_dimension,
    p_score_value, p_max_score, p_weight, p_weighted_score, p_notes,
    v_actor, v_actor
  )
  on conflict (evaluation_id, lower(dimension)) where deleted_at is null
  do update set
    score_value    = excluded.score_value,
    max_score      = excluded.max_score,
    weight         = excluded.weight,
    weighted_score = excluded.weighted_score,
    notes          = excluded.notes,
    updated_by     = v_actor
  returning id into v_id;

  perform evaluation.fn_audit('evaluation.score_upserted', p_evaluation_id,
    jsonb_build_object('score_id', v_id::text, 'dimension', p_dimension));
  return v_id;
end;
$$;

-- 6.4 buyer_remove_score ---------------------------------------------------
create or replace function evaluation.buyer_remove_score(p_score_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_eval uuid;
begin
  select evaluation_id into v_eval from evaluation.offer_evaluation_scores
   where id = p_score_id and deleted_at is null;
  if v_eval is null then
    raise exception 'evaluation: score not found' using errcode = 'P0002';
  end if;
  perform evaluation.fn_assert_evaluation_owned(v_eval);
  perform evaluation.fn_assert_evaluation_editable(v_eval);

  update evaluation.offer_evaluation_scores
     set deleted_at = now(), updated_by = v_actor
   where id = p_score_id;

  perform evaluation.fn_audit('evaluation.score_removed', v_eval,
    jsonb_build_object('score_id', p_score_id::text));
end;
$$;

-- 6.5 buyer_complete_evaluation : draft|in_review → completed --------------
create or replace function evaluation.buyer_complete_evaluation(p_evaluation_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status evaluation.evaluation_status;
  v_actor uuid := auth.uid();
begin
  perform evaluation.fn_assert_evaluation_owned(p_evaluation_id);
  select status into v_status from evaluation.offer_evaluations where id = p_evaluation_id;
  if v_status not in ('draft', 'in_review') then
    raise exception 'evaluation: invalid_transition: cannot complete from %', v_status
      using errcode = 'P0001';
  end if;

  update evaluation.offer_evaluations
     set status       = 'completed',
         completed_at = now(),
         completed_by = v_actor,
         updated_by   = v_actor
   where id = p_evaluation_id;

  perform evaluation.fn_audit('evaluation.completed', p_evaluation_id);
end;
$$;

-- 6.6 buyer_cancel_evaluation ----------------------------------------------
create or replace function evaluation.buyer_cancel_evaluation(
  p_evaluation_id uuid,
  p_reason        text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status evaluation.evaluation_status;
  v_actor uuid := auth.uid();
begin
  perform evaluation.fn_assert_evaluation_owned(p_evaluation_id);
  select status into v_status from evaluation.offer_evaluations where id = p_evaluation_id;
  if v_status in ('completed', 'cancelled') then
    raise exception 'evaluation: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;

  update evaluation.offer_evaluations
     set status           = 'cancelled',
         cancelled_at     = now(),
         cancelled_by     = v_actor,
         cancelled_reason = p_reason,
         updated_by       = v_actor
   where id = p_evaluation_id;

  perform evaluation.fn_audit('evaluation.cancelled', p_evaluation_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.7 buyer_create_comparison_snapshot -------------------------------------
create or replace function evaluation.buyer_create_comparison_snapshot(
  p_request_id    uuid,
  p_title         text,
  p_snapshot_data jsonb default '{}'::jsonb,
  p_notes         text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_buyer_org uuid := evaluation.fn_assert_buyer_for_request(p_request_id);
  v_actor uuid := auth.uid();
  v_tenant uuid;
  v_id uuid;
begin
  if p_title is null or btrim(p_title) = '' then
    raise exception 'evaluation: snapshot title is required' using errcode = '22023';
  end if;
  select r.tenant_id into v_tenant from rfq.requests r where r.id = p_request_id;

  insert into evaluation.offer_comparison_snapshots (
    tenant_id, organization_id, request_id, title, snapshot_data, notes, created_by
  ) values (
    v_tenant, v_buyer_org, p_request_id, p_title,
    coalesce(p_snapshot_data, '{}'::jsonb), p_notes, v_actor
  ) returning id into v_id;

  perform evaluation.fn_audit('evaluation.snapshot_created', v_id,
    jsonb_build_object('request_id', p_request_id::text, 'title', p_title));
  return v_id;
end;
$$;

-- 6.8 buyer_list_evaluations -----------------------------------------------
create or replace function evaluation.buyer_list_evaluations(
  p_request_id uuid                          default null,
  p_status     evaluation.evaluation_status  default null,
  p_limit      integer                       default 25,
  p_offset     integer                       default 0
) returns table (
  id uuid, request_id uuid, offer_id uuid, evaluator_user_id uuid,
  status text, score_count bigint, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'evaluation: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'evaluation: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select e.id, e.request_id, e.offer_id, e.evaluator_user_id,
           e.status::text,
           (select count(*) from evaluation.offer_evaluation_scores s
             where s.evaluation_id = e.id and s.deleted_at is null),
           e.created_at, e.updated_at
      from evaluation.offer_evaluations e
     where e.deleted_at is null
       and (identity.is_platform_admin() or e.organization_id = v_caller_org)
       and (p_request_id is null or e.request_id = p_request_id)
       and (p_status     is null or e.status     = p_status)
     order by e.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.9 buyer_get_evaluation -------------------------------------------------
create or replace function evaluation.buyer_get_evaluation(p_evaluation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform evaluation.fn_assert_evaluation_owned(p_evaluation_id);
  return (
    select jsonb_build_object(
      'id', e.id, 'request_id', e.request_id, 'offer_id', e.offer_id,
      'evaluator_user_id', e.evaluator_user_id, 'status', e.status,
      'technical_notes', e.technical_notes, 'commercial_notes', e.commercial_notes,
      'risk_notes', e.risk_notes, 'overall_notes', e.overall_notes,
      'completed_at', e.completed_at, 'cancelled_at', e.cancelled_at,
      'created_at', e.created_at, 'updated_at', e.updated_at,
      'scores', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', s.id, 'dimension', s.dimension,
          'score_value', s.score_value, 'max_score', s.max_score,
          'weight', s.weight, 'weighted_score', s.weighted_score,
          'notes', s.notes
        ) order by s.created_at), '[]'::jsonb)
          from evaluation.offer_evaluation_scores s
         where s.evaluation_id = e.id and s.deleted_at is null
      )
    )
    from evaluation.offer_evaluations e where e.id = p_evaluation_id
  );
end;
$$;

-- 6.10 / 6.11 / 6.12: decision RPCs ----------------------------------------

-- Internal: record-decision implementation shared by the three decision RPCs.
create or replace function evaluation.fn_record_decision(
  p_offer_id uuid,
  p_status   evaluation.decision_status,
  p_reason   text default null,
  p_notes    text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_buyer_org uuid; v_request_id uuid;
  v_tenant uuid;
  v_existing uuid; v_current evaluation.decision_status;
  v_id uuid;
begin
  select buyer_org_id, request_id into v_buyer_org, v_request_id
    from evaluation.fn_assert_buyer_for_offer(p_offer_id);
  perform evaluation.fn_assert_offer_actionable(p_offer_id);

  select r.tenant_id into v_tenant from rfq.requests r where r.id = v_request_id;

  select id, decision_status into v_existing, v_current
    from evaluation.offer_decisions
   where offer_id = p_offer_id and deleted_at is null;

  if v_existing is null then
    insert into evaluation.offer_decisions (
      tenant_id, organization_id, request_id, offer_id,
      decision_status, reason, decision_notes,
      decided_by, decided_at, created_by, updated_by
    ) values (
      v_tenant, v_buyer_org, v_request_id, p_offer_id,
      p_status, p_reason, p_notes,
      v_actor, now(), v_actor, v_actor
    ) returning id into v_id;

    perform evaluation.fn_record_decision_event(v_id, p_offer_id, v_request_id,
      null, p_status, p_reason);
  else
    v_id := v_existing;
    if v_current = p_status then
      -- Idempotent: still update reason/notes if provided.
      update evaluation.offer_decisions
         set reason         = coalesce(p_reason, reason),
             decision_notes = coalesce(p_notes, decision_notes),
             updated_by     = v_actor
       where id = v_id;
    else
      update evaluation.offer_decisions
         set decision_status = p_status,
             reason          = coalesce(p_reason, reason),
             decision_notes  = coalesce(p_notes, decision_notes),
             decided_by      = v_actor,
             decided_at      = now(),
             updated_by      = v_actor
       where id = v_id;
      perform evaluation.fn_record_decision_event(v_id, p_offer_id, v_request_id,
        v_current, p_status, p_reason);
    end if;
  end if;

  -- Optional offer status sync (shortlisted/rejected only).
  perform evaluation.fn_sync_offer_status_for_decision(p_offer_id, p_status);

  perform evaluation.fn_audit('evaluation.decision_recorded', v_id,
    jsonb_build_object('offer_id', p_offer_id::text, 'status', p_status::text));
  return v_id;
end;
$$;

-- 6.10 buyer_shortlist_offer -----------------------------------------------
create or replace function evaluation.buyer_shortlist_offer(
  p_offer_id uuid, p_reason text default null, p_notes text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return evaluation.fn_record_decision(p_offer_id, 'shortlisted', p_reason, p_notes);
end;
$$;

-- 6.11 buyer_reject_offer --------------------------------------------------
create or replace function evaluation.buyer_reject_offer(
  p_offer_id uuid, p_reason text default null, p_notes text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return evaluation.fn_record_decision(p_offer_id, 'rejected', p_reason, p_notes);
end;
$$;

-- 6.12 buyer_select_for_contract -------------------------------------------
-- IMPORTANT: this does NOT create a contract, does NOT change offer status
-- to 'accepted'. It only records the buyer's intent to advance this offer
-- toward contract preparation. The contract foundation lands in a later CC.
create or replace function evaluation.buyer_select_for_contract(
  p_offer_id uuid, p_reason text default null, p_notes text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return evaluation.fn_record_decision(p_offer_id, 'selected_for_contract', p_reason, p_notes);
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (2 — read-only)
-- ===========================================================================

-- 7.1 supplier_list_my_decisions -------------------------------------------
create or replace function evaluation.supplier_list_my_decisions(
  p_status evaluation.decision_status default null,
  p_limit  integer                     default 25,
  p_offset integer                     default 0
) returns table (
  id uuid, offer_id uuid, request_id uuid, decision_status text,
  reason text, decided_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select d.id, d.offer_id, d.request_id, d.decision_status::text,
           d.reason, d.decided_at, d.updated_at
      from evaluation.offer_decisions d
      join offer.supplier_offers so on so.id = d.offer_id
     where d.deleted_at is null
       and so.supplier_id = v_supplier
       and (p_status is null or d.decision_status = p_status)
     order by d.decided_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 supplier_get_my_decision ---------------------------------------------
create or replace function evaluation.supplier_get_my_decision(p_decision_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_supplier uuid := supplier.fn_portal_supplier_id();
  v_offer_supplier uuid;
begin
  select so.supplier_id into v_offer_supplier
    from evaluation.offer_decisions d
    join offer.supplier_offers so on so.id = d.offer_id
   where d.id = p_decision_id and d.deleted_at is null;
  if v_offer_supplier is null then
    raise exception 'evaluation: decision not found' using errcode = 'P0002';
  end if;
  if v_offer_supplier <> v_supplier and not identity.is_platform_admin() then
    raise exception 'evaluation: decision is not on caller''s offer' using errcode = '42501';
  end if;

  return (
    select jsonb_build_object(
      'id', d.id, 'offer_id', d.offer_id, 'request_id', d.request_id,
      'decision_status', d.decision_status,
      'reason', d.reason, 'decided_at', d.decided_at,
      'created_at', d.created_at, 'updated_at', d.updated_at
    )
    from evaluation.offer_decisions d where d.id = p_decision_id
  );
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (5)
-- ===========================================================================

-- 8.1 admin_list_evaluations ----------------------------------------------
create or replace function evaluation.admin_list_evaluations(
  p_request_id uuid                          default null,
  p_offer_id   uuid                          default null,
  p_status     evaluation.evaluation_status  default null,
  p_limit      integer                       default 25,
  p_offset     integer                       default 0
) returns table (
  id uuid, organization_id uuid, request_id uuid, offer_id uuid,
  status text, evaluator_user_id uuid,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_evaluations: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.organization_id, e.request_id, e.offer_id,
           e.status::text, e.evaluator_user_id,
           e.created_at, e.updated_at
      from evaluation.offer_evaluations e
     where e.deleted_at is null
       and (p_request_id is null or e.request_id = p_request_id)
       and (p_offer_id   is null or e.offer_id   = p_offer_id)
       and (p_status     is null or e.status     = p_status)
     order by e.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_evaluation -------------------------------------------------
create or replace function evaluation.admin_get_evaluation(p_evaluation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_evaluation: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', e.id, 'organization_id', e.organization_id,
      'request_id', e.request_id, 'offer_id', e.offer_id,
      'evaluator_user_id', e.evaluator_user_id, 'status', e.status,
      'technical_notes', e.technical_notes, 'commercial_notes', e.commercial_notes,
      'risk_notes', e.risk_notes, 'overall_notes', e.overall_notes,
      'created_at', e.created_at, 'updated_at', e.updated_at,
      'scores', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', s.id, 'dimension', s.dimension,
          'score_value', s.score_value, 'max_score', s.max_score,
          'weight', s.weight, 'weighted_score', s.weighted_score
        )), '[]'::jsonb)
          from evaluation.offer_evaluation_scores s
         where s.evaluation_id = e.id and s.deleted_at is null
      )
    )
    from evaluation.offer_evaluations e where e.id = p_evaluation_id
  );
end;
$$;

-- 8.3 admin_list_decisions -------------------------------------------------
create or replace function evaluation.admin_list_decisions(
  p_request_id uuid                       default null,
  p_offer_id   uuid                       default null,
  p_status     evaluation.decision_status default null,
  p_limit      integer                    default 25,
  p_offset     integer                    default 0
) returns table (
  id uuid, organization_id uuid, request_id uuid, offer_id uuid,
  decision_status text, decided_by uuid, decided_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_decisions: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select d.id, d.organization_id, d.request_id, d.offer_id,
           d.decision_status::text, d.decided_by, d.decided_at
      from evaluation.offer_decisions d
     where d.deleted_at is null
       and (p_request_id is null or d.request_id = p_request_id)
       and (p_offer_id   is null or d.offer_id   = p_offer_id)
       and (p_status     is null or d.decision_status = p_status)
     order by d.decided_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.4 admin_get_decision ---------------------------------------------------
create or replace function evaluation.admin_get_decision(p_decision_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_decision: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', d.id, 'organization_id', d.organization_id,
      'request_id', d.request_id, 'offer_id', d.offer_id,
      'decision_status', d.decision_status, 'reason', d.reason,
      'decision_notes', d.decision_notes,
      'decided_by', d.decided_by, 'decided_at', d.decided_at,
      'created_at', d.created_at, 'updated_at', d.updated_at,
      'events', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', e.id, 'from_status', e.from_status, 'to_status', e.to_status,
          'actor_user_id', e.actor_user_id, 'reason', e.reason,
          'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from evaluation.offer_decision_events e where e.decision_id = d.id
      )
    )
    from evaluation.offer_decisions d where d.id = p_decision_id
  );
end;
$$;

-- 8.5 admin_list_decision_events -------------------------------------------
create or replace function evaluation.admin_list_decision_events(p_decision_id uuid)
returns table (
  id uuid, from_status text, to_status text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_decision_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from evaluation.offer_decision_events e
     where e.decision_id = p_decision_id
     order by e.created_at asc;
end;
$$;

-- ===========================================================================
-- 9. Trigger attachments (set_updated_at + audit)
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
      join information_schema.columns c
        on c.table_schema = t.table_schema and c.table_name = t.table_name
     where t.table_schema = 'evaluation'
       and t.table_type   = 'BASE TABLE'
       and c.column_name  = 'updated_at'
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on %I.%I',
      r.table_schema, r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on %I.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_schema, r.table_name
    );
  end loop;
end;
$$;

do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
     where t.table_schema = 'evaluation'
       and t.table_type   = 'BASE TABLE'
       and exists (
         select 1 from information_schema.columns c
          where c.table_schema = t.table_schema
            and c.table_name   = t.table_name
            and c.column_name  = 'id'
       )
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on %I.%I',
      r.table_schema, r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on %I.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_schema, r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 10. Grants (SELECT only on tables; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on evaluation.offer_evaluations          to anon, authenticated;
grant select on evaluation.offer_evaluation_scores    to anon, authenticated;
grant select on evaluation.offer_comparison_snapshots to authenticated;
grant select on evaluation.offer_decisions            to anon, authenticated;
grant select on evaluation.offer_decision_events      to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function evaluation.buyer_create_evaluation(uuid, uuid, text, text, text, text) to authenticated;
grant execute on function evaluation.buyer_update_evaluation(uuid, text, text, text, text) to authenticated;
grant execute on function evaluation.buyer_upsert_score(uuid, text, numeric, numeric, numeric, numeric, text) to authenticated;
grant execute on function evaluation.buyer_remove_score(uuid) to authenticated;
grant execute on function evaluation.buyer_complete_evaluation(uuid) to authenticated;
grant execute on function evaluation.buyer_cancel_evaluation(uuid, text) to authenticated;
grant execute on function evaluation.buyer_create_comparison_snapshot(uuid, text, jsonb, text) to authenticated;
grant execute on function evaluation.buyer_list_evaluations(uuid, evaluation.evaluation_status, integer, integer) to authenticated;
grant execute on function evaluation.buyer_get_evaluation(uuid) to authenticated;
grant execute on function evaluation.buyer_shortlist_offer(uuid, text, text) to authenticated;
grant execute on function evaluation.buyer_reject_offer(uuid, text, text) to authenticated;
grant execute on function evaluation.buyer_select_for_contract(uuid, text, text) to authenticated;

grant execute on function evaluation.supplier_list_my_decisions(evaluation.decision_status, integer, integer) to authenticated;
grant execute on function evaluation.supplier_get_my_decision(uuid) to authenticated;

grant execute on function evaluation.admin_list_evaluations(uuid, uuid, evaluation.evaluation_status, integer, integer) to authenticated;
grant execute on function evaluation.admin_get_evaluation(uuid) to authenticated;
grant execute on function evaluation.admin_list_decisions(uuid, uuid, evaluation.decision_status, integer, integer) to authenticated;
grant execute on function evaluation.admin_get_decision(uuid) to authenticated;
grant execute on function evaluation.admin_list_decision_events(uuid) to authenticated;
