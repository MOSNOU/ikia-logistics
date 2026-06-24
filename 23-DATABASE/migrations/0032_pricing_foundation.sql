-- CC-23 / Migration 0032 — Pricing & Quotation Foundation
-- Fifteenth business-domain step. New `pricing` schema atop CC-22 (kyc).
-- Append-only over migrations 0001-0031. Strictly additive — does not modify
-- any prior table, RPC body, grant, trigger, or seed.
--
-- Locked decisions (Q1–Q10):
--   Q1=A   single migration (schema + RPCs + RLS in one file).
--   Q2=Yes pricing exposed via PostgREST (config.toml updated alongside).
--   Q3=A   currency seed: IRR, USD, EUR.
--   Q4=A   currency_rates uniqueness: (base, quote, effective_from) — append-only.
--   Q5=A   free-text `source` on currency_rates and discount sources.
--   Q6=A   admin-only quote_captures write path (admin_capture_quote RPC).
--   Q7=A   discount_rules is a catalog only — informational, not auto-applied.
--   Q8=A   no KYC gating on portal_send_quotation.
--   Q9=A   no notify wiring for quotation events; notify schema untouched.
--   Q10=A  no UI deliverable; schema spine only.
--
-- Out-of-scope (literal "Do Not Build" — see CC-23 draft §9):
--   - Real FX provider integration. Rates are admin-entered manually.
--   - Tax / VAT / withholding engine.
--   - Payment / PSP / banking / payment gateway.
--   - Automatic discount application onto live offers or contracts.
--   - Modification to offer.*, contract.*, supplier.*, commodity.*, notify.*,
--     finance.*, settlement.*, dispute.*, kyc.* RPC bodies.
--   - notify.fn_resolve_recipients extension (Q9=A).
--   - KYC hard gating (Q8=A).
--   - UI / mobile / webhooks / scheduled jobs.
--
-- Security model: SECURITY DEFINER RPCs only; no direct DML grants on tables;
-- search_path=''. Portal RPCs derive identity from auth.uid(); admin RPCs
-- check identity.is_platform_admin() inside body.

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists pricing;
grant usage on schema pricing to anon, authenticated, service_role;
comment on schema pricing is
  'iKIA Phase 2 — pricing & quotation foundation. Standing supplier price lists, '
  'formal quotations, currency / FX rates, discount-rule catalog, immutable quote '
  'captures, append-only pricing events. No automatic discount application; no '
  'FX provider; no tax engine.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type pricing.price_list_status as enum (
  'draft', 'active', 'paused', 'archived'
);

create type pricing.quotation_status as enum (
  'draft', 'sent', 'accepted', 'rejected', 'expired', 'withdrawn'
);

create type pricing.quote_capture_kind as enum (
  'offer_submission', 'contract_execution', 'manual_audit'
);

create type pricing.discount_kind as enum (
  'volume_tier', 'contract_term', 'manual'
);

create type pricing.discount_application as enum (
  'percent_off', 'fixed_amount_off', 'unit_price_override'
);

create type pricing.pricing_event_kind as enum (
  'price_list_created', 'price_list_published', 'price_list_paused',
  'price_list_archived', 'price_list_item_updated',
  'quotation_drafted', 'quotation_sent', 'quotation_accepted',
  'quotation_rejected', 'quotation_expired', 'quotation_withdrawn',
  'quote_captured', 'currency_rate_set', 'discount_rule_published'
);

-- ===========================================================================
-- 3. Tables (8)
-- ===========================================================================

-- 3.1 currencies -----------------------------------------------------------
create table pricing.currencies (
  code               char(3) primary key,
  numeric_code       int,
  name_en            text not null,
  name_fa            text not null,
  minor_unit_digits  int not null default 2,
  is_active          boolean not null default true,
  created_at         timestamptz not null default now()
);

comment on table pricing.currencies is
  'ISO-4217 currencies the platform recognizes. Manually maintained in CC-23.';

-- 3.2 currency_rates -------------------------------------------------------
create table pricing.currency_rates (
  id                 uuid primary key default gen_random_uuid(),
  base_code          char(3) not null references pricing.currencies(code),
  quote_code         char(3) not null references pricing.currencies(code),
  rate               numeric(20, 10) not null check (rate > 0),
  effective_from     timestamptz not null,
  effective_to       timestamptz,
  source             text not null default 'manual',
  created_by         uuid references auth.users(id) on delete set null,
  created_at         timestamptz not null default now(),
  unique (base_code, quote_code, effective_from),
  check (base_code <> quote_code)
);

comment on table pricing.currency_rates is
  'FX rates (1 base = rate × quote). Q4=A: append-only with effective_from uniqueness.';

create index currency_rates_pair_idx
  on pricing.currency_rates(base_code, quote_code, effective_from desc);

-- 3.3 price_lists ----------------------------------------------------------
create table pricing.price_lists (
  id                 uuid primary key default gen_random_uuid(),
  tenant_id          uuid not null references identity.tenants(id) on delete restrict,
  supplier_id        uuid not null references supplier.suppliers(id) on delete cascade,
  organization_id    uuid not null references organization.organizations(id) on delete cascade,

  code               text not null,
  name_en            text not null,
  name_fa            text not null,
  description        text,
  currency_code      char(3) not null references pricing.currencies(code),
  status             pricing.price_list_status not null default 'draft',
  effective_from     timestamptz,
  effective_to       timestamptz,
  metadata           jsonb not null default '{}'::jsonb,

  created_by         uuid references auth.users(id) on delete set null,
  created_at         timestamptz not null default now(),
  updated_by         uuid references auth.users(id) on delete set null,
  updated_at         timestamptz not null default now(),
  deleted_at         timestamptz,
  version            integer not null default 1
);

comment on table pricing.price_lists is
  'Standing supplier price-list headers. One supplier may publish many lists '
  'over time; uniqueness on (tenant, supplier, lower(code)) among non-deleted rows.';

create unique index price_lists_unique_code
  on pricing.price_lists(tenant_id, supplier_id, lower(code))
  where deleted_at is null;
create index price_lists_supplier_idx
  on pricing.price_lists(supplier_id) where deleted_at is null;
create index price_lists_status_idx
  on pricing.price_lists(status) where deleted_at is null;
create index price_lists_tenant_idx
  on pricing.price_lists(tenant_id) where deleted_at is null;

-- 3.4 price_list_items -----------------------------------------------------
create table pricing.price_list_items (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  price_list_id       uuid not null references pricing.price_lists(id) on delete cascade,
  product_id          uuid not null references commodity.products(id) on delete restrict,
  unit_price          numeric(20, 4) not null check (unit_price >= 0),
  unit_of_measure     text not null,
  min_order_quantity  numeric(20, 4) check (min_order_quantity is null or min_order_quantity > 0),
  max_order_quantity  numeric(20, 4) check (max_order_quantity is null or max_order_quantity > 0),
  notes               text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  version             integer not null default 1,
  unique (price_list_id, product_id),
  check (
    max_order_quantity is null
    or min_order_quantity is null
    or max_order_quantity >= min_order_quantity
  )
);

