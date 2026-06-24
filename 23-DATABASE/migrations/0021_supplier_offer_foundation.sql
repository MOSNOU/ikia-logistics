-- CC-10 / Migration 0021 — Supplier Offer Foundation
-- Fourth business domain (after supplier, commodity, rfq).
-- Append-only over migrations 0001-0020.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().
-- Buyer RPCs derive organization from identity.current_organization_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists offer;
grant usage on schema offer to anon, authenticated, service_role;
comment on schema offer is
  'iKIA Phase 2 — supplier offer business domain. Offers reference RFQs from rfq schema.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type offer.offer_status as enum (
  'draft', 'submitted', 'withdrawn', 'expired', 'rejected', 'shortlisted', 'accepted'
);

create type offer.commitment_status as enum (
  'committed', 'with_caveat', 'cannot_provide', 'conditional'
);

create type offer.compliance_status as enum (
  'compliant', 'deviation', 'not_applicable', 'pending'
);

-- ===========================================================================
-- 3. Tables (5)
-- ===========================================================================

-- 3.1 supplier_offers --------------------------------------------------------
create table offer.supplier_offers (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  organization_id          uuid not null references organization.organizations(id) on delete cascade,
  supplier_id              uuid not null references supplier.suppliers(id) on delete cascade,
  request_id               uuid not null references rfq.requests(id) on delete restrict,

  offer_code               text not null unique,
  status                   offer.offer_status not null default 'draft',
  submitted_by             uuid references auth.users(id),

  currency                 text not null default 'USD',
  incoterm                 text,
  delivery_country         char(2),
  delivery_city            text,
  delivery_port            text,
  delivery_location_text   text,
  delivery_lead_time_text  text,
  payment_terms_text       text,
  validity_until           timestamptz,

  supplier_notes           text,
  metadata                 jsonb not null default '{}'::jsonb,

  submitted_at             timestamptz,
  withdrawn_at             timestamptz,
  withdrawn_by             uuid references auth.users(id),
  withdrawn_reason         text,
  rejected_at              timestamptz,
  rejected_by              uuid references auth.users(id),
  rejected_reason          text,
  shortlisted_at           timestamptz,
  shortlisted_by           uuid references auth.users(id),
  accepted_at              timestamptz,
  accepted_by              uuid references auth.users(id),

  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1
);

comment on table offer.supplier_offers is
  'Supplier offer/bid against an RFQ. One active row per (supplier_id, request_id) — enforced via partial unique index.';

-- One active offer per (supplier_id, request_id). Soft-delete on withdraw allows
-- the supplier to create a new offer; non-withdrawn terminal states (rejected,
-- expired, accepted, shortlisted) keep the row and block re-submission.
create unique index supplier_offers_unique_active
  on offer.supplier_offers(supplier_id, request_id)
  where deleted_at is null;

create index supplier_offers_request_idx  on offer.supplier_offers(request_id);
create index supplier_offers_supplier_idx on offer.supplier_offers(supplier_id);
create index supplier_offers_status_idx   on offer.supplier_offers(status);
create index supplier_offers_org_idx      on offer.supplier_offers(organization_id);

-- 3.2 supplier_offer_items --------------------------------------------------
create table offer.supplier_offer_items (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  organization_id          uuid not null references organization.organizations(id) on delete cascade,
  supplier_id              uuid not null references supplier.suppliers(id) on delete cascade,
  offer_id                 uuid not null references offer.supplier_offers(id) on delete cascade,
  request_item_id          uuid not null references rfq.request_items(id) on delete restrict,
  product_id               uuid not null references commodity.products(id) on delete restrict,

  offered_quantity         numeric,
  quantity_unit            text,
  unit_price               numeric,
  total_price              numeric,
  currency                 text,

  packaging                text,
  origin_country           char(2),
  origin_city              text,
  delivery_window_start    date,
  delivery_window_end      date,
  delivery_lead_time_text  text,

  notes                    text,
  metadata                 jsonb not null default '{}'::jsonb,
  sort_order               integer not null default 0,

  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1
);

comment on table offer.supplier_offer_items is
  'Offer line items. request_item_id must belong to the parent offer''s RFQ — enforced at RPC level.';

create unique index supplier_offer_items_unique_active
  on offer.supplier_offer_items(offer_id, request_item_id)
  where deleted_at is null;

create index supplier_offer_items_offer_idx       on offer.supplier_offer_items(offer_id);
create index supplier_offer_items_request_item_idx on offer.supplier_offer_items(request_item_id);

