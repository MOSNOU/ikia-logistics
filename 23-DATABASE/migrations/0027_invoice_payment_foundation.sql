-- CC-16 / Migration 0027 — Invoice / Payment Readiness Foundation
-- Tenth business domain step. New `finance` schema built atop CC-13/CC-14.
-- Append-only over migrations 0001-0026.
--
-- Scope: invoice + payment record-keeping ONLY.
-- No payment gateway integration, no pricing engine, no settlement, no escrow,
-- no insurance, no advanced accounting, no live GPS.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists finance;
grant usage on schema finance to anon, authenticated, service_role;
comment on schema finance is
  'iKIA Phase 2 — invoice / payment readiness domain. Record-keeping only; no payment gateway / pricing engine / settlement / escrow / accounting.';

-- ===========================================================================
-- 2. Enums (3)
-- ===========================================================================
create type finance.invoice_status as enum (
  'draft', 'issued', 'sent', 'due', 'paid', 'partial',
  'overdue', 'cancelled', 'voided'
);

create type finance.payment_status as enum (
  'pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled'
);

create type finance.payment_method_type as enum (
  'bank_transfer', 'credit_card', 'paypal', 'wire', 'check', 'other'
);

-- ===========================================================================
-- 3. Tables (6)
-- ===========================================================================

-- 3.1 invoices -------------------------------------------------------------
create table finance.invoices (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  executed_contract_id        uuid references contract.executed_contracts(id) on delete restrict,
  shipment_id                 uuid references shipment.shipments(id) on delete restrict,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,
  created_by                  uuid references auth.users(id) on delete set null,

  invoice_code                text not null,
  status                      finance.invoice_status not null default 'draft',
  invoice_date                date,
  due_date                    date,
  currency                    text not null default 'USD',

  subtotal_amount             numeric not null default 0,
  tax_amount                  numeric not null default 0,
  fees_amount                 numeric not null default 0,
  total_amount                numeric not null default 0,
  paid_amount                 numeric not null default 0,
  taxes_and_fees              jsonb not null default '{}'::jsonb,

  payment_terms_text          text,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  issued_at                   timestamptz,
  issued_by                   uuid references auth.users(id) on delete set null,
  sent_at                     timestamptz,
  sent_by                     uuid references auth.users(id) on delete set null,
  paid_at                     timestamptz,
  cancelled_at                timestamptz,
  cancelled_by                uuid references auth.users(id) on delete set null,
  cancelled_reason            text,
  voided_at                   timestamptz,
  voided_by                   uuid references auth.users(id) on delete set null,
  voided_reason               text,

  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1,

  constraint invoices_has_target check (
    executed_contract_id is not null or shipment_id is not null
  )
);

comment on table finance.invoices is
  'Invoice header. References an executed contract and/or a shipment. Record-keeping only — no payment gateway.';

create unique index invoices_code_unique
  on finance.invoices(tenant_id, lower(invoice_code))
  where deleted_at is null;

create index invoices_contract_idx on finance.invoices(executed_contract_id);
create index invoices_shipment_idx on finance.invoices(shipment_id);
create index invoices_supplier_idx on finance.invoices(supplier_id);
create index invoices_status_idx   on finance.invoices(status);