comment on table pricing.price_list_items is
  'Per-product lines on a price list. Unit price is in the parent list currency.';

create index price_list_items_product_idx
  on pricing.price_list_items(product_id);

-- 3.5 quotations -----------------------------------------------------------
create table pricing.quotations (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete cascade,
  supplier_organization_id    uuid not null references organization.organizations(id) on delete cascade,
  buyer_organization_id       uuid not null references organization.organizations(id) on delete restrict,
  rfq_request_id              uuid references rfq.requests(id) on delete set null,

  quotation_code              text not null,
  currency_code               char(3) not null references pricing.currencies(code),
  status                      pricing.quotation_status not null default 'draft',
  valid_from                  timestamptz,
  valid_until                 timestamptz,

  subtotal_amount             numeric(20, 4) not null default 0,
  discount_amount             numeric(20, 4) not null default 0,
  total_amount                numeric(20, 4) not null default 0 check (total_amount >= 0),

  notes_en                    text,
  notes_fa                    text,
  sent_at                     timestamptz,
  responded_at                timestamptz,
  response_actor_user_id      uuid references auth.users(id) on delete set null,
  decision_reason             text,
  metadata                    jsonb not null default '{}'::jsonb,

  created_by                  uuid references auth.users(id) on delete set null,
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table pricing.quotations is
  'Formal supplier → buyer price quotation. May be standalone or tied to an RFQ.';

create unique index quotations_unique_code
  on pricing.quotations(tenant_id, supplier_id, lower(quotation_code))
  where deleted_at is null;
create index quotations_buyer_idx
  on pricing.quotations(buyer_organization_id) where deleted_at is null;
create index quotations_supplier_idx
  on pricing.quotations(supplier_id) where deleted_at is null;
create index quotations_status_idx
  on pricing.quotations(status) where deleted_at is null;
create index quotations_rfq_idx
  on pricing.quotations(rfq_request_id) where deleted_at is null and rfq_request_id is not null;
create index quotations_valid_until_idx
  on pricing.quotations(valid_until)
  where status = 'sent' and deleted_at is null;

-- 3.6 quotation_items ------------------------------------------------------
create table pricing.quotation_items (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  quotation_id        uuid not null references pricing.quotations(id) on delete cascade,
  product_id          uuid not null references commodity.products(id) on delete restrict,
  quantity            numeric(20, 4) not null check (quantity > 0),
  unit_of_measure     text not null,
  unit_price          numeric(20, 4) not null check (unit_price >= 0),
  line_total          numeric(20, 4) not null check (line_total >= 0),
  discount_amount     numeric(20, 4) not null default 0 check (discount_amount >= 0),
  notes               text,
  position            integer not null default 0,
  created_at          timestamptz not null default now()
);

comment on table pricing.quotation_items is
  'Per-product lines on a quotation. Inherits parent quotation currency.';

create index quotation_items_quotation_idx
  on pricing.quotation_items(quotation_id, position);
create index quotation_items_product_idx
  on pricing.quotation_items(product_id);

-- 3.7 discount_rules (catalog only — Q7=A) ----------------------------------
create table pricing.discount_rules (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  supplier_id         uuid not null references supplier.suppliers(id) on delete cascade,
  code                text not null,
  name_en             text not null,
  name_fa             text not null,
  kind                pricing.discount_kind not null,
  application         pricing.discount_application not null,
  threshold_qty       numeric(20, 4) check (threshold_qty is null or threshold_qty > 0),
  amount              numeric(20, 4) check (amount is null or amount >= 0),
  currency_code       char(3) references pricing.currencies(code),
  effective_from      timestamptz,
  effective_to        timestamptz,
  active              boolean not null default true,
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table pricing.discount_rules is
  'Discount rule catalog. Q7=A: informational only — not auto-applied to live offers / contracts in CC-23.';

create unique index discount_rules_unique_code
  on pricing.discount_rules(tenant_id, supplier_id, lower(code))
  where deleted_at is null;
create index discount_rules_supplier_idx
  on pricing.discount_rules(supplier_id) where deleted_at is null;

-- 3.8 quote_captures (immutable price snapshots) ---------------------------
create table pricing.quote_captures (
  id                            uuid primary key default gen_random_uuid(),
  tenant_id                     uuid not null references identity.tenants(id) on delete restrict,
  kind                          pricing.quote_capture_kind not null,
  supplier_id                   uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id      uuid not null references organization.organizations(id) on delete restrict,
  buyer_organization_id         uuid not null references organization.organizations(id) on delete restrict,
  source_supplier_offer_id      uuid references offer.supplier_offers(id) on delete set null,
  source_executed_contract_id   uuid references contract.executed_contracts(id) on delete set null,
  source_quotation_id           uuid references pricing.quotations(id) on delete set null,
  currency_code                 char(3) not null references pricing.currencies(code),
  snapshot                      jsonb not null,
  captured_at                   timestamptz not null default now(),
  captured_by                   uuid references auth.users(id) on delete set null
);

comment on table pricing.quote_captures is
  'Immutable frozen-price snapshots taken at upstream events. INSERT only via '
  'pricing.admin_capture_quote; UPDATE / DELETE forbidden by absence of grants.';

create index quote_captures_supplier_idx
  on pricing.quote_captures(supplier_id, captured_at desc);
create index quote_captures_buyer_idx
  on pricing.quote_captures(buyer_organization_id, captured_at desc);
create index quote_captures_offer_idx
  on pricing.quote_captures(source_supplier_offer_id) where source_supplier_offer_id is not null;
create index quote_captures_contract_idx
  on pricing.quote_captures(source_executed_contract_id) where source_executed_contract_id is not null;
create index quote_captures_quotation_idx
  on pricing.quote_captures(source_quotation_id) where source_quotation_id is not null;

-- 3.9 events (append-only ledger) ------------------------------------------
create table pricing.events (
  id                            uuid primary key default gen_random_uuid(),
  tenant_id                     uuid not null references identity.tenants(id) on delete restrict,
  event_kind                    pricing.pricing_event_kind not null,
  price_list_id                 uuid,
  quotation_id                  uuid,
  discount_rule_id              uuid,
  actor_user_id                 uuid references auth.users(id) on delete set null,
  payload                       jsonb not null default '{}'::jsonb,
  occurred_at                   timestamptz not null default now()
);

comment on table pricing.events is
  'Pricing-domain immutable event ledger. UPDATE / DELETE forbidden.';

create index pricing_events_price_list_idx
  on pricing.events(price_list_id, occurred_at desc);
create index pricing_events_quotation_idx
  on pricing.events(quotation_id, occurred_at desc);
create index pricing_events_actor_idx
  on pricing.events(actor_user_id, occurred_at desc);
create index pricing_events_kind_idx
  on pricing.events(event_kind, occurred_at desc);

-- ===========================================================================
-- 4. Row Level Security
-- ===========================================================================
alter table pricing.currencies          enable row level security;
alter table pricing.currency_rates      enable row level security;
alter table pricing.price_lists         enable row level security;
alter table pricing.price_list_items    enable row level security;
alter table pricing.quotations          enable row level security;
alter table pricing.quotation_items     enable row level security;
alter table pricing.discount_rules      enable row level security;
alter table pricing.quote_captures      enable row level security;
alter table pricing.events              enable row level security;

-- 4.1 currencies / currency_rates: everyone authenticated can read.
drop policy if exists currencies_select on pricing.currencies;
create policy currencies_select on pricing.currencies
  for select
  using (identity.current_user_id() is not null);

drop policy if exists currencies_admin_modify on pricing.currencies;
create policy currencies_admin_modify on pricing.currencies
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

drop policy if exists currency_rates_select on pricing.currency_rates;
create policy currency_rates_select on pricing.currency_rates
  for select
  using (identity.current_user_id() is not null);

drop policy if exists currency_rates_admin_modify on pricing.currency_rates;
create policy currency_rates_admin_modify on pricing.currency_rates
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.2 price_lists: supplier-org member sees own; admin sees all.
drop policy if exists price_lists_select on pricing.price_lists;
create policy price_lists_select on pricing.price_lists
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = price_lists.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists price_lists_admin_modify on pricing.price_lists;
create policy price_lists_admin_modify on pricing.price_lists
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.3 price_list_items: inherit parent visibility.
drop policy if exists price_list_items_select on pricing.price_list_items;
create policy price_list_items_select on pricing.price_list_items
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1
        from pricing.price_lists pl
        join organization.memberships m on m.organization_id = pl.organization_id
       where pl.id = price_list_items.price_list_id
         and pl.deleted_at is null
         and m.user_id = identity.current_user_id()
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

drop policy if exists price_list_items_admin_modify on pricing.price_list_items;
create policy price_list_items_admin_modify on pricing.price_list_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.4 quotations: supplier-org member OR buyer-org member sees own; admin sees all.
drop policy if exists quotations_select on pricing.quotations;
create policy quotations_select on pricing.quotations
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.deleted_at is null
           and m.status = 'active'
           and m.organization_id in (
             quotations.supplier_organization_id,
             quotations.buyer_organization_id
           )
      )
    )
  );

