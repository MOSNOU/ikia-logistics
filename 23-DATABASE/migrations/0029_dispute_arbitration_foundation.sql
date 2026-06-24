-- CC-18 / Migration 0029 — Dispute & Arbitration Workflow Foundation
-- Twelfth business-domain step. New `dispute` schema built atop CC-17.
-- Append-only over migrations 0001-0028. Does not modify any CC-17 RPC body.
--
-- Scope: dispute case + evidence + decision + settlement-integration only.
-- No external arbitration provider, no SLA timers, no notification dispatch,
-- no court export, no new role for mediator.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists dispute;
grant usage on schema dispute to anon, authenticated, service_role;
comment on schema dispute is
  'iKIA Phase 2 — dispute / arbitration workflow domain. Completes the CC-17 dispute scaffolding with cases, evidence, decisions, and settlement-side wiring. No SLA / notifications / external arbitration / court export.';

-- ===========================================================================
-- 2. Enums (6)
-- ===========================================================================
create type dispute.dispute_case_status as enum (
  'opened', 'under_review',
  'resolved_buyer', 'resolved_supplier', 'resolved_split',
  'withdrawn', 'cancelled'
);

create type dispute.party_role as enum (
  'buyer', 'supplier', 'platform_admin', 'mediator', 'observer'
);

create type dispute.evidence_kind as enum (
  'narrative', 'document', 'financial', 'photo',
  'communication_log', 'inspection_report', 'other'
);

create type dispute.evidence_status as enum (
  'submitted', 'accepted', 'rejected', 'withdrawn'
);

create type dispute.decision_outcome as enum (
  'favor_buyer', 'favor_supplier', 'split', 'no_action', 'withdrawn'
);

create type dispute.settlement_action as enum (
  'release_to_supplier', 'reverse_to_buyer', 'split', 'no_change'
);

-- ===========================================================================
-- 3. Tables (5)
-- ===========================================================================