-- 3.2 invoice_items --------------------------------------------------------
create table finance.invoice_items (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  invoice_id                  uuid not null references finance.invoices(id) on delete cascade,

  executed_contract_item_id   uuid references contract.executed_contract_items(id) on delete set null,
  shipment_item_id            uuid references shipment.shipment_items(id) on delete set null,

  description                 text not null,
  quantity                    numeric not null default 1,
  quantity_unit               text,
  unit_price                  numeric not null default 0,
  tax_rate                    numeric not null default 0,
  total                       numeric not null default 0,
  metadata                    jsonb not null default '{}'::jsonb,
  sort_order                  integer not null default 0,

  created_by                  uuid references auth.users(id) on delete set null,
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table finance.invoice_items is
  'Invoice line items. May reference an executed contract item or a shipment item (both optional).';

create index invoice_items_invoice_idx on finance.invoice_items(invoice_id);

-- 3.3 payment_methods ------------------------------------------------------
create table finance.payment_methods (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,

  method_type         finance.payment_method_type not null,
  display_name        text not null,
  currency            text,
  is_active           boolean not null default true,
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table finance.payment_methods is
  'Allowed payment methods configured per organization. Record-keeping only — no gateway integration.';

create unique index payment_methods_unique_active
  on finance.payment_methods(organization_id, method_type, lower(display_name))
  where deleted_at is null;

create index payment_methods_org_idx on finance.payment_methods(organization_id);

-- 3.4 payments -------------------------------------------------------------
create table finance.payments (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  invoice_id                  uuid not null references finance.invoices(id) on delete cascade,
  payment_method_id           uuid references finance.payment_methods(id) on delete set null,
  recorded_by_user_id         uuid references auth.users(id) on delete set null,
  recorded_by_party           text not null default 'buyer',

  status                      finance.payment_status not null default 'completed',
  paid_amount                 numeric not null,
  currency                    text not null,
  payment_date                date,
  transaction_reference       text,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  completed_at                timestamptz,
  failed_at                   timestamptz,
  failed_reason               text,
  refunded_at                 timestamptz,
  refunded_reason             text,
  cancelled_at                timestamptz,
  cancelled_reason            text,

  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table finance.payments is
  'Payment records against invoices. recorded_by_party = buyer | supplier (who logged the receipt).';

create index payments_invoice_idx on finance.payments(invoice_id);
create index payments_status_idx  on finance.payments(status);

-- 3.5 invoice_status_events (immutable) ------------------------------------
create table finance.invoice_status_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  invoice_id              uuid not null references finance.invoices(id) on delete cascade,

  from_status             finance.invoice_status,
  to_status               finance.invoice_status not null,
  actor_user_id           uuid references auth.users(id) on delete set null,
  actor_organization_id   uuid references organization.organizations(id) on delete set null,
  reason                  text,
  payload                 jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table finance.invoice_status_events is
  'Immutable invoice status transition trail. No UPDATE/DELETE policies.';

create index invoice_status_events_invoice_idx
  on finance.invoice_status_events(invoice_id, created_at desc);

-- 3.6 payment_status_events (immutable) ------------------------------------
create table finance.payment_status_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  payment_id              uuid not null references finance.payments(id) on delete cascade,
  invoice_id              uuid not null references finance.invoices(id) on delete cascade,

  from_status             finance.payment_status,
  to_status               finance.payment_status not null,
  actor_user_id           uuid references auth.users(id) on delete set null,
  actor_organization_id   uuid references organization.organizations(id) on delete set null,
  reason                  text,
  payload                 jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table finance.payment_status_events is
  'Immutable payment status transition trail. No UPDATE/DELETE policies.';

create index payment_status_events_payment_idx
  on finance.payment_status_events(payment_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function finance.fn_audit(
  p_action_code text,
  p_invoice_id  uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from finance.invoices where id = p_invoice_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'finance', p_invoice_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_next_invoice_code -------------------------------------------------
create or replace function finance.fn_next_invoice_code(p_tenant_id uuid)
returns text
language plpgsql volatile security definer set search_path = ''
as $$
declare v_code text;
begin
  v_code := 'INV-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

-- 4.3 fn_record_invoice_event ----------------------------------------------
create or replace function finance.fn_record_invoice_event(
  p_invoice_id uuid,
  p_from       finance.invoice_status,
  p_to         finance.invoice_status,
  p_reason     text default null,
  p_payload    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from finance.invoices where id = p_invoice_id;
  insert into finance.invoice_status_events (
    tenant_id, organization_id, invoice_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_invoice_id,
    p_from, p_to, auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 4.4 fn_record_payment_event ----------------------------------------------
create or replace function finance.fn_record_payment_event(
  p_payment_id uuid,
  p_from       finance.payment_status,
  p_to         finance.payment_status,
  p_reason     text default null,
  p_payload    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid; v_invoice uuid;
begin
  select tenant_id, organization_id, invoice_id into v_t, v_o, v_invoice
    from finance.payments where id = p_payment_id;
  insert into finance.payment_status_events (
    tenant_id, organization_id, payment_id, invoice_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_payment_id, v_invoice,
    p_from, p_to, auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 4.5 fn_assert_buyer_for_invoice ------------------------------------------
create or replace function finance.fn_assert_buyer_for_invoice(p_invoice_id uuid)
returns finance.invoice_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid; v_status finance.invoice_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id, status into v_org, v_status
    from finance.invoices where id = p_invoice_id and deleted_at is null;
  if v_org is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'finance: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'finance: invoice not owned by caller organization' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.6 fn_assert_invoice_editable -------------------------------------------
create or replace function finance.fn_assert_invoice_editable(p_invoice_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status finance.invoice_status;
begin
  select status into v_status from finance.invoices
   where id = p_invoice_id and deleted_at is null;
  if v_status is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'finance: invoice locked from edit (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- 4.7 fn_assert_invoice_payable --------------------------------------------
create or replace function finance.fn_assert_invoice_payable(p_invoice_id uuid)
returns finance.invoice_status
language plpgsql stable security definer set search_path = ''
as $$
declare v_status finance.invoice_status;
begin
  select status into v_status from finance.invoices
   where id = p_invoice_id and deleted_at is null;
  if v_status is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if v_status not in ('issued', 'sent', 'due', 'partial', 'overdue') then
    raise exception 'finance: invoice not in a payable state (status=%)', v_status
      using errcode = 'P0001';
  end if;
  return v_status;
end;
$$;

-- 4.8 fn_recompute_invoice_totals ------------------------------------------
create or replace function finance.fn_recompute_invoice_totals(p_invoice_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_subtotal numeric := 0;
  v_tax      numeric := 0;
  v_paid     numeric := 0;
begin
  select coalesce(sum(coalesce(it.quantity, 0) * coalesce(it.unit_price, 0)), 0),
         coalesce(sum(coalesce(it.quantity, 0) * coalesce(it.unit_price, 0) * coalesce(it.tax_rate, 0)), 0)
    into v_subtotal, v_tax
    from finance.invoice_items it
   where it.invoice_id = p_invoice_id and it.deleted_at is null;

  select coalesce(sum(p.paid_amount), 0) into v_paid
    from finance.payments p
   where p.invoice_id = p_invoice_id and p.deleted_at is null and p.status = 'completed';

  update finance.invoices
     set subtotal_amount = v_subtotal,
         tax_amount      = v_tax,
         total_amount    = v_subtotal + v_tax + coalesce(fees_amount, 0),
         paid_amount     = v_paid
   where id = p_invoice_id;
end;
$$;

-- 4.9 fn_promote_invoice_after_payment -------------------------------------
-- After a payment status change, recompute totals and auto-promote invoice
-- status if it's currently in a payable state.
create or replace function finance.fn_promote_invoice_after_payment(p_invoice_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status finance.invoice_status;
  v_total  numeric;
  v_paid   numeric;
  v_to     finance.invoice_status;
begin
  perform finance.fn_recompute_invoice_totals(p_invoice_id);
  select status, total_amount, paid_amount into v_status, v_total, v_paid
    from finance.invoices where id = p_invoice_id;
  if v_status in ('issued', 'sent', 'due', 'partial', 'overdue') then
    if v_total > 0 and v_paid >= v_total then
      v_to := 'paid';
    elsif v_paid > 0 then
      v_to := 'partial';
    else
      return;
    end if;
  elsif v_status = 'paid' then
    -- Demote back if a refund dropped paid_amount below total_amount.
    if v_total > 0 and v_paid >= v_total then
      return;
    elsif v_paid > 0 then
      v_to := 'partial';
    else
      v_to := 'sent';
    end if;
  else
    -- draft, cancelled, voided: no auto-change.
    return;
  end if;
  if v_to = v_status then return; end if;

  update finance.invoices
     set status  = v_to,
         paid_at = case when v_to = 'paid' then now() else paid_at end,
         updated_by = auth.uid()
   where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, v_status, v_to, 'payment_auto_promotion');
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table finance.invoices               enable row level security;
alter table finance.invoice_items          enable row level security;
alter table finance.payment_methods        enable row level security;
alter table finance.payments               enable row level security;
alter table finance.invoice_status_events  enable row level security;
alter table finance.payment_status_events  enable row level security;

-- 5.1 invoices: buyer org + supplier of invoice + admin.
drop policy if exists invoices_select on finance.invoices;
create policy invoices_select on finance.invoices
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = finance.invoices.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = finance.invoices.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists invoices_admin_modify on finance.invoices;
create policy invoices_admin_modify on finance.invoices
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 invoice_items: same audience as parent invoice.
drop policy if exists invoice_items_select on finance.invoice_items;
create policy invoice_items_select on finance.invoice_items
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from finance.invoices i
       where i.id = finance.invoice_items.invoice_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = i.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = i.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists invoice_items_admin_modify on finance.invoice_items;
create policy invoice_items_admin_modify on finance.invoice_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 payment_methods: buyer org members + admin.
drop policy if exists payment_methods_select on finance.payment_methods;
create policy payment_methods_select on finance.payment_methods
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = finance.payment_methods.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists payment_methods_admin_modify on finance.payment_methods;
create policy payment_methods_admin_modify on finance.payment_methods
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.4 payments: same audience as parent invoice.
drop policy if exists payments_select on finance.payments;
create policy payments_select on finance.payments
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from finance.invoices i
       where i.id = finance.payments.invoice_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = i.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = i.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists payments_admin_modify on finance.payments;
create policy payments_admin_modify on finance.payments
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.5 invoice_status_events: same audience as parent invoice (immutable).
drop policy if exists invoice_status_events_select on finance.invoice_status_events;
create policy invoice_status_events_select on finance.invoice_status_events
  for select
  using (
    exists (
      select 1 from finance.invoices i
       where i.id = finance.invoice_status_events.invoice_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = i.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = i.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- 5.6 payment_status_events: same audience as parent invoice (immutable).
drop policy if exists payment_status_events_select on finance.payment_status_events;
create policy payment_status_events_select on finance.payment_status_events
  for select
  using (
    exists (
      select 1 from finance.invoices i
       where i.id = finance.payment_status_events.invoice_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = i.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = i.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. Buyer RPCs (14)
-- ===========================================================================

-- 6.1 buyer_create_draft_invoice -------------------------------------------
create or replace function finance.buyer_create_draft_invoice(
  p_executed_contract_id uuid default null,
  p_shipment_id          uuid default null,
  p_currency             text default 'USD',
  p_invoice_date         date default null,
  p_due_date             date default null,
  p_payment_terms_text   text default null,
  p_notes                text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org uuid; v_supplier_id uuid; v_supplier_org uuid;
  v_tenant uuid;
  v_contract_currency text;
  v_code text;
  v_id uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'finance: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if p_executed_contract_id is null and p_shipment_id is null then
    raise exception 'finance: either executed_contract_id or shipment_id is required'
      using errcode = '22023';
  end if;

  if p_executed_contract_id is not null then
    select ec.organization_id, ec.supplier_id, ec.supplier_organization_id,
           ec.tenant_id, ec.currency
      into v_buyer_org, v_supplier_id, v_supplier_org, v_tenant, v_contract_currency
      from contract.executed_contracts ec
     where ec.id = p_executed_contract_id and ec.deleted_at is null;
    if v_buyer_org is null then
      raise exception 'finance: executed contract not found' using errcode = 'P0002';
    end if;
  end if;

  if p_shipment_id is not null then
    if v_buyer_org is null then
      select sh.organization_id, sh.supplier_id, sh.supplier_organization_id, sh.tenant_id
        into v_buyer_org, v_supplier_id, v_supplier_org, v_tenant
        from shipment.shipments sh
       where sh.id = p_shipment_id and sh.deleted_at is null;
      if v_buyer_org is null then
        raise exception 'finance: shipment not found' using errcode = 'P0002';
      end if;
    else
      -- Both supplied: verify shipment is on the same contract.
      if not exists (
        select 1 from shipment.shipments sh
         where sh.id = p_shipment_id
           and sh.executed_contract_id = p_executed_contract_id
           and sh.deleted_at is null
      ) then
        raise exception 'finance: shipment does not belong to the supplied executed contract'
          using errcode = '42501';
      end if;
    end if;
  end if;

  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'finance: target not in caller''s organization' using errcode = '42501';
    end if;
  end if;

  v_code := finance.fn_next_invoice_code(v_tenant);
  insert into finance.invoices (
    tenant_id, organization_id, executed_contract_id, shipment_id,
    supplier_id, supplier_organization_id, created_by,
    invoice_code, status, invoice_date, due_date,
    currency, payment_terms_text, notes, updated_by
  ) values (
    v_tenant, v_buyer_org, p_executed_contract_id, p_shipment_id,
    v_supplier_id, v_supplier_org, v_actor,
    v_code, 'draft', p_invoice_date, p_due_date,
    coalesce(p_currency, v_contract_currency, 'USD'),
    p_payment_terms_text, p_notes, v_actor
  ) returning id into v_id;

  perform finance.fn_record_invoice_event(v_id, null, 'draft', 'invoice_created');
  perform finance.fn_audit('finance.invoice_created', v_id);
  return v_id;
end;
$$;

-- 6.2 buyer_update_invoice (draft only) ------------------------------------
create or replace function finance.buyer_update_invoice(
  p_invoice_id         uuid,
  p_invoice_date       date default null,
  p_due_date           date default null,
  p_currency           text default null,
  p_payment_terms_text text default null,
  p_notes              text default null,
  p_fees_amount        numeric default null,
  p_taxes_and_fees     jsonb default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform finance.fn_assert_buyer_for_invoice(p_invoice_id);
  perform finance.fn_assert_invoice_editable(p_invoice_id);

  update finance.invoices
     set invoice_date       = coalesce(p_invoice_date, invoice_date),
         due_date           = coalesce(p_due_date, due_date),
         currency           = coalesce(p_currency, currency),
         payment_terms_text = coalesce(p_payment_terms_text, payment_terms_text),
         notes              = coalesce(p_notes, notes),
         fees_amount        = coalesce(p_fees_amount, fees_amount),
         taxes_and_fees     = coalesce(p_taxes_and_fees, taxes_and_fees),
         updated_by         = v_actor
   where id = p_invoice_id;
  perform finance.fn_recompute_invoice_totals(p_invoice_id);
  perform finance.fn_audit('finance.invoice_updated', p_invoice_id);
end;
$$;

-- 6.3 buyer_upsert_invoice_item --------------------------------------------
create or replace function finance.buyer_upsert_invoice_item(
  p_invoice_id                uuid,
  p_description               text,
  p_quantity                  numeric default 1,
  p_quantity_unit             text default null,
  p_unit_price                numeric default 0,
  p_tax_rate                  numeric default 0,
  p_executed_contract_item_id uuid default null,
  p_shipment_item_id          uuid default null,
  p_sort_order                integer default 0,
  p_item_id                   uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_id uuid;
  v_total numeric;
begin
  perform finance.fn_assert_buyer_for_invoice(p_invoice_id);
  perform finance.fn_assert_invoice_editable(p_invoice_id);
  if p_description is null or btrim(p_description) = '' then
    raise exception 'finance: invoice item description is required' using errcode = '22023';
  end if;

  v_total := coalesce(p_quantity, 0) * coalesce(p_unit_price, 0) * (1 + coalesce(p_tax_rate, 0));

  select tenant_id, organization_id into v_tenant, v_org
    from finance.invoices where id = p_invoice_id;

  if p_item_id is null then
    insert into finance.invoice_items (
      tenant_id, organization_id, invoice_id, executed_contract_item_id, shipment_item_id,
      description, quantity, quantity_unit, unit_price, tax_rate, total, sort_order,
      created_by, updated_by
    ) values (
      v_tenant, v_org, p_invoice_id, p_executed_contract_item_id, p_shipment_item_id,
      p_description, p_quantity, p_quantity_unit, p_unit_price, p_tax_rate, v_total, p_sort_order,
      v_actor, v_actor
    ) returning id into v_id;
  else
    update finance.invoice_items
       set executed_contract_item_id = coalesce(p_executed_contract_item_id, executed_contract_item_id),
           shipment_item_id          = coalesce(p_shipment_item_id, shipment_item_id),
           description    = p_description,
           quantity       = p_quantity,
           quantity_unit  = coalesce(p_quantity_unit, quantity_unit),
           unit_price     = p_unit_price,
           tax_rate       = p_tax_rate,
           total          = v_total,
           sort_order     = p_sort_order,
           updated_by     = v_actor
     where id = p_item_id and invoice_id = p_invoice_id and deleted_at is null
     returning id into v_id;
    if v_id is null then
      raise exception 'finance: invoice item not found' using errcode = 'P0002';
    end if;
  end if;

  perform finance.fn_recompute_invoice_totals(p_invoice_id);
  perform finance.fn_audit('finance.invoice_item_upserted', p_invoice_id,
    jsonb_build_object('item_id', v_id::text));
  return v_id;
end;
$$;

-- 6.4 buyer_remove_invoice_item --------------------------------------------
create or replace function finance.buyer_remove_invoice_item(p_item_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_invoice uuid;
begin
  select invoice_id into v_invoice from finance.invoice_items
   where id = p_item_id and deleted_at is null;
  if v_invoice is null then
    raise exception 'finance: invoice item not found' using errcode = 'P0002';
  end if;
  perform finance.fn_assert_buyer_for_invoice(v_invoice);
  perform finance.fn_assert_invoice_editable(v_invoice);

  update finance.invoice_items
     set deleted_at = now(), updated_by = v_actor
   where id = p_item_id;
  perform finance.fn_recompute_invoice_totals(v_invoice);
  perform finance.fn_audit('finance.invoice_item_removed', v_invoice,
    jsonb_build_object('item_id', p_item_id::text));
end;
$$;

-- 6.5 buyer_issue_invoice --------------------------------------------------
create or replace function finance.buyer_issue_invoice(p_invoice_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status finance.invoice_status;
begin
  v_status := finance.fn_assert_buyer_for_invoice(p_invoice_id);
  if v_status <> 'draft' then
    raise exception 'finance: invalid_transition: cannot issue from %', v_status
      using errcode = 'P0001';
  end if;
  perform finance.fn_recompute_invoice_totals(p_invoice_id);
  update finance.invoices
     set status = 'issued',
         invoice_date = coalesce(invoice_date, current_date),
         issued_at = now(), issued_by = v_actor, updated_by = v_actor
   where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, 'draft', 'issued');
  perform finance.fn_audit('finance.invoice_issued', p_invoice_id);
end;
$$;

-- 6.6 buyer_send_invoice ---------------------------------------------------
create or replace function finance.buyer_send_invoice(p_invoice_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status finance.invoice_status;
begin
  v_status := finance.fn_assert_buyer_for_invoice(p_invoice_id);
  if v_status <> 'issued' then
    raise exception 'finance: invalid_transition: cannot send from %', v_status
      using errcode = 'P0001';
  end if;
  update finance.invoices
     set status = 'sent', sent_at = now(), sent_by = v_actor, updated_by = v_actor
   where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, 'issued', 'sent');
  perform finance.fn_audit('finance.invoice_sent', p_invoice_id);
end;
$$;

-- 6.7 buyer_mark_overdue ---------------------------------------------------
create or replace function finance.buyer_mark_overdue(p_invoice_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status finance.invoice_status;
begin
  v_status := finance.fn_assert_buyer_for_invoice(p_invoice_id);
  if v_status not in ('sent', 'due', 'partial') then
    raise exception 'finance: invalid_transition: cannot mark overdue from %', v_status
      using errcode = 'P0001';
  end if;
  update finance.invoices set status = 'overdue', updated_by = v_actor where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, v_status, 'overdue');
  perform finance.fn_audit('finance.invoice_marked_overdue', p_invoice_id);
end;
$$;

-- 6.8 buyer_cancel_invoice -------------------------------------------------
create or replace function finance.buyer_cancel_invoice(
  p_invoice_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status finance.invoice_status;
begin
  v_status := finance.fn_assert_buyer_for_invoice(p_invoice_id);
  if v_status in ('paid', 'cancelled', 'voided') then
    raise exception 'finance: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;
  update finance.invoices
     set status = 'cancelled', cancelled_at = now(), cancelled_by = v_actor,
         cancelled_reason = p_reason, updated_by = v_actor
   where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, v_status, 'cancelled', p_reason);
  perform finance.fn_audit('finance.invoice_cancelled', p_invoice_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.9 buyer_record_payment -------------------------------------------------
create or replace function finance.buyer_record_payment(
  p_invoice_id            uuid,
  p_paid_amount           numeric,
  p_payment_method_id     uuid default null,
  p_status                finance.payment_status default 'completed',
  p_payment_date          date default null,
  p_transaction_reference text default null,
  p_notes                 text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_inv_status finance.invoice_status;
  v_tenant uuid; v_org uuid; v_currency text;
  v_id uuid;
begin
  v_inv_status := finance.fn_assert_buyer_for_invoice(p_invoice_id);
  if v_inv_status not in ('issued', 'sent', 'due', 'partial', 'overdue') then
    raise exception 'finance: invoice not in payable state (status=%)', v_inv_status
      using errcode = 'P0001';
  end if;
  if p_paid_amount is null or p_paid_amount <= 0 then
    raise exception 'finance: paid_amount must be > 0' using errcode = '22023';
  end if;

  select tenant_id, organization_id, currency into v_tenant, v_org, v_currency
    from finance.invoices where id = p_invoice_id;

  -- If payment_method_id given, verify it belongs to caller org.
  if p_payment_method_id is not null then
    if not exists (
      select 1 from finance.payment_methods
       where id = p_payment_method_id
         and organization_id = v_org and deleted_at is null
    ) then
      raise exception 'finance: payment_method not found in caller''s organization'
        using errcode = '42501';
    end if;
  end if;

  insert into finance.payments (
    tenant_id, organization_id, invoice_id, payment_method_id,
    recorded_by_user_id, recorded_by_party,
    status, paid_amount, currency, payment_date, transaction_reference, notes,
    completed_at, updated_by
  ) values (
    v_tenant, v_org, p_invoice_id, p_payment_method_id,
    v_actor, 'buyer',
    p_status, p_paid_amount, v_currency, p_payment_date, p_transaction_reference, p_notes,
    case when p_status = 'completed' then now() else null end, v_actor
  ) returning id into v_id;

  perform finance.fn_record_payment_event(v_id, null, p_status, 'payment_recorded');
  if p_status = 'completed' then
    perform finance.fn_promote_invoice_after_payment(p_invoice_id);
  end if;
  perform finance.fn_audit('finance.payment_recorded', p_invoice_id,
    jsonb_build_object('payment_id', v_id::text, 'status', p_status::text));
  return v_id;
end;
$$;

-- 6.10 buyer_refund_payment ------------------------------------------------
create or replace function finance.buyer_refund_payment(
  p_payment_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_invoice uuid; v_status finance.payment_status;
begin
  select invoice_id, status into v_invoice, v_status
    from finance.payments where id = p_payment_id and deleted_at is null;
  if v_invoice is null then
    raise exception 'finance: payment not found' using errcode = 'P0002';
  end if;
  perform finance.fn_assert_buyer_for_invoice(v_invoice);
  if v_status <> 'completed' then
    raise exception 'finance: only completed payments can be refunded (status=%)', v_status
      using errcode = 'P0001';
  end if;
  update finance.payments
     set status = 'refunded', refunded_at = now(), refunded_reason = p_reason,
         updated_by = v_actor
   where id = p_payment_id;
  perform finance.fn_record_payment_event(p_payment_id, 'completed', 'refunded', p_reason);
  perform finance.fn_promote_invoice_after_payment(v_invoice);
  perform finance.fn_audit('finance.payment_refunded', v_invoice,
    jsonb_build_object('payment_id', p_payment_id::text, 'reason', p_reason));
end;
$$;

-- 6.11 buyer_list_invoices -------------------------------------------------
create or replace function finance.buyer_list_invoices(
  p_status finance.invoice_status default null,
  p_limit  integer                default 25,
  p_offset integer                default 0
) returns table (
  id uuid, invoice_code text, executed_contract_id uuid, shipment_id uuid,
  supplier_id uuid, status text, currency text, total_amount numeric, paid_amount numeric,
  invoice_date date, due_date date, created_at timestamptz, updated_at timestamptz
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
    raise exception 'finance: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'finance: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select i.id, i.invoice_code, i.executed_contract_id, i.shipment_id,
           i.supplier_id, i.status::text, i.currency, i.total_amount, i.paid_amount,
           i.invoice_date, i.due_date, i.created_at, i.updated_at
      from finance.invoices i
     where i.deleted_at is null
       and (identity.is_platform_admin() or i.organization_id = v_caller_org)
       and (p_status is null or i.status = p_status)
     order by i.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.12 buyer_get_invoice ---------------------------------------------------
create or replace function finance.buyer_get_invoice(p_invoice_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform finance.fn_assert_buyer_for_invoice(p_invoice_id);
  return (
    select jsonb_build_object(
      'id', i.id, 'invoice_code', i.invoice_code,
      'executed_contract_id', i.executed_contract_id, 'shipment_id', i.shipment_id,
      'supplier_id', i.supplier_id, 'supplier_organization_id', i.supplier_organization_id,
      'status', i.status, 'invoice_date', i.invoice_date, 'due_date', i.due_date,
      'currency', i.currency, 'subtotal_amount', i.subtotal_amount, 'tax_amount', i.tax_amount,
      'fees_amount', i.fees_amount, 'total_amount', i.total_amount, 'paid_amount', i.paid_amount,
      'taxes_and_fees', i.taxes_and_fees, 'payment_terms_text', i.payment_terms_text,
      'created_at', i.created_at, 'updated_at', i.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'description', it.description, 'quantity', it.quantity,
          'unit_price', it.unit_price, 'tax_rate', it.tax_rate, 'total', it.total
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from finance.invoice_items it
         where it.invoice_id = i.id and it.deleted_at is null
      ),
      'payments', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', p.id, 'status', p.status, 'paid_amount', p.paid_amount,
          'currency', p.currency, 'payment_date', p.payment_date,
          'recorded_by_party', p.recorded_by_party,
          'transaction_reference', p.transaction_reference
        )), '[]'::jsonb)
          from finance.payments p
         where p.invoice_id = i.id and p.deleted_at is null
      )
    )
    from finance.invoices i where i.id = p_invoice_id
  );
end;
$$;

-- 6.13 buyer_upsert_payment_method -----------------------------------------
create or replace function finance.buyer_upsert_payment_method(
  p_method_type   finance.payment_method_type,
  p_display_name  text,
  p_currency      text default null,
  p_is_active     boolean default true,
  p_metadata      jsonb default '{}'::jsonb,
  p_method_id     uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_org uuid := identity.current_organization_id();
  v_tenant uuid;
  v_id uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'finance: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null then
    raise exception 'finance: no active organization in JWT' using errcode = 'P0002';
  end if;
  if p_display_name is null or btrim(p_display_name) = '' then
    raise exception 'finance: display_name is required' using errcode = '22023';
  end if;
  select tenant_id into v_tenant from organization.organizations where id = v_caller_org;

  if p_method_id is null then
    insert into finance.payment_methods (
      tenant_id, organization_id, method_type, display_name, currency,
      is_active, metadata, created_by, updated_by
    ) values (
      v_tenant, v_caller_org, p_method_type, p_display_name, p_currency,
      p_is_active, coalesce(p_metadata, '{}'::jsonb), v_actor, v_actor
    ) returning id into v_id;
  else
    update finance.payment_methods
       set method_type   = p_method_type,
           display_name  = p_display_name,
           currency      = p_currency,
           is_active     = p_is_active,
           metadata      = coalesce(p_metadata, metadata),
           updated_by    = v_actor
     where id = p_method_id and organization_id = v_caller_org and deleted_at is null
     returning id into v_id;
    if v_id is null then
      raise exception 'finance: payment_method not found in caller''s organization' using errcode = 'P0002';
    end if;
  end if;
  return v_id;
end;
$$;

-- 6.14 buyer_list_payment_methods ------------------------------------------
create or replace function finance.buyer_list_payment_methods(
  p_method_type finance.payment_method_type default null,
  p_active_only boolean default true
) returns table (
  id uuid, method_type text, display_name text, currency text,
  is_active boolean, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_org uuid := identity.current_organization_id();
begin
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'finance: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select pm.id, pm.method_type::text, pm.display_name, pm.currency,
           pm.is_active, pm.created_at, pm.updated_at
      from finance.payment_methods pm
     where pm.deleted_at is null
       and (identity.is_platform_admin() or pm.organization_id = v_caller_org)
       and (p_method_type is null or pm.method_type = p_method_type)
       and (not p_active_only or pm.is_active)
     order by pm.created_at desc;
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (4)
-- ===========================================================================

-- 7.1 supplier_list_my_invoices --------------------------------------------
create or replace function finance.supplier_list_my_invoices(
  p_status finance.invoice_status default null,
  p_limit  integer                default 25,
  p_offset integer                default 0
) returns table (
  id uuid, invoice_code text, executed_contract_id uuid, shipment_id uuid,
  status text, currency text, total_amount numeric, paid_amount numeric,
  invoice_date date, due_date date, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select i.id, i.invoice_code, i.executed_contract_id, i.shipment_id,
           i.status::text, i.currency, i.total_amount, i.paid_amount,
           i.invoice_date, i.due_date, i.created_at, i.updated_at
      from finance.invoices i
     where i.deleted_at is null
       and i.supplier_id = v_supplier
       and (p_status is null or i.status = p_status)
     order by i.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 supplier_get_my_invoice ----------------------------------------------
create or replace function finance.supplier_get_my_invoice(p_invoice_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_sup uuid := supplier.fn_portal_supplier_id(); v_inv_sup uuid;
begin
  select supplier_id into v_inv_sup from finance.invoices
   where id = p_invoice_id and deleted_at is null;
  if v_inv_sup is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if v_inv_sup <> v_caller_sup and not identity.is_platform_admin() then
    raise exception 'finance: invoice not on caller''s supplier' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', i.id, 'invoice_code', i.invoice_code,
      'executed_contract_id', i.executed_contract_id, 'shipment_id', i.shipment_id,
      'status', i.status, 'invoice_date', i.invoice_date, 'due_date', i.due_date,
      'currency', i.currency, 'total_amount', i.total_amount, 'paid_amount', i.paid_amount,
      'created_at', i.created_at, 'updated_at', i.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'description', it.description, 'quantity', it.quantity,
          'unit_price', it.unit_price, 'total', it.total
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from finance.invoice_items it
         where it.invoice_id = i.id and it.deleted_at is null
      ),
      'payments', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', p.id, 'status', p.status, 'paid_amount', p.paid_amount,
          'payment_date', p.payment_date, 'recorded_by_party', p.recorded_by_party
        )), '[]'::jsonb)
          from finance.payments p
         where p.invoice_id = i.id and p.deleted_at is null
      )
    )
    from finance.invoices i where i.id = p_invoice_id
  );
end;
$$;

-- 7.3 supplier_record_payment_receipt --------------------------------------
-- Supplier confirms a payment receipt (e.g. bank transfer cleared on their end).
-- Creates a payment row with recorded_by_party='supplier'.
create or replace function finance.supplier_record_payment_receipt(
  p_invoice_id            uuid,
  p_paid_amount           numeric,
  p_payment_date          date default null,
  p_transaction_reference text default null,
  p_notes                 text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_sup uuid := supplier.fn_portal_supplier_id();
  v_tenant uuid; v_org uuid; v_currency text; v_supplier_id uuid;
  v_inv_status finance.invoice_status;
  v_id uuid;
begin
  select tenant_id, organization_id, currency, supplier_id, status
    into v_tenant, v_org, v_currency, v_supplier_id, v_inv_status
    from finance.invoices where id = p_invoice_id and deleted_at is null;
  if v_tenant is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if v_supplier_id <> v_caller_sup then
    raise exception 'finance: invoice not on caller''s supplier' using errcode = '42501';
  end if;
  if v_inv_status not in ('issued', 'sent', 'due', 'partial', 'overdue') then
    raise exception 'finance: invoice not in a payable state (status=%)', v_inv_status
      using errcode = 'P0001';
  end if;
  if p_paid_amount is null or p_paid_amount <= 0 then
    raise exception 'finance: paid_amount must be > 0' using errcode = '22023';
  end if;

  insert into finance.payments (
    tenant_id, organization_id, invoice_id, recorded_by_user_id, recorded_by_party,
    status, paid_amount, currency, payment_date, transaction_reference, notes,
    completed_at, updated_by
  ) values (
    v_tenant, v_org, p_invoice_id, v_actor, 'supplier',
    'completed', p_paid_amount, v_currency, p_payment_date, p_transaction_reference, p_notes,
    now(), v_actor
  ) returning id into v_id;

  perform finance.fn_record_payment_event(v_id, null, 'completed', 'supplier_recorded_receipt');
  perform finance.fn_promote_invoice_after_payment(p_invoice_id);
  perform finance.fn_audit('finance.payment_supplier_receipt', p_invoice_id,
    jsonb_build_object('payment_id', v_id::text));
  return v_id;
end;
$$;

-- 7.4 supplier_list_my_payments --------------------------------------------
create or replace function finance.supplier_list_my_payments(
  p_invoice_id uuid                   default null,
  p_status     finance.payment_status default null,
  p_limit      integer                default 25,
  p_offset     integer                default 0
) returns table (
  id uuid, invoice_id uuid, status text, paid_amount numeric, currency text,
  payment_date date, recorded_by_party text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_sup uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select p.id, p.invoice_id, p.status::text, p.paid_amount, p.currency,
           p.payment_date, p.recorded_by_party, p.created_at
      from finance.payments p
      join finance.invoices i on i.id = p.invoice_id
     where p.deleted_at is null
       and i.supplier_id = v_caller_sup
       and (p_invoice_id is null or p.invoice_id = p_invoice_id)
       and (p_status is null or p.status = p_status)
     order by p.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (6)
-- ===========================================================================

-- 8.1 admin_list_invoices --------------------------------------------------
create or replace function finance.admin_list_invoices(
  p_organization_id uuid                     default null,
  p_supplier_id     uuid                     default null,
  p_status          finance.invoice_status   default null,
  p_limit           integer                  default 25,
  p_offset          integer                  default 0
) returns table (
  id uuid, invoice_code text, organization_id uuid, supplier_id uuid,
  status text, currency text, total_amount numeric, paid_amount numeric,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_invoices: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select i.id, i.invoice_code, i.organization_id, i.supplier_id,
           i.status::text, i.currency, i.total_amount, i.paid_amount, i.created_at
      from finance.invoices i
     where i.deleted_at is null
       and (p_organization_id is null or i.organization_id = p_organization_id)
       and (p_supplier_id is null or i.supplier_id = p_supplier_id)
       and (p_status is null or i.status = p_status)
     order by i.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_invoice ----------------------------------------------------
create or replace function finance.admin_get_invoice(p_invoice_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_invoice: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', i.id, 'invoice_code', i.invoice_code,
      'organization_id', i.organization_id, 'supplier_id', i.supplier_id,
      'executed_contract_id', i.executed_contract_id, 'shipment_id', i.shipment_id,
      'status', i.status, 'currency', i.currency,
      'total_amount', i.total_amount, 'paid_amount', i.paid_amount,
      'created_at', i.created_at, 'updated_at', i.updated_at,
      'items_count', (select count(*) from finance.invoice_items
                       where invoice_id = i.id and deleted_at is null),
      'payments_count', (select count(*) from finance.payments
                          where invoice_id = i.id and deleted_at is null)
    )
    from finance.invoices i where i.id = p_invoice_id
  );
end;
$$;

-- 8.3 admin_force_invoice_status -------------------------------------------
create or replace function finance.admin_force_invoice_status(
  p_invoice_id uuid,
  p_status     finance.invoice_status,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_current finance.invoice_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_invoice_status: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from finance.invoices
   where id = p_invoice_id and deleted_at is null;
  if v_current is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if v_current = p_status then return; end if;
  update finance.invoices
     set status = p_status,
         paid_at      = case when p_status = 'paid' then now() else paid_at end,
         voided_at    = case when p_status = 'voided' then now() else voided_at end,
         voided_by    = case when p_status = 'voided' then v_actor else voided_by end,
         voided_reason= case when p_status = 'voided' then p_reason else voided_reason end,
         updated_by   = v_actor
   where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, v_current, p_status,
    coalesce(p_reason, 'admin_force_status_change'));
  perform finance.fn_audit('finance.invoice_admin_status_change', p_invoice_id,
    jsonb_build_object('to', p_status::text, 'reason', p_reason));
end;
$$;

-- 8.4 admin_list_invoice_events --------------------------------------------
create or replace function finance.admin_list_invoice_events(p_invoice_id uuid)
returns table (
  id uuid, from_status text, to_status text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_invoice_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from finance.invoice_status_events e
     where e.invoice_id = p_invoice_id
     order by e.created_at asc;
end;
$$;

-- 8.5 admin_list_payment_events --------------------------------------------
create or replace function finance.admin_list_payment_events(
  p_invoice_id uuid default null,
  p_payment_id uuid default null
) returns table (
  id uuid, payment_id uuid, invoice_id uuid,
  from_status text, to_status text, actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_payment_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.payment_id, e.invoice_id,
           e.from_status::text, e.to_status::text,
           e.actor_user_id, e.reason, e.created_at
      from finance.payment_status_events e
     where (p_invoice_id is null or e.invoice_id = p_invoice_id)
       and (p_payment_id is null or e.payment_id = p_payment_id)
     order by e.created_at asc;
end;
$$;

-- 8.6 admin_void_invoice ---------------------------------------------------
create or replace function finance.admin_void_invoice(
  p_invoice_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status finance.invoice_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_void_invoice: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from finance.invoices where id = p_invoice_id and deleted_at is null;
  if v_status is null then
    raise exception 'finance: invoice not found' using errcode = 'P0002';
  end if;
  if v_status = 'voided' then
    raise exception 'finance: already voided' using errcode = 'P0001';
  end if;
  update finance.invoices
     set status = 'voided', voided_at = now(), voided_by = v_actor,
         voided_reason = p_reason, updated_by = v_actor
   where id = p_invoice_id;
  perform finance.fn_record_invoice_event(p_invoice_id, v_status, 'voided', p_reason);
  perform finance.fn_audit('finance.invoice_voided', p_invoice_id,
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
     where t.table_schema = 'finance'
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
     where t.table_schema = 'finance'
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
grant select on finance.invoices               to anon, authenticated;
grant select on finance.invoice_items          to anon, authenticated;
grant select on finance.payment_methods        to authenticated;
grant select on finance.payments               to authenticated;
grant select on finance.invoice_status_events  to authenticated;
grant select on finance.payment_status_events  to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function finance.buyer_create_draft_invoice(uuid, uuid, text, date, date, text, text) to authenticated;
grant execute on function finance.buyer_update_invoice(uuid, date, date, text, text, text, numeric, jsonb) to authenticated;
grant execute on function finance.buyer_upsert_invoice_item(uuid, text, numeric, text, numeric, numeric, uuid, uuid, integer, uuid) to authenticated;
grant execute on function finance.buyer_remove_invoice_item(uuid) to authenticated;
grant execute on function finance.buyer_issue_invoice(uuid) to authenticated;
grant execute on function finance.buyer_send_invoice(uuid) to authenticated;
grant execute on function finance.buyer_mark_overdue(uuid) to authenticated;
grant execute on function finance.buyer_cancel_invoice(uuid, text) to authenticated;
grant execute on function finance.buyer_record_payment(uuid, numeric, uuid, finance.payment_status, date, text, text) to authenticated;
grant execute on function finance.buyer_refund_payment(uuid, text) to authenticated;
grant execute on function finance.buyer_list_invoices(finance.invoice_status, integer, integer) to authenticated;
grant execute on function finance.buyer_get_invoice(uuid) to authenticated;
grant execute on function finance.buyer_upsert_payment_method(finance.payment_method_type, text, text, boolean, jsonb, uuid) to authenticated;
grant execute on function finance.buyer_list_payment_methods(finance.payment_method_type, boolean) to authenticated;

grant execute on function finance.supplier_list_my_invoices(finance.invoice_status, integer, integer) to authenticated;
grant execute on function finance.supplier_get_my_invoice(uuid) to authenticated;
grant execute on function finance.supplier_record_payment_receipt(uuid, numeric, date, text, text) to authenticated;
grant execute on function finance.supplier_list_my_payments(uuid, finance.payment_status, integer, integer) to authenticated;

grant execute on function finance.admin_list_invoices(uuid, uuid, finance.invoice_status, integer, integer) to authenticated;
grant execute on function finance.admin_get_invoice(uuid) to authenticated;
grant execute on function finance.admin_force_invoice_status(uuid, finance.invoice_status, text) to authenticated;
grant execute on function finance.admin_list_invoice_events(uuid) to authenticated;
grant execute on function finance.admin_list_payment_events(uuid, uuid) to authenticated;
grant execute on function finance.admin_void_invoice(uuid, text) to authenticated;