drop policy if exists quotations_admin_modify on pricing.quotations;
create policy quotations_admin_modify on pricing.quotations
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.5 quotation_items: parent-scoped.
drop policy if exists quotation_items_select on pricing.quotation_items;
create policy quotation_items_select on pricing.quotation_items
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1
        from pricing.quotations q
        join organization.memberships m
          on m.organization_id in (q.supplier_organization_id, q.buyer_organization_id)
       where q.id = quotation_items.quotation_id
         and q.deleted_at is null
         and m.user_id = identity.current_user_id()
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

drop policy if exists quotation_items_admin_modify on pricing.quotation_items;
create policy quotation_items_admin_modify on pricing.quotation_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.6 discount_rules: supplier-org member + admin.
drop policy if exists discount_rules_select on pricing.discount_rules;
create policy discount_rules_select on pricing.discount_rules
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1
          from supplier.suppliers s
          join organization.memberships m on m.organization_id = s.organization_id
         where s.id = discount_rules.supplier_id
           and m.user_id = identity.current_user_id()
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists discount_rules_admin_modify on pricing.discount_rules;
create policy discount_rules_admin_modify on pricing.discount_rules
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.7 quote_captures: supplier-org OR buyer-org member + admin.
drop policy if exists quote_captures_select on pricing.quote_captures;
create policy quote_captures_select on pricing.quote_captures
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.deleted_at is null
         and m.status = 'active'
         and m.organization_id in (
           quote_captures.supplier_organization_id,
           quote_captures.buyer_organization_id
         )
    )
  );

-- 4.8 events: actor's org members + admin.
drop policy if exists events_select on pricing.events;
create policy events_select on pricing.events
  for select
  using (
    identity.is_platform_admin()
    or actor_user_id = identity.current_user_id()
  );

-- ===========================================================================
-- 5. Internal helpers
-- ===========================================================================

