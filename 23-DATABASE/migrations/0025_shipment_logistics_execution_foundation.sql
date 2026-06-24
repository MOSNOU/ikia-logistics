-- CC-14 / Migration 0025 — Shipment / Logistics Execution Foundation
-- Eighth business domain. New `shipment` schema, built atop CC-13 executed contracts.
-- Append-only over migrations 0001-0024.
--
-- Scope: shipment + logistics execution only.
-- No pricing engine, settlement, escrow, payment, invoice, accounting, insurance claim, live GPS.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists shipment;
grant usage on schema shipment to anon, authenticated, service_role;
comment on schema shipment is
  'iKIA Phase 2 — shipment / logistics execution domain. Execution only; no pricing / payment / settlement / escrow / invoice / accounting / insurance claim / GPS.';

-- ===========================================================================
-- 2. Enums (7)
-- ===========================================================================
create type shipment.shipment_status as enum (
  'draft', 'planned', 'booked', 'in_transit', 'arrived', 'delivered', 'cancelled', 'closed'
);

create type shipment.transport_mode as enum (
  'road', 'rail', 'sea', 'air', 'multimodal', 'pipeline', 'other'
);

create type shipment.stop_type as enum (
  'pickup', 'loading', 'border', 'transshipment', 'customs', 'unloading', 'delivery', 'other'
);

create type shipment.milestone_type as enum (
  'booking_confirmed', 'cargo_ready', 'pickup_completed',
  'customs_export_cleared', 'departed_origin', 'border_crossed',
  'arrived_destination', 'customs_import_cleared',
  'delivered', 'closed', 'other'
);

create type shipment.milestone_status as enum (
  'pending', 'in_progress', 'completed', 'skipped', 'blocked'
);

create type shipment.document_kind as enum (
  'bill_of_lading', 'cmr', 'rail_waybill', 'airway_bill',
  'packing_list', 'certificate_of_origin', 'inspection_certificate',
  'customs_declaration', 'delivery_order', 'proof_of_delivery', 'other'
);

create type shipment.requirement_level as enum (
  'required', 'recommended', 'optional'
);

create type shipment.document_status as enum (
  'pending', 'available', 'expired', 'rejected', 'archived'
);

-- ===========================================================================
-- 3. Tables (7)
-- ===========================================================================