-- 3.3 supplier_offer_item_specifications ------------------------------------
create table offer.supplier_offer_item_specifications (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete cascade,
  offer_id                    uuid not null references offer.supplier_offers(id) on delete cascade,
  offer_item_id               uuid not null references offer.supplier_offer_items(id) on delete cascade,
  request_item_spec_id        uuid references rfq.request_item_specifications(id) on delete set null,

  spec_key                    text not null,
  display_name_fa             text,
  display_name_en             text,
  data_type                   commodity.spec_data_type not null default 'text',
  unit                        text,
  offered_value               text,
  min_value                   numeric,
  max_value                   numeric,
  compliance_status           offer.compliance_status not null default 'pending',
  deviation_text              text,
  notes                       text,
  sort_order                  integer not null default 0,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

create unique index offer_item_specs_unique_active
  on offer.supplier_offer_item_specifications(offer_item_id, spec_key)
  where deleted_at is null;

create index offer_item_specs_offer_idx      on offer.supplier_offer_item_specifications(offer_id);
create index offer_item_specs_offer_item_idx on offer.supplier_offer_item_specifications(offer_item_id);

-- 3.4 supplier_offer_document_commitments ----------------------------------
create table offer.supplier_offer_document_commitments (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  organization_id          uuid not null references organization.organizations(id) on delete cascade,
  supplier_id              uuid not null references supplier.suppliers(id) on delete cascade,
  offer_id                 uuid not null references offer.supplier_offers(id) on delete cascade,
  offer_item_id            uuid references offer.supplier_offer_items(id) on delete cascade,
  request_doc_req_id       uuid references rfq.request_document_requirements(id) on delete set null,

  document_kind            commodity.document_kind not null,
  commitment_status        offer.commitment_status not null default 'committed',
  expected_available_date  date,
  notes                    text,
  metadata                 jsonb not null default '{}'::jsonb,

  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1
);

-- Partial uniques by scope: one row per (offer, document_kind) at offer-level,
-- one row per (offer_item, document_kind) at item-level.
create unique index offer_doc_commit_unique_offer_scope
  on offer.supplier_offer_document_commitments(offer_id, document_kind)
  where offer_item_id is null and deleted_at is null;

create unique index offer_doc_commit_unique_item_scope
  on offer.supplier_offer_document_commitments(offer_item_id, document_kind)
  where offer_item_id is not null and deleted_at is null;

create index offer_doc_commit_offer_idx on offer.supplier_offer_document_commitments(offer_id);

-- 3.5 supplier_offer_status_events (immutable) -----------------------------
create table offer.supplier_offer_status_events (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references identity.tenants(id) on delete restrict,
  organization_id       uuid not null references organization.organizations(id) on delete cascade,
  offer_id              uuid not null references offer.supplier_offers(id) on delete cascade,

  from_status           offer.offer_status,
  to_status             offer.offer_status not null,
  actor_user_id         uuid references auth.users(id),
  actor_organization_id uuid references organization.organizations(id),
  reason                text,
  payload               jsonb not null default '{}'::jsonb,
  created_at            timestamptz not null default now()
);

comment on table offer.supplier_offer_status_events is
  'Immutable audit trail of offer status transitions. No UPDATE/DELETE policies.';

create index offer_status_events_offer_idx on offer.supplier_offer_status_events(offer_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit: domain audit event ------------------------------------------
create or replace function offer.fn_audit(
  p_action_code text,
  p_offer_id    uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from offer.supplier_offers where id = p_offer_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'offer', p_offer_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_record_status_event ------------------------------------------------
create or replace function offer.fn_record_status_event(
  p_offer_id uuid,
  p_from     offer.offer_status,
  p_to       offer.offer_status,
  p_reason   text default null,
  p_payload  jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from offer.supplier_offers where id = p_offer_id;
  insert into offer.supplier_offer_status_events (
    tenant_id, organization_id, offer_id, from_status, to_status,
    actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_offer_id, p_from, p_to,
    auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 4.3 fn_assert_offer_supplier_owned ---------------------------------------
-- Caller's supplier must own the offer. platform_admin bypasses.
create or replace function offer.fn_assert_offer_supplier_owned(p_offer_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_owner_supplier uuid;
  v_caller_supplier uuid;
begin
  select supplier_id into v_owner_supplier
    from offer.supplier_offers
   where id = p_offer_id and deleted_at is null;
  if v_owner_supplier is null then
    raise exception 'offer: not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;

  -- Resolve caller's supplier (raises if not a supplier portal role / no active org).
  v_caller_supplier := supplier.fn_portal_supplier_id();
  if v_caller_supplier <> v_owner_supplier then
    raise exception 'offer: caller does not own this offer' using errcode = '42501';
  end if;
end;
$$;

-- 4.4 fn_assert_offer_editable: draft only ---------------------------------
create or replace function offer.fn_assert_offer_editable(p_offer_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status offer.offer_status;
begin
  select status into v_status from offer.supplier_offers
   where id = p_offer_id and deleted_at is null;
  if v_status is null then
    raise exception 'offer: not found' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'offer: locked (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- 4.5 fn_assert_supplier_invited_to_rfq -----------------------------------
create or replace function offer.fn_assert_supplier_invited_to_rfq(
  p_supplier_id uuid,
  p_request_id  uuid
) returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not exists (
    select 1 from rfq.request_supplier_invitations inv
     where inv.supplier_id = p_supplier_id
       and inv.request_id  = p_request_id
       and inv.deleted_at  is null
  ) then
    raise exception 'offer: supplier is not invited to this RFQ' using errcode = '42501';
  end if;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table offer.supplier_offers                       enable row level security;
alter table offer.supplier_offer_items                  enable row level security;
alter table offer.supplier_offer_item_specifications    enable row level security;
alter table offer.supplier_offer_document_commitments   enable row level security;
alter table offer.supplier_offer_status_events          enable row level security;

-- Shared visibility predicate:
--   * platform_admin
--   * member of supplier organization that owns the offer (offer.organization_id = supplier's org)
--   * member of buyer organization that owns the parent RFQ

-- 5.1 supplier_offers ------------------------------------------------------
drop policy if exists supplier_offers_select on offer.supplier_offers;
create policy supplier_offers_select on offer.supplier_offers
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = offer.supplier_offers.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from rfq.requests r
         join organization.memberships m on m.organization_id = r.organization_id
        where r.id = offer.supplier_offers.request_id
          and r.deleted_at is null
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists supplier_offers_select_deleted on offer.supplier_offers;
create policy supplier_offers_select_deleted on offer.supplier_offers
  for select
  using (
    deleted_at is not null
    and (identity.is_platform_admin() or identity.has_role('compliance_officer'))
  );

drop policy if exists supplier_offers_admin_modify on offer.supplier_offers;
create policy supplier_offers_admin_modify on offer.supplier_offers
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.2 supplier_offer_items -------------------------------------------------
drop policy if exists supplier_offer_items_select on offer.supplier_offer_items;
create policy supplier_offer_items_select on offer.supplier_offer_items
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = offer.supplier_offer_items.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from offer.supplier_offers so
         join rfq.requests r on r.id = so.request_id
         join organization.memberships m on m.organization_id = r.organization_id
        where so.id = offer.supplier_offer_items.offer_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists supplier_offer_items_admin_modify on offer.supplier_offer_items;
create policy supplier_offer_items_admin_modify on offer.supplier_offer_items
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.3 supplier_offer_item_specifications -----------------------------------
drop policy if exists offer_specs_select on offer.supplier_offer_item_specifications;
create policy offer_specs_select on offer.supplier_offer_item_specifications
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = offer.supplier_offer_item_specifications.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from offer.supplier_offers so
         join rfq.requests r on r.id = so.request_id
         join organization.memberships m on m.organization_id = r.organization_id
        where so.id = offer.supplier_offer_item_specifications.offer_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists offer_specs_admin_modify on offer.supplier_offer_item_specifications;
create policy offer_specs_admin_modify on offer.supplier_offer_item_specifications
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.4 supplier_offer_document_commitments ----------------------------------
drop policy if exists offer_doc_commit_select on offer.supplier_offer_document_commitments;
create policy offer_doc_commit_select on offer.supplier_offer_document_commitments
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = offer.supplier_offer_document_commitments.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from offer.supplier_offers so
         join rfq.requests r on r.id = so.request_id
         join organization.memberships m on m.organization_id = r.organization_id
        where so.id = offer.supplier_offer_document_commitments.offer_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists offer_doc_commit_admin_modify on offer.supplier_offer_document_commitments;
create policy offer_doc_commit_admin_modify on offer.supplier_offer_document_commitments
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.5 supplier_offer_status_events ----------------------------------------
drop policy if exists offer_status_events_select on offer.supplier_offer_status_events;
create policy offer_status_events_select on offer.supplier_offer_status_events
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = offer.supplier_offer_status_events.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
    or exists (
      select 1 from offer.supplier_offers so
       join rfq.requests r on r.id = so.request_id
       join organization.memberships m on m.organization_id = r.organization_id
      where so.id = offer.supplier_offer_status_events.offer_id
        and m.user_id = identity.current_user_id()
        and m.deleted_at is null
        and m.status = 'active'
    )
  );

-- ===========================================================================
-- 6. Supplier RPCs (12)
-- ===========================================================================

-- 6.1 supplier_create_draft_offer ------------------------------------------
create or replace function offer.supplier_create_draft_offer(
  p_request_id              uuid,
  p_currency                text default 'USD',
  p_incoterm                text default null,
  p_delivery_country        char(2) default null,
  p_delivery_city           text default null,
  p_delivery_port           text default null,
  p_delivery_location_text  text default null,
  p_delivery_lead_time_text text default null,
  p_payment_terms_text      text default null,
  p_validity_until          timestamptz default null,
  p_supplier_notes          text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier uuid := supplier.fn_portal_supplier_id();
  v_actor    uuid := auth.uid();
  v_tenant   uuid;
  v_org      uuid;
  v_rfq_status rfq.request_status;
  v_id       uuid;
  v_code     text;
begin
  -- Verify RFQ exists and is open for offers (invited or published).
  select status into v_rfq_status from rfq.requests
   where id = p_request_id and deleted_at is null;
  if v_rfq_status is null then
    raise exception 'offer: RFQ not found' using errcode = 'P0002';
  end if;
  if v_rfq_status not in ('invited', 'published', 'submitted') then
    raise exception 'offer: RFQ status % does not accept offers', v_rfq_status
      using errcode = 'P0001';
  end if;

  -- Invitation gate.
  perform offer.fn_assert_supplier_invited_to_rfq(v_supplier, p_request_id);

  -- Duplicate-active guard.
  if exists (
    select 1 from offer.supplier_offers
     where supplier_id = v_supplier and request_id = p_request_id and deleted_at is null
  ) then
    raise exception 'offer: an active offer already exists for this supplier and RFQ'
      using errcode = '23505';
  end if;

  -- Derive tenant + organization_id from the supplier record.
  select s.tenant_id, s.organization_id into v_tenant, v_org
    from supplier.suppliers s where s.id = v_supplier;

  v_code := 'OFFER-' || to_char(now(), 'YYYY') || '-' ||
            lpad((floor(random() * 1000000)::int)::text, 6, '0');

  insert into offer.supplier_offers (
    tenant_id, organization_id, supplier_id, request_id, offer_code, status,
    currency, incoterm, delivery_country, delivery_city, delivery_port,
    delivery_location_text, delivery_lead_time_text, payment_terms_text,
    validity_until, supplier_notes, created_by, updated_by
  ) values (
    v_tenant, v_org, v_supplier, p_request_id, v_code, 'draft',
    coalesce(p_currency, 'USD'), p_incoterm,
    p_delivery_country, p_delivery_city, p_delivery_port,
    p_delivery_location_text, p_delivery_lead_time_text, p_payment_terms_text,
    p_validity_until, p_supplier_notes, v_actor, v_actor
  ) returning id into v_id;

  perform offer.fn_record_status_event(v_id, null, 'draft', 'created');
  perform offer.fn_audit('offer.created', v_id, jsonb_build_object('offer_code', v_code));
  return v_id;
end;
$$;

-- 6.2 supplier_update_my_offer ---------------------------------------------
create or replace function offer.supplier_update_my_offer(
  p_offer_id                uuid,
  p_currency                text default null,
  p_incoterm                text default null,
  p_delivery_country        char(2) default null,
  p_delivery_city           text default null,
  p_delivery_port           text default null,
  p_delivery_location_text  text default null,
  p_delivery_lead_time_text text default null,
  p_payment_terms_text      text default null,
  p_validity_until          timestamptz default null,
  p_supplier_notes          text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform offer.fn_assert_offer_supplier_owned(p_offer_id);
  perform offer.fn_assert_offer_editable(p_offer_id);

  update offer.supplier_offers
     set currency                = coalesce(p_currency, currency),
         incoterm                = coalesce(p_incoterm, incoterm),
         delivery_country        = coalesce(p_delivery_country, delivery_country),
         delivery_city           = coalesce(p_delivery_city, delivery_city),
         delivery_port           = coalesce(p_delivery_port, delivery_port),
         delivery_location_text  = coalesce(p_delivery_location_text, delivery_location_text),
         delivery_lead_time_text = coalesce(p_delivery_lead_time_text, delivery_lead_time_text),
         payment_terms_text      = coalesce(p_payment_terms_text, payment_terms_text),
         validity_until          = coalesce(p_validity_until, validity_until),
         supplier_notes          = coalesce(p_supplier_notes, supplier_notes),
         updated_by              = v_actor
   where id = p_offer_id;

  perform offer.fn_audit('offer.updated', p_offer_id);
end;
$$;

-- 6.3 supplier_upsert_offer_item -------------------------------------------
create or replace function offer.supplier_upsert_offer_item(
  p_offer_id              uuid,
  p_offer_item_id         uuid default null,
  p_request_item_id       uuid default null,
  p_offered_quantity      numeric default null,
  p_quantity_unit         text default null,
  p_unit_price            numeric default null,
  p_total_price           numeric default null,
  p_currency              text default null,
  p_packaging             text default null,
  p_origin_country        char(2) default null,
  p_origin_city           text default null,
  p_delivery_window_start date default null,
  p_delivery_window_end   date default null,
  p_delivery_lead_time_text text default null,
  p_notes                 text default null,
  p_sort_order            integer default 0
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid;
  v_org uuid;
  v_supplier uuid;
  v_request_id uuid;
  v_ri_request_id uuid;
  v_product_id uuid;
  v_id uuid;
begin
  perform offer.fn_assert_offer_supplier_owned(p_offer_id);
  perform offer.fn_assert_offer_editable(p_offer_id);

  select tenant_id, organization_id, supplier_id, request_id
    into v_tenant, v_org, v_supplier, v_request_id
    from offer.supplier_offers where id = p_offer_id;

  if p_offer_item_id is null then
    -- INSERT path.
    if p_request_item_id is null then
      raise exception 'offer: p_request_item_id required for new offer item' using errcode = '22023';
    end if;
    -- Cross-RFQ integrity: request_item must belong to the offer's RFQ.
    select request_id, product_id into v_ri_request_id, v_product_id
      from rfq.request_items
     where id = p_request_item_id and deleted_at is null;
    if v_ri_request_id is null then
      raise exception 'offer: request item not found' using errcode = 'P0002';
    end if;
    if v_ri_request_id <> v_request_id then
      raise exception 'offer: request item belongs to a different RFQ' using errcode = '42501';
    end if;

    insert into offer.supplier_offer_items (
      tenant_id, organization_id, supplier_id, offer_id, request_item_id, product_id,
      offered_quantity, quantity_unit, unit_price, total_price, currency,
      packaging, origin_country, origin_city,
      delivery_window_start, delivery_window_end, delivery_lead_time_text,
      notes, sort_order, created_by, updated_by
    ) values (
      v_tenant, v_org, v_supplier, p_offer_id, p_request_item_id, v_product_id,
      p_offered_quantity, p_quantity_unit, p_unit_price, p_total_price, p_currency,
      p_packaging, p_origin_country, p_origin_city,
      p_delivery_window_start, p_delivery_window_end, p_delivery_lead_time_text,
      p_notes, coalesce(p_sort_order, 0), v_actor, v_actor
    ) returning id into v_id;
  else
    -- UPDATE path.
    update offer.supplier_offer_items
       set offered_quantity        = coalesce(p_offered_quantity, offered_quantity),
           quantity_unit           = coalesce(p_quantity_unit, quantity_unit),
           unit_price              = coalesce(p_unit_price, unit_price),
           total_price             = coalesce(p_total_price, total_price),
           currency                = coalesce(p_currency, currency),
           packaging               = coalesce(p_packaging, packaging),
           origin_country          = coalesce(p_origin_country, origin_country),
           origin_city             = coalesce(p_origin_city, origin_city),
           delivery_window_start   = coalesce(p_delivery_window_start, delivery_window_start),
           delivery_window_end     = coalesce(p_delivery_window_end, delivery_window_end),
           delivery_lead_time_text = coalesce(p_delivery_lead_time_text, delivery_lead_time_text),
           notes                   = coalesce(p_notes, notes),
           sort_order              = coalesce(p_sort_order, sort_order),
           updated_by              = v_actor
     where id = p_offer_item_id and offer_id = p_offer_id and deleted_at is null;
    if not found then
      raise exception 'offer: item not found in this offer' using errcode = 'P0002';
    end if;
    v_id := p_offer_item_id;
  end if;

  perform offer.fn_audit('offer.item_upserted', p_offer_id,
    jsonb_build_object('offer_item_id', v_id::text));
  return v_id;
end;
$$;

-- 6.4 supplier_remove_offer_item (soft) ------------------------------------
create or replace function offer.supplier_remove_offer_item(p_offer_item_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_offer_id uuid;
begin
  select offer_id into v_offer_id from offer.supplier_offer_items
   where id = p_offer_item_id and deleted_at is null;
  if v_offer_id is null then
    raise exception 'offer: item not found' using errcode = 'P0002';
  end if;
  perform offer.fn_assert_offer_supplier_owned(v_offer_id);
  perform offer.fn_assert_offer_editable(v_offer_id);

  update offer.supplier_offer_items
     set deleted_at = now(), updated_by = v_actor
   where id = p_offer_item_id;

  perform offer.fn_audit('offer.item_removed', v_offer_id,
    jsonb_build_object('offer_item_id', p_offer_item_id::text));
end;
$$;

-- 6.5 supplier_upsert_spec_response ----------------------------------------
create or replace function offer.supplier_upsert_spec_response(
  p_offer_item_id          uuid,
  p_spec_key               text,
  p_display_name_fa        text default null,
  p_display_name_en        text default null,
  p_data_type              commodity.spec_data_type default 'text',
  p_unit                   text default null,
  p_offered_value          text default null,
  p_min_value              numeric default null,
  p_max_value              numeric default null,
  p_compliance_status      offer.compliance_status default 'pending',
  p_deviation_text         text default null,
  p_request_item_spec_id   uuid default null,
  p_sort_order             integer default 0,
  p_notes                  text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_offer_id uuid;
  v_request_item_id uuid;
  v_supplier uuid;
  v_tenant uuid;
  v_org uuid;
  v_spec_request_item uuid;
  v_id uuid;
begin
  select oi.offer_id, oi.request_item_id, oi.supplier_id, oi.tenant_id, oi.organization_id
    into v_offer_id, v_request_item_id, v_supplier, v_tenant, v_org
    from offer.supplier_offer_items oi
   where oi.id = p_offer_item_id and oi.deleted_at is null;
  if v_offer_id is null then
    raise exception 'offer: offer item not found' using errcode = 'P0002';
  end if;
  perform offer.fn_assert_offer_supplier_owned(v_offer_id);
  perform offer.fn_assert_offer_editable(v_offer_id);

  -- Cross-RFQ integrity: rfq spec must belong to the same RFQ item as the offer item.
  if p_request_item_spec_id is not null then
    select request_item_id into v_spec_request_item
      from rfq.request_item_specifications
     where id = p_request_item_spec_id and deleted_at is null;
    if v_spec_request_item is null then
      raise exception 'offer: rfq spec not found' using errcode = 'P0002';
    end if;
    if v_spec_request_item <> v_request_item_id then
      raise exception 'offer: rfq spec does not match the offer item''s RFQ item'
        using errcode = '42501';
    end if;
  end if;

  insert into offer.supplier_offer_item_specifications (
    tenant_id, organization_id, supplier_id, offer_id, offer_item_id,
    request_item_spec_id, spec_key, display_name_fa, display_name_en,
    data_type, unit, offered_value, min_value, max_value,
    compliance_status, deviation_text, sort_order, notes,
    created_by, updated_by
  ) values (
    v_tenant, v_org, v_supplier, v_offer_id, p_offer_item_id,
    p_request_item_spec_id, p_spec_key, p_display_name_fa, p_display_name_en,
    p_data_type, p_unit, p_offered_value, p_min_value, p_max_value,
    p_compliance_status, p_deviation_text, coalesce(p_sort_order, 0), p_notes,
    v_actor, v_actor
  )
  on conflict (offer_item_id, spec_key) where deleted_at is null
  do update set
    request_item_spec_id = excluded.request_item_spec_id,
    display_name_fa      = excluded.display_name_fa,
    display_name_en      = excluded.display_name_en,
    data_type            = excluded.data_type,
    unit                 = excluded.unit,
    offered_value        = excluded.offered_value,
    min_value            = excluded.min_value,
    max_value            = excluded.max_value,
    compliance_status    = excluded.compliance_status,
    deviation_text       = excluded.deviation_text,
    sort_order           = excluded.sort_order,
    notes                = excluded.notes,
    updated_by           = v_actor
  returning id into v_id;

  perform offer.fn_audit('offer.spec_response_upserted', v_offer_id,
    jsonb_build_object('spec_key', p_spec_key, 'response_id', v_id::text));
  return v_id;
end;
$$;

-- 6.6 supplier_remove_spec_response ----------------------------------------
create or replace function offer.supplier_remove_spec_response(p_response_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_offer_id uuid;
begin
  select offer_id into v_offer_id from offer.supplier_offer_item_specifications
   where id = p_response_id and deleted_at is null;
  if v_offer_id is null then
    raise exception 'offer: spec response not found' using errcode = 'P0002';
  end if;
  perform offer.fn_assert_offer_supplier_owned(v_offer_id);
  perform offer.fn_assert_offer_editable(v_offer_id);

  update offer.supplier_offer_item_specifications
     set deleted_at = now(), updated_by = v_actor
   where id = p_response_id;

  perform offer.fn_audit('offer.spec_response_removed', v_offer_id,
    jsonb_build_object('response_id', p_response_id::text));
end;
$$;

-- 6.7 supplier_upsert_doc_commitment ---------------------------------------
create or replace function offer.supplier_upsert_doc_commitment(
  p_offer_id              uuid,
  p_offer_item_id         uuid default null,
  p_document_kind         commodity.document_kind default 'other',
  p_commitment_status     offer.commitment_status default 'committed',
  p_expected_available_date date default null,
  p_request_doc_req_id    uuid default null,
  p_notes                 text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_supplier uuid;
  v_tenant uuid;
  v_org uuid;
  v_request_id uuid;
  v_dr_request_id uuid;
  v_offer_item_offer uuid;
  v_id uuid;
begin
  perform offer.fn_assert_offer_supplier_owned(p_offer_id);
  perform offer.fn_assert_offer_editable(p_offer_id);

  select tenant_id, organization_id, supplier_id, request_id
    into v_tenant, v_org, v_supplier, v_request_id
    from offer.supplier_offers where id = p_offer_id;

  if p_offer_item_id is not null then
    select offer_id into v_offer_item_offer from offer.supplier_offer_items
     where id = p_offer_item_id and deleted_at is null;
    if v_offer_item_offer <> p_offer_id then
      raise exception 'offer: offer item does not belong to this offer' using errcode = '42501';
    end if;
  end if;

  -- Cross-RFQ integrity: rfq doc requirement must belong to the same RFQ.
  if p_request_doc_req_id is not null then
    select request_id into v_dr_request_id from rfq.request_document_requirements
     where id = p_request_doc_req_id and deleted_at is null;
    if v_dr_request_id is null then
      raise exception 'offer: rfq doc requirement not found' using errcode = 'P0002';
    end if;
    if v_dr_request_id <> v_request_id then
      raise exception 'offer: rfq doc requirement belongs to a different RFQ'
        using errcode = '42501';
    end if;
  end if;

  -- Try update existing active row (handles re-add after soft-remove).
  if p_offer_item_id is null then
    update offer.supplier_offer_document_commitments
       set commitment_status       = p_commitment_status,
           expected_available_date = p_expected_available_date,
           request_doc_req_id      = coalesce(p_request_doc_req_id, request_doc_req_id),
           notes                   = p_notes,
           deleted_at              = null,
           updated_by              = v_actor
     where offer_id = p_offer_id
       and offer_item_id is null
       and document_kind = p_document_kind
    returning id into v_id;
  else
    update offer.supplier_offer_document_commitments
       set commitment_status       = p_commitment_status,
           expected_available_date = p_expected_available_date,
           request_doc_req_id      = coalesce(p_request_doc_req_id, request_doc_req_id),
           notes                   = p_notes,
           deleted_at              = null,
           updated_by              = v_actor
     where offer_item_id = p_offer_item_id
       and document_kind = p_document_kind
    returning id into v_id;
  end if;

  if v_id is null then
    insert into offer.supplier_offer_document_commitments (
      tenant_id, organization_id, supplier_id, offer_id, offer_item_id,
      request_doc_req_id, document_kind, commitment_status,
      expected_available_date, notes, created_by, updated_by
    ) values (
      v_tenant, v_org, v_supplier, p_offer_id, p_offer_item_id,
      p_request_doc_req_id, p_document_kind, p_commitment_status,
      p_expected_available_date, p_notes, v_actor, v_actor
    ) returning id into v_id;
  end if;

  perform offer.fn_audit('offer.doc_commitment_upserted', p_offer_id,
    jsonb_build_object('commitment_id', v_id::text,
                       'document_kind', p_document_kind::text));
  return v_id;
end;
$$;

-- 6.8 supplier_remove_doc_commitment ---------------------------------------
create or replace function offer.supplier_remove_doc_commitment(p_commitment_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_offer_id uuid;
begin
  select offer_id into v_offer_id from offer.supplier_offer_document_commitments
   where id = p_commitment_id and deleted_at is null;
  if v_offer_id is null then
    raise exception 'offer: doc commitment not found' using errcode = 'P0002';
  end if;
  perform offer.fn_assert_offer_supplier_owned(v_offer_id);
  perform offer.fn_assert_offer_editable(v_offer_id);

  update offer.supplier_offer_document_commitments
     set deleted_at = now(), updated_by = v_actor
   where id = p_commitment_id;

  perform offer.fn_audit('offer.doc_commitment_removed', v_offer_id,
    jsonb_build_object('commitment_id', p_commitment_id::text));
end;
$$;

-- 6.9 supplier_submit_my_offer : draft → submitted -------------------------
create or replace function offer.supplier_submit_my_offer(p_offer_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status offer.offer_status;
  v_actor uuid := auth.uid();
begin
  perform offer.fn_assert_offer_supplier_owned(p_offer_id);
  select status into v_status from offer.supplier_offers where id = p_offer_id;
  if v_status <> 'draft' then
    raise exception 'offer: invalid_transition: cannot submit from %', v_status
      using errcode = 'P0001';
  end if;

  update offer.supplier_offers
     set status       = 'submitted',
         submitted_at = now(),
         submitted_by = v_actor,
         updated_by   = v_actor
   where id = p_offer_id;

  perform offer.fn_record_status_event(p_offer_id, 'draft', 'submitted', 'supplier_submit');
  perform offer.fn_audit('offer.submitted', p_offer_id);
end;
$$;

-- 6.10 supplier_withdraw_my_offer : submitted/shortlisted → withdrawn ------
create or replace function offer.supplier_withdraw_my_offer(
  p_offer_id uuid,
  p_reason   text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status offer.offer_status;
  v_actor uuid := auth.uid();
begin
  perform offer.fn_assert_offer_supplier_owned(p_offer_id);
  select status into v_status from offer.supplier_offers where id = p_offer_id;
  if v_status not in ('draft', 'submitted', 'shortlisted') then
    raise exception 'offer: invalid_transition: cannot withdraw from %', v_status
      using errcode = 'P0001';
  end if;

  -- Soft-delete so the unique-active index frees up for a new offer.
  update offer.supplier_offers
     set status           = 'withdrawn',
         withdrawn_at     = now(),
         withdrawn_by     = v_actor,
         withdrawn_reason = p_reason,
         deleted_at       = now(),
         updated_by       = v_actor
   where id = p_offer_id;

  perform offer.fn_record_status_event(p_offer_id, v_status, 'withdrawn',
    coalesce(p_reason, 'supplier_withdraw'));
  perform offer.fn_audit('offer.withdrawn', p_offer_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.11 supplier_list_my_offers ---------------------------------------------
create or replace function offer.supplier_list_my_offers(
  p_status offer.offer_status default null,
  p_limit  integer             default 25,
  p_offset integer             default 0
) returns table (
  id uuid, offer_code text, status text, request_id uuid, rfq_code text,
  rfq_title text, currency text, validity_until timestamptz,
  item_count bigint, submitted_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select so.id, so.offer_code, so.status::text,
           so.request_id, r.rfq_code::text, r.title,
           so.currency, so.validity_until,
           (select count(*) from offer.supplier_offer_items oi
             where oi.offer_id = so.id and oi.deleted_at is null),
           so.submitted_at, so.updated_at
      from offer.supplier_offers so
      join rfq.requests r on r.id = so.request_id
     where so.supplier_id = v_supplier
       and so.deleted_at is null
       and (p_status is null or so.status = p_status)
     order by so.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.12 supplier_get_my_offer -----------------------------------------------
create or replace function offer.supplier_get_my_offer(p_offer_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_supplier uuid := supplier.fn_portal_supplier_id();
  v_owner uuid;
begin
  select supplier_id into v_owner from offer.supplier_offers
   where id = p_offer_id and deleted_at is null;
  if v_owner is null then
    raise exception 'offer: not found' using errcode = 'P0002';
  end if;
  if v_owner <> v_supplier and not identity.is_platform_admin() then
    raise exception 'offer: caller does not own this offer' using errcode = '42501';
  end if;

  return (
    select jsonb_build_object(
      'id', so.id, 'offer_code', so.offer_code, 'status', so.status,
      'request_id', so.request_id,
      'currency', so.currency, 'incoterm', so.incoterm,
      'delivery_country', so.delivery_country, 'delivery_city', so.delivery_city,
      'delivery_port', so.delivery_port,
      'delivery_location_text', so.delivery_location_text,
      'delivery_lead_time_text', so.delivery_lead_time_text,
      'payment_terms_text', so.payment_terms_text,
      'validity_until', so.validity_until,
      'supplier_notes', so.supplier_notes,
      'submitted_at', so.submitted_at,
      'created_at', so.created_at, 'updated_at', so.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', i.id, 'request_item_id', i.request_item_id, 'product_id', i.product_id,
          'offered_quantity', i.offered_quantity, 'quantity_unit', i.quantity_unit,
          'unit_price', i.unit_price, 'total_price', i.total_price,
          'currency', i.currency, 'packaging', i.packaging,
          'origin_country', i.origin_country, 'origin_city', i.origin_city,
          'delivery_window_start', i.delivery_window_start,
          'delivery_window_end', i.delivery_window_end,
          'delivery_lead_time_text', i.delivery_lead_time_text,
          'notes', i.notes
        ) order by i.sort_order), '[]'::jsonb)
          from offer.supplier_offer_items i
         where i.offer_id = so.id and i.deleted_at is null
      ),
      'spec_responses', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', s.id, 'offer_item_id', s.offer_item_id,
          'request_item_spec_id', s.request_item_spec_id,
          'spec_key', s.spec_key, 'data_type', s.data_type, 'unit', s.unit,
          'offered_value', s.offered_value, 'min_value', s.min_value, 'max_value', s.max_value,
          'compliance_status', s.compliance_status, 'deviation_text', s.deviation_text
        ) order by s.sort_order), '[]'::jsonb)
          from offer.supplier_offer_item_specifications s
         where s.offer_id = so.id and s.deleted_at is null
      ),
      'document_commitments', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', c.id, 'offer_item_id', c.offer_item_id,
          'request_doc_req_id', c.request_doc_req_id,
          'document_kind', c.document_kind,
          'commitment_status', c.commitment_status,
          'expected_available_date', c.expected_available_date,
          'notes', c.notes
        )), '[]'::jsonb)
          from offer.supplier_offer_document_commitments c
         where c.offer_id = so.id and c.deleted_at is null
      )
    )
    from offer.supplier_offers so where so.id = p_offer_id
  );
end;
$$;

-- ===========================================================================
-- 7. Buyer RPCs (2 — read-only)
-- ===========================================================================

-- 7.1 buyer_list_received_offers -------------------------------------------
create or replace function offer.buyer_list_received_offers(
  p_request_id uuid              default null,
  p_status     offer.offer_status default null,
  p_limit      integer            default 25,
  p_offset     integer            default 0
) returns table (
  id uuid, offer_code text, status text,
  request_id uuid, rfq_code text, rfq_title text,
  supplier_id uuid, supplier_org_id uuid,
  currency text, validity_until timestamptz,
  item_count bigint, submitted_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer_org uuid := identity.current_organization_id();
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'offer: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_buyer_org is null then
    raise exception 'offer: no active organization in JWT' using errcode = 'P0002';
  end if;

  return query
    select so.id, so.offer_code, so.status::text,
           so.request_id, r.rfq_code::text, r.title,
           so.supplier_id, so.organization_id,
           so.currency, so.validity_until,
           (select count(*) from offer.supplier_offer_items oi
             where oi.offer_id = so.id and oi.deleted_at is null),
           so.submitted_at, so.updated_at
      from offer.supplier_offers so
      join rfq.requests r on r.id = so.request_id
     where so.deleted_at is null
       and r.organization_id = v_buyer_org
       and (p_request_id is null or so.request_id = p_request_id)
       and (p_status     is null or so.status     = p_status)
     order by so.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 buyer_get_offer ------------------------------------------------------
create or replace function offer.buyer_get_offer(p_offer_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer_org uuid := identity.current_organization_id();
  v_rfq_org uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'offer: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;

  select r.organization_id into v_rfq_org
    from offer.supplier_offers so
    join rfq.requests r on r.id = so.request_id
   where so.id = p_offer_id and so.deleted_at is null;
  if v_rfq_org is null then
    raise exception 'offer: not found' using errcode = 'P0002';
  end if;
  if v_rfq_org <> v_buyer_org and not identity.is_platform_admin() then
    raise exception 'offer: not visible to caller organization' using errcode = '42501';
  end if;

  return (
    select jsonb_build_object(
      'id', so.id, 'offer_code', so.offer_code, 'status', so.status,
      'request_id', so.request_id, 'supplier_id', so.supplier_id,
      'currency', so.currency, 'incoterm', so.incoterm,
      'delivery_country', so.delivery_country, 'delivery_city', so.delivery_city,
      'delivery_port', so.delivery_port, 'delivery_lead_time_text', so.delivery_lead_time_text,
      'payment_terms_text', so.payment_terms_text,
      'validity_until', so.validity_until,
      'submitted_at', so.submitted_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', i.id, 'request_item_id', i.request_item_id, 'product_id', i.product_id,
          'offered_quantity', i.offered_quantity, 'quantity_unit', i.quantity_unit,
          'unit_price', i.unit_price, 'total_price', i.total_price,
          'currency', i.currency, 'packaging', i.packaging,
          'origin_country', i.origin_country, 'origin_city', i.origin_city,
          'notes', i.notes
        ) order by i.sort_order), '[]'::jsonb)
          from offer.supplier_offer_items i
         where i.offer_id = so.id and i.deleted_at is null
      ),
      'spec_responses', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', s.id, 'offer_item_id', s.offer_item_id,
          'spec_key', s.spec_key, 'offered_value', s.offered_value,
          'compliance_status', s.compliance_status, 'deviation_text', s.deviation_text
        ) order by s.sort_order), '[]'::jsonb)
          from offer.supplier_offer_item_specifications s
         where s.offer_id = so.id and s.deleted_at is null
      ),
      'document_commitments', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', c.id, 'document_kind', c.document_kind,
          'commitment_status', c.commitment_status,
          'expected_available_date', c.expected_available_date
        )), '[]'::jsonb)
          from offer.supplier_offer_document_commitments c
         where c.offer_id = so.id and c.deleted_at is null
      )
    )
    from offer.supplier_offers so where so.id = p_offer_id
  );
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (4)
-- ===========================================================================

