-- CC-13 / Migration 0024 — Contract Execution / Signature Foundation
-- Seventh business domain step. Extends the existing contract schema from CC-12.
-- Append-only over migrations 0001-0023.
--
-- Scope: formal contract execution and signature workflow only.
-- No shipment, pricing engine, settlement, escrow, payment, invoice, accounting, negotiation.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Enums (4 new)
-- ===========================================================================
create type contract.contract_status as enum (
  'draft_execution',
  'pending_signatures',
  'partially_signed',
  'executed',
  'cancelled',
  'voided',
  'superseded'
);

create type contract.party_type as enum (
  'buyer', 'supplier', 'platform', 'witness', 'other'
);

create type contract.signature_status as enum (
  'pending', 'viewed', 'signed', 'declined', 'cancelled', 'expired'
);

create type contract.executed_snapshot_type as enum (
  'initial_from_preparation',
  'pending_signature_snapshot',
  'executed_snapshot',
  'voided_snapshot'
);

-- ===========================================================================
-- 2. Tables (8 new)
-- ===========================================================================

-- 2.1 executed_contracts ---------------------------------------------------
create table contract.executed_contracts (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  preparation_id              uuid not null references contract.contract_preparations(id) on delete restrict,
  request_id                  uuid not null references rfq.requests(id) on delete restrict,
  offer_id                    uuid not null references offer.supplier_offers(id) on delete restrict,
  decision_id                 uuid not null references evaluation.offer_decisions(id) on delete restrict,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,
  created_by                  uuid references auth.users(id),

  contract_code               text not null,
  status                      contract.contract_status not null default 'draft_execution',
  title                       text not null,
  contract_type               contract.preparation_contract_type not null default 'spot',
  currency                    text not null default 'USD',
  incoterm                    text,
  delivery_country            char(2),
  delivery_city               text,
  delivery_port               text,
  delivery_location_text      text,

  payment_terms_text          text,
  delivery_terms_text         text,
  inspection_terms_text       text,
  governing_law_text          text,
  dispute_resolution_text     text,
  special_conditions_text     text,
  internal_notes              text,

  effective_date              date,
  expiry_date                 date,
  executed_at                 timestamptz,
  executed_by                 uuid references auth.users(id),

  metadata                    jsonb not null default '{}'::jsonb,

  pending_signatures_at       timestamptz,
  pending_signatures_by       uuid references auth.users(id),
  cancelled_at                timestamptz,
  cancelled_by                uuid references auth.users(id),
  cancelled_reason            text,
  voided_at                   timestamptz,
  voided_by                   uuid references auth.users(id),
  voided_reason               text,
  superseded_at               timestamptz,
  superseded_by               uuid references auth.users(id),
  superseded_reason           text,

  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table contract.executed_contracts is
  'Formal executable contract record derived from a ready_for_contract preparation. No payment/shipment/settlement/etc. is created or executed.';

-- One active (non-superseded, not soft-deleted) executed contract per preparation.
create unique index executed_contracts_unique_active
  on contract.executed_contracts(preparation_id)
  where deleted_at is null and status <> 'superseded';

create unique index executed_contracts_code_unique
  on contract.executed_contracts(tenant_id, lower(contract_code))
  where deleted_at is null;

create index executed_contracts_request_idx   on contract.executed_contracts(request_id);
create index executed_contracts_offer_idx     on contract.executed_contracts(offer_id);
create index executed_contracts_supplier_idx  on contract.executed_contracts(supplier_id);
create index executed_contracts_status_idx    on contract.executed_contracts(status);

-- 2.2 executed_contract_items ----------------------------------------------
create table contract.executed_contract_items (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  contract_id             uuid not null references contract.executed_contracts(id) on delete cascade,
  preparation_item_id     uuid references contract.contract_preparation_items(id) on delete set null,
  offer_item_id           uuid references offer.supplier_offer_items(id) on delete set null,
  request_item_id         uuid references rfq.request_items(id) on delete set null,
  product_id              uuid not null references commodity.products(id) on delete restrict,

  quantity                numeric,
  quantity_unit           text,
  unit_price              numeric,
  total_price             numeric,
  currency                text,
  packaging               text,
  origin_country          char(2),
  origin_city             text,
  delivery_window_start   date,
  delivery_window_end     date,
  delivery_lead_time_text text,
  notes                   text,
  metadata                jsonb not null default '{}'::jsonb,
  sort_order              integer not null default 0,

  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_by              uuid references auth.users(id),
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz,
  version                 integer not null default 1
);

comment on table contract.executed_contract_items is
  'Line items copied from contract.contract_preparation_items into the executed contract at execution-draft time.';

create unique index executed_contract_items_unique_active
  on contract.executed_contract_items(contract_id, preparation_item_id)
  where deleted_at is null and preparation_item_id is not null;

create index executed_contract_items_contract_idx
  on contract.executed_contract_items(contract_id);

-- 2.3 executed_contract_clauses --------------------------------------------
create table contract.executed_contract_clauses (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  contract_id             uuid not null references contract.executed_contracts(id) on delete cascade,
  preparation_clause_id   uuid references contract.contract_preparation_clauses(id) on delete set null,

  clause_type             contract.preparation_clause_type not null,
  clause_key              text,
  title_fa                text,
  title_en                text,
  body_fa                 text,
  body_en                 text,
  source                  text,
  is_required             boolean not null default false,
  sort_order              integer not null default 0,
  metadata                jsonb not null default '{}'::jsonb,

  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_by              uuid references auth.users(id),
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz,
  version                 integer not null default 1
);

comment on table contract.executed_contract_clauses is
  'Clauses copied from contract.contract_preparation_clauses into the executed contract.';

create unique index executed_contract_clauses_unique_active
  on contract.executed_contract_clauses(contract_id, clause_type, coalesce(lower(clause_key), ''))
  where deleted_at is null;

create index executed_contract_clauses_contract_idx
  on contract.executed_contract_clauses(contract_id);

-- 2.4 contract_parties -----------------------------------------------------
create table contract.contract_parties (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  contract_id         uuid not null references contract.executed_contracts(id) on delete cascade,

  party_type          contract.party_type not null,
  party_organization_id uuid references organization.organizations(id) on delete set null,
  party_supplier_id   uuid references supplier.suppliers(id) on delete set null,
  party_user_id       uuid references auth.users(id) on delete set null,
  display_name        text not null,
  role_title          text,
  signer_role         text,
  signing_order       integer not null default 0,
  is_required_signer  boolean not null default true,
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table contract.contract_parties is
  'Parties and signer roles attached to an executed contract.';

create index contract_parties_contract_idx on contract.contract_parties(contract_id);

-- 2.5 contract_signature_requests ------------------------------------------
create table contract.contract_signature_requests (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  contract_id         uuid not null references contract.executed_contracts(id) on delete cascade,
  party_id            uuid not null references contract.contract_parties(id) on delete cascade,

  requested_to_user   uuid references auth.users(id) on delete set null,
  requested_to_email  text,
  status              contract.signature_status not null default 'pending',

  requested_at        timestamptz not null default now(),
  viewed_at           timestamptz,
  signed_at           timestamptz,
  declined_at         timestamptz,
  decline_reason      text,
  due_at              timestamptz,
  completed_at        timestamptz,
  cancelled_at        timestamptz,
  cancelled_reason    text,

  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table contract.contract_signature_requests is
  'Platform-controlled signature request for a contract party. One active request per party at a time.';

-- One active signature request per (contract, party) — once completed/cancelled/expired
-- the party may be re-requested (the unique active constraint frees up automatically).
create unique index contract_signature_requests_unique_active
  on contract.contract_signature_requests(contract_id, party_id)
  where deleted_at is null
    and status not in ('signed', 'declined', 'cancelled', 'expired');

create index contract_signature_requests_contract_idx
  on contract.contract_signature_requests(contract_id);
create index contract_signature_requests_status_idx
  on contract.contract_signature_requests(status);

-- 2.6 contract_signature_events (immutable) --------------------------------
create table contract.contract_signature_events (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  signature_request_id        uuid not null references contract.contract_signature_requests(id) on delete cascade,
  contract_id                 uuid not null references contract.executed_contracts(id) on delete cascade,

  from_status                 contract.signature_status,
  to_status                   contract.signature_status not null,
  event_type                  text not null,
  actor_user_id               uuid references auth.users(id),
  actor_organization_id       uuid references organization.organizations(id),
  reason                      text,
  metadata                    jsonb not null default '{}'::jsonb,
  created_at                  timestamptz not null default now()
);

comment on table contract.contract_signature_events is
  'Immutable audit trail of signature_request state changes. No UPDATE/DELETE policies.';

create index contract_signature_events_request_idx
  on contract.contract_signature_events(signature_request_id, created_at desc);
create index contract_signature_events_contract_idx
  on contract.contract_signature_events(contract_id, created_at desc);

-- 2.7 executed_contract_snapshots (immutable) ------------------------------
create table contract.executed_contract_snapshots (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  contract_id         uuid not null references contract.executed_contracts(id) on delete cascade,

  snapshot_type       contract.executed_snapshot_type not null,
  title               text not null,
  snapshot_data       jsonb not null default '{}'::jsonb,
  notes               text,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now()
);

comment on table contract.executed_contract_snapshots is
  'Immutable snapshots of an executed contract at lifecycle checkpoints. No UPDATE/DELETE policies.';

create index executed_contract_snapshots_contract_idx
  on contract.executed_contract_snapshots(contract_id, created_at desc);

-- 2.8 executed_contract_events (immutable) ---------------------------------
create table contract.executed_contract_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  contract_id             uuid not null references contract.executed_contracts(id) on delete cascade,

  from_status             contract.contract_status,
  to_status               contract.contract_status not null,
  actor_user_id           uuid references auth.users(id),
  actor_organization_id   uuid references organization.organizations(id),
  reason                  text,
  payload                 jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table contract.executed_contract_events is
  'Immutable lifecycle audit trail for executed contracts. No UPDATE/DELETE policies.';

create index executed_contract_events_contract_idx
  on contract.executed_contract_events(contract_id, created_at desc);

-- ===========================================================================
-- 3. Internal helpers
-- ===========================================================================

-- 3.1 fn_audit_contract ----------------------------------------------------
create or replace function contract.fn_audit_contract(
  p_action_code text,
  p_contract_id uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from contract.executed_contracts where id = p_contract_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'contract.execution', p_contract_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 3.2 fn_record_executed_contract_event ------------------------------------
create or replace function contract.fn_record_executed_contract_event(
  p_contract_id uuid,
  p_from        contract.contract_status,
  p_to          contract.contract_status,
  p_reason      text default null,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from contract.executed_contracts where id = p_contract_id;
  insert into contract.executed_contract_events (
    tenant_id, organization_id, contract_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_contract_id,
    p_from, p_to, auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 3.3 fn_record_signature_event --------------------------------------------
create or replace function contract.fn_record_signature_event(
  p_signature_request_id uuid,
  p_from        contract.signature_status,
  p_to          contract.signature_status,
  p_event_type  text,
  p_reason      text default null,
  p_metadata    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_o uuid; v_contract uuid;
begin
  select tenant_id, organization_id, contract_id
    into v_t, v_o, v_contract
    from contract.contract_signature_requests
   where id = p_signature_request_id;
  insert into contract.contract_signature_events (
    tenant_id, organization_id, signature_request_id, contract_id,
    from_status, to_status, event_type, actor_user_id, actor_organization_id, reason, metadata
  ) values (
    v_t, v_o, p_signature_request_id, v_contract,
    p_from, p_to, p_event_type, auth.uid(), v_o, p_reason, coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

-- 3.4 fn_next_contract_code ------------------------------------------------
create or replace function contract.fn_next_contract_code(p_tenant_id uuid)
returns text
language plpgsql volatile security definer set search_path = ''
as $$
declare v_code text;
begin
  v_code := 'CON-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

-- 3.5 fn_assert_buyer_for_preparation --------------------------------------
-- Verifies role + caller's org is the preparation's buyer org + preparation is ready_for_contract.
create or replace function contract.fn_assert_buyer_for_preparation(p_preparation_id uuid)
returns table (
  buyer_org_id              uuid,
  request_id                uuid,
  offer_id                  uuid,
  decision_id               uuid,
  supplier_id               uuid,
  supplier_organization_id  uuid,
  prep_status               contract.preparation_status
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org  uuid;
  v_request_id uuid;
  v_offer_id   uuid;
  v_decision_id uuid;
  v_supplier_id uuid;
  v_supplier_org uuid;
  v_status     contract.preparation_status;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'contract.execution: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;

  select p.organization_id, p.request_id, p.offer_id, p.decision_id,
         p.supplier_id, p.supplier_organization_id, p.status
    into v_buyer_org, v_request_id, v_offer_id, v_decision_id,
         v_supplier_id, v_supplier_org, v_status
    from contract.contract_preparations p
   where p.id = p_preparation_id and p.deleted_at is null;

  if v_buyer_org is null then
    raise exception 'contract.execution: preparation not found' using errcode = 'P0002';
  end if;
  if v_status <> 'ready_for_contract' then
    raise exception 'contract.execution: preparation is not ready_for_contract (status=%)', v_status
      using errcode = 'P0001';
  end if;

  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'contract.execution: preparation is not in caller''s organization'
        using errcode = '42501';
    end if;
  end if;

  return query select v_buyer_org, v_request_id, v_offer_id, v_decision_id,
                      v_supplier_id, v_supplier_org, v_status;
end;
$$;

-- 3.6 fn_assert_executed_contract_owned ------------------------------------
create or replace function contract.fn_assert_executed_contract_owned(p_contract_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_org from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_org is null then
    raise exception 'contract.execution: contract not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'contract.execution: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'contract.execution: contract not owned by caller organization' using errcode = '42501';
  end if;
end;
$$;

-- 3.7 fn_assert_executed_contract_editable ---------------------------------
-- Only draft_execution permits full edits.
create or replace function contract.fn_assert_executed_contract_editable(p_contract_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status contract.contract_status;
begin
  select status into v_status from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract.execution: contract not found' using errcode = 'P0002';
  end if;
  if v_status <> 'draft_execution' then
    raise exception 'contract.execution: contract locked from normal edit (status=%)', v_status
      using errcode = 'P0001';
  end if;
end;
$$;

-- 3.8 fn_try_promote_to_executed -------------------------------------------
-- After each signature_sign event, check whether all required signers have signed.
-- If all required and ≥1 required signed: move to executed.
-- Else if some signed: partially_signed.
-- Else: no change (stays pending_signatures).
create or replace function contract.fn_try_promote_to_executed(p_contract_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.contract_status;
  v_total_required int;
  v_signed_required int;
  v_to contract.contract_status;
  v_actor uuid := auth.uid();
begin
  select status into v_status from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_status not in ('pending_signatures', 'partially_signed') then
    return;
  end if;

  select count(*) into v_total_required
    from contract.contract_parties cp
   where cp.contract_id = p_contract_id
     and cp.deleted_at is null
     and cp.is_required_signer = true;

  select count(*) into v_signed_required
    from contract.contract_signature_requests sr
    join contract.contract_parties cp on cp.id = sr.party_id
   where sr.contract_id = p_contract_id
     and sr.deleted_at is null
     and cp.is_required_signer = true
     and sr.status = 'signed';

  if v_total_required > 0 and v_signed_required >= v_total_required then
    v_to := 'executed';
  elsif v_signed_required > 0 then
    v_to := 'partially_signed';
  else
    return;
  end if;

  if v_to = v_status then
    return;
  end if;

  if v_to = 'executed' then
    update contract.executed_contracts
       set status = v_to, executed_at = now(), executed_by = v_actor, updated_by = v_actor
     where id = p_contract_id;
  else
    update contract.executed_contracts
       set status = v_to, updated_by = v_actor
     where id = p_contract_id;
  end if;

  perform contract.fn_record_executed_contract_event(p_contract_id, v_status, v_to,
    case when v_to = 'executed' then 'all_required_signatures_received'
         else 'some_required_signatures_received' end);
end;
$$;

-- 3.9 fn_assert_supplier_for_signature -------------------------------------
-- Verifies that signature request belongs to a contract whose supplier_id matches the caller.
create or replace function contract.fn_assert_supplier_for_signature(p_signature_request_id uuid)
returns table (
  signature_request_id  uuid,
  contract_id           uuid,
  party_id              uuid,
  party_type            contract.party_type,
  status                contract.signature_status
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_supplier uuid := supplier.fn_portal_supplier_id();
  v_party_supplier uuid;
  v_party_type contract.party_type;
  v_status contract.signature_status;
  v_contract uuid;
  v_party uuid;
begin
  select sr.id, sr.contract_id, sr.party_id, cp.party_type, cp.party_supplier_id, sr.status
    into signature_request_id, v_contract, v_party, v_party_type, v_party_supplier, v_status
    from contract.contract_signature_requests sr
    join contract.contract_parties cp on cp.id = sr.party_id
   where sr.id = p_signature_request_id and sr.deleted_at is null;
  if signature_request_id is null then
    raise exception 'contract.execution: signature request not found' using errcode = 'P0002';
  end if;
  if v_party_type <> 'supplier' then
    raise exception 'contract.execution: signature request is not on a supplier party'
      using errcode = '42501';
  end if;
  if v_party_supplier is null or v_party_supplier <> v_caller_supplier then
    raise exception 'contract.execution: signature request is not on caller''s supplier party'
      using errcode = '42501';
  end if;
  return query select signature_request_id, v_contract, v_party, v_party_type, v_status;
end;
$$;

-- 3.10 fn_assert_buyer_for_signature ---------------------------------------
create or replace function contract.fn_assert_buyer_for_signature(p_signature_request_id uuid)
returns table (
  signature_request_id uuid,
  contract_id          uuid,
  party_id             uuid,
  party_type           contract.party_type,
  status               contract.signature_status
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org uuid;
  v_party_org uuid;
  v_party_type contract.party_type;
  v_status contract.signature_status;
  v_contract uuid;
  v_party uuid;
begin
  select sr.id, sr.contract_id, sr.party_id, cp.party_type, cp.party_organization_id,
         sr.status, ec.organization_id
    into signature_request_id, v_contract, v_party, v_party_type, v_party_org,
         v_status, v_buyer_org
    from contract.contract_signature_requests sr
    join contract.contract_parties cp on cp.id = sr.party_id
    join contract.executed_contracts ec on ec.id = sr.contract_id
   where sr.id = p_signature_request_id and sr.deleted_at is null;
  if signature_request_id is null then
    raise exception 'contract.execution: signature request not found' using errcode = 'P0002';
  end if;
  if v_party_type <> 'buyer' then
    raise exception 'contract.execution: signature request is not on a buyer party'
      using errcode = '42501';
  end if;
  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'contract.execution: signature request is not in caller''s organization'
        using errcode = '42501';
    end if;
  end if;
  return query select signature_request_id, v_contract, v_party, v_party_type, v_status;
end;
$$;

-- ===========================================================================
-- 4. Row Level Security
-- ===========================================================================
alter table contract.executed_contracts          enable row level security;
alter table contract.executed_contract_items     enable row level security;
alter table contract.executed_contract_clauses   enable row level security;
alter table contract.contract_parties            enable row level security;
alter table contract.contract_signature_requests enable row level security;
alter table contract.contract_signature_events   enable row level security;
alter table contract.executed_contract_snapshots enable row level security;
alter table contract.executed_contract_events    enable row level security;

-- 4.1 executed_contracts: buyer org + supplier of contract + admin.
drop policy if exists executed_contracts_select on contract.executed_contracts;
create policy executed_contracts_select on contract.executed_contracts
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = contract.executed_contracts.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = contract.executed_contracts.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists executed_contracts_admin_modify on contract.executed_contracts;
create policy executed_contracts_admin_modify on contract.executed_contracts
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.2 executed_contract_items: same audience as parent contract.
drop policy if exists executed_contract_items_select on contract.executed_contract_items;
create policy executed_contract_items_select on contract.executed_contract_items
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from contract.executed_contracts ec
       where ec.id = contract.executed_contract_items.contract_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ec.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ec.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

drop policy if exists executed_contract_items_admin_modify on contract.executed_contract_items;
create policy executed_contract_items_admin_modify on contract.executed_contract_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.3 executed_contract_clauses: same audience as parent contract.
drop policy if exists executed_contract_clauses_select on contract.executed_contract_clauses;
create policy executed_contract_clauses_select on contract.executed_contract_clauses
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from contract.executed_contracts ec
       where ec.id = contract.executed_contract_clauses.contract_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ec.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ec.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

drop policy if exists executed_contract_clauses_admin_modify on contract.executed_contract_clauses;
create policy executed_contract_clauses_admin_modify on contract.executed_contract_clauses
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.4 contract_parties: same audience as parent contract.
drop policy if exists contract_parties_select on contract.contract_parties;
create policy contract_parties_select on contract.contract_parties
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from contract.executed_contracts ec
       where ec.id = contract.contract_parties.contract_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ec.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ec.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

drop policy if exists contract_parties_admin_modify on contract.contract_parties;
create policy contract_parties_admin_modify on contract.contract_parties
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.5 contract_signature_requests: visible to buyer org + supplier of contract + admin.
drop policy if exists contract_signature_requests_select on contract.contract_signature_requests;
create policy contract_signature_requests_select on contract.contract_signature_requests
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from contract.executed_contracts ec
       where ec.id = contract.contract_signature_requests.contract_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ec.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ec.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

drop policy if exists contract_signature_requests_admin_modify on contract.contract_signature_requests;
create policy contract_signature_requests_admin_modify on contract.contract_signature_requests
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.6 contract_signature_events: same audience (immutable).
drop policy if exists contract_signature_events_select on contract.contract_signature_events;
create policy contract_signature_events_select on contract.contract_signature_events
  for select
  using (
    exists (
      select 1 from contract.executed_contracts ec
       where ec.id = contract.contract_signature_events.contract_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ec.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ec.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

-- 4.7 executed_contract_snapshots: buyer org + admin (working artefacts).
drop policy if exists executed_contract_snapshots_select on contract.executed_contract_snapshots;
create policy executed_contract_snapshots_select on contract.executed_contract_snapshots
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = contract.executed_contract_snapshots.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

-- 4.8 executed_contract_events: buyer org + supplier of contract + admin.
drop policy if exists executed_contract_events_select on contract.executed_contract_events;
create policy executed_contract_events_select on contract.executed_contract_events
  for select
  using (
    exists (
      select 1 from contract.executed_contracts ec
       where ec.id = contract.executed_contract_events.contract_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ec.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ec.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 5. Buyer RPCs
-- ===========================================================================

-- 5.1 buyer_create_executed_contract ---------------------------------------
-- Creates executed contract from a ready_for_contract preparation. Copies items,
-- copies clauses, creates buyer + supplier parties, writes initial snapshot + event.
create or replace function contract.buyer_create_executed_contract(
  p_preparation_id uuid,
  p_title          text default null,
  p_effective_date date default null,
  p_expiry_date    date default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_buyer_org uuid; v_request_id uuid; v_offer_id uuid; v_decision_id uuid;
  v_supplier_id uuid; v_supplier_org uuid;
  v_prep_status contract.preparation_status;
  v_tenant uuid;
  v_code text;
  v_id uuid;
  v_title text;
  v_buyer_name text;
  v_supplier_name text;
  v_prep contract.contract_preparations%rowtype;
begin
  select buyer_org_id, request_id, offer_id, decision_id,
         supplier_id, supplier_organization_id, prep_status
    into v_buyer_org, v_request_id, v_offer_id, v_decision_id,
         v_supplier_id, v_supplier_org, v_prep_status
    from contract.fn_assert_buyer_for_preparation(p_preparation_id);

  -- Duplicate active executed contract for this preparation?
  if exists (
    select 1 from contract.executed_contracts
     where preparation_id = p_preparation_id and deleted_at is null and status <> 'superseded'
  ) then
    raise exception 'contract.execution: active executed contract already exists for this preparation'
      using errcode = '23505';
  end if;

  select * into v_prep from contract.contract_preparations where id = p_preparation_id;
  select r.tenant_id into v_tenant from rfq.requests r where r.id = v_request_id;
  v_code := contract.fn_next_contract_code(v_tenant);
  v_title := coalesce(p_title, v_prep.title);

  -- Insert master record.
  insert into contract.executed_contracts (
    tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id,
    supplier_id, supplier_organization_id, created_by,
    contract_code, status, title, contract_type, currency,
    incoterm, delivery_country, delivery_city, delivery_port, delivery_location_text,
    payment_terms_text, delivery_terms_text, inspection_terms_text,
    governing_law_text, dispute_resolution_text, special_conditions_text,
    internal_notes, effective_date, expiry_date, updated_by
  ) values (
    v_tenant, v_buyer_org, p_preparation_id, v_request_id, v_offer_id, v_decision_id,
    v_supplier_id, v_supplier_org, v_actor,
    v_code, 'draft_execution', v_title, v_prep.contract_type, v_prep.currency,
    v_prep.incoterm, v_prep.delivery_country, v_prep.delivery_city,
    v_prep.delivery_port, v_prep.delivery_location_text,
    v_prep.payment_terms_text, v_prep.delivery_terms_text, v_prep.inspection_terms_text,
    v_prep.governing_law_text, v_prep.dispute_resolution_text, v_prep.special_conditions_text,
    v_prep.internal_notes, p_effective_date, p_expiry_date, v_actor
  ) returning id into v_id;

  -- Copy items from preparation items.
  insert into contract.executed_contract_items (
    tenant_id, organization_id, contract_id, preparation_item_id, offer_item_id,
    request_item_id, product_id, quantity, quantity_unit, unit_price, total_price, currency,
    packaging, origin_country, origin_city, delivery_window_start, delivery_window_end,
    delivery_lead_time_text, notes, sort_order, created_by, updated_by
  )
  select v_tenant, v_buyer_org, v_id, it.id, it.offer_item_id,
         it.request_item_id, it.product_id, it.quantity, it.quantity_unit,
         it.unit_price, it.total_price, it.currency,
         it.packaging, it.origin_country, it.origin_city,
         it.delivery_window_start, it.delivery_window_end,
         it.delivery_lead_time_text, it.notes, it.sort_order, v_actor, v_actor
    from contract.contract_preparation_items it
   where it.preparation_id = p_preparation_id and it.deleted_at is null;

  -- Copy clauses from preparation clauses.
  insert into contract.executed_contract_clauses (
    tenant_id, organization_id, contract_id, preparation_clause_id,
    clause_type, clause_key, title_fa, title_en, body_fa, body_en, source,
    is_required, sort_order, created_by, updated_by
  )
  select v_tenant, v_buyer_org, v_id, c.id,
         c.clause_type, c.clause_key, c.title_fa, c.title_en, c.body_fa, c.body_en, c.source,
         c.is_required, c.sort_order, v_actor, v_actor
    from contract.contract_preparation_clauses c
   where c.preparation_id = p_preparation_id and c.deleted_at is null;

  -- Lookup display names for default parties.
  select name_en into v_buyer_name from organization.organizations where id = v_buyer_org;
  v_buyer_name := coalesce(v_buyer_name, 'Buyer');

  if v_supplier_org is not null then
    select name_en into v_supplier_name from organization.organizations where id = v_supplier_org;
  end if;
  v_supplier_name := coalesce(v_supplier_name, 'Supplier');

  -- Auto-add buyer + supplier parties (both required signers).
  insert into contract.contract_parties (
    tenant_id, organization_id, contract_id, party_type,
    party_organization_id, party_supplier_id, display_name, signing_order,
    is_required_signer, created_by, updated_by
  ) values
    (v_tenant, v_buyer_org, v_id, 'buyer',
     v_buyer_org, null, v_buyer_name, 1, true, v_actor, v_actor),
    (v_tenant, v_buyer_org, v_id, 'supplier',
     v_supplier_org, v_supplier_id, v_supplier_name, 2, true, v_actor, v_actor);

  -- Auto-create initial_from_preparation snapshot.
  insert into contract.executed_contract_snapshots (
    tenant_id, organization_id, contract_id, snapshot_type, title, snapshot_data, created_by
  ) values (
    v_tenant, v_buyer_org, v_id, 'initial_from_preparation',
    'Initial from preparation',
    jsonb_build_object(
      'preparation_id', p_preparation_id,
      'item_count', (select count(*) from contract.contract_preparation_items
                      where preparation_id = p_preparation_id and deleted_at is null),
      'clause_count', (select count(*) from contract.contract_preparation_clauses
                        where preparation_id = p_preparation_id and deleted_at is null)
    ),
    v_actor
  );

  perform contract.fn_record_executed_contract_event(v_id, null, 'draft_execution', 'contract_created');
  perform contract.fn_audit_contract('contract.executed_created', v_id,
    jsonb_build_object('preparation_id', p_preparation_id::text));
  return v_id;
end;
$$;

-- 5.2 buyer_update_executed_contract (draft_execution only) ----------------
create or replace function contract.buyer_update_executed_contract(
  p_contract_id              uuid,
  p_title                    text default null,
  p_incoterm                 text default null,
  p_delivery_country         char(2) default null,
  p_delivery_city            text default null,
  p_delivery_port            text default null,
  p_delivery_location_text   text default null,
  p_payment_terms_text       text default null,
  p_delivery_terms_text      text default null,
  p_inspection_terms_text    text default null,
  p_governing_law_text       text default null,
  p_dispute_resolution_text  text default null,
  p_special_conditions_text  text default null,
  p_internal_notes           text default null,
  p_effective_date           date default null,
  p_expiry_date              date default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  perform contract.fn_assert_executed_contract_editable(p_contract_id);

  update contract.executed_contracts
     set title                   = coalesce(p_title, title),
         incoterm                = coalesce(p_incoterm, incoterm),
         delivery_country        = coalesce(p_delivery_country, delivery_country),
         delivery_city           = coalesce(p_delivery_city, delivery_city),
         delivery_port           = coalesce(p_delivery_port, delivery_port),
         delivery_location_text  = coalesce(p_delivery_location_text, delivery_location_text),
         payment_terms_text      = coalesce(p_payment_terms_text, payment_terms_text),
         delivery_terms_text     = coalesce(p_delivery_terms_text, delivery_terms_text),
         inspection_terms_text   = coalesce(p_inspection_terms_text, inspection_terms_text),
         governing_law_text      = coalesce(p_governing_law_text, governing_law_text),
         dispute_resolution_text = coalesce(p_dispute_resolution_text, dispute_resolution_text),
         special_conditions_text = coalesce(p_special_conditions_text, special_conditions_text),
         internal_notes          = coalesce(p_internal_notes, internal_notes),
         effective_date          = coalesce(p_effective_date, effective_date),
         expiry_date             = coalesce(p_expiry_date, expiry_date),
         updated_by              = v_actor
   where id = p_contract_id;

  perform contract.fn_audit_contract('contract.executed_updated', p_contract_id);
end;
$$;

-- 5.3 buyer_add_party ------------------------------------------------------
create or replace function contract.buyer_add_party(
  p_contract_id          uuid,
  p_party_type           contract.party_type,
  p_display_name         text,
  p_party_organization_id uuid default null,
  p_party_supplier_id    uuid default null,
  p_party_user_id        uuid default null,
  p_role_title           text default null,
  p_signer_role          text default null,
  p_signing_order        integer default 0,
  p_is_required_signer   boolean default true
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  perform contract.fn_assert_executed_contract_editable(p_contract_id);
  if p_display_name is null or btrim(p_display_name) = '' then
    raise exception 'contract.execution: party display_name is required' using errcode = '22023';
  end if;

  select tenant_id, organization_id into v_tenant, v_org
    from contract.executed_contracts where id = p_contract_id;

  insert into contract.contract_parties (
    tenant_id, organization_id, contract_id, party_type,
    party_organization_id, party_supplier_id, party_user_id,
    display_name, role_title, signer_role, signing_order,
    is_required_signer, created_by, updated_by
  ) values (
    v_tenant, v_org, p_contract_id, p_party_type,
    p_party_organization_id, p_party_supplier_id, p_party_user_id,
    p_display_name, p_role_title, p_signer_role, p_signing_order,
    p_is_required_signer, v_actor, v_actor
  ) returning id into v_id;

  perform contract.fn_audit_contract('contract.party_added', p_contract_id,
    jsonb_build_object('party_id', v_id::text, 'party_type', p_party_type::text));
  return v_id;
end;
$$;

-- 5.4 buyer_create_signature_request ---------------------------------------
create or replace function contract.buyer_create_signature_request(
  p_contract_id       uuid,
  p_party_id          uuid,
  p_requested_to_user uuid default null,
  p_requested_to_email text default null,
  p_due_at            timestamptz default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_status contract.contract_status;
  v_id uuid;
begin
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  select status, tenant_id, organization_id into v_status, v_tenant, v_org
    from contract.executed_contracts where id = p_contract_id;
  if v_status not in ('draft_execution', 'pending_signatures', 'partially_signed') then
    raise exception 'contract.execution: cannot create signature request from status %', v_status
      using errcode = 'P0001';
  end if;

  -- Party must belong to this contract.
  if not exists (
    select 1 from contract.contract_parties
     where id = p_party_id and contract_id = p_contract_id and deleted_at is null
  ) then
    raise exception 'contract.execution: party not found in this contract' using errcode = 'P0002';
  end if;

  -- One active signature request per (contract, party) — handled by partial unique index.
  insert into contract.contract_signature_requests (
    tenant_id, organization_id, contract_id, party_id,
    requested_to_user, requested_to_email, status, due_at,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_contract_id, p_party_id,
    p_requested_to_user, p_requested_to_email, 'pending', p_due_at,
    v_actor, v_actor
  ) returning id into v_id;

  perform contract.fn_record_signature_event(v_id, null, 'pending', 'requested');
  perform contract.fn_audit_contract('contract.signature_requested', p_contract_id,
    jsonb_build_object('signature_request_id', v_id::text, 'party_id', p_party_id::text));
  return v_id;
end;
$$;

-- 5.5 buyer_mark_pending_signatures ----------------------------------------
create or replace function contract.buyer_mark_pending_signatures(p_contract_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.contract_status;
  v_req_count int;
  v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  select status into v_status from contract.executed_contracts where id = p_contract_id;
  if v_status <> 'draft_execution' then
    raise exception 'contract.execution: invalid_transition: cannot mark pending from %', v_status
      using errcode = 'P0001';
  end if;
  select count(*) into v_req_count from contract.contract_signature_requests
   where contract_id = p_contract_id and deleted_at is null and status = 'pending';
  if v_req_count = 0 then
    raise exception 'contract.execution: at least one pending signature request is required'
      using errcode = 'P0001';
  end if;

  update contract.executed_contracts
     set status = 'pending_signatures',
         pending_signatures_at = now(),
         pending_signatures_by = v_actor,
         updated_by = v_actor
   where id = p_contract_id;

  perform contract.fn_record_executed_contract_event(p_contract_id, 'draft_execution', 'pending_signatures');
  perform contract.fn_audit_contract('contract.executed_pending_signatures', p_contract_id);
end;
$$;

-- 5.6 buyer_create_executed_snapshot ---------------------------------------
create or replace function contract.buyer_create_executed_snapshot(
  p_contract_id    uuid,
  p_snapshot_type  contract.executed_snapshot_type,
  p_title          text,
  p_snapshot_data  jsonb default '{}'::jsonb,
  p_notes          text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  if p_title is null or btrim(p_title) = '' then
    raise exception 'contract.execution: snapshot title is required' using errcode = '22023';
  end if;
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  select tenant_id, organization_id into v_tenant, v_org
    from contract.executed_contracts where id = p_contract_id;

  insert into contract.executed_contract_snapshots (
    tenant_id, organization_id, contract_id, snapshot_type, title, snapshot_data, notes, created_by
  ) values (
    v_tenant, v_org, p_contract_id, p_snapshot_type, p_title,
    coalesce(p_snapshot_data, '{}'::jsonb), p_notes, v_actor
  ) returning id into v_id;

  perform contract.fn_audit_contract('contract.executed_snapshot_created', p_contract_id,
    jsonb_build_object('snapshot_id', v_id::text, 'snapshot_type', p_snapshot_type::text));
  return v_id;
end;
$$;

-- 5.7 buyer_cancel_executed_contract ---------------------------------------
create or replace function contract.buyer_cancel_executed_contract(
  p_contract_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.contract_status;
  v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  select status into v_status from contract.executed_contracts where id = p_contract_id;
  if v_status not in ('draft_execution', 'pending_signatures', 'partially_signed') then
    raise exception 'contract.execution: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;

  update contract.executed_contracts
     set status           = 'cancelled',
         cancelled_at     = now(),
         cancelled_by     = v_actor,
         cancelled_reason = p_reason,
         updated_by       = v_actor
   where id = p_contract_id;

  perform contract.fn_record_executed_contract_event(p_contract_id, v_status, 'cancelled', p_reason);
  perform contract.fn_audit_contract('contract.executed_cancelled', p_contract_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 5.8 buyer_list_executed_contracts ----------------------------------------
create or replace function contract.buyer_list_executed_contracts(
  p_request_id uuid                       default null,
  p_status     contract.contract_status   default null,
  p_limit      integer                    default 25,
  p_offset     integer                    default 0
) returns table (
  id uuid, contract_code text, preparation_id uuid, request_id uuid, offer_id uuid,
  supplier_id uuid, status text, title text, created_at timestamptz, updated_at timestamptz
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
    raise exception 'contract.execution: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'contract.execution: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select ec.id, ec.contract_code, ec.preparation_id, ec.request_id, ec.offer_id,
           ec.supplier_id, ec.status::text, ec.title, ec.created_at, ec.updated_at
      from contract.executed_contracts ec
     where ec.deleted_at is null
       and (identity.is_platform_admin() or ec.organization_id = v_caller_org)
       and (p_request_id is null or ec.request_id = p_request_id)
       and (p_status     is null or ec.status     = p_status)
     order by ec.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 5.9 buyer_get_executed_contract ------------------------------------------
create or replace function contract.buyer_get_executed_contract(p_contract_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform contract.fn_assert_executed_contract_owned(p_contract_id);
  return (
    select jsonb_build_object(
      'id', ec.id, 'contract_code', ec.contract_code,
      'preparation_id', ec.preparation_id, 'request_id', ec.request_id,
      'offer_id', ec.offer_id, 'decision_id', ec.decision_id,
      'supplier_id', ec.supplier_id, 'supplier_organization_id', ec.supplier_organization_id,
      'status', ec.status, 'title', ec.title, 'contract_type', ec.contract_type,
      'currency', ec.currency, 'incoterm', ec.incoterm,
      'effective_date', ec.effective_date, 'expiry_date', ec.expiry_date,
      'executed_at', ec.executed_at,
      'created_at', ec.created_at, 'updated_at', ec.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'preparation_item_id', it.preparation_item_id,
          'product_id', it.product_id, 'quantity', it.quantity, 'unit_price', it.unit_price,
          'total_price', it.total_price, 'currency', it.currency, 'sort_order', it.sort_order
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from contract.executed_contract_items it
         where it.contract_id = ec.id and it.deleted_at is null
      ),
      'clauses', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', c.id, 'clause_type', c.clause_type, 'clause_key', c.clause_key,
          'title_en', c.title_en, 'is_required', c.is_required, 'sort_order', c.sort_order
        ) order by c.sort_order, c.created_at), '[]'::jsonb)
          from contract.executed_contract_clauses c
         where c.contract_id = ec.id and c.deleted_at is null
      ),
      'parties', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', cp.id, 'party_type', cp.party_type, 'display_name', cp.display_name,
          'signing_order', cp.signing_order, 'is_required_signer', cp.is_required_signer
        ) order by cp.signing_order, cp.created_at), '[]'::jsonb)
          from contract.contract_parties cp
         where cp.contract_id = ec.id and cp.deleted_at is null
      ),
      'signature_requests', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', sr.id, 'party_id', sr.party_id, 'status', sr.status,
          'requested_at', sr.requested_at, 'signed_at', sr.signed_at,
          'declined_at', sr.declined_at
        ) order by sr.created_at), '[]'::jsonb)
          from contract.contract_signature_requests sr
         where sr.contract_id = ec.id and sr.deleted_at is null
      )
    )
    from contract.executed_contracts ec where ec.id = p_contract_id
  );
end;
$$;

-- 5.10 buyer_sign_signature_request ----------------------------------------
create or replace function contract.buyer_sign_signature_request(
  p_signature_request_id uuid,
  p_metadata             jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status contract.signature_status;
  v_contract uuid;
begin
  select status, contract_id into v_status, v_contract
    from contract.fn_assert_buyer_for_signature(p_signature_request_id);
  if v_status not in ('pending', 'viewed') then
    raise exception 'contract.execution: signature already in terminal state (%)', v_status
      using errcode = 'P0001';
  end if;
  update contract.contract_signature_requests
     set status     = 'signed',
         signed_at  = now(),
         completed_at = now(),
         updated_by = v_actor
   where id = p_signature_request_id;
  perform contract.fn_record_signature_event(p_signature_request_id, v_status, 'signed', 'signed',
    null, coalesce(p_metadata, '{}'::jsonb));
  perform contract.fn_try_promote_to_executed(v_contract);
  perform contract.fn_audit_contract('contract.signature_signed', v_contract,
    jsonb_build_object('signature_request_id', p_signature_request_id::text));
end;
$$;

-- 5.11 buyer_decline_signature_request -------------------------------------
create or replace function contract.buyer_decline_signature_request(
  p_signature_request_id uuid,
  p_reason               text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status contract.signature_status;
  v_contract uuid;
begin
  select status, contract_id into v_status, v_contract
    from contract.fn_assert_buyer_for_signature(p_signature_request_id);
  if v_status in ('signed', 'declined', 'cancelled', 'expired') then
    raise exception 'contract.execution: signature already in terminal state (%)', v_status
      using errcode = 'P0001';
  end if;
  update contract.contract_signature_requests
     set status         = 'declined',
         declined_at    = now(),
         completed_at   = now(),
         decline_reason = p_reason,
         updated_by     = v_actor
   where id = p_signature_request_id;
  perform contract.fn_record_signature_event(p_signature_request_id, v_status, 'declined', 'declined', p_reason);
  perform contract.fn_audit_contract('contract.signature_declined', v_contract,
    jsonb_build_object('signature_request_id', p_signature_request_id::text, 'reason', p_reason));
end;
$$;

-- ===========================================================================
-- 6. Supplier RPCs
-- ===========================================================================

-- 6.1 supplier_list_my_executed_contracts ----------------------------------
create or replace function contract.supplier_list_my_executed_contracts(
  p_status contract.contract_status default null,
  p_limit  integer                    default 25,
  p_offset integer                    default 0
) returns table (
  id uuid, contract_code text, request_id uuid, offer_id uuid,
  status text, title text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select ec.id, ec.contract_code, ec.request_id, ec.offer_id,
           ec.status::text, ec.title, ec.created_at, ec.updated_at
      from contract.executed_contracts ec
     where ec.deleted_at is null
       and ec.supplier_id = v_supplier
       and (p_status is null or ec.status = p_status)
     order by ec.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.2 supplier_get_my_executed_contract ------------------------------------
create or replace function contract.supplier_get_my_executed_contract(p_contract_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_supplier uuid := supplier.fn_portal_supplier_id();
  v_contract_supplier uuid;
begin
  select supplier_id into v_contract_supplier from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_contract_supplier is null then
    raise exception 'contract.execution: contract not found' using errcode = 'P0002';
  end if;
  if v_contract_supplier <> v_caller_supplier and not identity.is_platform_admin() then
    raise exception 'contract.execution: contract is not on caller''s offer' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', ec.id, 'contract_code', ec.contract_code,
      'request_id', ec.request_id, 'offer_id', ec.offer_id,
      'status', ec.status, 'title', ec.title,
      'contract_type', ec.contract_type, 'currency', ec.currency,
      'incoterm', ec.incoterm,
      'effective_date', ec.effective_date, 'expiry_date', ec.expiry_date,
      'executed_at', ec.executed_at,
      'created_at', ec.created_at, 'updated_at', ec.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'product_id', it.product_id, 'quantity', it.quantity,
          'unit_price', it.unit_price, 'total_price', it.total_price, 'currency', it.currency
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from contract.executed_contract_items it
         where it.contract_id = ec.id and it.deleted_at is null
      )
    )
    from contract.executed_contracts ec where ec.id = p_contract_id
  );
end;
$$;

-- 6.3 supplier_list_my_signature_requests ----------------------------------
create or replace function contract.supplier_list_my_signature_requests(
  p_status contract.signature_status default null,
  p_limit  integer                    default 25,
  p_offset integer                    default 0
) returns table (
  id uuid, contract_id uuid, party_id uuid, status text,
  requested_at timestamptz, due_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select sr.id, sr.contract_id, sr.party_id, sr.status::text,
           sr.requested_at, sr.due_at
      from contract.contract_signature_requests sr
      join contract.contract_parties cp on cp.id = sr.party_id
     where sr.deleted_at is null
       and cp.party_type = 'supplier'
       and cp.party_supplier_id = v_supplier
       and (p_status is null or sr.status = p_status)
     order by sr.requested_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.4 supplier_view_signature_request --------------------------------------
create or replace function contract.supplier_view_signature_request(p_signature_request_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status contract.signature_status;
begin
  select status into v_status
    from contract.fn_assert_supplier_for_signature(p_signature_request_id);
  if v_status not in ('pending') then
    return;
  end if;
  update contract.contract_signature_requests
     set status = 'viewed',
         viewed_at = now(),
         updated_by = v_actor
   where id = p_signature_request_id;
  perform contract.fn_record_signature_event(p_signature_request_id, 'pending', 'viewed', 'viewed');
end;
$$;

-- 6.5 supplier_sign_signature_request --------------------------------------
create or replace function contract.supplier_sign_signature_request(
  p_signature_request_id uuid,
  p_metadata             jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status contract.signature_status;
  v_contract uuid;
begin
  select status, contract_id into v_status, v_contract
    from contract.fn_assert_supplier_for_signature(p_signature_request_id);
  if v_status not in ('pending', 'viewed') then
    raise exception 'contract.execution: signature already in terminal state (%)', v_status
      using errcode = 'P0001';
  end if;
  update contract.contract_signature_requests
     set status     = 'signed',
         signed_at  = now(),
         completed_at = now(),
         updated_by = v_actor
   where id = p_signature_request_id;
  perform contract.fn_record_signature_event(p_signature_request_id, v_status, 'signed', 'signed',
    null, coalesce(p_metadata, '{}'::jsonb));
  perform contract.fn_try_promote_to_executed(v_contract);
  perform contract.fn_audit_contract('contract.signature_signed', v_contract,
    jsonb_build_object('signature_request_id', p_signature_request_id::text));
end;
$$;

-- 6.6 supplier_decline_signature_request -----------------------------------
create or replace function contract.supplier_decline_signature_request(
  p_signature_request_id uuid,
  p_reason               text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status contract.signature_status;
  v_contract uuid;
begin
  select status, contract_id into v_status, v_contract
    from contract.fn_assert_supplier_for_signature(p_signature_request_id);
  if v_status in ('signed', 'declined', 'cancelled', 'expired') then
    raise exception 'contract.execution: signature already in terminal state (%)', v_status
      using errcode = 'P0001';
  end if;
  update contract.contract_signature_requests
     set status         = 'declined',
         declined_at    = now(),
         completed_at   = now(),
         decline_reason = p_reason,
         updated_by     = v_actor
   where id = p_signature_request_id;
  perform contract.fn_record_signature_event(p_signature_request_id, v_status, 'declined', 'declined', p_reason);
  perform contract.fn_audit_contract('contract.signature_declined', v_contract,
    jsonb_build_object('signature_request_id', p_signature_request_id::text, 'reason', p_reason));
end;
$$;

-- ===========================================================================
-- 7. Admin RPCs
-- ===========================================================================

-- 7.1 admin_list_executed_contracts ----------------------------------------
create or replace function contract.admin_list_executed_contracts(
  p_request_id  uuid                       default null,
  p_offer_id    uuid                       default null,
  p_supplier_id uuid                       default null,
  p_status      contract.contract_status   default null,
  p_limit       integer                    default 25,
  p_offset      integer                    default 0
) returns table (
  id uuid, contract_code text, organization_id uuid,
  request_id uuid, offer_id uuid, supplier_id uuid,
  status text, title text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_executed_contracts: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select ec.id, ec.contract_code, ec.organization_id,
           ec.request_id, ec.offer_id, ec.supplier_id,
           ec.status::text, ec.title, ec.created_at, ec.updated_at
      from contract.executed_contracts ec
     where ec.deleted_at is null
       and (p_request_id  is null or ec.request_id  = p_request_id)
       and (p_offer_id    is null or ec.offer_id    = p_offer_id)
       and (p_supplier_id is null or ec.supplier_id = p_supplier_id)
       and (p_status      is null or ec.status      = p_status)
     order by ec.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 admin_get_executed_contract ------------------------------------------
create or replace function contract.admin_get_executed_contract(p_contract_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_executed_contract: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', ec.id, 'contract_code', ec.contract_code,
      'organization_id', ec.organization_id, 'preparation_id', ec.preparation_id,
      'request_id', ec.request_id, 'offer_id', ec.offer_id,
      'supplier_id', ec.supplier_id,
      'status', ec.status, 'title', ec.title,
      'executed_at', ec.executed_at,
      'created_at', ec.created_at, 'updated_at', ec.updated_at,
      'items_count', (select count(*) from contract.executed_contract_items
                       where contract_id = ec.id and deleted_at is null),
      'clauses_count', (select count(*) from contract.executed_contract_clauses
                         where contract_id = ec.id and deleted_at is null),
      'parties_count', (select count(*) from contract.contract_parties
                         where contract_id = ec.id and deleted_at is null),
      'signature_requests_count', (select count(*) from contract.contract_signature_requests
                                    where contract_id = ec.id and deleted_at is null)
    )
    from contract.executed_contracts ec where ec.id = p_contract_id
  );
end;
$$;

-- 7.3 admin_list_executed_contract_events ----------------------------------
create or replace function contract.admin_list_executed_contract_events(p_contract_id uuid)
returns table (
  id uuid, from_status text, to_status text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_executed_contract_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from contract.executed_contract_events e
     where e.contract_id = p_contract_id
     order by e.created_at asc;
end;
$$;

-- 7.4 admin_list_signature_events ------------------------------------------
create or replace function contract.admin_list_signature_events(
  p_contract_id uuid default null,
  p_signature_request_id uuid default null
) returns table (
  id uuid, signature_request_id uuid, contract_id uuid,
  from_status text, to_status text, event_type text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_signature_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.signature_request_id, e.contract_id,
           e.from_status::text, e.to_status::text, e.event_type,
           e.actor_user_id, e.reason, e.created_at
      from contract.contract_signature_events e
     where (p_contract_id is null or e.contract_id = p_contract_id)
       and (p_signature_request_id is null or e.signature_request_id = p_signature_request_id)
     order by e.created_at asc;
end;
$$;

-- 7.5 admin_force_cancel_contract ------------------------------------------
create or replace function contract.admin_force_cancel_contract(
  p_contract_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.contract_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_cancel_contract: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract.execution: contract not found' using errcode = 'P0002';
  end if;
  if v_status in ('cancelled', 'voided', 'superseded', 'executed') then
    raise exception 'contract.execution: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;
  update contract.executed_contracts
     set status = 'cancelled', cancelled_at = now(), cancelled_by = v_actor,
         cancelled_reason = p_reason, updated_by = v_actor
   where id = p_contract_id;
  perform contract.fn_record_executed_contract_event(p_contract_id, v_status, 'cancelled',
    coalesce(p_reason, 'admin_force_cancel'));
  perform contract.fn_audit_contract('contract.executed_admin_cancelled', p_contract_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 7.6 admin_void_contract --------------------------------------------------
create or replace function contract.admin_void_contract(
  p_contract_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.contract_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_void_contract: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract.execution: contract not found' using errcode = 'P0002';
  end if;
  if v_status in ('voided', 'superseded') then
    raise exception 'contract.execution: invalid_transition: cannot void from %', v_status
      using errcode = 'P0001';
  end if;
  update contract.executed_contracts
     set status = 'voided', voided_at = now(), voided_by = v_actor,
         voided_reason = p_reason, updated_by = v_actor
   where id = p_contract_id;
  perform contract.fn_record_executed_contract_event(p_contract_id, v_status, 'voided', p_reason);
  perform contract.fn_audit_contract('contract.executed_voided', p_contract_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 7.7 admin_supersede_contract ---------------------------------------------
create or replace function contract.admin_supersede_contract(
  p_contract_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.contract_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_supersede_contract: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from contract.executed_contracts
   where id = p_contract_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract.execution: contract not found' using errcode = 'P0002';
  end if;
  if v_status = 'superseded' then
    raise exception 'contract.execution: already superseded' using errcode = 'P0001';
  end if;
  update contract.executed_contracts
     set status = 'superseded', superseded_at = now(), superseded_by = v_actor,
         superseded_reason = p_reason, updated_by = v_actor
   where id = p_contract_id;
  perform contract.fn_record_executed_contract_event(p_contract_id, v_status, 'superseded', p_reason);
  perform contract.fn_audit_contract('contract.executed_superseded', p_contract_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 8. Trigger attachments (set_updated_at + audit)
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
      join information_schema.columns c
        on c.table_schema = t.table_schema and c.table_name = t.table_name
     where t.table_schema = 'contract'
       and t.table_type   = 'BASE TABLE'
       and c.column_name  = 'updated_at'
       and t.table_name in ('executed_contracts','executed_contract_items','executed_contract_clauses',
                            'contract_parties','contract_signature_requests')
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
     where t.table_schema = 'contract'
       and t.table_type   = 'BASE TABLE'
       and t.table_name in ('executed_contracts','executed_contract_items','executed_contract_clauses',
                            'contract_parties','contract_signature_requests',
                            'contract_signature_events','executed_contract_snapshots',
                            'executed_contract_events')
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
-- 9. Grants (SELECT only on tables; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on contract.executed_contracts          to anon, authenticated;
grant select on contract.executed_contract_items     to anon, authenticated;
grant select on contract.executed_contract_clauses   to authenticated;
grant select on contract.contract_parties            to authenticated;
grant select on contract.contract_signature_requests to authenticated;
grant select on contract.contract_signature_events   to authenticated;
grant select on contract.executed_contract_snapshots to authenticated;
grant select on contract.executed_contract_events    to authenticated;

-- ===========================================================================
-- 10. RPC EXECUTE grants
-- ===========================================================================
grant execute on function contract.buyer_create_executed_contract(uuid, text, date, date) to authenticated;
grant execute on function contract.buyer_update_executed_contract(uuid, text, text, char, text, text, text, text, text, text, text, text, text, text, date, date) to authenticated;
grant execute on function contract.buyer_add_party(uuid, contract.party_type, text, uuid, uuid, uuid, text, text, integer, boolean) to authenticated;
grant execute on function contract.buyer_create_signature_request(uuid, uuid, uuid, text, timestamptz) to authenticated;
grant execute on function contract.buyer_mark_pending_signatures(uuid) to authenticated;
grant execute on function contract.buyer_create_executed_snapshot(uuid, contract.executed_snapshot_type, text, jsonb, text) to authenticated;
grant execute on function contract.buyer_cancel_executed_contract(uuid, text) to authenticated;
grant execute on function contract.buyer_list_executed_contracts(uuid, contract.contract_status, integer, integer) to authenticated;
grant execute on function contract.buyer_get_executed_contract(uuid) to authenticated;
grant execute on function contract.buyer_sign_signature_request(uuid, jsonb) to authenticated;
grant execute on function contract.buyer_decline_signature_request(uuid, text) to authenticated;

grant execute on function contract.supplier_list_my_executed_contracts(contract.contract_status, integer, integer) to authenticated;
grant execute on function contract.supplier_get_my_executed_contract(uuid) to authenticated;
grant execute on function contract.supplier_list_my_signature_requests(contract.signature_status, integer, integer) to authenticated;
grant execute on function contract.supplier_view_signature_request(uuid) to authenticated;
grant execute on function contract.supplier_sign_signature_request(uuid, jsonb) to authenticated;
grant execute on function contract.supplier_decline_signature_request(uuid, text) to authenticated;

grant execute on function contract.admin_list_executed_contracts(uuid, uuid, uuid, contract.contract_status, integer, integer) to authenticated;
grant execute on function contract.admin_get_executed_contract(uuid) to authenticated;
grant execute on function contract.admin_list_executed_contract_events(uuid) to authenticated;
grant execute on function contract.admin_list_signature_events(uuid, uuid) to authenticated;
grant execute on function contract.admin_force_cancel_contract(uuid, text) to authenticated;
grant execute on function contract.admin_void_contract(uuid, text) to authenticated;
grant execute on function contract.admin_supersede_contract(uuid, text) to authenticated;
