-- CC-12 / Migration 0023 — Contract Preparation Foundation
-- Sixth business domain (after supplier, commodity, rfq, offer, evaluation).
-- Append-only over migrations 0001-0022.
--
-- Scope: contract PREPARATION only. No formal contract execution, no signatures,
-- no payment, no shipment, no settlement, no escrow, no invoice, no negotiation.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists contract;
grant usage on schema contract to anon, authenticated, service_role;
comment on schema contract is
  'iKIA Phase 2 — contract preparation domain. Preparation only; no formal contract execution / signatures / payment / shipment.';

-- ===========================================================================
-- 2. Enums (4)
-- ===========================================================================
create type contract.preparation_status as enum (
  'draft', 'under_review', 'ready_for_contract', 'cancelled', 'superseded'
);

create type contract.preparation_contract_type as enum (
  'spot', 'framework', 'term', 'other'
);

create type contract.preparation_clause_type as enum (
  'payment', 'delivery', 'inspection', 'quality', 'documents',
  'force_majeure', 'dispute_resolution', 'governing_law',
  'special_conditions', 'other'
);

create type contract.preparation_snapshot_type as enum (
  'initial_from_offer', 'review_snapshot', 'ready_for_contract_snapshot'
);

-- ===========================================================================
-- 3. Tables (5)
-- ===========================================================================