-- 8.1 admin_list_offers ----------------------------------------------------
create or replace function offer.admin_list_offers(
  p_status      offer.offer_status default null,
  p_request_id  uuid               default null,
  p_supplier_id uuid               default null,
  p_limit       integer            default 25,
  p_offset      integer            default 0
) returns table (
  id uuid, offer_code text, status text,
  request_id uuid, supplier_id uuid, organization_id uuid,
  currency text, submitted_at timestamptz, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_offers: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select so.id, so.offer_code, so.status::text,
           so.request_id, so.supplier_id, so.organization_id,
           so.currency, so.submitted_at, so.created_at
      from offer.supplier_offers so
     where so.deleted_at is null
       and (p_status      is null or so.status      = p_status)
       and (p_request_id  is null or so.request_id  = p_request_id)
       and (p_supplier_id is null or so.supplier_id = p_supplier_id)
     order by so.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_offer ------------------------------------------------------
create or replace function offer.admin_get_offer(p_offer_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_offer: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', so.id, 'offer_code', so.offer_code, 'status', so.status,
      'request_id', so.request_id, 'supplier_id', so.supplier_id,
      'organization_id', so.organization_id,
      'currency', so.currency, 'submitted_at', so.submitted_at,
      'created_at', so.created_at, 'updated_at', so.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', i.id, 'request_item_id', i.request_item_id,
          'unit_price', i.unit_price, 'total_price', i.total_price
        )), '[]'::jsonb)
          from offer.supplier_offer_items i
         where i.offer_id = so.id and i.deleted_at is null
      ),
      'status_events', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'from_status', e.from_status, 'to_status', e.to_status,
          'actor_user_id', e.actor_user_id, 'reason', e.reason,
          'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from offer.supplier_offer_status_events e where e.offer_id = so.id
      )
    )
    from offer.supplier_offers so where so.id = p_offer_id
  );