-- 5.1 fn_audit -------------------------------------------------------------
create or replace function pricing.fn_audit(
  p_action_code text,
  p_resource_id uuid,
  p_tenant_id   uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  insert into audit.audit_event (
    tenant_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    p_tenant_id, auth.uid(), p_action_code,
    'pricing', p_resource_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 5.2 fn_record_event ------------------------------------------------------
create or replace function pricing.fn_record_event(
  p_tenant_id        uuid,
  p_event_kind       pricing.pricing_event_kind,
  p_price_list_id    uuid,
  p_quotation_id     uuid,
  p_discount_rule_id uuid,
  p_payload          jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  insert into pricing.events (
    tenant_id, event_kind, price_list_id, quotation_id, discount_rule_id,
    actor_user_id, payload, occurred_at
  ) values (
    p_tenant_id, p_event_kind, p_price_list_id, p_quotation_id, p_discount_rule_id,
    auth.uid(), coalesce(p_payload, '{}'::jsonb), now()
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 5.3 fn_assert_admin ------------------------------------------------------
create or replace function pricing.fn_assert_admin() returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'pricing: requires platform_admin' using errcode = '42501';
  end if;
end;
$$;

-- 5.4 fn_assert_supplier_member --------------------------------------------
-- Verifies caller is an active member of the supplier's organization.
create or replace function pricing.fn_assert_supplier_member(
  p_supplier_id uuid
) returns supplier.suppliers
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_sup supplier.suppliers%rowtype;
  v_ok  boolean;
begin
  select * into v_sup from supplier.suppliers
   where id = p_supplier_id and deleted_at is null;
  if v_sup.id is null then
    raise exception 'pricing: supplier not found' using errcode = 'P0002';
  end if;
  select exists (
    select 1
      from organization.memberships m
      join identity.roles r on r.id = m.role_id
     where m.organization_id = v_sup.organization_id
       and m.user_id = auth.uid()
       and m.deleted_at is null
       and m.status = 'active'
       and r.code in (
         'organization_admin', 'supplier_admin', 'buyer_admin',
         'carrier_admin', 'compliance_officer', 'operations_user'
       )
  ) into v_ok;
  if not v_ok then
    raise exception 'pricing: not authorized for this supplier' using errcode = '42501';
  end if;
  return v_sup;
end;
$$;

-- 5.5 fn_assert_buyer_member -----------------------------------------------
create or replace function pricing.fn_assert_buyer_member(
  p_organization_id uuid
) returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_ok boolean;
begin
  select exists (
    select 1 from organization.memberships m
     where m.organization_id = p_organization_id
       and m.user_id = auth.uid()
       and m.deleted_at is null
       and m.status = 'active'
  ) into v_ok;
  if not v_ok then
    raise exception 'pricing: not authorized for this organization' using errcode = '42501';
  end if;
end;
$$;

-- ===========================================================================
-- 6. Supplier portal RPCs
-- ===========================================================================

-- 6.1 portal_create_price_list ---------------------------------------------
create or replace function pricing.portal_create_price_list(
  p_supplier_id    uuid,
  p_code           text,
  p_name_en        text,
  p_name_fa        text,
  p_currency_code  char(3),
  p_description    text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_sup supplier.suppliers%rowtype;
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  if p_code is null or btrim(p_code) = '' then
    raise exception 'pricing: code is required' using errcode = '22023';
  end if;
  v_sup := pricing.fn_assert_supplier_member(p_supplier_id);

  if not exists (select 1 from pricing.currencies where code = p_currency_code and is_active) then
    raise exception 'pricing: currency % is not active', p_currency_code using errcode = '22023';
  end if;

  insert into pricing.price_lists (
    tenant_id, supplier_id, organization_id, code,
    name_en, name_fa, description, currency_code, status,
    created_by, updated_by
  ) values (
    v_sup.tenant_id, p_supplier_id, v_sup.organization_id, p_code,
    p_name_en, p_name_fa, p_description, p_currency_code, 'draft',
    v_uid, v_uid
  ) returning id into v_id;

  perform pricing.fn_record_event(
    v_sup.tenant_id, 'price_list_created', v_id, null, null,
    jsonb_build_object('supplier_id', p_supplier_id, 'code', p_code)
  );
  perform pricing.fn_audit('pricing.price_list.created', v_id, v_sup.tenant_id,
                          jsonb_build_object('supplier_id', p_supplier_id));
  return v_id;
end;
$$;

-- 6.2 portal_upsert_price_list_item ----------------------------------------
create or replace function pricing.portal_upsert_price_list_item(
  p_price_list_id  uuid,
  p_product_id     uuid,
  p_unit_price     numeric,
  p_uom            text,
  p_min_qty        numeric default null,
  p_max_qty        numeric default null,
  p_notes          text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_pl pricing.price_lists%rowtype;
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  select * into v_pl from pricing.price_lists where id = p_price_list_id and deleted_at is null;
  if v_pl.id is null then
    raise exception 'pricing: price list not found' using errcode = 'P0002';
  end if;
  if v_pl.status = 'archived' then
    raise exception 'pricing: cannot edit items on archived list' using errcode = '22023';
  end if;
  perform pricing.fn_assert_supplier_member(v_pl.supplier_id);

  insert into pricing.price_list_items (
    tenant_id, price_list_id, product_id,
    unit_price, unit_of_measure, min_order_quantity, max_order_quantity, notes
  ) values (
    v_pl.tenant_id, p_price_list_id, p_product_id,
    p_unit_price, p_uom, p_min_qty, p_max_qty, p_notes
  )
  on conflict (price_list_id, product_id) do update set
    unit_price          = excluded.unit_price,
    unit_of_measure     = excluded.unit_of_measure,
    min_order_quantity  = excluded.min_order_quantity,
    max_order_quantity  = excluded.max_order_quantity,
    notes               = excluded.notes,
    updated_at          = now(),
    version             = pricing.price_list_items.version + 1
  returning id into v_id;

  perform pricing.fn_record_event(
    v_pl.tenant_id, 'price_list_item_updated', p_price_list_id, null, null,
    jsonb_build_object('item_id', v_id, 'product_id', p_product_id,
                       'unit_price', p_unit_price)
  );
  return v_id;
end;
$$;

-- 6.3 portal_publish_price_list --------------------------------------------
create or replace function pricing.portal_publish_price_list(
  p_id              uuid,
  p_effective_from  timestamptz default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_pl pricing.price_lists%rowtype;
begin
  select * into v_pl from pricing.price_lists where id = p_id and deleted_at is null;
  if v_pl.id is null then
    raise exception 'pricing: price list not found' using errcode = 'P0002';
  end if;
  if v_pl.status <> 'draft' then
    raise exception 'pricing: cannot publish list in status %', v_pl.status using errcode = '22023';
  end if;
  perform pricing.fn_assert_supplier_member(v_pl.supplier_id);

  update pricing.price_lists
     set status         = 'active',
         effective_from = coalesce(p_effective_from, now()),
         updated_by     = auth.uid()
   where id = p_id;

  perform pricing.fn_record_event(
    v_pl.tenant_id, 'price_list_published', p_id, null, null,
    jsonb_build_object('effective_from', coalesce(p_effective_from, now()))
  );
  perform pricing.fn_audit('pricing.price_list.published', p_id, v_pl.tenant_id, '{}'::jsonb);
end;
$$;

-- 6.4 portal_pause_price_list ----------------------------------------------
create or replace function pricing.portal_pause_price_list(
  p_id     uuid,
  p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_pl pricing.price_lists%rowtype;
begin
  select * into v_pl from pricing.price_lists where id = p_id and deleted_at is null;
  if v_pl.id is null then
    raise exception 'pricing: price list not found' using errcode = 'P0002';
  end if;
  if v_pl.status <> 'active' then
    raise exception 'pricing: cannot pause list in status %', v_pl.status using errcode = '22023';
  end if;
  perform pricing.fn_assert_supplier_member(v_pl.supplier_id);

  update pricing.price_lists
     set status = 'paused', updated_by = auth.uid()
   where id = p_id;

  perform pricing.fn_record_event(
    v_pl.tenant_id, 'price_list_paused', p_id, null, null,
    jsonb_build_object('reason', p_reason)
  );
end;
$$;

-- 6.5 portal_archive_price_list --------------------------------------------
create or replace function pricing.portal_archive_price_list(
  p_id     uuid,
  p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_pl pricing.price_lists%rowtype;
begin
  select * into v_pl from pricing.price_lists where id = p_id and deleted_at is null;
  if v_pl.id is null then
    raise exception 'pricing: price list not found' using errcode = 'P0002';
  end if;
  if v_pl.status not in ('active', 'paused', 'draft') then
    raise exception 'pricing: cannot archive list in status %', v_pl.status using errcode = '22023';
  end if;
  perform pricing.fn_assert_supplier_member(v_pl.supplier_id);

  update pricing.price_lists
     set status = 'archived', updated_by = auth.uid()
   where id = p_id;

  perform pricing.fn_record_event(
    v_pl.tenant_id, 'price_list_archived', p_id, null, null,
    jsonb_build_object('reason', p_reason)
  );
  perform pricing.fn_audit('pricing.price_list.archived', p_id, v_pl.tenant_id, '{}'::jsonb);
end;
$$;

-- 6.6 portal_create_quotation ----------------------------------------------
create or replace function pricing.portal_create_quotation(
  p_supplier_id            uuid,
  p_buyer_organization_id  uuid,
  p_quotation_code         text,
  p_currency_code          char(3),
  p_rfq_request_id         uuid default null,
  p_valid_until            timestamptz default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_sup supplier.suppliers%rowtype;
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  if p_quotation_code is null or btrim(p_quotation_code) = '' then
    raise exception 'pricing: quotation_code is required' using errcode = '22023';
  end if;
  v_sup := pricing.fn_assert_supplier_member(p_supplier_id);

  if not exists (select 1 from pricing.currencies where code = p_currency_code and is_active) then
    raise exception 'pricing: currency % is not active', p_currency_code using errcode = '22023';
  end if;

  if not exists (
    select 1 from organization.organizations where id = p_buyer_organization_id and deleted_at is null
  ) then
    raise exception 'pricing: buyer organization not found' using errcode = 'P0002';
  end if;

  insert into pricing.quotations (
    tenant_id, supplier_id, supplier_organization_id, buyer_organization_id,
    rfq_request_id, quotation_code, currency_code, status,
    valid_from, valid_until, created_by, updated_by
  ) values (
    v_sup.tenant_id, p_supplier_id, v_sup.organization_id, p_buyer_organization_id,
    p_rfq_request_id, p_quotation_code, p_currency_code, 'draft',
    now(), p_valid_until, v_uid, v_uid
  ) returning id into v_id;

  perform pricing.fn_record_event(
    v_sup.tenant_id, 'quotation_drafted', null, v_id, null,
    jsonb_build_object('quotation_code', p_quotation_code,
                       'buyer_organization_id', p_buyer_organization_id)
  );
  perform pricing.fn_audit('pricing.quotation.drafted', v_id, v_sup.tenant_id, '{}'::jsonb);
  return v_id;
end;
$$;

-- 6.7 portal_add_quotation_item --------------------------------------------
create or replace function pricing.portal_add_quotation_item(
  p_quotation_id    uuid,
  p_product_id      uuid,
  p_quantity        numeric,
  p_uom             text,
  p_unit_price      numeric,
  p_discount_amount numeric default 0,
  p_notes           text default null,
  p_position        integer default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_q pricing.quotations%rowtype;
  v_uid uuid := auth.uid();
  v_id uuid;
  v_pos integer;
  v_line_total numeric(20,4);
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  select * into v_q from pricing.quotations where id = p_quotation_id and deleted_at is null;
  if v_q.id is null then
    raise exception 'pricing: quotation not found' using errcode = 'P0002';
  end if;
  if v_q.status <> 'draft' then
    raise exception 'pricing: cannot add items to quotation in status %', v_q.status
      using errcode = '22023';
  end if;
  perform pricing.fn_assert_supplier_member(v_q.supplier_id);

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'pricing: quantity must be > 0' using errcode = '22023';
  end if;
  if p_unit_price is null or p_unit_price < 0 then
    raise exception 'pricing: unit_price must be >= 0' using errcode = '22023';
  end if;

  select coalesce(p_position, coalesce(max(position), -1) + 1)
    into v_pos
    from pricing.quotation_items where quotation_id = p_quotation_id;

  v_line_total := (p_quantity * p_unit_price) - coalesce(p_discount_amount, 0);
  if v_line_total < 0 then
    raise exception 'pricing: line_total cannot be negative' using errcode = '22023';
  end if;

  insert into pricing.quotation_items (
    tenant_id, quotation_id, product_id, quantity, unit_of_measure,
    unit_price, line_total, discount_amount, notes, position
  ) values (
    v_q.tenant_id, p_quotation_id, p_product_id, p_quantity, p_uom,
    p_unit_price, v_line_total, coalesce(p_discount_amount, 0), p_notes, v_pos
  ) returning id into v_id;

  -- Recompute totals on parent.
  perform pricing.compute_quote_totals(p_quotation_id);
  return v_id;
end;
$$;

-- 6.8 portal_send_quotation ------------------------------------------------
create or replace function pricing.portal_send_quotation(p_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_q pricing.quotations%rowtype;
begin
  select * into v_q from pricing.quotations where id = p_id and deleted_at is null;
  if v_q.id is null then
    raise exception 'pricing: quotation not found' using errcode = 'P0002';
  end if;
  if v_q.status <> 'draft' then
    raise exception 'pricing: cannot send quotation in status %', v_q.status using errcode = '22023';
  end if;
  perform pricing.fn_assert_supplier_member(v_q.supplier_id);

  if not exists (select 1 from pricing.quotation_items where quotation_id = p_id) then
    raise exception 'pricing: cannot send empty quotation' using errcode = '22023';
  end if;

  -- Recompute totals first.
  perform pricing.compute_quote_totals(p_id);

  update pricing.quotations
     set status     = 'sent',
         sent_at    = now(),
         updated_by = auth.uid()
   where id = p_id;

  perform pricing.fn_record_event(
    v_q.tenant_id, 'quotation_sent', null, p_id, null,
    jsonb_build_object('valid_until', v_q.valid_until)
  );
  perform pricing.fn_audit('pricing.quotation.sent', p_id, v_q.tenant_id, '{}'::jsonb);
end;
$$;

-- ===========================================================================
-- 7. Buyer portal RPCs
-- ===========================================================================

-- 7.1 portal_accept_quotation ----------------------------------------------
create or replace function pricing.portal_accept_quotation(p_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_q pricing.quotations%rowtype;
begin
  select * into v_q from pricing.quotations where id = p_id and deleted_at is null;
  if v_q.id is null then
    raise exception 'pricing: quotation not found' using errcode = 'P0002';
  end if;
  if v_q.status <> 'sent' then
    raise exception 'pricing: cannot accept quotation in status %', v_q.status
      using errcode = '22023';
  end if;
  perform pricing.fn_assert_buyer_member(v_q.buyer_organization_id);

  update pricing.quotations
     set status                  = 'accepted',
         responded_at            = now(),
         response_actor_user_id  = auth.uid(),
         updated_by              = auth.uid()
   where id = p_id;

  perform pricing.fn_record_event(
    v_q.tenant_id, 'quotation_accepted', null, p_id, null, '{}'::jsonb
  );
  perform pricing.fn_audit('pricing.quotation.accepted', p_id, v_q.tenant_id, '{}'::jsonb);
end;
$$;

-- 7.2 portal_reject_quotation ----------------------------------------------
create or replace function pricing.portal_reject_quotation(
  p_id     uuid,
  p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_q pricing.quotations%rowtype;
begin
  select * into v_q from pricing.quotations where id = p_id and deleted_at is null;
  if v_q.id is null then
    raise exception 'pricing: quotation not found' using errcode = 'P0002';
  end if;
  if v_q.status <> 'sent' then
    raise exception 'pricing: cannot reject quotation in status %', v_q.status
      using errcode = '22023';
  end if;
  perform pricing.fn_assert_buyer_member(v_q.buyer_organization_id);

  update pricing.quotations
     set status                  = 'rejected',
         responded_at            = now(),
         response_actor_user_id  = auth.uid(),
         decision_reason         = p_reason,
         updated_by              = auth.uid()
   where id = p_id;

  perform pricing.fn_record_event(
    v_q.tenant_id, 'quotation_rejected', null, p_id, null,
    jsonb_build_object('reason', p_reason)
  );
  perform pricing.fn_audit('pricing.quotation.rejected', p_id, v_q.tenant_id, '{}'::jsonb);
end;
$$;

-- 7.3 portal_list_my_quotations --------------------------------------------
create or replace function pricing.portal_list_my_quotations(
  p_status                  pricing.quotation_status default null,
  p_buyer_organization_id   uuid default null,
  p_limit                   integer default 25,
  p_offset                  integer default 0
) returns table (
  id uuid,
  supplier_id uuid,
  buyer_organization_id uuid,
  quotation_code text,
  currency_code char(3),
  status text,
  total_amount numeric,
  valid_until timestamptz,
  sent_at timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  return query
    select q.id, q.supplier_id, q.buyer_organization_id,
           q.quotation_code, q.currency_code, q.status::text,
           q.total_amount, q.valid_until, q.sent_at, q.created_at
      from pricing.quotations q
     where q.deleted_at is null
       and (p_status is null or q.status = p_status)
       and (p_buyer_organization_id is null or q.buyer_organization_id = p_buyer_organization_id)
       and (
         identity.is_platform_admin()
         or exists (
           select 1 from organization.memberships m
            where m.user_id = v_uid
              and m.deleted_at is null
              and m.status = 'active'
              and m.organization_id in (q.supplier_organization_id, q.buyer_organization_id)
         )
       )
     order by q.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs
-- ===========================================================================

-- 8.1 admin_set_currency_rate ----------------------------------------------
create or replace function pricing.admin_set_currency_rate(
  p_base_code        char(3),
  p_quote_code       char(3),
  p_rate             numeric,
  p_effective_from   timestamptz default null,
  p_effective_to     timestamptz default null,
  p_source           text default 'manual'
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid; v_eff timestamptz;
begin
  perform pricing.fn_assert_admin();
  if p_base_code is null or p_quote_code is null then
    raise exception 'pricing: base and quote codes are required' using errcode = '22023';
  end if;
  if p_base_code = p_quote_code then
    raise exception 'pricing: base and quote must differ' using errcode = '22023';
  end if;
  if p_rate is null or p_rate <= 0 then
    raise exception 'pricing: rate must be > 0' using errcode = '22023';
  end if;
  v_eff := coalesce(p_effective_from, now());

  insert into pricing.currency_rates (
    base_code, quote_code, rate, effective_from, effective_to, source, created_by
  ) values (
    p_base_code, p_quote_code, p_rate, v_eff, p_effective_to, coalesce(p_source, 'manual'), auth.uid()
  ) returning id into v_id;

  perform pricing.fn_record_event(
    -- currency_rates is platform-scoped; tenant_id NULL not allowed in events.
    -- Use the calling admin's tenant if available, else fall back to first tenant.
    coalesce(
      (select tenant_id from identity.user_profiles where id = auth.uid()),
      (select id from identity.tenants order by created_at limit 1)
    ),
    'currency_rate_set', null, null, null,
    jsonb_build_object('rate_id', v_id,
                       'base_code', p_base_code,
                       'quote_code', p_quote_code,
                       'rate', p_rate,
                       'effective_from', v_eff,
                       'source', p_source)
  );
  perform pricing.fn_audit('pricing.currency_rate.set', v_id,
                          (select tenant_id from identity.user_profiles where id = auth.uid()),
                          jsonb_build_object('base_code', p_base_code,
                                             'quote_code', p_quote_code,
                                             'rate', p_rate));
  return v_id;
end;
$$;

-- 8.2 admin_list_price_lists -----------------------------------------------
create or replace function pricing.admin_list_price_lists(
  p_supplier_id  uuid default null,
  p_status       pricing.price_list_status default null,
  p_limit        integer default 25,
  p_offset       integer default 0
) returns table (
  id uuid,
  tenant_id uuid,
  supplier_id uuid,
  organization_id uuid,
  code text,
  name_en text,
  currency_code char(3),
  status text,
  effective_from timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform pricing.fn_assert_admin();
  return query
    select pl.id, pl.tenant_id, pl.supplier_id, pl.organization_id,
           pl.code, pl.name_en, pl.currency_code, pl.status::text,
           pl.effective_from, pl.created_at
      from pricing.price_lists pl
     where pl.deleted_at is null
       and (p_supplier_id is null or pl.supplier_id = p_supplier_id)
       and (p_status is null or pl.status = p_status)
     order by pl.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.3 admin_list_quotations ------------------------------------------------
create or replace function pricing.admin_list_quotations(
  p_status                  pricing.quotation_status default null,
  p_buyer_organization_id   uuid default null,
  p_supplier_id             uuid default null,
  p_limit                   integer default 25,
  p_offset                  integer default 0
) returns table (
  id uuid,
  tenant_id uuid,
  supplier_id uuid,
  buyer_organization_id uuid,
  quotation_code text,
  currency_code char(3),
  status text,
  total_amount numeric,
  valid_until timestamptz,
  sent_at timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform pricing.fn_assert_admin();
  return query
    select q.id, q.tenant_id, q.supplier_id, q.buyer_organization_id,
           q.quotation_code, q.currency_code, q.status::text,
           q.total_amount, q.valid_until, q.sent_at, q.created_at
      from pricing.quotations q
     where q.deleted_at is null
       and (p_status is null or q.status = p_status)
       and (p_buyer_organization_id is null or q.buyer_organization_id = p_buyer_organization_id)
       and (p_supplier_id is null or q.supplier_id = p_supplier_id)
     order by q.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.4 admin_capture_quote --------------------------------------------------
-- Q6=A: admin-only manual/service freeze RPC. Inserts an immutable snapshot
-- into pricing.quote_captures. No automatic trigger from upstream domains.
create or replace function pricing.admin_capture_quote(
  p_kind                          pricing.quote_capture_kind,
  p_supplier_id                   uuid,
  p_buyer_organization_id         uuid,
  p_currency_code                 char(3),
  p_snapshot                      jsonb,
  p_source_supplier_offer_id      uuid default null,
  p_source_executed_contract_id   uuid default null,
  p_source_quotation_id           uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_sup supplier.suppliers%rowtype;
  v_id uuid;
begin
  perform pricing.fn_assert_admin();
  if p_snapshot is null then
    raise exception 'pricing: snapshot is required' using errcode = '22023';
  end if;
  select * into v_sup from supplier.suppliers where id = p_supplier_id and deleted_at is null;
  if v_sup.id is null then
    raise exception 'pricing: supplier not found' using errcode = 'P0002';
  end if;
  if not exists (
    select 1 from organization.organizations where id = p_buyer_organization_id and deleted_at is null
  ) then
    raise exception 'pricing: buyer organization not found' using errcode = 'P0002';
  end if;
  if not exists (select 1 from pricing.currencies where code = p_currency_code) then
    raise exception 'pricing: currency % unknown', p_currency_code using errcode = '22023';
  end if;

  insert into pricing.quote_captures (
    tenant_id, kind,
    supplier_id, supplier_organization_id, buyer_organization_id,
    source_supplier_offer_id, source_executed_contract_id, source_quotation_id,
    currency_code, snapshot, captured_by
  ) values (
    v_sup.tenant_id, p_kind,
    p_supplier_id, v_sup.organization_id, p_buyer_organization_id,
    p_source_supplier_offer_id, p_source_executed_contract_id, p_source_quotation_id,
    p_currency_code, p_snapshot, auth.uid()
  ) returning id into v_id;

  perform pricing.fn_record_event(
    v_sup.tenant_id, 'quote_captured', null, p_source_quotation_id, null,
    jsonb_build_object('capture_id', v_id, 'kind', p_kind,
                       'supplier_offer_id', p_source_supplier_offer_id,
                       'executed_contract_id', p_source_executed_contract_id)
  );
  perform pricing.fn_audit('pricing.quote.captured', v_id, v_sup.tenant_id,
                          jsonb_build_object('kind', p_kind));
  return v_id;
end;
$$;

-- 8.5 admin_expire_due_quotations ------------------------------------------
create or replace function pricing.admin_expire_due_quotations()
returns integer
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_count integer := 0;
  v_row record;
begin
  perform pricing.fn_assert_admin();
  for v_row in
    update pricing.quotations
       set status     = 'expired',
           updated_by = auth.uid()
     where status = 'sent'
       and valid_until is not null
       and valid_until <= now()
       and deleted_at is null
    returning id, tenant_id
  loop
    perform pricing.fn_record_event(
      v_row.tenant_id, 'quotation_expired', null, v_row.id, null, '{}'::jsonb
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- ===========================================================================
-- 9. Read RPCs
-- ===========================================================================

-- 9.1 get_my_price_lists ---------------------------------------------------
create or replace function pricing.get_my_price_lists(
  p_status pricing.price_list_status default null,
  p_limit  integer default 25,
  p_offset integer default 0
) returns table (
  id uuid,
  supplier_id uuid,
  organization_id uuid,
  code text,
  name_en text,
  name_fa text,
  currency_code char(3),
  status text,
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  return query
    select pl.id, pl.supplier_id, pl.organization_id,
           pl.code, pl.name_en, pl.name_fa, pl.currency_code, pl.status::text,
           pl.effective_from, pl.effective_to, pl.created_at
      from pricing.price_lists pl
     where pl.deleted_at is null
       and (p_status is null or pl.status = p_status)
       and (
         identity.is_platform_admin()
         or exists (
           select 1 from organization.memberships m
            where m.user_id = v_uid
              and m.deleted_at is null
              and m.status = 'active'
              and m.organization_id = pl.organization_id
         )
       )
     order by pl.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 9.2 get_quotation --------------------------------------------------------
create or replace function pricing.get_quotation(p_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_q pricing.quotations%rowtype;
  v_uid uuid := auth.uid();
  v_authorized boolean;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'pricing: not authenticated' using errcode = '42501';
  end if;
  select * into v_q from pricing.quotations where id = p_id and deleted_at is null;
  if v_q.id is null then
    raise exception 'pricing: quotation not found' using errcode = 'P0002';
  end if;

  if identity.is_platform_admin() then
    v_authorized := true;
  else
    select exists (
      select 1 from organization.memberships m
       where m.user_id = v_uid
         and m.deleted_at is null
         and m.status = 'active'
         and m.organization_id in (v_q.supplier_organization_id, v_q.buyer_organization_id)
    ) into v_authorized;
  end if;
  if not v_authorized then
    raise exception 'pricing: not authorized' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'quotation', to_jsonb(v_q),
    'items', coalesce(
      (select jsonb_agg(to_jsonb(qi) order by qi.position)
         from pricing.quotation_items qi where qi.quotation_id = v_q.id),
      '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

-- 9.3 get_active_unit_price ------------------------------------------------
-- Returns the active unit_price for (supplier, product, currency) as of a
-- timestamp. Active = price_list.status = 'active' AND row is current.
create or replace function pricing.get_active_unit_price(
  p_supplier_id    uuid,
  p_product_id     uuid,
  p_currency_code  char(3),
  p_as_of          timestamptz default null
) returns numeric
language plpgsql stable security definer set search_path = ''
as $$
declare v_price numeric; v_at timestamptz;
begin
  v_at := coalesce(p_as_of, now());
  select pli.unit_price into v_price
    from pricing.price_list_items pli
    join pricing.price_lists pl on pl.id = pli.price_list_id
   where pl.supplier_id = p_supplier_id
     and pli.product_id = p_product_id
     and pl.currency_code = p_currency_code
     and pl.status = 'active'
     and pl.deleted_at is null
     and (pl.effective_from is null or pl.effective_from <= v_at)
     and (pl.effective_to is null or pl.effective_to > v_at)
   order by pl.effective_from desc nulls last
   limit 1;
  return v_price;
end;
$$;

-- 9.4 list_currency_rates --------------------------------------------------
create or replace function pricing.list_currency_rates(
  p_base_code  char(3) default null,
  p_quote_code char(3) default null,
  p_as_of      timestamptz default null
) returns table (
  id uuid,
  base_code char(3),
  quote_code char(3),
  rate numeric,
  effective_from timestamptz,
  effective_to timestamptz,
  source text,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_at timestamptz;
begin
  v_at := coalesce(p_as_of, now());
  return query
    select cr.id, cr.base_code, cr.quote_code, cr.rate,
           cr.effective_from, cr.effective_to, cr.source, cr.created_at
      from pricing.currency_rates cr
     where (p_base_code is null or cr.base_code = p_base_code)
       and (p_quote_code is null or cr.quote_code = p_quote_code)
       and cr.effective_from <= v_at
       and (cr.effective_to is null or cr.effective_to > v_at)
     order by cr.effective_from desc;
end;
$$;

-- ===========================================================================
-- 10. Helper RPCs
-- ===========================================================================

-- 10.1 convert_amount ------------------------------------------------------
create or replace function pricing.convert_amount(
  p_amount     numeric,
  p_from_code  char(3),
  p_to_code    char(3),
  p_as_of      timestamptz default null
) returns numeric
language plpgsql stable security definer set search_path = ''
as $$
declare v_rate numeric; v_at timestamptz;
begin
  if p_amount is null then return null; end if;
  if p_from_code = p_to_code then return p_amount; end if;
  v_at := coalesce(p_as_of, now());

  select cr.rate into v_rate
    from pricing.currency_rates cr
   where cr.base_code = p_from_code
     and cr.quote_code = p_to_code
     and cr.effective_from <= v_at
     and (cr.effective_to is null or cr.effective_to > v_at)
   order by cr.effective_from desc
   limit 1;

  if v_rate is null then
    -- Try inverse direction.
    select (1.0 / cr.rate) into v_rate
      from pricing.currency_rates cr
     where cr.base_code = p_to_code
       and cr.quote_code = p_from_code
       and cr.effective_from <= v_at
       and (cr.effective_to is null or cr.effective_to > v_at)
     order by cr.effective_from desc
     limit 1;
  end if;

  if v_rate is null then
    raise exception 'pricing: no FX rate available % → % as of %', p_from_code, p_to_code, v_at
      using errcode = 'P0002';
  end if;

  return p_amount * v_rate;
end;
$$;

-- 10.2 compute_quote_totals ------------------------------------------------
-- Recomputes subtotal/discount/total from line items. Idempotent.
create or replace function pricing.compute_quote_totals(p_quotation_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_subtotal numeric(20,4) := 0;
  v_discount numeric(20,4) := 0;
  v_total    numeric(20,4) := 0;
begin
  select
    coalesce(sum(quantity * unit_price), 0),
    coalesce(sum(discount_amount), 0),
    coalesce(sum(line_total), 0)
  into v_subtotal, v_discount, v_total
  from pricing.quotation_items
  where quotation_id = p_quotation_id;

  update pricing.quotations
     set subtotal_amount = v_subtotal,
         discount_amount = v_discount,
         total_amount    = v_total,
         updated_at      = now()
   where id = p_quotation_id;
end;
$$;

-- ===========================================================================
-- 11. Trigger attachments (updated_at + audit_entity)
-- ===========================================================================
-- Note: pricing.price_list_items and pricing.quotation_items do NOT have an
-- `updated_by` column, so the identity.set_updated_at() trigger cannot bind
-- against them. Both are touched only by their parent's RPCs which already
-- maintain updated_at explicitly.
do $$
declare r record;
begin
  for r in
    select unnest(array[
      'price_lists', 'quotations', 'discount_rules'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on pricing.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on pricing.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_name
    );
  end loop;
end;
$$;

-- Note: pricing.currencies is a static reference table keyed by char(3) `code`
-- (no `id` column), so the generic audit.fn_audit_entity trigger cannot run
-- against it. We deliberately exclude it from the audit_entity attachment loop.
do $$
declare r record;
begin
  for r in
    select unnest(array[
      'currency_rates',
      'price_lists', 'price_list_items',
      'quotations', 'quotation_items',
      'discount_rules', 'quote_captures', 'events'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on pricing.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on pricing.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 12. Grants (SELECT only; mutations via SECURITY DEFINER RPCs)
-- ===========================================================================
revoke all on all tables in schema pricing from anon;

grant select on pricing.currencies            to authenticated;
grant select on pricing.currency_rates        to authenticated;
grant select on pricing.price_lists           to authenticated;
grant select on pricing.price_list_items      to authenticated;
grant select on pricing.quotations            to authenticated;
grant select on pricing.quotation_items       to authenticated;
grant select on pricing.discount_rules        to authenticated;
grant select on pricing.quote_captures        to authenticated;
grant select on pricing.events                to authenticated;

-- ===========================================================================
-- 13. RPC EXECUTE grants
-- ===========================================================================
grant execute on function pricing.portal_create_price_list(uuid, text, text, text, char, text) to authenticated;
grant execute on function pricing.portal_upsert_price_list_item(uuid, uuid, numeric, text, numeric, numeric, text) to authenticated;
grant execute on function pricing.portal_publish_price_list(uuid, timestamptz) to authenticated;
grant execute on function pricing.portal_pause_price_list(uuid, text) to authenticated;
grant execute on function pricing.portal_archive_price_list(uuid, text) to authenticated;
grant execute on function pricing.portal_create_quotation(uuid, uuid, text, char, uuid, timestamptz) to authenticated;
grant execute on function pricing.portal_add_quotation_item(uuid, uuid, numeric, text, numeric, numeric, text, integer) to authenticated;
grant execute on function pricing.portal_send_quotation(uuid) to authenticated;

grant execute on function pricing.portal_accept_quotation(uuid) to authenticated;
grant execute on function pricing.portal_reject_quotation(uuid, text) to authenticated;
grant execute on function pricing.portal_list_my_quotations(pricing.quotation_status, uuid, integer, integer) to authenticated;

grant execute on function pricing.admin_set_currency_rate(char, char, numeric, timestamptz, timestamptz, text) to authenticated;
grant execute on function pricing.admin_list_price_lists(uuid, pricing.price_list_status, integer, integer) to authenticated;
grant execute on function pricing.admin_list_quotations(pricing.quotation_status, uuid, uuid, integer, integer) to authenticated;
grant execute on function pricing.admin_capture_quote(pricing.quote_capture_kind, uuid, uuid, char, jsonb, uuid, uuid, uuid) to authenticated;
grant execute on function pricing.admin_expire_due_quotations() to authenticated, service_role;

grant execute on function pricing.get_my_price_lists(pricing.price_list_status, integer, integer) to authenticated;
grant execute on function pricing.get_quotation(uuid) to authenticated;
grant execute on function pricing.get_active_unit_price(uuid, uuid, char, timestamptz) to authenticated;
grant execute on function pricing.list_currency_rates(char, char, timestamptz) to authenticated;

grant execute on function pricing.convert_amount(numeric, char, char, timestamptz) to authenticated;
grant execute on function pricing.compute_quote_totals(uuid) to authenticated, service_role;

-- ===========================================================================
-- 14. Currency seed (Q3=A: IRR, USD, EUR)
-- ===========================================================================
insert into pricing.currencies (code, numeric_code, name_en, name_fa, minor_unit_digits, is_active) values
  ('IRR', 364, 'Iranian Rial',  'ریال ایران', 0, true),
  ('USD', 840, 'US Dollar',     'دلار آمریکا', 2, true),
  ('EUR', 978, 'Euro',          'یورو',        2, true)
on conflict (code) do nothing;