-- 3.1 contract_preparations ------------------------------------------------
create table contract.contract_preparations (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  request_id                  uuid not null references rfq.requests(id) on delete restrict,
  offer_id                    uuid not null references offer.supplier_offers(id) on delete restrict,
  decision_id                 uuid not null references evaluation.offer_decisions(id) on delete restrict,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,
  prepared_by                 uuid references auth.users(id),

  preparation_code            text not null,
  status                      contract.preparation_status not null default 'draft',
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

  metadata                    jsonb not null default '{}'::jsonb,

  submitted_for_review_at     timestamptz,
  submitted_for_review_by     uuid references auth.users(id),
  ready_at                    timestamptz,
  ready_by                    uuid references auth.users(id),
  cancelled_at                timestamptz,
  cancelled_by                uuid references auth.users(id),
  cancelled_reason            text,
  superseded_at               timestamptz,
  superseded_by               uuid references auth.users(id),
  superseded_reason           text,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table contract.contract_preparations is
  'Buyer-prepared contract draft derived from an evaluation decision (selected_for_contract). Not an executed contract.';

-- One active (non-superseded, not soft-deleted) preparation per decision.
create unique index contract_preparations_unique_active
  on contract.contract_preparations(decision_id)
  where deleted_at is null and status <> 'superseded';

create unique index contract_preparations_code_unique
  on contract.contract_preparations(tenant_id, lower(preparation_code))
  where deleted_at is null;

create index contract_preparations_request_idx  on contract.contract_preparations(request_id);
create index contract_preparations_offer_idx    on contract.contract_preparations(offer_id);
create index contract_preparations_supplier_idx on contract.contract_preparations(supplier_id);
create index contract_preparations_status_idx   on contract.contract_preparations(status);

-- 3.2 contract_preparation_items -------------------------------------------
create table contract.contract_preparation_items (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  preparation_id          uuid not null references contract.contract_preparations(id) on delete cascade,
  offer_item_id           uuid not null references offer.supplier_offer_items(id) on delete restrict,
  request_item_id         uuid not null references rfq.request_items(id) on delete restrict,
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

comment on table contract.contract_preparation_items is
  'Line items copied from the selected offer''s items into the contract preparation. Editable while preparation is draft/under_review.';

create unique index contract_preparation_items_unique_active
  on contract.contract_preparation_items(preparation_id, offer_item_id)
  where deleted_at is null;

create index contract_preparation_items_prep_idx
  on contract.contract_preparation_items(preparation_id);

-- 3.3 contract_preparation_clauses -----------------------------------------
create table contract.contract_preparation_clauses (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  preparation_id      uuid not null references contract.contract_preparations(id) on delete cascade,

  clause_type         contract.preparation_clause_type not null,
  clause_key          text,
  title_fa            text,
  title_en            text,
  body_fa             text,
  body_en             text,
  source              text,
  is_required         boolean not null default false,
  sort_order          integer not null default 0,
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table contract.contract_preparation_clauses is
  'Structured clauses for the contract preparation. clause_key is an optional natural key for upsert within a preparation.';

create unique index contract_preparation_clauses_unique_active
  on contract.contract_preparation_clauses(preparation_id, clause_type, coalesce(lower(clause_key), ''))
  where deleted_at is null;

create index contract_preparation_clauses_prep_idx
  on contract.contract_preparation_clauses(preparation_id);

-- 3.4 contract_preparation_snapshots (immutable) ---------------------------
create table contract.contract_preparation_snapshots (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  preparation_id      uuid not null references contract.contract_preparations(id) on delete cascade,

  snapshot_type       contract.preparation_snapshot_type not null,
  title               text not null,
  snapshot_data       jsonb not null default '{}'::jsonb,
  notes               text,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now()
);

comment on table contract.contract_preparation_snapshots is
  'Immutable snapshots of a contract preparation at a point in time. No UPDATE/DELETE policies.';

create index contract_preparation_snapshots_prep_idx
  on contract.contract_preparation_snapshots(preparation_id, created_at desc);

-- 3.5 contract_preparation_events (immutable) ------------------------------
create table contract.contract_preparation_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  preparation_id          uuid not null references contract.contract_preparations(id) on delete cascade,

  from_status             contract.preparation_status,
  to_status               contract.preparation_status not null,
  actor_user_id           uuid references auth.users(id),
  actor_organization_id   uuid references organization.organizations(id),
  reason                  text,
  payload                 jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table contract.contract_preparation_events is
  'Immutable audit trail of contract-preparation lifecycle transitions. No UPDATE/DELETE policies.';

create index contract_preparation_events_prep_idx
  on contract.contract_preparation_events(preparation_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function contract.fn_audit(
  p_action_code text,
  p_preparation_id uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from contract.contract_preparations where id = p_preparation_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'contract', p_preparation_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_record_preparation_event ------------------------------------------
create or replace function contract.fn_record_preparation_event(
  p_preparation_id uuid,
  p_from           contract.preparation_status,
  p_to             contract.preparation_status,
  p_reason         text default null,
  p_payload        jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from contract.contract_preparations where id = p_preparation_id;
  insert into contract.contract_preparation_events (
    tenant_id, organization_id, preparation_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_preparation_id,
    p_from, p_to, auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 4.3 fn_assert_buyer_for_decision -----------------------------------------
-- Verifies that:
--   * caller has buyer_admin / organization_admin / platform_admin
--   * decision exists, is selected_for_contract
--   * decision's offer's RFQ is owned by caller's organization
-- Returns a row with all the cross-domain identifiers needed to build a preparation.
create or replace function contract.fn_assert_buyer_for_decision(p_decision_id uuid)
returns table (
  buyer_org_id              uuid,
  request_id                uuid,
  offer_id                  uuid,
  supplier_id               uuid,
  supplier_organization_id  uuid,
  decision_status           evaluation.decision_status
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org  uuid;
  v_request_id uuid;
  v_offer_id   uuid;
  v_supplier_id uuid;
  v_supplier_org uuid;
  v_dec_status evaluation.decision_status;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'contract: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;

  select d.decision_status, d.offer_id, d.request_id,
         r.organization_id, so.supplier_id, so.organization_id
    into v_dec_status, v_offer_id, v_request_id,
         v_buyer_org, v_supplier_id, v_supplier_org
    from evaluation.offer_decisions d
    join offer.supplier_offers so on so.id = d.offer_id
    join rfq.requests r            on r.id = d.request_id
   where d.id = p_decision_id and d.deleted_at is null;

  if v_dec_status is null then
    raise exception 'contract: decision not found' using errcode = 'P0002';
  end if;
  if v_dec_status <> 'selected_for_contract' then
    raise exception 'contract: decision is not selected_for_contract (current=%)', v_dec_status
      using errcode = 'P0001';
  end if;

  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'contract: decision is not in caller''s organization'
        using errcode = '42501';
    end if;
  end if;

  return query select v_buyer_org, v_request_id, v_offer_id,
                      v_supplier_id, v_supplier_org, v_dec_status;
end;
$$;

-- 4.4 fn_assert_preparation_owned ------------------------------------------
create or replace function contract.fn_assert_preparation_owned(p_preparation_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_org from contract.contract_preparations
   where id = p_preparation_id and deleted_at is null;
  if v_org is null then
    raise exception 'contract: preparation not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'contract: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'contract: preparation not owned by caller organization' using errcode = '42501';
  end if;
end;
$$;

-- 4.5 fn_assert_preparation_editable ---------------------------------------
create or replace function contract.fn_assert_preparation_editable(p_preparation_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status contract.preparation_status;
begin
  select status into v_status from contract.contract_preparations
   where id = p_preparation_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract: preparation not found' using errcode = 'P0002';
  end if;
  if v_status not in ('draft', 'under_review') then
    raise exception 'contract: preparation locked (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- 4.6 fn_next_preparation_code ---------------------------------------------
create or replace function contract.fn_next_preparation_code(p_tenant_id uuid)
returns text
language plpgsql volatile security definer set search_path = ''
as $$
declare v_code text;
begin
  -- Format: PREP-YYYY-XXXXXXXX (random short hex). Tenant scope only.
  v_code := 'PREP-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table contract.contract_preparations          enable row level security;
alter table contract.contract_preparation_items     enable row level security;
alter table contract.contract_preparation_clauses   enable row level security;
alter table contract.contract_preparation_snapshots enable row level security;
alter table contract.contract_preparation_events    enable row level security;

-- 5.1 contract_preparations: buyer org + supplier of the offer + platform_admin.
drop policy if exists contract_preparations_select on contract.contract_preparations;
create policy contract_preparations_select on contract.contract_preparations
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = contract.contract_preparations.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = contract.contract_preparations.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists contract_preparations_admin_modify on contract.contract_preparations;
create policy contract_preparations_admin_modify on contract.contract_preparations
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 contract_preparation_items: same audience as parent preparation.
drop policy if exists contract_preparation_items_select on contract.contract_preparation_items;
create policy contract_preparation_items_select on contract.contract_preparation_items
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from contract.contract_preparations p
       where p.id = contract.contract_preparation_items.preparation_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = p.organization_id
                and m.deleted_at is null
                and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = p.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null
               and m.status = 'active'
           )
         )
    )
  );

drop policy if exists contract_preparation_items_admin_modify on contract.contract_preparation_items;
create policy contract_preparation_items_admin_modify on contract.contract_preparation_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 contract_preparation_clauses: buyer org + admin only (suppliers cannot read clauses
-- until the preparation is shared — out of scope here; buyer-only working surface).
drop policy if exists contract_preparation_clauses_select on contract.contract_preparation_clauses;
create policy contract_preparation_clauses_select on contract.contract_preparation_clauses
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = contract.contract_preparation_clauses.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists contract_preparation_clauses_admin_modify on contract.contract_preparation_clauses;
create policy contract_preparation_clauses_admin_modify on contract.contract_preparation_clauses
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.4 contract_preparation_snapshots: buyer org + admin (immutable; no INS/UPD/DEL policies).
drop policy if exists contract_preparation_snapshots_select on contract.contract_preparation_snapshots;
create policy contract_preparation_snapshots_select on contract.contract_preparation_snapshots
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = contract.contract_preparation_snapshots.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

-- 5.5 contract_preparation_events: buyer org + supplier of related preparation + admin.
drop policy if exists contract_preparation_events_select on contract.contract_preparation_events;
create policy contract_preparation_events_select on contract.contract_preparation_events
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = contract.contract_preparation_events.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
    or exists (
      select 1 from contract.contract_preparations p
       join supplier.suppliers s on s.id = p.supplier_id
       join organization.memberships m on m.organization_id = s.organization_id
      where p.id = contract.contract_preparation_events.preparation_id
        and m.user_id = identity.current_user_id()
        and m.deleted_at is null
        and m.status = 'active'
    )
  );

-- ===========================================================================
-- 6. Buyer RPCs (11)
-- ===========================================================================

-- 6.1 buyer_create_preparation ---------------------------------------------
create or replace function contract.buyer_create_preparation(
  p_decision_id              uuid,
  p_title                    text,
  p_contract_type            contract.preparation_contract_type default 'spot',
  p_currency                 text default null,
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
  p_internal_notes           text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_buyer_org uuid; v_request_id uuid; v_offer_id uuid;
  v_supplier_id uuid; v_supplier_org uuid; v_dec_status evaluation.decision_status;
  v_tenant uuid;
  v_currency text;
  v_code text;
  v_id uuid;
begin
  if p_title is null or btrim(p_title) = '' then
    raise exception 'contract: title is required' using errcode = '22023';
  end if;

  select buyer_org_id, request_id, offer_id,
         supplier_id, supplier_organization_id, decision_status
    into v_buyer_org, v_request_id, v_offer_id,
         v_supplier_id, v_supplier_org, v_dec_status
    from contract.fn_assert_buyer_for_decision(p_decision_id);

  -- Duplicate active preparation for the same decision (non-superseded, non-deleted).
  if exists (
    select 1 from contract.contract_preparations
     where decision_id = p_decision_id and deleted_at is null and status <> 'superseded'
  ) then
    raise exception 'contract: active preparation already exists for this decision'
      using errcode = '23505';
  end if;

  select r.tenant_id into v_tenant from rfq.requests r where r.id = v_request_id;
  select coalesce(p_currency, so.currency) into v_currency
    from offer.supplier_offers so where so.id = v_offer_id;
  v_code := contract.fn_next_preparation_code(v_tenant);

  insert into contract.contract_preparations (
    tenant_id, organization_id, request_id, offer_id, decision_id,
    supplier_id, supplier_organization_id, prepared_by,
    preparation_code, status, title, contract_type, currency,
    incoterm, delivery_country, delivery_city, delivery_port, delivery_location_text,
    payment_terms_text, delivery_terms_text, inspection_terms_text,
    governing_law_text, dispute_resolution_text, special_conditions_text,
    internal_notes, created_by, updated_by
  ) values (
    v_tenant, v_buyer_org, v_request_id, v_offer_id, p_decision_id,
    v_supplier_id, v_supplier_org, v_actor,
    v_code, 'draft', p_title, p_contract_type, v_currency,
    p_incoterm, p_delivery_country, p_delivery_city, p_delivery_port, p_delivery_location_text,
    p_payment_terms_text, p_delivery_terms_text, p_inspection_terms_text,
    p_governing_law_text, p_dispute_resolution_text, p_special_conditions_text,
    p_internal_notes, v_actor, v_actor
  ) returning id into v_id;

  -- Derive preparation items from the selected offer's items.
  insert into contract.contract_preparation_items (
    tenant_id, organization_id, preparation_id, offer_item_id, request_item_id,
    product_id, quantity, quantity_unit, unit_price, total_price, currency,
    packaging, origin_country, origin_city, delivery_window_start, delivery_window_end,
    delivery_lead_time_text, notes, sort_order, created_by, updated_by
  )
  select v_tenant, v_buyer_org, v_id, oi.id, oi.request_item_id,
         oi.product_id, oi.offered_quantity, oi.quantity_unit, oi.unit_price, oi.total_price,
         coalesce(oi.currency, v_currency),
         oi.packaging, oi.origin_country, oi.origin_city,
         oi.delivery_window_start, oi.delivery_window_end,
         oi.delivery_lead_time_text, oi.notes, oi.sort_order, v_actor, v_actor
    from offer.supplier_offer_items oi
   where oi.offer_id = v_offer_id and oi.deleted_at is null;

  -- Immutable initial snapshot capturing the source state.
  insert into contract.contract_preparation_snapshots (
    tenant_id, organization_id, preparation_id, snapshot_type, title, snapshot_data, created_by
  ) values (
    v_tenant, v_buyer_org, v_id, 'initial_from_offer',
    'Initial from selected offer',
    jsonb_build_object(
      'decision_id', p_decision_id,
      'offer_id', v_offer_id,
      'request_id', v_request_id,
      'item_count', (select count(*) from offer.supplier_offer_items
                      where offer_id = v_offer_id and deleted_at is null)
    ),
    v_actor
  );

  perform contract.fn_record_preparation_event(v_id, null, 'draft', 'preparation_created');
  perform contract.fn_audit('contract.preparation_created', v_id,
    jsonb_build_object('decision_id', p_decision_id::text, 'offer_id', v_offer_id::text));
  return v_id;
end;
$$;

-- 6.2 buyer_update_preparation ---------------------------------------------
create or replace function contract.buyer_update_preparation(
  p_preparation_id           uuid,
  p_title                    text default null,
  p_contract_type            contract.preparation_contract_type default null,
  p_currency                 text default null,
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
  p_internal_notes           text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  perform contract.fn_assert_preparation_editable(p_preparation_id);

  update contract.contract_preparations
     set title                   = coalesce(p_title, title),
         contract_type           = coalesce(p_contract_type, contract_type),
         currency                = coalesce(p_currency, currency),
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
         updated_by              = v_actor
   where id = p_preparation_id;

  perform contract.fn_audit('contract.preparation_updated', p_preparation_id);
end;
$$;

-- 6.3 buyer_upsert_clause --------------------------------------------------
create or replace function contract.buyer_upsert_clause(
  p_preparation_id uuid,
  p_clause_type    contract.preparation_clause_type,
  p_clause_key     text default null,
  p_title_fa       text default null,
  p_title_en       text default null,
  p_body_fa        text default null,
  p_body_en        text default null,
  p_source         text default null,
  p_is_required    boolean default false,
  p_sort_order     integer default 0
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  perform contract.fn_assert_preparation_editable(p_preparation_id);

  select tenant_id, organization_id into v_tenant, v_org
    from contract.contract_preparations where id = p_preparation_id;

  insert into contract.contract_preparation_clauses (
    tenant_id, organization_id, preparation_id, clause_type, clause_key,
    title_fa, title_en, body_fa, body_en, source, is_required, sort_order,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_preparation_id, p_clause_type, p_clause_key,
    p_title_fa, p_title_en, p_body_fa, p_body_en, p_source, p_is_required, p_sort_order,
    v_actor, v_actor
  )
  on conflict (preparation_id, clause_type, coalesce(lower(clause_key), ''))
    where deleted_at is null
  do update set
    title_fa    = excluded.title_fa,
    title_en    = excluded.title_en,
    body_fa     = excluded.body_fa,
    body_en     = excluded.body_en,
    source      = excluded.source,
    is_required = excluded.is_required,
    sort_order  = excluded.sort_order,
    updated_by  = v_actor
  returning id into v_id;

  perform contract.fn_audit('contract.clause_upserted', p_preparation_id,
    jsonb_build_object('clause_id', v_id::text, 'clause_type', p_clause_type::text));
  return v_id;
end;
$$;

-- 6.4 buyer_remove_clause --------------------------------------------------
create or replace function contract.buyer_remove_clause(p_clause_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_prep uuid;
begin
  select preparation_id into v_prep from contract.contract_preparation_clauses
   where id = p_clause_id and deleted_at is null;
  if v_prep is null then
    raise exception 'contract: clause not found' using errcode = 'P0002';
  end if;
  perform contract.fn_assert_preparation_owned(v_prep);
  perform contract.fn_assert_preparation_editable(v_prep);

  update contract.contract_preparation_clauses
     set deleted_at = now(), updated_by = v_actor
   where id = p_clause_id;

  perform contract.fn_audit('contract.clause_removed', v_prep,
    jsonb_build_object('clause_id', p_clause_id::text));
end;
$$;

-- 6.5 buyer_create_snapshot ------------------------------------------------
create or replace function contract.buyer_create_snapshot(
  p_preparation_id uuid,
  p_snapshot_type  contract.preparation_snapshot_type,
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
    raise exception 'contract: snapshot title is required' using errcode = '22023';
  end if;
  perform contract.fn_assert_preparation_owned(p_preparation_id);

  select tenant_id, organization_id into v_tenant, v_org
    from contract.contract_preparations where id = p_preparation_id;

  insert into contract.contract_preparation_snapshots (
    tenant_id, organization_id, preparation_id, snapshot_type, title, snapshot_data, notes, created_by
  ) values (
    v_tenant, v_org, p_preparation_id, p_snapshot_type, p_title,
    coalesce(p_snapshot_data, '{}'::jsonb), p_notes, v_actor
  ) returning id into v_id;

  perform contract.fn_audit('contract.snapshot_created', p_preparation_id,
    jsonb_build_object('snapshot_id', v_id::text, 'snapshot_type', p_snapshot_type::text));
  return v_id;
end;
$$;

-- 6.6 buyer_move_to_under_review -------------------------------------------
create or replace function contract.buyer_move_to_under_review(p_preparation_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.preparation_status;
  v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  select status into v_status from contract.contract_preparations where id = p_preparation_id;
  if v_status <> 'draft' then
    raise exception 'contract: invalid_transition: cannot move to under_review from %', v_status
      using errcode = 'P0001';
  end if;

  update contract.contract_preparations
     set status = 'under_review',
         submitted_for_review_at = now(),
         submitted_for_review_by = v_actor,
         updated_by = v_actor
   where id = p_preparation_id;

  perform contract.fn_record_preparation_event(p_preparation_id, 'draft', 'under_review');
  perform contract.fn_audit('contract.preparation_under_review', p_preparation_id);
end;
$$;

-- 6.7 buyer_mark_ready_for_contract ----------------------------------------
-- IMPORTANT: ready_for_contract DOES NOT create a contract / signature / payment /
-- shipment. It only marks the buyer's preparation package as ready for the future
-- contract module. No cross-domain side effects.
create or replace function contract.buyer_mark_ready_for_contract(p_preparation_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.preparation_status;
  v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  select status into v_status from contract.contract_preparations where id = p_preparation_id;
  if v_status not in ('draft', 'under_review') then
    raise exception 'contract: invalid_transition: cannot mark ready_for_contract from %', v_status
      using errcode = 'P0001';
  end if;

  update contract.contract_preparations
     set status     = 'ready_for_contract',
         ready_at   = now(),
         ready_by   = v_actor,
         updated_by = v_actor
   where id = p_preparation_id;

  perform contract.fn_record_preparation_event(p_preparation_id, v_status, 'ready_for_contract');
  perform contract.fn_audit('contract.preparation_ready_for_contract', p_preparation_id);
end;
$$;

-- 6.8 buyer_cancel_preparation ---------------------------------------------
create or replace function contract.buyer_cancel_preparation(
  p_preparation_id uuid,
  p_reason         text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.preparation_status;
  v_actor uuid := auth.uid();
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  select status into v_status from contract.contract_preparations where id = p_preparation_id;
  if v_status in ('cancelled', 'superseded') then
    raise exception 'contract: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;

  update contract.contract_preparations
     set status           = 'cancelled',
         cancelled_at     = now(),
         cancelled_by     = v_actor,
         cancelled_reason = p_reason,
         updated_by       = v_actor
   where id = p_preparation_id;

  perform contract.fn_record_preparation_event(p_preparation_id, v_status, 'cancelled', p_reason);
  perform contract.fn_audit('contract.preparation_cancelled', p_preparation_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.9 buyer_list_preparations ----------------------------------------------
create or replace function contract.buyer_list_preparations(
  p_request_id uuid                            default null,
  p_status     contract.preparation_status     default null,
  p_limit      integer                         default 25,
  p_offset     integer                         default 0
) returns table (
  id uuid, preparation_code text, request_id uuid, offer_id uuid, decision_id uuid,
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
    raise exception 'contract: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'contract: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select p.id, p.preparation_code, p.request_id, p.offer_id, p.decision_id,
           p.supplier_id, p.status::text, p.title, p.created_at, p.updated_at
      from contract.contract_preparations p
     where p.deleted_at is null
       and (identity.is_platform_admin() or p.organization_id = v_caller_org)
       and (p_request_id is null or p.request_id = p_request_id)
       and (p_status     is null or p.status     = p_status)
     order by p.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.10 buyer_get_preparation -----------------------------------------------
create or replace function contract.buyer_get_preparation(p_preparation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  return (
    select jsonb_build_object(
      'id', p.id, 'preparation_code', p.preparation_code,
      'organization_id', p.organization_id, 'request_id', p.request_id,
      'offer_id', p.offer_id, 'decision_id', p.decision_id,
      'supplier_id', p.supplier_id, 'supplier_organization_id', p.supplier_organization_id,
      'status', p.status, 'title', p.title, 'contract_type', p.contract_type,
      'currency', p.currency, 'incoterm', p.incoterm,
      'delivery_country', p.delivery_country, 'delivery_city', p.delivery_city,
      'delivery_port', p.delivery_port, 'delivery_location_text', p.delivery_location_text,
      'payment_terms_text', p.payment_terms_text, 'delivery_terms_text', p.delivery_terms_text,
      'inspection_terms_text', p.inspection_terms_text,
      'governing_law_text', p.governing_law_text,
      'dispute_resolution_text', p.dispute_resolution_text,
      'special_conditions_text', p.special_conditions_text,
      'internal_notes', p.internal_notes,
      'created_at', p.created_at, 'updated_at', p.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'offer_item_id', it.offer_item_id, 'request_item_id', it.request_item_id,
          'product_id', it.product_id, 'quantity', it.quantity, 'quantity_unit', it.quantity_unit,
          'unit_price', it.unit_price, 'total_price', it.total_price, 'currency', it.currency,
          'packaging', it.packaging, 'origin_country', it.origin_country, 'origin_city', it.origin_city,
          'sort_order', it.sort_order
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from contract.contract_preparation_items it
         where it.preparation_id = p.id and it.deleted_at is null
      ),
      'clauses', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', c.id, 'clause_type', c.clause_type, 'clause_key', c.clause_key,
          'title_fa', c.title_fa, 'title_en', c.title_en,
          'body_fa', c.body_fa, 'body_en', c.body_en,
          'is_required', c.is_required, 'sort_order', c.sort_order
        ) order by c.sort_order, c.created_at), '[]'::jsonb)
          from contract.contract_preparation_clauses c
         where c.preparation_id = p.id and c.deleted_at is null
      ),
      'snapshots', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', s.id, 'snapshot_type', s.snapshot_type, 'title', s.title,
          'created_at', s.created_at
        ) order by s.created_at), '[]'::jsonb)
          from contract.contract_preparation_snapshots s
         where s.preparation_id = p.id
      )
    )
    from contract.contract_preparations p where p.id = p_preparation_id
  );
end;
$$;

-- 6.11 buyer_list_preparation_events ---------------------------------------
create or replace function contract.buyer_list_preparation_events(p_preparation_id uuid)
returns table (
  id uuid, from_status text, to_status text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform contract.fn_assert_preparation_owned(p_preparation_id);
  return query
    select e.id, e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from contract.contract_preparation_events e
     where e.preparation_id = p_preparation_id
     order by e.created_at asc;
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (2)
-- ===========================================================================

-- 7.1 supplier_list_my_preparations ----------------------------------------
create or replace function contract.supplier_list_my_preparations(
  p_status contract.preparation_status default null,
  p_limit  integer                      default 25,
  p_offset integer                      default 0
) returns table (
  id uuid, preparation_code text, request_id uuid, offer_id uuid,
  status text, title text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select p.id, p.preparation_code, p.request_id, p.offer_id,
           p.status::text, p.title, p.created_at, p.updated_at
      from contract.contract_preparations p
     where p.deleted_at is null
       and p.supplier_id = v_supplier
       and (p_status is null or p.status = p_status)
     order by p.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 supplier_get_my_preparation ------------------------------------------
create or replace function contract.supplier_get_my_preparation(p_preparation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_supplier_caller uuid := supplier.fn_portal_supplier_id();
  v_supplier_owner  uuid;
begin
  select p.supplier_id into v_supplier_owner
    from contract.contract_preparations p
   where p.id = p_preparation_id and p.deleted_at is null;
  if v_supplier_owner is null then
    raise exception 'contract: preparation not found' using errcode = 'P0002';
  end if;
  if v_supplier_owner <> v_supplier_caller and not identity.is_platform_admin() then
    raise exception 'contract: preparation is not on caller''s offer' using errcode = '42501';
  end if;

  return (
    select jsonb_build_object(
      'id', p.id, 'preparation_code', p.preparation_code,
      'request_id', p.request_id, 'offer_id', p.offer_id,
      'status', p.status, 'title', p.title,
      'contract_type', p.contract_type, 'currency', p.currency,
      'incoterm', p.incoterm,
      'delivery_country', p.delivery_country, 'delivery_city', p.delivery_city,
      'delivery_port', p.delivery_port, 'delivery_location_text', p.delivery_location_text,
      'created_at', p.created_at, 'updated_at', p.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'offer_item_id', it.offer_item_id, 'request_item_id', it.request_item_id,
          'product_id', it.product_id, 'quantity', it.quantity, 'quantity_unit', it.quantity_unit,
          'unit_price', it.unit_price, 'total_price', it.total_price, 'currency', it.currency
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from contract.contract_preparation_items it
         where it.preparation_id = p.id and it.deleted_at is null
      )
    )
    from contract.contract_preparations p where p.id = p_preparation_id
  );
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (5)
-- ===========================================================================

-- 8.1 admin_list_preparations ----------------------------------------------
create or replace function contract.admin_list_preparations(
  p_request_id uuid                        default null,
  p_offer_id   uuid                        default null,
  p_supplier_id uuid                       default null,
  p_status     contract.preparation_status default null,
  p_limit      integer                     default 25,
  p_offset     integer                     default 0
) returns table (
  id uuid, preparation_code text, organization_id uuid,
  request_id uuid, offer_id uuid, decision_id uuid, supplier_id uuid,
  status text, title text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_preparations: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select p.id, p.preparation_code, p.organization_id,
           p.request_id, p.offer_id, p.decision_id, p.supplier_id,
           p.status::text, p.title, p.created_at, p.updated_at
      from contract.contract_preparations p
     where p.deleted_at is null
       and (p_request_id  is null or p.request_id  = p_request_id)
       and (p_offer_id    is null or p.offer_id    = p_offer_id)
       and (p_supplier_id is null or p.supplier_id = p_supplier_id)
       and (p_status      is null or p.status      = p_status)
     order by p.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_preparation ------------------------------------------------
create or replace function contract.admin_get_preparation(p_preparation_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_preparation: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', p.id, 'preparation_code', p.preparation_code,
      'organization_id', p.organization_id, 'request_id', p.request_id,
      'offer_id', p.offer_id, 'decision_id', p.decision_id, 'supplier_id', p.supplier_id,
      'status', p.status, 'title', p.title, 'contract_type', p.contract_type,
      'currency', p.currency, 'created_at', p.created_at, 'updated_at', p.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'offer_item_id', it.offer_item_id,
          'quantity', it.quantity, 'unit_price', it.unit_price, 'total_price', it.total_price
        )), '[]'::jsonb)
          from contract.contract_preparation_items it
         where it.preparation_id = p.id and it.deleted_at is null
      ),
      'clauses', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', c.id, 'clause_type', c.clause_type, 'title_en', c.title_en
        )), '[]'::jsonb)
          from contract.contract_preparation_clauses c
         where c.preparation_id = p.id and c.deleted_at is null
      ),
      'events', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', e.id, 'from_status', e.from_status, 'to_status', e.to_status,
          'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from contract.contract_preparation_events e
         where e.preparation_id = p.id
      )
    )
    from contract.contract_preparations p where p.id = p_preparation_id
  );