-- 3.1 disputes -------------------------------------------------------------
create table dispute.disputes (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  settlement_id               uuid not null references settlement.settlements(id) on delete restrict,
  executed_contract_id        uuid references contract.executed_contracts(id) on delete set null,
  shipment_id                 uuid references shipment.shipments(id) on delete set null,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,

  dispute_code                text not null,
  status                      dispute.dispute_case_status not null default 'opened',
  opened_by_party             text not null,
  opened_by_user_id           uuid references auth.users(id) on delete set null,
  opened_at                   timestamptz not null default now(),
  title                       text not null,
  description                 text,
  amount_in_dispute           numeric,
  currency                    text,

  assigned_mediator_id        uuid references auth.users(id) on delete set null,
  assigned_at                 timestamptz,
  review_started_at           timestamptz,
  review_started_by           uuid references auth.users(id) on delete set null,
  resolved_at                 timestamptz,
  resolved_by                 uuid references auth.users(id) on delete set null,
  withdrawn_at                timestamptz,
  withdrawn_by                uuid references auth.users(id) on delete set null,
  withdrawn_reason            text,
  cancelled_at                timestamptz,
  cancelled_by                uuid references auth.users(id) on delete set null,
  cancelled_reason            text,

  metadata                    jsonb not null default '{}'::jsonb,

  created_by                  uuid references auth.users(id) on delete set null,
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table dispute.disputes is
  'Formal dispute case anchored to a settlement. One active case per settlement (Q1).';

-- Q1: One active (non-terminal) case per settlement.
create unique index disputes_unique_active
  on dispute.disputes(settlement_id)
  where deleted_at is null
    and status not in ('withdrawn','cancelled','resolved_buyer','resolved_supplier','resolved_split');

create unique index disputes_code_unique
  on dispute.disputes(tenant_id, lower(dispute_code))
  where deleted_at is null;

create index disputes_settlement_idx on dispute.disputes(settlement_id);
create index disputes_supplier_idx   on dispute.disputes(supplier_id);
create index disputes_status_idx     on dispute.disputes(status);

-- 3.2 dispute_participants -------------------------------------------------
create table dispute.dispute_participants (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  dispute_id              uuid not null references dispute.disputes(id) on delete cascade,

  party_role              dispute.party_role not null,
  party_user_id           uuid references auth.users(id) on delete set null,
  party_organization_id   uuid references organization.organizations(id) on delete set null,
  party_supplier_id       uuid references supplier.suppliers(id) on delete set null,
  display_name            text not null,
  notes                   text,
  metadata                jsonb not null default '{}'::jsonb,

  created_by              uuid references auth.users(id) on delete set null,
  created_at              timestamptz not null default now(),
  updated_by              uuid references auth.users(id) on delete set null,
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz,
  version                 integer not null default 1
);

comment on table dispute.dispute_participants is
  'Named participants on a dispute. Auto-populated with buyer + supplier; admin adds mediator and observers.';

create index dispute_participants_dispute_idx on dispute.dispute_participants(dispute_id);

-- 3.3 dispute_evidence -----------------------------------------------------
create table dispute.dispute_evidence (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  dispute_id                  uuid not null references dispute.disputes(id) on delete cascade,

  submitter_party_role        dispute.party_role not null,
  submitter_user_id           uuid references auth.users(id) on delete set null,
  submitter_organization_id   uuid references organization.organizations(id) on delete set null,
  submitter_supplier_id       uuid references supplier.suppliers(id) on delete set null,

  evidence_kind               dispute.evidence_kind not null default 'narrative',
  title                       text not null,
  narrative                   text,
  status                      dispute.evidence_status not null default 'submitted',
  reviewed_at                 timestamptz,
  reviewed_by                 uuid references auth.users(id) on delete set null,
  review_notes                text,
  metadata                    jsonb not null default '{}'::jsonb,
  sort_order                  integer not null default 0,

  created_by                  uuid references auth.users(id) on delete set null,
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table dispute.dispute_evidence is
  'Evidence rows attached to a dispute. Files live in app_storage (entity_type=''dispute_evidence''). metadata.confidential=true hides narrative from opposing party.';

create index dispute_evidence_dispute_idx on dispute.dispute_evidence(dispute_id);

-- 3.4 dispute_decisions ----------------------------------------------------
create table dispute.dispute_decisions (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  dispute_id              uuid not null references dispute.disputes(id) on delete cascade,
  decided_by              uuid references auth.users(id) on delete set null,

  outcome                 dispute.decision_outcome not null,
  settlement_action       dispute.settlement_action not null,
  buyer_share_amount      numeric not null default 0,
  supplier_share_amount   numeric not null default 0,
  fee_share_amount        numeric not null default 0,
  reason                  text,
  mediator_notes          text,
  metadata                jsonb not null default '{}'::jsonb,

  voided_at               timestamptz,
  voided_by               uuid references auth.users(id) on delete set null,
  voided_reason           text,

  created_at              timestamptz not null default now()
);

comment on table dispute.dispute_decisions is
  'Mediator decisions. Q3: exactly one active (non-voided) decision per dispute. Corrections require admin_void_decision then a new admin_record_decision.';

-- Q3: One active (non-voided) decision per dispute.
create unique index dispute_decisions_unique_active
  on dispute.dispute_decisions(dispute_id)
  where voided_at is null;

create index dispute_decisions_dispute_idx on dispute.dispute_decisions(dispute_id);

-- 3.5 dispute_events (immutable) -------------------------------------------
create table dispute.dispute_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  dispute_id              uuid not null references dispute.disputes(id) on delete cascade,

  from_status             dispute.dispute_case_status,
  to_status               dispute.dispute_case_status,
  event_type              text not null,
  actor_user_id           uuid references auth.users(id) on delete set null,
  actor_organization_id   uuid references organization.organizations(id) on delete set null,
  reason                  text,
  payload                 jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table dispute.dispute_events is
  'Immutable dispute lifecycle + structural trail. No UPDATE/DELETE policies.';

create index dispute_events_dispute_idx on dispute.dispute_events(dispute_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function dispute.fn_audit(
  p_action_code text,
  p_dispute_id  uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from dispute.disputes where id = p_dispute_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'dispute', p_dispute_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_next_dispute_code -------------------------------------------------
create or replace function dispute.fn_next_dispute_code(p_tenant_id uuid)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare v_code text;
begin
  v_code := 'DSP-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

-- 4.3 fn_record_dispute_event ----------------------------------------------
create or replace function dispute.fn_record_dispute_event(
  p_dispute_id uuid,
  p_from       dispute.dispute_case_status,
  p_to         dispute.dispute_case_status,
  p_event_type text,
  p_reason     text default null,
  p_payload    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from dispute.disputes where id = p_dispute_id;
  insert into dispute.dispute_events (
    tenant_id, organization_id, dispute_id,
    from_status, to_status, event_type, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_dispute_id,
    p_from, p_to, p_event_type, auth.uid(), v_o, p_reason, coalesce(p_payload, '{}'::jsonb)
  );
end;
$$;

-- 4.4 fn_assert_buyer_for_dispute ------------------------------------------
create or replace function dispute.fn_assert_buyer_for_dispute(p_dispute_id uuid)
returns dispute.dispute_case_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid; v_status dispute.dispute_case_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id, status into v_org, v_status
    from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_org is null then
    raise exception 'dispute: not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'dispute: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'dispute: not owned by caller organization' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.5 fn_assert_supplier_for_dispute ---------------------------------------
create or replace function dispute.fn_assert_supplier_for_dispute(p_dispute_id uuid)
returns dispute.dispute_case_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_sup uuid := supplier.fn_portal_supplier_id();
  v_sup uuid; v_status dispute.dispute_case_status;
begin
  select supplier_id, status into v_sup, v_status
    from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_sup is null then
    raise exception 'dispute: not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if v_sup <> v_caller_sup then
    raise exception 'dispute: not on caller''s supplier' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.6 fn_assert_dispute_open_for_submission --------------------------------
create or replace function dispute.fn_assert_dispute_open_for_submission(p_dispute_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status dispute.dispute_case_status;
begin
  select status into v_status from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_status is null then
    raise exception 'dispute: not found' using errcode = 'P0002';
  end if;
  if v_status not in ('opened', 'under_review') then
    raise exception 'dispute: not open for submission (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- 4.7 fn_apply_decision_to_settlement (Q10: 3 ledger entries on split) -----
create or replace function dispute.fn_apply_decision_to_settlement(p_dispute_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_dispute   dispute.disputes%rowtype;
  v_settle    settlement.settlements%rowtype;
  v_decision  dispute.dispute_decisions%rowtype;
  v_escrow    uuid;
  v_actor uuid := auth.uid();
  v_settlement_dispute_status settlement.dispute_status;
begin
  select * into v_dispute from dispute.disputes where id = p_dispute_id;
  select * into v_settle  from settlement.settlements where id = v_dispute.settlement_id;
  select * into v_decision from dispute.dispute_decisions
   where dispute_id = p_dispute_id and voided_at is null;
  v_escrow := v_settle.escrow_account_id;

  case v_decision.settlement_action
    when 'release_to_supplier' then
      if v_escrow is not null and v_settle.held_amount > 0 then
        perform settlement.fn_record_escrow_entry(
          v_escrow, 'release', v_settle.held_amount, v_settle.id, null,
          'dispute_resolution_release', v_decision.reason, '{}'::jsonb
        );
        perform settlement.fn_record_escrow_entry(
          v_escrow, 'debit', v_settle.held_amount, v_settle.id, null,
          'dispute_resolution_release_debit', v_decision.reason, '{}'::jsonb
        );
        perform settlement.fn_recompute_escrow_balances(v_escrow);
      end if;
      update settlement.settlements
         set status = 'released',
             released_amount = coalesce(v_settle.held_amount, v_settle.released_amount),
             released_at = coalesce(released_at, now()),
             released_by = coalesce(released_by, v_actor),
             release_reason = coalesce(release_reason, 'dispute_resolution'),
             updated_by = v_actor
       where id = v_settle.id;
      v_settlement_dispute_status := 'resolved_supplier'::settlement.dispute_status;

    when 'reverse_to_buyer' then
      if v_escrow is not null and v_settle.held_amount > 0 then
        perform settlement.fn_record_escrow_entry(
          v_escrow, 'reverse', v_settle.held_amount, v_settle.id, null,
          'dispute_resolution_reverse', v_decision.reason, '{}'::jsonb
        );
        perform settlement.fn_recompute_escrow_balances(v_escrow);
      end if;
      update settlement.settlements
         set status = 'cancelled',
             cancelled_at = coalesce(cancelled_at, now()),
             cancelled_by = coalesce(cancelled_by, v_actor),
             cancelled_reason = coalesce(cancelled_reason, 'dispute_resolution_reverse'),
             updated_by = v_actor
       where id = v_settle.id;
      v_settlement_dispute_status := 'resolved_buyer'::settlement.dispute_status;

    when 'split' then
      -- Q10: 3 ledger entries (release + debit for supplier share, reverse for buyer share).
      if v_escrow is not null then
        if v_decision.supplier_share_amount > 0 then
          perform settlement.fn_record_escrow_entry(
            v_escrow, 'release', v_decision.supplier_share_amount, v_settle.id, null,
            'dispute_split_supplier_release', v_decision.reason, '{}'::jsonb
          );
          perform settlement.fn_record_escrow_entry(
            v_escrow, 'debit', v_decision.supplier_share_amount, v_settle.id, null,
            'dispute_split_supplier_debit', v_decision.reason, '{}'::jsonb
          );
        end if;
        if v_decision.buyer_share_amount > 0 then
          perform settlement.fn_record_escrow_entry(
            v_escrow, 'reverse', v_decision.buyer_share_amount, v_settle.id, null,
            'dispute_split_buyer_reverse', v_decision.reason, '{}'::jsonb
          );
        end if;
        perform settlement.fn_recompute_escrow_balances(v_escrow);
      end if;
      -- Q4: settlement_status stays 'released' + metadata flag (no new enum value).
      update settlement.settlements
         set status = 'released',
             released_amount = coalesce(v_decision.supplier_share_amount, 0),
             released_at = coalesce(released_at, now()),
             released_by = coalesce(released_by, v_actor),
             release_reason = coalesce(release_reason, 'dispute_resolution_split'),
             metadata = coalesce(metadata, '{}'::jsonb)
                         || jsonb_build_object(
                              'dispute_resolution',
                              jsonb_build_object(
                                'split', true,
                                'supplier_share', v_decision.supplier_share_amount,
                                'buyer_share', v_decision.buyer_share_amount,
                                'dispute_id', p_dispute_id::text
                              )
                           ),
             updated_by = v_actor
       where id = v_settle.id;
      v_settlement_dispute_status := 'resolved_supplier'::settlement.dispute_status;

    when 'no_change' then
      -- Settlement state untouched; only dispute_status on settlement flips to 'withdrawn'
      -- (neither party prevailed materially).
      v_settlement_dispute_status := 'withdrawn'::settlement.dispute_status;

  end case;

  if v_settlement_dispute_status is not null then
    update settlement.settlements
       set dispute_status = v_settlement_dispute_status, updated_by = v_actor
     where id = v_settle.id;
  end if;

  perform dispute.fn_record_dispute_event(
    p_dispute_id, v_dispute.status, v_dispute.status,
    'settlement_action_applied', v_decision.reason,
    jsonb_build_object('settlement_action', v_decision.settlement_action::text)
  );
end;
$$;

-- 4.8 fn_autocreate_from_settlement (trigger for Q7-A) ---------------------
create or replace function dispute.fn_autocreate_from_settlement()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_existing uuid;
  v_code text;
  v_dispute_id uuid;
  v_supplier_name text;
  v_buyer_name text;
begin
  if new.dispute_status <> 'opened' then return new; end if;
  if old.dispute_status = 'opened' then return new; end if;

  select id into v_existing from dispute.disputes
   where settlement_id = new.id and deleted_at is null
     and status not in ('withdrawn','cancelled','resolved_buyer','resolved_supplier','resolved_split');
  if v_existing is not null then return new; end if;

  v_code := dispute.fn_next_dispute_code(new.tenant_id);
  select o.name_en into v_supplier_name
    from supplier.suppliers s left join organization.organizations o on o.id = s.organization_id
   where s.id = new.supplier_id;
  v_supplier_name := coalesce(v_supplier_name, 'Supplier');
  select name_en into v_buyer_name from organization.organizations where id = new.organization_id;
  v_buyer_name := coalesce(v_buyer_name, 'Buyer');

  insert into dispute.disputes (
    tenant_id, organization_id, settlement_id, executed_contract_id, shipment_id,
    supplier_id, supplier_organization_id, dispute_code, status, opened_by_party,
    opened_by_user_id, opened_at, title, description, currency,
    created_by, updated_by
  ) values (
    new.tenant_id, new.organization_id, new.id, new.executed_contract_id, new.shipment_id,
    new.supplier_id, new.supplier_organization_id, v_code, 'opened',
    coalesce(new.dispute_opened_by_party, 'unknown'), new.disputed_by,
    coalesce(new.disputed_at, now()),
    coalesce(new.dispute_reason, 'Auto-created from settlement dispute'),
    new.dispute_reason, new.currency,
    new.disputed_by, new.disputed_by
  ) returning id into v_dispute_id;

  insert into dispute.dispute_participants (
    tenant_id, organization_id, dispute_id, party_role,
    party_organization_id, display_name, created_by, updated_by
  ) values (
    new.tenant_id, new.organization_id, v_dispute_id, 'buyer'::dispute.party_role,
    new.organization_id, v_buyer_name, new.disputed_by, new.disputed_by
  );

  insert into dispute.dispute_participants (
    tenant_id, organization_id, dispute_id, party_role,
    party_supplier_id, party_organization_id, display_name, created_by, updated_by
  ) values (
    new.tenant_id, new.organization_id, v_dispute_id, 'supplier'::dispute.party_role,
    new.supplier_id, new.supplier_organization_id, v_supplier_name, new.disputed_by, new.disputed_by
  );

  insert into dispute.dispute_events (
    tenant_id, organization_id, dispute_id,
    from_status, to_status, event_type, actor_user_id, actor_organization_id, reason
  ) values (
    new.tenant_id, new.organization_id, v_dispute_id,
    null, 'opened', 'autocreated_from_settlement', new.disputed_by, new.organization_id,
    new.dispute_reason
  );

  return new;
end;
$$;

-- Trigger attachment on settlement.settlements — strictly additive; CC-17 RPCs unmodified.
drop trigger if exists trg_dispute_autocreate on settlement.settlements;
create trigger trg_dispute_autocreate
  after update on settlement.settlements
  for each row
  when (old.dispute_status is distinct from new.dispute_status)
  execute function dispute.fn_autocreate_from_settlement();

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table dispute.disputes               enable row level security;
alter table dispute.dispute_participants   enable row level security;
alter table dispute.dispute_evidence       enable row level security;
alter table dispute.dispute_decisions      enable row level security;
alter table dispute.dispute_events         enable row level security;

-- 5.1 disputes -------------------------------------------------------------
drop policy if exists disputes_select on dispute.disputes;
create policy disputes_select on dispute.disputes
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = dispute.disputes.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = dispute.disputes.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists disputes_admin_modify on dispute.disputes;
create policy disputes_admin_modify on dispute.disputes
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 dispute_participants -------------------------------------------------
drop policy if exists dispute_participants_select on dispute.dispute_participants;
create policy dispute_participants_select on dispute.dispute_participants
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from dispute.disputes d
       where d.id = dispute_participants.dispute_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = d.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = d.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists dispute_participants_admin_modify on dispute.dispute_participants;
create policy dispute_participants_admin_modify on dispute.dispute_participants
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 dispute_evidence: Q6 confidentiality enforced via RLS ----------------
drop policy if exists dispute_evidence_select on dispute.dispute_evidence;
create policy dispute_evidence_select on dispute.dispute_evidence
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from dispute.disputes d
       where d.id = dispute_evidence.dispute_id
         and d.deleted_at is null
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = d.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = d.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
    and (
      -- Q6 confidentiality: hide from opposing party only.
      identity.is_platform_admin()
      or submitter_user_id = identity.current_user_id()
      or coalesce(metadata->>'confidential', 'false')::boolean = false
      or (
        submitter_party_role = 'buyer'::dispute.party_role
        and exists (
          select 1 from dispute.disputes d
           join organization.memberships m on m.organization_id = d.organization_id
          where d.id = dispute_evidence.dispute_id
            and m.user_id = identity.current_user_id()
            and m.deleted_at is null and m.status = 'active'
        )
      )
      or (
        submitter_party_role = 'supplier'::dispute.party_role
        and exists (
          select 1 from dispute.disputes d
           join supplier.suppliers s on s.id = d.supplier_id
           join organization.memberships m on m.organization_id = s.organization_id
          where d.id = dispute_evidence.dispute_id
            and m.user_id = identity.current_user_id()
            and m.deleted_at is null and m.status = 'active'
        )
      )
    )
  );

drop policy if exists dispute_evidence_admin_modify on dispute.dispute_evidence;
create policy dispute_evidence_admin_modify on dispute.dispute_evidence
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.4 dispute_decisions ----------------------------------------------------
drop policy if exists dispute_decisions_select on dispute.dispute_decisions;
create policy dispute_decisions_select on dispute.dispute_decisions
  for select
  using (
    exists (
      select 1 from dispute.disputes d
       where d.id = dispute_decisions.dispute_id
         and d.deleted_at is null
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = d.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = d.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- 5.5 dispute_events (immutable) -------------------------------------------
drop policy if exists dispute_events_select on dispute.dispute_events;
create policy dispute_events_select on dispute.dispute_events
  for select
  using (
    exists (
      select 1 from dispute.disputes d
       where d.id = dispute_events.dispute_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = d.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = d.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. Buyer RPCs (5)
-- ===========================================================================

-- 6.1 buyer_open_dispute ---------------------------------------------------
create or replace function dispute.buyer_open_dispute(
  p_settlement_id      uuid,
  p_title              text,
  p_description        text default null,
  p_amount_in_dispute  numeric default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_org uuid := identity.current_organization_id();
  v_settle settlement.settlements%rowtype;
  v_tenant uuid; v_code text;
  v_dispute_id uuid;
  v_buyer_name text; v_supplier_name text;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'dispute: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if p_title is null or btrim(p_title) = '' then
    raise exception 'dispute: title is required' using errcode = '22023';
  end if;

  select * into v_settle from settlement.settlements
   where id = p_settlement_id and deleted_at is null;
  if v_settle.id is null then
    raise exception 'dispute: settlement not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_settle.organization_id then
      raise exception 'dispute: settlement not in caller''s organization' using errcode = '42501';
    end if;
  end if;
  if exists (
    select 1 from dispute.disputes
     where settlement_id = p_settlement_id and deleted_at is null
       and status not in ('withdrawn','cancelled','resolved_buyer','resolved_supplier','resolved_split')
  ) then
    raise exception 'dispute: active dispute already exists for this settlement' using errcode = '23505';
  end if;

  v_tenant := v_settle.tenant_id;
  v_code := dispute.fn_next_dispute_code(v_tenant);
  select name_en into v_buyer_name from organization.organizations where id = v_settle.organization_id;
  v_buyer_name := coalesce(v_buyer_name, 'Buyer');
  select o.name_en into v_supplier_name
    from supplier.suppliers s left join organization.organizations o on o.id = s.organization_id
   where s.id = v_settle.supplier_id;
  v_supplier_name := coalesce(v_supplier_name, 'Supplier');

  insert into dispute.disputes (
    tenant_id, organization_id, settlement_id, executed_contract_id, shipment_id,
    supplier_id, supplier_organization_id, dispute_code, status, opened_by_party,
    opened_by_user_id, opened_at, title, description, amount_in_dispute, currency,
    created_by, updated_by
  ) values (
    v_tenant, v_settle.organization_id, p_settlement_id, v_settle.executed_contract_id, v_settle.shipment_id,
    v_settle.supplier_id, v_settle.supplier_organization_id, v_code, 'opened', 'buyer',
    v_actor, now(), p_title, p_description, p_amount_in_dispute, v_settle.currency,
    v_actor, v_actor
  ) returning id into v_dispute_id;

  insert into dispute.dispute_participants (
    tenant_id, organization_id, dispute_id, party_role,
    party_organization_id, display_name, created_by, updated_by
  ) values (
    v_tenant, v_settle.organization_id, v_dispute_id, 'buyer'::dispute.party_role,
    v_settle.organization_id, v_buyer_name, v_actor, v_actor
  );
  insert into dispute.dispute_participants (
    tenant_id, organization_id, dispute_id, party_role,
    party_supplier_id, party_organization_id, display_name, created_by, updated_by
  ) values (
    v_tenant, v_settle.organization_id, v_dispute_id, 'supplier'::dispute.party_role,
    v_settle.supplier_id, v_settle.supplier_organization_id, v_supplier_name, v_actor, v_actor
  );

  perform dispute.fn_record_dispute_event(v_dispute_id, null, 'opened', 'buyer_opened_dispute');

  -- Mirror onto settlement (the trigger will see the existing dispute row and skip).
  update settlement.settlements
     set dispute_status = 'opened',
         disputed_at = now(),
         disputed_by = v_actor,
         dispute_opened_by_party = 'buyer',
         dispute_reason = coalesce(p_description, p_title),
         status = case when status in ('holding','released') then 'disputed' else status end,
         updated_by = v_actor
   where id = p_settlement_id;

  perform dispute.fn_audit('dispute.opened', v_dispute_id,
    jsonb_build_object('settlement_id', p_settlement_id::text, 'by_party', 'buyer'));
  return v_dispute_id;
end;
$$;

-- 6.2 buyer_submit_evidence ------------------------------------------------
create or replace function dispute.buyer_submit_evidence(
  p_dispute_id     uuid,
  p_evidence_kind  dispute.evidence_kind,
  p_title          text,
  p_narrative      text default null,
  p_metadata       jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_id uuid;
begin
  perform dispute.fn_assert_buyer_for_dispute(p_dispute_id);
  perform dispute.fn_assert_dispute_open_for_submission(p_dispute_id);
  if p_title is null or btrim(p_title) = '' then
    raise exception 'dispute: evidence title is required' using errcode = '22023';
  end if;

  select tenant_id, organization_id into v_tenant, v_org
    from dispute.disputes where id = p_dispute_id;

  insert into dispute.dispute_evidence (
    tenant_id, organization_id, dispute_id, submitter_party_role,
    submitter_user_id, submitter_organization_id,
    evidence_kind, title, narrative, status, metadata,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_dispute_id, 'buyer'::dispute.party_role,
    v_actor, v_org,
    p_evidence_kind, p_title, p_narrative, 'submitted', coalesce(p_metadata, '{}'::jsonb),
    v_actor, v_actor
  ) returning id into v_id;

  perform dispute.fn_record_dispute_event(p_dispute_id, null, null, 'evidence_submitted', null,
    jsonb_build_object('evidence_id', v_id::text, 'submitter', 'buyer'));
  perform dispute.fn_audit('dispute.evidence_submitted', p_dispute_id,
    jsonb_build_object('evidence_id', v_id::text, 'submitter', 'buyer'));
  return v_id;
end;
$$;

-- 6.3 buyer_withdraw_dispute (Q5: only before decision recorded) -----------
create or replace function dispute.buyer_withdraw_dispute(
  p_dispute_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispute.dispute_case_status;
  v_opened_by text;
begin
  v_status := dispute.fn_assert_buyer_for_dispute(p_dispute_id);
  select opened_by_party into v_opened_by from dispute.disputes where id = p_dispute_id;
  if v_opened_by <> 'buyer' and not identity.is_platform_admin() then
    raise exception 'dispute: only the opener may withdraw (or admin)' using errcode = '42501';
  end if;
  if v_status in ('resolved_buyer','resolved_supplier','resolved_split','withdrawn','cancelled') then
    raise exception 'dispute: invalid_transition: cannot withdraw from %', v_status using errcode = 'P0001';
  end if;
  -- Q5: block withdrawal once a (non-voided) decision exists.
  if exists (select 1 from dispute.dispute_decisions where dispute_id = p_dispute_id and voided_at is null) then
    raise exception 'dispute: cannot withdraw — decision already recorded; use admin_force_dispute_status'
      using errcode = 'P0001';
  end if;

  update dispute.disputes
     set status = 'withdrawn', withdrawn_at = now(), withdrawn_by = v_actor,
         withdrawn_reason = p_reason, updated_by = v_actor
   where id = p_dispute_id;
  perform dispute.fn_record_dispute_event(p_dispute_id, v_status, 'withdrawn', 'buyer_withdrew', p_reason);
  perform dispute.fn_audit('dispute.withdrawn', p_dispute_id, jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.4 buyer_list_disputes --------------------------------------------------
create or replace function dispute.buyer_list_disputes(
  p_status        dispute.dispute_case_status default null,
  p_settlement_id uuid                          default null,
  p_limit         integer                       default 25,
  p_offset        integer                       default 0
) returns table (
  id uuid, dispute_code text, settlement_id uuid, supplier_id uuid,
  status text, title text, opened_by_party text,
  amount_in_dispute numeric, currency text,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_org uuid := identity.current_organization_id();
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'dispute: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'dispute: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select d.id, d.dispute_code, d.settlement_id, d.supplier_id,
           d.status::text, d.title, d.opened_by_party,
           d.amount_in_dispute, d.currency, d.created_at, d.updated_at
      from dispute.disputes d
     where d.deleted_at is null
       and (identity.is_platform_admin() or d.organization_id = v_caller_org)
       and (p_status is null or d.status = p_status)
       and (p_settlement_id is null or d.settlement_id = p_settlement_id)
     order by d.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.5 buyer_get_dispute ----------------------------------------------------
create or replace function dispute.buyer_get_dispute(p_dispute_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform dispute.fn_assert_buyer_for_dispute(p_dispute_id);
  return (
    select jsonb_build_object(
      'id', d.id, 'dispute_code', d.dispute_code,
      'settlement_id', d.settlement_id, 'supplier_id', d.supplier_id,
      'executed_contract_id', d.executed_contract_id, 'shipment_id', d.shipment_id,
      'status', d.status, 'title', d.title, 'description', d.description,
      'opened_by_party', d.opened_by_party,
      'amount_in_dispute', d.amount_in_dispute, 'currency', d.currency,
      'assigned_mediator_id', d.assigned_mediator_id,
      'created_at', d.created_at, 'updated_at', d.updated_at,
      'participants', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', p.id, 'party_role', p.party_role, 'display_name', p.display_name
        )), '[]'::jsonb)
          from dispute.dispute_participants p
         where p.dispute_id = d.id and p.deleted_at is null
      ),
      -- Evidence: RLS already filters confidential rows from opposing side.
      'evidence', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', e.id, 'submitter_party_role', e.submitter_party_role,
          'evidence_kind', e.evidence_kind, 'title', e.title, 'narrative', e.narrative,
          'status', e.status, 'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from dispute.dispute_evidence e
         where e.dispute_id = d.id and e.deleted_at is null
      ),
      'decision', (
        select jsonb_build_object(
          'id', dc.id, 'outcome', dc.outcome,
          'settlement_action', dc.settlement_action,
          'buyer_share_amount', dc.buyer_share_amount,
          'supplier_share_amount', dc.supplier_share_amount,
          'reason', dc.reason, 'created_at', dc.created_at
        )
          from dispute.dispute_decisions dc
         where dc.dispute_id = d.id and dc.voided_at is null
         limit 1
      ),
      'events', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', ev.id, 'from_status', ev.from_status, 'to_status', ev.to_status,
          'event_type', ev.event_type, 'created_at', ev.created_at
        ) order by ev.created_at), '[]'::jsonb)
          from dispute.dispute_events ev
         where ev.dispute_id = d.id
      )
    )
    from dispute.disputes d where d.id = p_dispute_id
  );
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (4)
-- ===========================================================================

-- 7.1 supplier_submit_evidence ---------------------------------------------
create or replace function dispute.supplier_submit_evidence(
  p_dispute_id    uuid,
  p_evidence_kind dispute.evidence_kind,
  p_title         text,
  p_narrative     text default null,
  p_metadata      jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_sup uuid := supplier.fn_portal_supplier_id();
  v_tenant uuid; v_org uuid; v_id uuid;
begin
  perform dispute.fn_assert_supplier_for_dispute(p_dispute_id);
  perform dispute.fn_assert_dispute_open_for_submission(p_dispute_id);
  if p_title is null or btrim(p_title) = '' then
    raise exception 'dispute: evidence title is required' using errcode = '22023';
  end if;

  select tenant_id, organization_id into v_tenant, v_org
    from dispute.disputes where id = p_dispute_id;

  insert into dispute.dispute_evidence (
    tenant_id, organization_id, dispute_id, submitter_party_role,
    submitter_user_id, submitter_supplier_id,
    evidence_kind, title, narrative, status, metadata,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_dispute_id, 'supplier'::dispute.party_role,
    v_actor, v_caller_sup,
    p_evidence_kind, p_title, p_narrative, 'submitted', coalesce(p_metadata, '{}'::jsonb),
    v_actor, v_actor
  ) returning id into v_id;

  perform dispute.fn_record_dispute_event(p_dispute_id, null, null, 'evidence_submitted', null,
    jsonb_build_object('evidence_id', v_id::text, 'submitter', 'supplier'));
  perform dispute.fn_audit('dispute.evidence_submitted', p_dispute_id,
    jsonb_build_object('evidence_id', v_id::text, 'submitter', 'supplier'));
  return v_id;
end;
$$;

-- 7.2 supplier_withdraw_dispute (Q5: only before decision) -----------------
create or replace function dispute.supplier_withdraw_dispute(
  p_dispute_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispute.dispute_case_status;
  v_opened_by text;
begin
  v_status := dispute.fn_assert_supplier_for_dispute(p_dispute_id);
  select opened_by_party into v_opened_by from dispute.disputes where id = p_dispute_id;
  if v_opened_by <> 'supplier' and not identity.is_platform_admin() then
    raise exception 'dispute: only the opener may withdraw (or admin)' using errcode = '42501';
  end if;
  if v_status in ('resolved_buyer','resolved_supplier','resolved_split','withdrawn','cancelled') then
    raise exception 'dispute: invalid_transition: cannot withdraw from %', v_status using errcode = 'P0001';
  end if;
  if exists (select 1 from dispute.dispute_decisions where dispute_id = p_dispute_id and voided_at is null) then
    raise exception 'dispute: cannot withdraw — decision already recorded'
      using errcode = 'P0001';
  end if;

  update dispute.disputes
     set status = 'withdrawn', withdrawn_at = now(), withdrawn_by = v_actor,
         withdrawn_reason = p_reason, updated_by = v_actor
   where id = p_dispute_id;
  perform dispute.fn_record_dispute_event(p_dispute_id, v_status, 'withdrawn', 'supplier_withdrew', p_reason);
  perform dispute.fn_audit('dispute.withdrawn', p_dispute_id, jsonb_build_object('reason', p_reason));
end;
$$;

-- 7.3 supplier_list_my_disputes --------------------------------------------
create or replace function dispute.supplier_list_my_disputes(
  p_status dispute.dispute_case_status default null,
  p_limit  integer                      default 25,
  p_offset integer                      default 0
) returns table (
  id uuid, dispute_code text, settlement_id uuid,
  status text, title text, opened_by_party text,
  amount_in_dispute numeric, currency text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select d.id, d.dispute_code, d.settlement_id,
           d.status::text, d.title, d.opened_by_party,
           d.amount_in_dispute, d.currency, d.created_at, d.updated_at
      from dispute.disputes d
     where d.deleted_at is null
       and d.supplier_id = v_supplier
       and (p_status is null or d.status = p_status)
     order by d.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.4 supplier_get_my_dispute ----------------------------------------------
create or replace function dispute.supplier_get_my_dispute(p_dispute_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform dispute.fn_assert_supplier_for_dispute(p_dispute_id);
  return (
    select jsonb_build_object(
      'id', d.id, 'dispute_code', d.dispute_code,
      'settlement_id', d.settlement_id, 'supplier_id', d.supplier_id,
      'status', d.status, 'title', d.title, 'description', d.description,
      'opened_by_party', d.opened_by_party,
      'amount_in_dispute', d.amount_in_dispute, 'currency', d.currency,
      'created_at', d.created_at, 'updated_at', d.updated_at,
      'participants', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', p.id, 'party_role', p.party_role, 'display_name', p.display_name
        )), '[]'::jsonb)
          from dispute.dispute_participants p
         where p.dispute_id = d.id and p.deleted_at is null
      ),
      'evidence', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', e.id, 'submitter_party_role', e.submitter_party_role,
          'evidence_kind', e.evidence_kind, 'title', e.title, 'narrative', e.narrative,
          'status', e.status, 'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from dispute.dispute_evidence e
         where e.dispute_id = d.id and e.deleted_at is null
      ),
      'decision', (
        select jsonb_build_object(
          'id', dc.id, 'outcome', dc.outcome,
          'settlement_action', dc.settlement_action,
          'buyer_share_amount', dc.buyer_share_amount,
          'supplier_share_amount', dc.supplier_share_amount,
          'reason', dc.reason, 'created_at', dc.created_at
        )
          from dispute.dispute_decisions dc
         where dc.dispute_id = d.id and dc.voided_at is null
         limit 1
      )
    )
    from dispute.disputes d where d.id = p_dispute_id
  );
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (~14)
-- ===========================================================================

-- 8.1 admin_list_disputes --------------------------------------------------
create or replace function dispute.admin_list_disputes(
  p_status          dispute.dispute_case_status default null,
  p_organization_id uuid                          default null,
  p_supplier_id     uuid                          default null,
  p_limit           integer                       default 25,
  p_offset          integer                       default 0
) returns table (
  id uuid, dispute_code text, organization_id uuid, supplier_id uuid,
  settlement_id uuid, status text, title text, opened_by_party text,
  amount_in_dispute numeric, currency text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_disputes: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select d.id, d.dispute_code, d.organization_id, d.supplier_id,
           d.settlement_id, d.status::text, d.title, d.opened_by_party,
           d.amount_in_dispute, d.currency, d.created_at
      from dispute.disputes d
     where d.deleted_at is null
       and (p_status is null or d.status = p_status)
       and (p_organization_id is null or d.organization_id = p_organization_id)
       and (p_supplier_id is null or d.supplier_id = p_supplier_id)
     order by d.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_dispute ----------------------------------------------------
create or replace function dispute.admin_get_dispute(p_dispute_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_dispute: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', d.id, 'dispute_code', d.dispute_code,
      'organization_id', d.organization_id, 'supplier_id', d.supplier_id,
      'settlement_id', d.settlement_id, 'status', d.status,
      'title', d.title, 'description', d.description,
      'opened_by_party', d.opened_by_party, 'opened_at', d.opened_at,
      'assigned_mediator_id', d.assigned_mediator_id, 'assigned_at', d.assigned_at,
      'review_started_at', d.review_started_at, 'resolved_at', d.resolved_at,
      'amount_in_dispute', d.amount_in_dispute, 'currency', d.currency,
      'evidence_count', (select count(*) from dispute.dispute_evidence
                          where dispute_id = d.id and deleted_at is null),
      'decision', (
        select jsonb_build_object(
          'id', dc.id, 'outcome', dc.outcome, 'settlement_action', dc.settlement_action,
          'buyer_share_amount', dc.buyer_share_amount, 'supplier_share_amount', dc.supplier_share_amount,
          'reason', dc.reason, 'mediator_notes', dc.mediator_notes,
          'created_at', dc.created_at
        )
          from dispute.dispute_decisions dc where dc.dispute_id = d.id and dc.voided_at is null
         limit 1
      ),
      'created_at', d.created_at, 'updated_at', d.updated_at
    )
    from dispute.disputes d where d.id = p_dispute_id
  );
end;
$$;

-- 8.3 admin_add_participant ------------------------------------------------
create or replace function dispute.admin_add_participant(
  p_dispute_id    uuid,
  p_party_role    dispute.party_role,
  p_display_name  text,
  p_user_id       uuid default null,
  p_organization_id uuid default null,
  p_supplier_id   uuid default null,
  p_notes         text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_add_participant: requires platform_admin' using errcode = '42501';
  end if;
  if p_display_name is null or btrim(p_display_name) = '' then
    raise exception 'dispute: display_name required' using errcode = '22023';
  end if;
  select tenant_id, organization_id into v_tenant, v_org from dispute.disputes where id = p_dispute_id;
  if v_tenant is null then
    raise exception 'dispute: not found' using errcode = 'P0002';
  end if;
  insert into dispute.dispute_participants (
    tenant_id, organization_id, dispute_id, party_role,
    party_user_id, party_organization_id, party_supplier_id, display_name, notes,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_dispute_id, p_party_role,
    p_user_id, p_organization_id, p_supplier_id, p_display_name, p_notes,
    v_actor, v_actor
  ) returning id into v_id;
  perform dispute.fn_audit('dispute.participant_added', p_dispute_id,
    jsonb_build_object('participant_id', v_id::text, 'role', p_party_role::text));
  return v_id;
end;
$$;

-- 8.4 admin_assign_mediator (Q9: platform_admin only) ----------------------
create or replace function dispute.admin_assign_mediator(
  p_dispute_id uuid, p_mediator_user_id uuid
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status dispute.dispute_case_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_assign_mediator: requires platform_admin' using errcode = '42501';
  end if;
  -- Mediator must be a platform_admin user (Q9).
  if not exists (
    select 1 from identity.user_roles ur
     join identity.roles r on r.id = ur.role_id
    where ur.user_id = p_mediator_user_id and r.code = 'platform_admin'
  ) then
    raise exception 'dispute: mediator must be a platform_admin user' using errcode = '42501';
  end if;
  select status into v_status from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_status is null then raise exception 'dispute: not found' using errcode = 'P0002'; end if;
  if v_status not in ('opened','under_review') then
    raise exception 'dispute: cannot assign mediator from status %', v_status using errcode = 'P0001';
  end if;
  update dispute.disputes
     set assigned_mediator_id = p_mediator_user_id, assigned_at = now(), updated_by = v_actor
   where id = p_dispute_id;
  perform dispute.fn_record_dispute_event(p_dispute_id, v_status, v_status, 'mediator_assigned');
  perform dispute.fn_audit('dispute.mediator_assigned', p_dispute_id,
    jsonb_build_object('mediator_id', p_mediator_user_id::text));
end;
$$;

-- 8.5 admin_start_review ---------------------------------------------------
create or replace function dispute.admin_start_review(p_dispute_id uuid)
returns void language plpgsql volatile security definer set search_path = '' as $$
declare v_actor uuid := auth.uid(); v_status dispute.dispute_case_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_start_review: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_status is null then raise exception 'dispute: not found' using errcode = 'P0002'; end if;
  if v_status <> 'opened' then
    raise exception 'dispute: invalid_transition: cannot start review from %', v_status using errcode = 'P0001';
  end if;
  update dispute.disputes
     set status = 'under_review', review_started_at = now(), review_started_by = v_actor, updated_by = v_actor
   where id = p_dispute_id;
  perform dispute.fn_record_dispute_event(p_dispute_id, 'opened', 'under_review', 'review_started');
  perform dispute.fn_audit('dispute.review_started', p_dispute_id);
end;
$$;

-- 8.6 admin_review_evidence ------------------------------------------------
create or replace function dispute.admin_review_evidence(
  p_evidence_id uuid,
  p_status      dispute.evidence_status,
  p_notes       text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_dispute uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_review_evidence: requires platform_admin' using errcode = '42501';
  end if;
  if p_status not in ('accepted','rejected') then
    raise exception 'dispute: review status must be accepted or rejected' using errcode = '22023';
  end if;
  select dispute_id into v_dispute from dispute.dispute_evidence
   where id = p_evidence_id and deleted_at is null;
  if v_dispute is null then
    raise exception 'dispute: evidence not found' using errcode = 'P0002';
  end if;
  update dispute.dispute_evidence
     set status = p_status, reviewed_at = now(), reviewed_by = v_actor,
         review_notes = p_notes, updated_by = v_actor
   where id = p_evidence_id;
  perform dispute.fn_record_dispute_event(v_dispute, null, null, 'evidence_reviewed',
    p_notes, jsonb_build_object('evidence_id', p_evidence_id::text, 'to_status', p_status::text));
  perform dispute.fn_audit('dispute.evidence_reviewed', v_dispute,
    jsonb_build_object('evidence_id', p_evidence_id::text, 'status', p_status::text));
end;
$$;

-- 8.7 admin_record_decision (calls fn_apply_decision_to_settlement) --------
create or replace function dispute.admin_record_decision(
  p_dispute_id           uuid,
  p_outcome              dispute.decision_outcome,
  p_settlement_action    dispute.settlement_action,
  p_buyer_share_amount   numeric default 0,
  p_supplier_share_amount numeric default 0,
  p_fee_share_amount     numeric default 0,
  p_reason               text default null,
  p_mediator_notes       text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_status dispute.dispute_case_status;
  v_to dispute.dispute_case_status;
  v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_record_decision: requires platform_admin' using errcode = '42501';
  end if;
  select tenant_id, organization_id, status into v_tenant, v_org, v_status
    from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_tenant is null then raise exception 'dispute: not found' using errcode = 'P0002'; end if;
  if v_status <> 'under_review' then
    raise exception 'dispute: invalid_transition: decision only from under_review (current=%)', v_status
      using errcode = 'P0001';
  end if;
  -- Q3: prevent duplicate active decision (also enforced by partial unique index).
  if exists (select 1 from dispute.dispute_decisions where dispute_id = p_dispute_id and voided_at is null) then
    raise exception 'dispute: active decision already exists; void it first' using errcode = '23505';
  end if;

  insert into dispute.dispute_decisions (
    tenant_id, organization_id, dispute_id, decided_by,
    outcome, settlement_action,
    buyer_share_amount, supplier_share_amount, fee_share_amount,
    reason, mediator_notes
  ) values (
    v_tenant, v_org, p_dispute_id, v_actor,
    p_outcome, p_settlement_action,
    coalesce(p_buyer_share_amount, 0), coalesce(p_supplier_share_amount, 0),
    coalesce(p_fee_share_amount, 0), p_reason, p_mediator_notes
  ) returning id into v_id;

  case p_outcome
    when 'favor_buyer'    then v_to := 'resolved_buyer';
    when 'favor_supplier' then v_to := 'resolved_supplier';
    when 'split'          then v_to := 'resolved_split';
    when 'no_action'      then v_to := 'resolved_supplier';  -- neutral: settlement state stays
    when 'withdrawn'      then v_to := 'withdrawn';
  end case;

  update dispute.disputes
     set status = v_to, resolved_at = now(), resolved_by = v_actor, updated_by = v_actor
   where id = p_dispute_id;

  perform dispute.fn_record_dispute_event(p_dispute_id, v_status, v_to, 'decision_recorded',
    p_reason, jsonb_build_object('decision_id', v_id::text, 'outcome', p_outcome::text));

  -- Apply settlement-side effect (release / reverse / split / no_change).
  perform dispute.fn_apply_decision_to_settlement(p_dispute_id);

  perform dispute.fn_audit('dispute.decision_recorded', p_dispute_id,
    jsonb_build_object('decision_id', v_id::text, 'outcome', p_outcome::text,
                       'settlement_action', p_settlement_action::text));
  return v_id;
end;
$$;

-- 8.8 admin_void_decision (Q3 correction path) -----------------------------
create or replace function dispute.admin_void_decision(
  p_decision_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_dispute uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_void_decision: requires platform_admin' using errcode = '42501';
  end if;
  select dispute_id into v_dispute from dispute.dispute_decisions
   where id = p_decision_id and voided_at is null;
  if v_dispute is null then
    raise exception 'dispute: decision not found or already voided' using errcode = 'P0002';
  end if;
  update dispute.dispute_decisions
     set voided_at = now(), voided_by = v_actor, voided_reason = p_reason
   where id = p_decision_id;
  perform dispute.fn_record_dispute_event(v_dispute, null, null, 'decision_voided', p_reason,
    jsonb_build_object('decision_id', p_decision_id::text));
  perform dispute.fn_audit('dispute.decision_voided', v_dispute,
    jsonb_build_object('decision_id', p_decision_id::text, 'reason', p_reason));
end;
$$;

-- 8.9 admin_cancel_dispute -------------------------------------------------
create or replace function dispute.admin_cancel_dispute(
  p_dispute_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status dispute.dispute_case_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_cancel_dispute: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_status is null then raise exception 'dispute: not found' using errcode = 'P0002'; end if;
  if v_status in ('resolved_buyer','resolved_supplier','resolved_split','withdrawn','cancelled') then
    raise exception 'dispute: invalid_transition: cannot cancel from %', v_status using errcode = 'P0001';
  end if;
  update dispute.disputes
     set status = 'cancelled', cancelled_at = now(), cancelled_by = v_actor,
         cancelled_reason = p_reason, updated_by = v_actor
   where id = p_dispute_id;
  perform dispute.fn_record_dispute_event(p_dispute_id, v_status, 'cancelled', 'admin_cancel', p_reason);
  perform dispute.fn_audit('dispute.cancelled', p_dispute_id, jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.10 admin_list_dispute_events -------------------------------------------
create or replace function dispute.admin_list_dispute_events(p_dispute_id uuid)
returns table (
  id uuid, from_status text, to_status text, event_type text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_dispute_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text, e.event_type,
           e.actor_user_id, e.reason, e.created_at
      from dispute.dispute_events e
     where e.dispute_id = p_dispute_id
     order by e.created_at asc;
end;
$$;

-- 8.11 admin_list_dispute_evidence -----------------------------------------
create or replace function dispute.admin_list_dispute_evidence(
  p_dispute_id uuid, p_status dispute.evidence_status default null
) returns table (
  id uuid, submitter_party_role text, evidence_kind text,
  title text, status text, created_at timestamptz
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_dispute_evidence: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.submitter_party_role::text, e.evidence_kind::text,
           e.title, e.status::text, e.created_at
      from dispute.dispute_evidence e
     where e.dispute_id = p_dispute_id and e.deleted_at is null
       and (p_status is null or e.status = p_status)
     order by e.created_at asc;
end;
$$;

-- 8.12 admin_list_decisions ------------------------------------------------
create or replace function dispute.admin_list_decisions(p_dispute_id uuid)
returns table (
  id uuid, outcome text, settlement_action text,
  buyer_share_amount numeric, supplier_share_amount numeric,
  voided_at timestamptz, created_at timestamptz
)
language plpgsql stable security definer set search_path = '' as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_decisions: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select dc.id, dc.outcome::text, dc.settlement_action::text,
           dc.buyer_share_amount, dc.supplier_share_amount,
           dc.voided_at, dc.created_at
      from dispute.dispute_decisions dc
     where dc.dispute_id = p_dispute_id
     order by dc.created_at asc;
end;
$$;

-- 8.13 admin_force_dispute_status ------------------------------------------
create or replace function dispute.admin_force_dispute_status(
  p_dispute_id uuid,
  p_status     dispute.dispute_case_status,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_current dispute.dispute_case_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_dispute_status: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from dispute.disputes where id = p_dispute_id and deleted_at is null;
  if v_current is null then raise exception 'dispute: not found' using errcode = 'P0002'; end if;
  if v_current = p_status then return; end if;
  update dispute.disputes
     set status = p_status, updated_by = v_actor
   where id = p_dispute_id;
  perform dispute.fn_record_dispute_event(p_dispute_id, v_current, p_status, 'admin_force_status', p_reason);
  perform dispute.fn_audit('dispute.admin_force_status', p_dispute_id,
    jsonb_build_object('to', p_status::text, 'reason', p_reason));
end;
$$;

-- ===========================================================================
-- 9. Trigger attachments (set_updated_at + audit) — scoped to OUR tables
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select unnest(array['disputes','dispute_participants','dispute_evidence']) as table_name
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on dispute.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on dispute.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_name
    );
  end loop;
end;
$$;

do $$
declare r record;
begin
  for r in
    select unnest(array[
      'disputes','dispute_participants','dispute_evidence','dispute_decisions','dispute_events'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on dispute.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on dispute.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 10. Grants (SELECT only; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on dispute.disputes              to anon, authenticated;
grant select on dispute.dispute_participants  to authenticated;
grant select on dispute.dispute_evidence      to authenticated;
grant select on dispute.dispute_decisions     to authenticated;
grant select on dispute.dispute_events        to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function dispute.buyer_open_dispute(uuid, text, text, numeric) to authenticated;
grant execute on function dispute.buyer_submit_evidence(uuid, dispute.evidence_kind, text, text, jsonb) to authenticated;
grant execute on function dispute.buyer_withdraw_dispute(uuid, text) to authenticated;
grant execute on function dispute.buyer_list_disputes(dispute.dispute_case_status, uuid, integer, integer) to authenticated;
grant execute on function dispute.buyer_get_dispute(uuid) to authenticated;

grant execute on function dispute.supplier_submit_evidence(uuid, dispute.evidence_kind, text, text, jsonb) to authenticated;
grant execute on function dispute.supplier_withdraw_dispute(uuid, text) to authenticated;
grant execute on function dispute.supplier_list_my_disputes(dispute.dispute_case_status, integer, integer) to authenticated;
grant execute on function dispute.supplier_get_my_dispute(uuid) to authenticated;

grant execute on function dispute.admin_list_disputes(dispute.dispute_case_status, uuid, uuid, integer, integer) to authenticated;
grant execute on function dispute.admin_get_dispute(uuid) to authenticated;
grant execute on function dispute.admin_add_participant(uuid, dispute.party_role, text, uuid, uuid, uuid, text) to authenticated;
grant execute on function dispute.admin_assign_mediator(uuid, uuid) to authenticated;
grant execute on function dispute.admin_start_review(uuid) to authenticated;
grant execute on function dispute.admin_review_evidence(uuid, dispute.evidence_status, text) to authenticated;
grant execute on function dispute.admin_record_decision(uuid, dispute.decision_outcome, dispute.settlement_action, numeric, numeric, numeric, text, text) to authenticated;
grant execute on function dispute.admin_void_decision(uuid, text) to authenticated;
grant execute on function dispute.admin_cancel_dispute(uuid, text) to authenticated;
grant execute on function dispute.admin_list_dispute_events(uuid) to authenticated;
grant execute on function dispute.admin_list_dispute_evidence(uuid, dispute.evidence_status) to authenticated;
grant execute on function dispute.admin_list_decisions(uuid) to authenticated;
grant execute on function dispute.admin_force_dispute_status(uuid, dispute.dispute_case_status, text) to authenticated;