end;
$$;

-- 8.3 admin_force_status_change --------------------------------------------
create or replace function offer.admin_force_status_change(
  p_offer_id uuid,
  p_status   offer.offer_status,
  p_reason   text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current offer.offer_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_status_change: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from offer.supplier_offers where id = p_offer_id;
  if v_current is null then
    raise exception 'offer: not found' using errcode = 'P0002';
  end if;
  if v_current = p_status then
    return;
  end if;

  update offer.supplier_offers
     set status         = p_status,
         rejected_at    = case when p_status = 'rejected'    then now() else rejected_at end,
         rejected_by    = case when p_status = 'rejected'    then v_actor else rejected_by end,
         rejected_reason= case when p_status = 'rejected'    then p_reason else rejected_reason end,
         shortlisted_at = case when p_status = 'shortlisted' then now() else shortlisted_at end,
         shortlisted_by = case when p_status = 'shortlisted' then v_actor else shortlisted_by end,
         accepted_at    = case when p_status = 'accepted'    then now() else accepted_at end,
         accepted_by    = case when p_status = 'accepted'    then v_actor else accepted_by end,
         updated_by     = v_actor
   where id = p_offer_id;

  perform offer.fn_record_status_event(p_offer_id, v_current, p_status,
    coalesce(p_reason, 'admin_force_status_change'));
  perform offer.fn_audit('offer.admin_status_change', p_offer_id,
    jsonb_build_object('from', v_current::text, 'to', p_status::text, 'reason', p_reason));
end;
$$;

-- 8.4 admin_list_offer_status_events ---------------------------------------
create or replace function offer.admin_list_offer_status_events(p_offer_id uuid)
returns table (
  id uuid, from_status text, to_status text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_offer_status_events: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from offer.supplier_offer_status_events e
     where e.offer_id = p_offer_id
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
     where t.table_schema = 'offer'
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
     where t.table_schema = 'offer'
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
grant select on offer.supplier_offers                     to anon, authenticated;
grant select on offer.supplier_offer_items                to anon, authenticated;
grant select on offer.supplier_offer_item_specifications  to anon, authenticated;
grant select on offer.supplier_offer_document_commitments to anon, authenticated;
grant select on offer.supplier_offer_status_events        to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function offer.supplier_create_draft_offer(
  uuid, text, text, char, text, text, text, text, text, timestamptz, text
) to authenticated;

grant execute on function offer.supplier_update_my_offer(
  uuid, text, text, char, text, text, text, text, text, timestamptz, text
) to authenticated;

grant execute on function offer.supplier_upsert_offer_item(
  uuid, uuid, uuid, numeric, text, numeric, numeric, text, text, char, text,
  date, date, text, text, integer
) to authenticated;

grant execute on function offer.supplier_remove_offer_item(uuid) to authenticated;

grant execute on function offer.supplier_upsert_spec_response(
  uuid, text, text, text, commodity.spec_data_type, text, text,
  numeric, numeric, offer.compliance_status, text, uuid, integer, text
) to authenticated;

grant execute on function offer.supplier_remove_spec_response(uuid) to authenticated;

grant execute on function offer.supplier_upsert_doc_commitment(
  uuid, uuid, commodity.document_kind, offer.commitment_status, date, uuid, text
) to authenticated;

grant execute on function offer.supplier_remove_doc_commitment(uuid) to authenticated;

grant execute on function offer.supplier_submit_my_offer(uuid) to authenticated;
grant execute on function offer.supplier_withdraw_my_offer(uuid, text) to authenticated;
grant execute on function offer.supplier_list_my_offers(
  offer.offer_status, integer, integer
) to authenticated;
grant execute on function offer.supplier_get_my_offer(uuid) to authenticated;

grant execute on function offer.buyer_list_received_offers(
  uuid, offer.offer_status, integer, integer
) to authenticated;
grant execute on function offer.buyer_get_offer(uuid) to authenticated;

grant execute on function offer.admin_list_offers(
  offer.offer_status, uuid, uuid, integer, integer
) to authenticated;
grant execute on function offer.admin_get_offer(uuid) to authenticated;
grant execute on function offer.admin_force_status_change(
  uuid, offer.offer_status, text
) to authenticated;
grant execute on function offer.admin_list_offer_status_events(uuid) to authenticated;