end;
$$;

-- 8.3 admin_list_preparation_events ----------------------------------------
create or replace function contract.admin_list_preparation_events(p_preparation_id uuid)
returns table (
  id uuid, from_status text, to_status text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_preparation_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from contract.contract_preparation_events e
     where e.preparation_id = p_preparation_id
     order by e.created_at asc;
end;
$$;

-- 8.4 admin_force_cancel_preparation ---------------------------------------
create or replace function contract.admin_force_cancel_preparation(
  p_preparation_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.preparation_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_cancel_preparation: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from contract.contract_preparations
   where id = p_preparation_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract: preparation not found' using errcode = 'P0002';
  end if;
  if v_status in ('cancelled', 'superseded') then
    raise exception 'contract: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;

  update contract.contract_preparations
     set status           = 'cancelled',
         cancelled_at     = now(),
         cancelled_by     = v_actor,
         cancelled_reason = p_reason,
         updated_by       = v_actor
   where id = p_preparation_id;

  perform contract.fn_record_preparation_event(p_preparation_id, v_status, 'cancelled',
    coalesce(p_reason, 'admin_force_cancel'));
  perform contract.fn_audit('contract.preparation_admin_cancelled', p_preparation_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.5 admin_supersede_preparation ------------------------------------------
create or replace function contract.admin_supersede_preparation(
  p_preparation_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status contract.preparation_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_supersede_preparation: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from contract.contract_preparations
   where id = p_preparation_id and deleted_at is null;
  if v_status is null then
    raise exception 'contract: preparation not found' using errcode = 'P0002';
  end if;
  if v_status = 'superseded' then
    raise exception 'contract: already superseded' using errcode = 'P0001';
  end if;

  update contract.contract_preparations
     set status            = 'superseded',
         superseded_at     = now(),
         superseded_by     = v_actor,
         superseded_reason = p_reason,
         updated_by        = v_actor
   where id = p_preparation_id;

  perform contract.fn_record_preparation_event(p_preparation_id, v_status, 'superseded', p_reason);
  perform contract.fn_audit('contract.preparation_superseded', p_preparation_id,
    jsonb_build_object('reason', p_reason));
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
     where t.table_schema = 'contract'
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
     where t.table_schema = 'contract'
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
grant select on contract.contract_preparations         to anon, authenticated;
grant select on contract.contract_preparation_items    to anon, authenticated;
grant select on contract.contract_preparation_clauses  to authenticated;
grant select on contract.contract_preparation_snapshots to authenticated;
grant select on contract.contract_preparation_events   to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function contract.buyer_create_preparation(uuid, text, contract.preparation_contract_type, text, text, char, text, text, text, text, text, text, text, text, text, text) to authenticated;
grant execute on function contract.buyer_update_preparation(uuid, text, contract.preparation_contract_type, text, text, char, text, text, text, text, text, text, text, text, text, text) to authenticated;
grant execute on function contract.buyer_upsert_clause(uuid, contract.preparation_clause_type, text, text, text, text, text, text, boolean, integer) to authenticated;
grant execute on function contract.buyer_remove_clause(uuid) to authenticated;
grant execute on function contract.buyer_create_snapshot(uuid, contract.preparation_snapshot_type, text, jsonb, text) to authenticated;
grant execute on function contract.buyer_move_to_under_review(uuid) to authenticated;
grant execute on function contract.buyer_mark_ready_for_contract(uuid) to authenticated;
grant execute on function contract.buyer_cancel_preparation(uuid, text) to authenticated;
grant execute on function contract.buyer_list_preparations(uuid, contract.preparation_status, integer, integer) to authenticated;
grant execute on function contract.buyer_get_preparation(uuid) to authenticated;
grant execute on function contract.buyer_list_preparation_events(uuid) to authenticated;

grant execute on function contract.supplier_list_my_preparations(contract.preparation_status, integer, integer) to authenticated;
grant execute on function contract.supplier_get_my_preparation(uuid) to authenticated;

grant execute on function contract.admin_list_preparations(uuid, uuid, uuid, contract.preparation_status, integer, integer) to authenticated;
grant execute on function contract.admin_get_preparation(uuid) to authenticated;
grant execute on function contract.admin_list_preparation_events(uuid) to authenticated;
grant execute on function contract.admin_force_cancel_preparation(uuid, text) to authenticated;
grant execute on function contract.admin_supersede_preparation(uuid, text) to authenticated;