-- 3.1 shipments ------------------------------------------------------------
create table shipment.shipments (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  executed_contract_id        uuid not null references contract.executed_contracts(id) on delete restrict,
  request_id                  uuid not null references rfq.requests(id) on delete restrict,
  offer_id                    uuid not null references offer.supplier_offers(id) on delete restrict,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,
  created_by                  uuid references auth.users(id),

  shipment_code               text not null,
  status                      shipment.shipment_status not null default 'draft',
  transport_mode              shipment.transport_mode not null default 'road',
  incoterm                    text,

  origin_country              char(2),
  origin_city                 text,
  origin_port                 text,
  origin_location_text        text,
  destination_country         char(2),
  destination_city            text,
  destination_port            text,
  destination_location_text   text,

  planned_pickup_date         timestamptz,
  planned_delivery_date       timestamptz,
  actual_pickup_date          timestamptz,
  actual_delivery_date        timestamptz,

  carrier_organization_id     uuid references organization.organizations(id) on delete set null,
  carrier_name                text,
  vehicle_reference           text,
  tracking_reference          text,

  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  planned_at                  timestamptz,
  planned_by                  uuid references auth.users(id),
  booked_at                   timestamptz,
  booked_by                   uuid references auth.users(id),
  in_transit_at               timestamptz,
  in_transit_by               uuid references auth.users(id),
  arrived_at                  timestamptz,
  arrived_by                  uuid references auth.users(id),
  delivered_at                timestamptz,
  delivered_by                uuid references auth.users(id),
  closed_at                   timestamptz,
  closed_by                   uuid references auth.users(id),
  closed_reason               text,
  cancelled_at                timestamptz,
  cancelled_by                uuid references auth.users(id),
  cancelled_reason            text,

  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table shipment.shipments is
  'Shipment / logistics execution record built atop an executed contract. No pricing/payment/settlement/etc. created.';

create unique index shipments_code_unique
  on shipment.shipments(tenant_id, lower(shipment_code))
  where deleted_at is null;

create index shipments_contract_idx on shipment.shipments(executed_contract_id);
create index shipments_supplier_idx on shipment.shipments(supplier_id);
create index shipments_status_idx   on shipment.shipments(status);

-- 3.2 shipment_items -------------------------------------------------------
create table shipment.shipment_items (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  shipment_id                 uuid not null references shipment.shipments(id) on delete cascade,
  executed_contract_item_id   uuid references contract.executed_contract_items(id) on delete set null,
  product_id                  uuid not null references commodity.products(id) on delete restrict,

  quantity                    numeric,
  quantity_unit               text,
  packaging                   text,
  batch_number                text,
  gross_weight                numeric,
  net_weight                  numeric,
  volume                      numeric,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,
  sort_order                  integer not null default 0,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table shipment.shipment_items is
  'Shipment line items derived from contract.executed_contract_items at draft time.';

create unique index shipment_items_unique_active
  on shipment.shipment_items(shipment_id, executed_contract_item_id)
  where deleted_at is null and executed_contract_item_id is not null;

create index shipment_items_shipment_idx on shipment.shipment_items(shipment_id);

-- 3.3 shipment_stops -------------------------------------------------------
create table shipment.shipment_stops (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  shipment_id                 uuid not null references shipment.shipments(id) on delete cascade,

  stop_type                   shipment.stop_type not null,
  sequence_number             integer not null,
  country                     char(2),
  city                        text,
  port                        text,
  location_text               text,

  planned_arrival_at          timestamptz,
  planned_departure_at        timestamptz,
  actual_arrival_at           timestamptz,
  actual_departure_at         timestamptz,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table shipment.shipment_stops is
  'Route stops for a shipment. Unique sequence_number per shipment.';

create unique index shipment_stops_unique_sequence
  on shipment.shipment_stops(shipment_id, sequence_number)
  where deleted_at is null;

create index shipment_stops_shipment_idx on shipment.shipment_stops(shipment_id);

-- 3.4 shipment_milestones --------------------------------------------------
create table shipment.shipment_milestones (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  shipment_id                 uuid not null references shipment.shipments(id) on delete cascade,

  milestone_type              shipment.milestone_type not null,
  status                      shipment.milestone_status not null default 'pending',
  planned_at                  timestamptz,
  completed_at                timestamptz,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table shipment.shipment_milestones is
  'Operational milestones for a shipment. One active milestone of each type per shipment.';

create unique index shipment_milestones_unique_active
  on shipment.shipment_milestones(shipment_id, milestone_type)
  where deleted_at is null;

create index shipment_milestones_shipment_idx on shipment.shipment_milestones(shipment_id);

-- 3.5 shipment_document_requirements ---------------------------------------
create table shipment.shipment_document_requirements (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  shipment_id                 uuid not null references shipment.shipments(id) on delete cascade,

  document_kind               shipment.document_kind not null,
  requirement_level           shipment.requirement_level not null default 'required',
  display_name_en             text,
  display_name_fa             text,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table shipment.shipment_document_requirements is
  'Per-shipment document requirements. One active entry per (shipment, document_kind).';

create unique index shipment_doc_requirements_unique_active
  on shipment.shipment_document_requirements(shipment_id, document_kind)
  where deleted_at is null;

create index shipment_doc_requirements_shipment_idx
  on shipment.shipment_document_requirements(shipment_id);

-- 3.6 shipment_documents ---------------------------------------------------
create table shipment.shipment_documents (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  shipment_id                 uuid not null references shipment.shipments(id) on delete cascade,
  shipment_item_id            uuid references shipment.shipment_items(id) on delete set null,
  requirement_id              uuid references shipment.shipment_document_requirements(id) on delete set null,

  document_kind               shipment.document_kind not null,
  document_status             shipment.document_status not null default 'pending',
  external_reference          text,
  issued_at                   timestamptz,
  expires_at                  timestamptz,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table shipment.shipment_documents is
  'Document metadata records (no file storage in CC-14). May reference an in-shipment requirement.';

create index shipment_documents_shipment_idx on shipment.shipment_documents(shipment_id);
create index shipment_documents_kind_idx     on shipment.shipment_documents(shipment_id, document_kind);

-- 3.7 shipment_events (immutable) ------------------------------------------
create table shipment.shipment_events (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  shipment_id                 uuid not null references shipment.shipments(id) on delete cascade,

  from_status                 shipment.shipment_status,
  to_status                   shipment.shipment_status,
  event_type                  text not null,
  actor_user_id               uuid references auth.users(id),
  actor_organization_id       uuid references organization.organizations(id),
  reason                      text,
  metadata                    jsonb not null default '{}'::jsonb,
  created_at                  timestamptz not null default now()
);

comment on table shipment.shipment_events is
  'Immutable shipment lifecycle / operational event trail. No UPDATE/DELETE policies.';

create index shipment_events_shipment_idx
  on shipment.shipment_events(shipment_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function shipment.fn_audit(
  p_action_code text,
  p_shipment_id uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from shipment.shipments where id = p_shipment_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'shipment', p_shipment_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_record_shipment_event ---------------------------------------------
create or replace function shipment.fn_record_shipment_event(
  p_shipment_id uuid,
  p_from        shipment.shipment_status,
  p_to          shipment.shipment_status,
  p_event_type  text,
  p_reason      text default null,
  p_metadata    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from shipment.shipments where id = p_shipment_id;
  insert into shipment.shipment_events (
    tenant_id, organization_id, shipment_id,
    from_status, to_status, event_type, actor_user_id, actor_organization_id, reason, metadata
  ) values (
    v_t, v_o, p_shipment_id,
    p_from, p_to, p_event_type, auth.uid(), v_o, p_reason, coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

-- 4.3 fn_next_shipment_code ------------------------------------------------
create or replace function shipment.fn_next_shipment_code(p_tenant_id uuid)
returns text
language plpgsql volatile security definer set search_path = ''
as $$
declare v_code text;
begin
  v_code := 'SHP-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

-- 4.4 fn_assert_buyer_for_contract -----------------------------------------
-- Verifies role + caller's org matches contract buyer org + contract is executed.
create or replace function shipment.fn_assert_buyer_for_contract(p_contract_id uuid)
returns table (
  buyer_org_id              uuid,
  request_id                uuid,
  offer_id                  uuid,
  supplier_id               uuid,
  supplier_organization_id  uuid,
  contract_status           contract.contract_status
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org uuid; v_request_id uuid; v_offer_id uuid;
  v_supplier_id uuid; v_supplier_org uuid;
  v_status contract.contract_status;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'shipment: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;

  select ec.organization_id, ec.request_id, ec.offer_id,
         ec.supplier_id, ec.supplier_organization_id, ec.status
    into v_buyer_org, v_request_id, v_offer_id,
         v_supplier_id, v_supplier_org, v_status
    from contract.executed_contracts ec
   where ec.id = p_contract_id and ec.deleted_at is null;

  if v_buyer_org is null then
    raise exception 'shipment: contract not found' using errcode = 'P0002';
  end if;
  if v_status <> 'executed' then
    raise exception 'shipment: contract is not executed (status=%)', v_status
      using errcode = 'P0001';
  end if;
  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'shipment: contract is not in caller''s organization'
        using errcode = '42501';
    end if;
  end if;

  return query select v_buyer_org, v_request_id, v_offer_id,
                      v_supplier_id, v_supplier_org, v_status;
end;
$$;

-- 4.5 fn_assert_shipment_owned ---------------------------------------------
create or replace function shipment.fn_assert_shipment_owned(p_shipment_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_org from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_org is null then
    raise exception 'shipment: shipment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'shipment: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'shipment: not owned by caller organization' using errcode = '42501';
  end if;
end;
$$;

-- 4.6 fn_assert_shipment_editable ------------------------------------------
-- Returns the current status; raises P0001 if status is terminal/locked.
-- p_strict=true → only draft/planned permitted (used for structural edits).
-- p_strict=false → any non-terminal permitted (used for operational updates).
create or replace function shipment.fn_assert_shipment_editable(
  p_shipment_id uuid,
  p_strict      boolean default true
) returns shipment.shipment_status
language plpgsql stable security definer set search_path = ''
as $$
declare v_status shipment.shipment_status;
begin
  select status into v_status from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_status is null then
    raise exception 'shipment: shipment not found' using errcode = 'P0002';
  end if;
  if p_strict then
    if v_status not in ('draft', 'planned') then
      raise exception 'shipment: locked from structural edit (status=%)', v_status using errcode = 'P0001';
    end if;
  else
    if v_status in ('delivered', 'closed', 'cancelled') then
      raise exception 'shipment: locked (status=%)', v_status using errcode = 'P0001';
    end if;
  end if;
  return v_status;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table shipment.shipments                       enable row level security;
alter table shipment.shipment_items                  enable row level security;
alter table shipment.shipment_stops                  enable row level security;
alter table shipment.shipment_milestones             enable row level security;
alter table shipment.shipment_document_requirements  enable row level security;
alter table shipment.shipment_documents              enable row level security;
alter table shipment.shipment_events                 enable row level security;

-- 5.1 shipments: buyer org + supplier of contract + admin.
drop policy if exists shipments_select on shipment.shipments;
create policy shipments_select on shipment.shipments
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = shipment.shipments.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = shipment.shipments.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists shipments_admin_modify on shipment.shipments;
create policy shipments_admin_modify on shipment.shipments
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 shipment_items: same audience as parent shipment.
drop policy if exists shipment_items_select on shipment.shipment_items;
create policy shipment_items_select on shipment.shipment_items
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from shipment.shipments sh
       where sh.id = shipment.shipment_items.shipment_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = sh.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = sh.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists shipment_items_admin_modify on shipment.shipment_items;
create policy shipment_items_admin_modify on shipment.shipment_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 shipment_stops: same audience.
drop policy if exists shipment_stops_select on shipment.shipment_stops;
create policy shipment_stops_select on shipment.shipment_stops
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from shipment.shipments sh
       where sh.id = shipment.shipment_stops.shipment_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = sh.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = sh.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists shipment_stops_admin_modify on shipment.shipment_stops;
create policy shipment_stops_admin_modify on shipment.shipment_stops
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.4 shipment_milestones: same audience.
drop policy if exists shipment_milestones_select on shipment.shipment_milestones;
create policy shipment_milestones_select on shipment.shipment_milestones
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from shipment.shipments sh
       where sh.id = shipment.shipment_milestones.shipment_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = sh.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = sh.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists shipment_milestones_admin_modify on shipment.shipment_milestones;
create policy shipment_milestones_admin_modify on shipment.shipment_milestones
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.5 shipment_document_requirements: buyer org + admin (working artefacts).
drop policy if exists shipment_doc_reqs_select on shipment.shipment_document_requirements;
create policy shipment_doc_reqs_select on shipment.shipment_document_requirements
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = shipment.shipment_document_requirements.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists shipment_doc_reqs_admin_modify on shipment.shipment_document_requirements;
create policy shipment_doc_reqs_admin_modify on shipment.shipment_document_requirements
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.6 shipment_documents: buyer org + supplier of contract + admin.
drop policy if exists shipment_documents_select on shipment.shipment_documents;
create policy shipment_documents_select on shipment.shipment_documents
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from shipment.shipments sh
       where sh.id = shipment.shipment_documents.shipment_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = sh.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = sh.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists shipment_documents_admin_modify on shipment.shipment_documents;
create policy shipment_documents_admin_modify on shipment.shipment_documents
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.7 shipment_events: buyer org + supplier of contract + admin (immutable).
drop policy if exists shipment_events_select on shipment.shipment_events;
create policy shipment_events_select on shipment.shipment_events
  for select
  using (
    exists (
      select 1 from shipment.shipments sh
       where sh.id = shipment.shipment_events.shipment_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = sh.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = sh.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. Buyer RPCs (14)
-- ===========================================================================

-- 6.1 buyer_create_shipment ------------------------------------------------
create or replace function shipment.buyer_create_shipment(
  p_executed_contract_id      uuid,
  p_transport_mode            shipment.transport_mode default 'road',
  p_incoterm                  text default null,
  p_origin_country            char(2) default null,
  p_origin_city               text default null,
  p_origin_port               text default null,
  p_origin_location_text      text default null,
  p_destination_country       char(2) default null,
  p_destination_city          text default null,
  p_destination_port          text default null,
  p_destination_location_text text default null,
  p_planned_pickup_date       timestamptz default null,
  p_planned_delivery_date     timestamptz default null,
  p_notes                     text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_buyer_org uuid; v_request_id uuid; v_offer_id uuid;
  v_supplier_id uuid; v_supplier_org uuid;
  v_contract_status contract.contract_status;
  v_tenant uuid;
  v_code text;
  v_id uuid;
  v_contract_incoterm text;
begin
  select buyer_org_id, request_id, offer_id,
         supplier_id, supplier_organization_id, contract_status
    into v_buyer_org, v_request_id, v_offer_id,
         v_supplier_id, v_supplier_org, v_contract_status
    from shipment.fn_assert_buyer_for_contract(p_executed_contract_id);

  select ec.tenant_id, ec.incoterm into v_tenant, v_contract_incoterm
    from contract.executed_contracts ec where ec.id = p_executed_contract_id;
  v_code := shipment.fn_next_shipment_code(v_tenant);

  insert into shipment.shipments (
    tenant_id, organization_id, executed_contract_id, request_id, offer_id,
    supplier_id, supplier_organization_id, created_by,
    shipment_code, status, transport_mode, incoterm,
    origin_country, origin_city, origin_port, origin_location_text,
    destination_country, destination_city, destination_port, destination_location_text,
    planned_pickup_date, planned_delivery_date, notes, updated_by
  ) values (
    v_tenant, v_buyer_org, p_executed_contract_id, v_request_id, v_offer_id,
    v_supplier_id, v_supplier_org, v_actor,
    v_code, 'draft', p_transport_mode, coalesce(p_incoterm, v_contract_incoterm),
    p_origin_country, p_origin_city, p_origin_port, p_origin_location_text,
    p_destination_country, p_destination_city, p_destination_port, p_destination_location_text,
    p_planned_pickup_date, p_planned_delivery_date, p_notes, v_actor
  ) returning id into v_id;

  -- Derive shipment items from executed contract items.
  insert into shipment.shipment_items (
    tenant_id, organization_id, shipment_id, executed_contract_item_id,
    product_id, quantity, quantity_unit, packaging, sort_order, created_by, updated_by
  )
  select v_tenant, v_buyer_org, v_id, it.id,
         it.product_id, it.quantity, it.quantity_unit, it.packaging, it.sort_order, v_actor, v_actor
    from contract.executed_contract_items it
   where it.contract_id = p_executed_contract_id and it.deleted_at is null;

  perform shipment.fn_record_shipment_event(v_id, null, 'draft', 'shipment_created');
  perform shipment.fn_audit('shipment.created', v_id,
    jsonb_build_object('executed_contract_id', p_executed_contract_id::text));
  return v_id;
end;
$$;

-- 6.2 buyer_update_shipment (draft/planned only) ---------------------------
create or replace function shipment.buyer_update_shipment(
  p_shipment_id               uuid,
  p_transport_mode            shipment.transport_mode default null,
  p_incoterm                  text default null,
  p_origin_country            char(2) default null,
  p_origin_city               text default null,
  p_origin_port               text default null,
  p_origin_location_text      text default null,
  p_destination_country       char(2) default null,
  p_destination_city          text default null,
  p_destination_port          text default null,
  p_destination_location_text text default null,
  p_planned_pickup_date       timestamptz default null,
  p_planned_delivery_date     timestamptz default null,
  p_carrier_organization_id   uuid default null,
  p_carrier_name              text default null,
  p_vehicle_reference         text default null,
  p_tracking_reference        text default null,
  p_notes                     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  perform shipment.fn_assert_shipment_editable(p_shipment_id, true);

  update shipment.shipments
     set transport_mode             = coalesce(p_transport_mode, transport_mode),
         incoterm                   = coalesce(p_incoterm, incoterm),
         origin_country             = coalesce(p_origin_country, origin_country),
         origin_city                = coalesce(p_origin_city, origin_city),
         origin_port                = coalesce(p_origin_port, origin_port),
         origin_location_text       = coalesce(p_origin_location_text, origin_location_text),
         destination_country        = coalesce(p_destination_country, destination_country),
         destination_city           = coalesce(p_destination_city, destination_city),
         destination_port           = coalesce(p_destination_port, destination_port),
         destination_location_text  = coalesce(p_destination_location_text, destination_location_text),
         planned_pickup_date        = coalesce(p_planned_pickup_date, planned_pickup_date),
         planned_delivery_date      = coalesce(p_planned_delivery_date, planned_delivery_date),
         carrier_organization_id    = coalesce(p_carrier_organization_id, carrier_organization_id),
         carrier_name               = coalesce(p_carrier_name, carrier_name),
         vehicle_reference          = coalesce(p_vehicle_reference, vehicle_reference),
         tracking_reference         = coalesce(p_tracking_reference, tracking_reference),
         notes                      = coalesce(p_notes, notes),
         updated_by                 = v_actor
   where id = p_shipment_id;

  perform shipment.fn_audit('shipment.updated', p_shipment_id);
end;
$$;

-- 6.3 buyer_upsert_stop (draft/planned only) -------------------------------
create or replace function shipment.buyer_upsert_stop(
  p_shipment_id          uuid,
  p_sequence_number      integer,
  p_stop_type            shipment.stop_type,
  p_country              char(2) default null,
  p_city                 text default null,
  p_port                 text default null,
  p_location_text        text default null,
  p_planned_arrival_at   timestamptz default null,
  p_planned_departure_at timestamptz default null,
  p_actual_arrival_at    timestamptz default null,
  p_actual_departure_at  timestamptz default null,
  p_notes                text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  perform shipment.fn_assert_shipment_editable(p_shipment_id, true);

  select tenant_id, organization_id into v_tenant, v_org
    from shipment.shipments where id = p_shipment_id;

  insert into shipment.shipment_stops (
    tenant_id, organization_id, shipment_id, stop_type, sequence_number,
    country, city, port, location_text,
    planned_arrival_at, planned_departure_at, actual_arrival_at, actual_departure_at,
    notes, created_by, updated_by
  ) values (
    v_tenant, v_org, p_shipment_id, p_stop_type, p_sequence_number,
    p_country, p_city, p_port, p_location_text,
    p_planned_arrival_at, p_planned_departure_at, p_actual_arrival_at, p_actual_departure_at,
    p_notes, v_actor, v_actor
  )
  on conflict (shipment_id, sequence_number) where deleted_at is null
  do update set
    stop_type            = excluded.stop_type,
    country              = excluded.country,
    city                 = excluded.city,
    port                 = excluded.port,
    location_text        = excluded.location_text,
    planned_arrival_at   = excluded.planned_arrival_at,
    planned_departure_at = excluded.planned_departure_at,
    actual_arrival_at    = excluded.actual_arrival_at,
    actual_departure_at  = excluded.actual_departure_at,
    notes                = excluded.notes,
    updated_by           = v_actor
  returning id into v_id;

  perform shipment.fn_audit('shipment.stop_upserted', p_shipment_id,
    jsonb_build_object('stop_id', v_id::text, 'sequence', p_sequence_number));
  return v_id;
end;
$$;

-- 6.4 buyer_upsert_milestone (non-terminal) --------------------------------
create or replace function shipment.buyer_upsert_milestone(
  p_shipment_id    uuid,
  p_milestone_type shipment.milestone_type,
  p_status         shipment.milestone_status default 'pending',
  p_planned_at     timestamptz default null,
  p_completed_at   timestamptz default null,
  p_notes          text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  perform shipment.fn_assert_shipment_editable(p_shipment_id, false);

  select tenant_id, organization_id into v_tenant, v_org
    from shipment.shipments where id = p_shipment_id;

  insert into shipment.shipment_milestones (
    tenant_id, organization_id, shipment_id, milestone_type, status,
    planned_at, completed_at, notes, created_by, updated_by
  ) values (
    v_tenant, v_org, p_shipment_id, p_milestone_type, p_status,
    p_planned_at, p_completed_at, p_notes, v_actor, v_actor
  )
  on conflict (shipment_id, milestone_type) where deleted_at is null
  do update set
    status       = excluded.status,
    planned_at   = excluded.planned_at,
    completed_at = excluded.completed_at,
    notes        = excluded.notes,
    updated_by   = v_actor
  returning id into v_id;

  perform shipment.fn_audit('shipment.milestone_upserted', p_shipment_id,
    jsonb_build_object('milestone_id', v_id::text, 'milestone_type', p_milestone_type::text));
  return v_id;
end;
$$;

-- 6.5 buyer_upsert_doc_requirement (draft/planned) -------------------------
create or replace function shipment.buyer_upsert_doc_requirement(
  p_shipment_id        uuid,
  p_document_kind      shipment.document_kind,
  p_requirement_level  shipment.requirement_level default 'required',
  p_display_name_en    text default null,
  p_display_name_fa    text default null,
  p_notes              text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  perform shipment.fn_assert_shipment_editable(p_shipment_id, true);

  select tenant_id, organization_id into v_tenant, v_org
    from shipment.shipments where id = p_shipment_id;

  insert into shipment.shipment_document_requirements (
    tenant_id, organization_id, shipment_id, document_kind, requirement_level,
    display_name_en, display_name_fa, notes, created_by, updated_by
  ) values (
    v_tenant, v_org, p_shipment_id, p_document_kind, p_requirement_level,
    p_display_name_en, p_display_name_fa, p_notes, v_actor, v_actor
  )
  on conflict (shipment_id, document_kind) where deleted_at is null
  do update set
    requirement_level = excluded.requirement_level,
    display_name_en   = excluded.display_name_en,
    display_name_fa   = excluded.display_name_fa,
    notes             = excluded.notes,
    updated_by        = v_actor
  returning id into v_id;

  perform shipment.fn_audit('shipment.doc_requirement_upserted', p_shipment_id,
    jsonb_build_object('requirement_id', v_id::text, 'document_kind', p_document_kind::text));
  return v_id;
end;
$$;

-- 6.6 buyer_upsert_document (non-terminal) ---------------------------------
create or replace function shipment.buyer_upsert_document(
  p_shipment_id        uuid,
  p_document_kind      shipment.document_kind,
  p_document_status    shipment.document_status default 'pending',
  p_requirement_id     uuid default null,
  p_shipment_item_id   uuid default null,
  p_external_reference text default null,
  p_issued_at          timestamptz default null,
  p_expires_at         timestamptz default null,
  p_notes              text default null,
  p_document_id        uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  perform shipment.fn_assert_shipment_editable(p_shipment_id, false);

  -- Requirement (if supplied) must belong to the same shipment.
  if p_requirement_id is not null then
    if not exists (
      select 1 from shipment.shipment_document_requirements
       where id = p_requirement_id and shipment_id = p_shipment_id and deleted_at is null
    ) then
      raise exception 'shipment: requirement not found in this shipment' using errcode = '42501';
    end if;
  end if;

  -- Item (if supplied) must belong to the same shipment.
  if p_shipment_item_id is not null then
    if not exists (
      select 1 from shipment.shipment_items
       where id = p_shipment_item_id and shipment_id = p_shipment_id and deleted_at is null
    ) then
      raise exception 'shipment: item not found in this shipment' using errcode = '42501';
    end if;
  end if;

  select tenant_id, organization_id into v_tenant, v_org
    from shipment.shipments where id = p_shipment_id;

  if p_document_id is null then
    insert into shipment.shipment_documents (
      tenant_id, organization_id, shipment_id, shipment_item_id, requirement_id,
      document_kind, document_status, external_reference, issued_at, expires_at, notes,
      created_by, updated_by
    ) values (
      v_tenant, v_org, p_shipment_id, p_shipment_item_id, p_requirement_id,
      p_document_kind, p_document_status, p_external_reference, p_issued_at, p_expires_at, p_notes,
      v_actor, v_actor
    ) returning id into v_id;
  else
    update shipment.shipment_documents
       set shipment_item_id   = coalesce(p_shipment_item_id, shipment_item_id),
           requirement_id     = coalesce(p_requirement_id, requirement_id),
           document_kind      = p_document_kind,
           document_status    = p_document_status,
           external_reference = coalesce(p_external_reference, external_reference),
           issued_at          = coalesce(p_issued_at, issued_at),
           expires_at         = coalesce(p_expires_at, expires_at),
           notes              = coalesce(p_notes, notes),
           updated_by         = v_actor
     where id = p_document_id and shipment_id = p_shipment_id and deleted_at is null
     returning id into v_id;
    if v_id is null then
      raise exception 'shipment: document not found in this shipment' using errcode = 'P0002';
    end if;
  end if;

  perform shipment.fn_audit('shipment.document_upserted', p_shipment_id,
    jsonb_build_object('document_id', v_id::text, 'document_kind', p_document_kind::text));
  return v_id;
end;
$$;

-- 6.7 buyer_mark_planned ---------------------------------------------------
create or replace function shipment.buyer_mark_planned(p_shipment_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  select status into v_status from shipment.shipments where id = p_shipment_id;
  if v_status <> 'draft' then
    raise exception 'shipment: invalid_transition: cannot move to planned from %', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status = 'planned', planned_at = now(), planned_by = v_actor, updated_by = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, 'draft', 'planned', 'marked_planned');
  perform shipment.fn_audit('shipment.marked_planned', p_shipment_id);
end;
$$;

-- 6.8 buyer_mark_booked ----------------------------------------------------
create or replace function shipment.buyer_mark_booked(
  p_shipment_id              uuid,
  p_carrier_organization_id  uuid default null,
  p_carrier_name             text default null,
  p_vehicle_reference        text default null,
  p_tracking_reference       text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  select status into v_status from shipment.shipments where id = p_shipment_id;
  if v_status <> 'planned' then
    raise exception 'shipment: invalid_transition: cannot mark booked from %', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status                  = 'booked',
         booked_at               = now(),
         booked_by               = v_actor,
         carrier_organization_id = coalesce(p_carrier_organization_id, carrier_organization_id),
         carrier_name            = coalesce(p_carrier_name, carrier_name),
         vehicle_reference       = coalesce(p_vehicle_reference, vehicle_reference),
         tracking_reference      = coalesce(p_tracking_reference, tracking_reference),
         updated_by              = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, 'planned', 'booked', 'marked_booked');
  perform shipment.fn_audit('shipment.marked_booked', p_shipment_id);
end;
$$;

-- 6.9 buyer_mark_in_transit ------------------------------------------------
create or replace function shipment.buyer_mark_in_transit(p_shipment_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  select status into v_status from shipment.shipments where id = p_shipment_id;
  if v_status <> 'booked' then
    raise exception 'shipment: invalid_transition: cannot mark in_transit from %', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status              = 'in_transit',
         in_transit_at       = now(),
         in_transit_by       = v_actor,
         actual_pickup_date  = coalesce(actual_pickup_date, now()),
         updated_by          = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, 'booked', 'in_transit', 'marked_in_transit');
  perform shipment.fn_audit('shipment.marked_in_transit', p_shipment_id);
end;
$$;

-- 6.10 buyer_mark_arrived --------------------------------------------------
create or replace function shipment.buyer_mark_arrived(p_shipment_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  select status into v_status from shipment.shipments where id = p_shipment_id;
  if v_status <> 'in_transit' then
    raise exception 'shipment: invalid_transition: cannot mark arrived from %', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status     = 'arrived', arrived_at = now(), arrived_by = v_actor, updated_by = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, 'in_transit', 'arrived', 'marked_arrived');
  perform shipment.fn_audit('shipment.marked_arrived', p_shipment_id);
end;
$$;

-- 6.11 buyer_mark_delivered ------------------------------------------------
create or replace function shipment.buyer_mark_delivered(p_shipment_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  select status into v_status from shipment.shipments where id = p_shipment_id;
  if v_status <> 'arrived' then
    raise exception 'shipment: invalid_transition: cannot mark delivered from %', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status                = 'delivered',
         delivered_at          = now(),
         delivered_by          = v_actor,
         actual_delivery_date  = coalesce(actual_delivery_date, now()),
         updated_by            = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, 'arrived', 'delivered', 'marked_delivered');
  perform shipment.fn_audit('shipment.marked_delivered', p_shipment_id);
end;
$$;

-- 6.12 buyer_cancel_shipment -----------------------------------------------
create or replace function shipment.buyer_cancel_shipment(
  p_shipment_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  select status into v_status from shipment.shipments where id = p_shipment_id;
  if v_status in ('delivered', 'closed', 'cancelled') then
    raise exception 'shipment: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status = 'cancelled', cancelled_at = now(), cancelled_by = v_actor,
         cancelled_reason = p_reason, updated_by = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, v_status, 'cancelled', 'cancelled', p_reason);
  perform shipment.fn_audit('shipment.cancelled', p_shipment_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.13 buyer_list_shipments ------------------------------------------------
create or replace function shipment.buyer_list_shipments(
  p_executed_contract_id uuid                     default null,
  p_status              shipment.shipment_status default null,
  p_limit               integer                  default 25,
  p_offset              integer                  default 0
) returns table (
  id uuid, shipment_code text, executed_contract_id uuid, supplier_id uuid,
  status text, transport_mode text, created_at timestamptz, updated_at timestamptz
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
    raise exception 'shipment: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'shipment: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select sh.id, sh.shipment_code, sh.executed_contract_id, sh.supplier_id,
           sh.status::text, sh.transport_mode::text, sh.created_at, sh.updated_at
      from shipment.shipments sh
     where sh.deleted_at is null
       and (identity.is_platform_admin() or sh.organization_id = v_caller_org)
       and (p_executed_contract_id is null or sh.executed_contract_id = p_executed_contract_id)
       and (p_status is null or sh.status = p_status)
     order by sh.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.14 buyer_get_shipment --------------------------------------------------
create or replace function shipment.buyer_get_shipment(p_shipment_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform shipment.fn_assert_shipment_owned(p_shipment_id);
  return (
    select jsonb_build_object(
      'id', sh.id, 'shipment_code', sh.shipment_code,
      'executed_contract_id', sh.executed_contract_id, 'supplier_id', sh.supplier_id,
      'status', sh.status, 'transport_mode', sh.transport_mode,
      'incoterm', sh.incoterm,
      'origin_country', sh.origin_country, 'origin_city', sh.origin_city,
      'origin_port', sh.origin_port, 'origin_location_text', sh.origin_location_text,
      'destination_country', sh.destination_country, 'destination_city', sh.destination_city,
      'destination_port', sh.destination_port, 'destination_location_text', sh.destination_location_text,
      'planned_pickup_date', sh.planned_pickup_date,
      'planned_delivery_date', sh.planned_delivery_date,
      'actual_pickup_date', sh.actual_pickup_date,
      'actual_delivery_date', sh.actual_delivery_date,
      'carrier_organization_id', sh.carrier_organization_id,
      'carrier_name', sh.carrier_name,
      'vehicle_reference', sh.vehicle_reference, 'tracking_reference', sh.tracking_reference,
      'created_at', sh.created_at, 'updated_at', sh.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'executed_contract_item_id', it.executed_contract_item_id,
          'product_id', it.product_id, 'quantity', it.quantity, 'quantity_unit', it.quantity_unit
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from shipment.shipment_items it
         where it.shipment_id = sh.id and it.deleted_at is null
      ),
      'stops', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', s.id, 'sequence_number', s.sequence_number, 'stop_type', s.stop_type,
          'country', s.country, 'city', s.city, 'port', s.port
        ) order by s.sequence_number), '[]'::jsonb)
          from shipment.shipment_stops s
         where s.shipment_id = sh.id and s.deleted_at is null
      ),
      'milestones', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', m.id, 'milestone_type', m.milestone_type, 'status', m.status,
          'planned_at', m.planned_at, 'completed_at', m.completed_at
        )), '[]'::jsonb)
          from shipment.shipment_milestones m
         where m.shipment_id = sh.id and m.deleted_at is null
      ),
      'document_requirements', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', r.id, 'document_kind', r.document_kind, 'requirement_level', r.requirement_level
        )), '[]'::jsonb)
          from shipment.shipment_document_requirements r
         where r.shipment_id = sh.id and r.deleted_at is null
      ),
      'documents', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', d.id, 'document_kind', d.document_kind, 'document_status', d.document_status,
          'requirement_id', d.requirement_id, 'external_reference', d.external_reference
        )), '[]'::jsonb)
          from shipment.shipment_documents d
         where d.shipment_id = sh.id and d.deleted_at is null
      )
    )
    from shipment.shipments sh where sh.id = p_shipment_id
  );
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (2 — read-only)
-- ===========================================================================

-- 7.1 supplier_list_my_shipments -------------------------------------------
create or replace function shipment.supplier_list_my_shipments(
  p_status shipment.shipment_status default null,
  p_limit  integer                   default 25,
  p_offset integer                   default 0
) returns table (
  id uuid, shipment_code text, executed_contract_id uuid,
  status text, transport_mode text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select sh.id, sh.shipment_code, sh.executed_contract_id,
           sh.status::text, sh.transport_mode::text, sh.created_at, sh.updated_at
      from shipment.shipments sh
     where sh.deleted_at is null
       and sh.supplier_id = v_supplier
       and (p_status is null or sh.status = p_status)
     order by sh.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 supplier_get_my_shipment ---------------------------------------------
create or replace function shipment.supplier_get_my_shipment(p_shipment_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_supplier uuid := supplier.fn_portal_supplier_id();
  v_shipment_supplier uuid;
begin
  select supplier_id into v_shipment_supplier from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_shipment_supplier is null then
    raise exception 'shipment: not found' using errcode = 'P0002';
  end if;
  if v_shipment_supplier <> v_caller_supplier and not identity.is_platform_admin() then
    raise exception 'shipment: not on caller''s contract' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', sh.id, 'shipment_code', sh.shipment_code,
      'executed_contract_id', sh.executed_contract_id,
      'status', sh.status, 'transport_mode', sh.transport_mode,
      'incoterm', sh.incoterm,
      'origin_country', sh.origin_country, 'destination_country', sh.destination_country,
      'planned_pickup_date', sh.planned_pickup_date,
      'planned_delivery_date', sh.planned_delivery_date,
      'created_at', sh.created_at, 'updated_at', sh.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'product_id', it.product_id, 'quantity', it.quantity, 'quantity_unit', it.quantity_unit
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from shipment.shipment_items it
         where it.shipment_id = sh.id and it.deleted_at is null
      )
    )
    from shipment.shipments sh where sh.id = p_shipment_id
  );
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (5)
-- ===========================================================================

-- 8.1 admin_list_shipments -------------------------------------------------
create or replace function shipment.admin_list_shipments(
  p_executed_contract_id uuid                     default null,
  p_supplier_id          uuid                     default null,
  p_status               shipment.shipment_status default null,
  p_limit                integer                  default 25,
  p_offset               integer                  default 0
) returns table (
  id uuid, shipment_code text, organization_id uuid,
  executed_contract_id uuid, supplier_id uuid,
  status text, transport_mode text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_shipments: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select sh.id, sh.shipment_code, sh.organization_id,
           sh.executed_contract_id, sh.supplier_id,
           sh.status::text, sh.transport_mode::text, sh.created_at, sh.updated_at
      from shipment.shipments sh
     where sh.deleted_at is null
       and (p_executed_contract_id is null or sh.executed_contract_id = p_executed_contract_id)
       and (p_supplier_id is null or sh.supplier_id = p_supplier_id)
       and (p_status is null or sh.status = p_status)
     order by sh.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_shipment ---------------------------------------------------
create or replace function shipment.admin_get_shipment(p_shipment_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_shipment: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', sh.id, 'shipment_code', sh.shipment_code,
      'organization_id', sh.organization_id,
      'executed_contract_id', sh.executed_contract_id, 'supplier_id', sh.supplier_id,
      'status', sh.status, 'transport_mode', sh.transport_mode,
      'created_at', sh.created_at, 'updated_at', sh.updated_at,
      'items_count', (select count(*) from shipment.shipment_items
                       where shipment_id = sh.id and deleted_at is null),
      'stops_count', (select count(*) from shipment.shipment_stops
                       where shipment_id = sh.id and deleted_at is null),
      'milestones_count', (select count(*) from shipment.shipment_milestones
                            where shipment_id = sh.id and deleted_at is null),
      'documents_count', (select count(*) from shipment.shipment_documents
                           where shipment_id = sh.id and deleted_at is null)
    )
    from shipment.shipments sh where sh.id = p_shipment_id
  );
end;
$$;

-- 8.3 admin_list_shipment_events -------------------------------------------
create or replace function shipment.admin_list_shipment_events(p_shipment_id uuid)
returns table (
  id uuid, from_status text, to_status text, event_type text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_shipment_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text, e.event_type,
           e.actor_user_id, e.reason, e.created_at
      from shipment.shipment_events e
     where e.shipment_id = p_shipment_id
     order by e.created_at asc;
end;
$$;

-- 8.4 admin_force_cancel_shipment ------------------------------------------
create or replace function shipment.admin_force_cancel_shipment(
  p_shipment_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_cancel_shipment: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_status is null then
    raise exception 'shipment: not found' using errcode = 'P0002';
  end if;
  if v_status in ('delivered', 'closed', 'cancelled') then
    raise exception 'shipment: invalid_transition: cannot cancel from %', v_status using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status = 'cancelled', cancelled_at = now(), cancelled_by = v_actor,
         cancelled_reason = p_reason, updated_by = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, v_status, 'cancelled', 'admin_force_cancel', p_reason);
  perform shipment.fn_audit('shipment.admin_cancelled', p_shipment_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.5 admin_close_shipment -------------------------------------------------
create or replace function shipment.admin_close_shipment(
  p_shipment_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_status shipment.shipment_status; v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_close_shipment: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_status is null then
    raise exception 'shipment: not found' using errcode = 'P0002';
  end if;
  if v_status not in ('delivered', 'arrived') then
    raise exception 'shipment: invalid_transition: can only close from delivered/arrived (current=%)', v_status
      using errcode = 'P0001';
  end if;
  update shipment.shipments
     set status = 'closed', closed_at = now(), closed_by = v_actor,
         closed_reason = p_reason, updated_by = v_actor
   where id = p_shipment_id;
  perform shipment.fn_record_shipment_event(p_shipment_id, v_status, 'closed', 'admin_close', p_reason);
  perform shipment.fn_audit('shipment.closed', p_shipment_id,
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
     where t.table_schema = 'shipment'
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
     where t.table_schema = 'shipment'
       and t.table_type   = 'BASE TABLE'
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
-- 10. Grants (SELECT only; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on shipment.shipments                       to anon, authenticated;
grant select on shipment.shipment_items                  to anon, authenticated;
grant select on shipment.shipment_stops                  to authenticated;
grant select on shipment.shipment_milestones             to authenticated;
grant select on shipment.shipment_document_requirements  to authenticated;
grant select on shipment.shipment_documents              to authenticated;
grant select on shipment.shipment_events                 to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function shipment.buyer_create_shipment(uuid, shipment.transport_mode, text, char, text, text, text, char, text, text, text, timestamptz, timestamptz, text) to authenticated;
grant execute on function shipment.buyer_update_shipment(uuid, shipment.transport_mode, text, char, text, text, text, char, text, text, text, timestamptz, timestamptz, uuid, text, text, text, text) to authenticated;
grant execute on function shipment.buyer_upsert_stop(uuid, integer, shipment.stop_type, char, text, text, text, timestamptz, timestamptz, timestamptz, timestamptz, text) to authenticated;
grant execute on function shipment.buyer_upsert_milestone(uuid, shipment.milestone_type, shipment.milestone_status, timestamptz, timestamptz, text) to authenticated;
grant execute on function shipment.buyer_upsert_doc_requirement(uuid, shipment.document_kind, shipment.requirement_level, text, text, text) to authenticated;
grant execute on function shipment.buyer_upsert_document(uuid, shipment.document_kind, shipment.document_status, uuid, uuid, text, timestamptz, timestamptz, text, uuid) to authenticated;
grant execute on function shipment.buyer_mark_planned(uuid) to authenticated;
grant execute on function shipment.buyer_mark_booked(uuid, uuid, text, text, text) to authenticated;
grant execute on function shipment.buyer_mark_in_transit(uuid) to authenticated;
grant execute on function shipment.buyer_mark_arrived(uuid) to authenticated;
grant execute on function shipment.buyer_mark_delivered(uuid) to authenticated;
grant execute on function shipment.buyer_cancel_shipment(uuid, text) to authenticated;
grant execute on function shipment.buyer_list_shipments(uuid, shipment.shipment_status, integer, integer) to authenticated;
grant execute on function shipment.buyer_get_shipment(uuid) to authenticated;

grant execute on function shipment.supplier_list_my_shipments(shipment.shipment_status, integer, integer) to authenticated;
grant execute on function shipment.supplier_get_my_shipment(uuid) to authenticated;

grant execute on function shipment.admin_list_shipments(uuid, uuid, shipment.shipment_status, integer, integer) to authenticated;
grant execute on function shipment.admin_get_shipment(uuid) to authenticated;
grant execute on function shipment.admin_list_shipment_events(uuid) to authenticated;
grant execute on function shipment.admin_force_cancel_shipment(uuid, text) to authenticated;
grant execute on function shipment.admin_close_shipment(uuid, text) to authenticated;
