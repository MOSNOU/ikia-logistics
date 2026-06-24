-- CC-17 / Migration 0028 — Settlement / Escrow Foundation
-- Eleventh business-domain step. New `settlement` schema built atop CC-13/CC-14/CC-16.
-- Append-only over migrations 0001-0027.
--
-- Scope: settlement + logical escrow ledger ONLY.
-- No banking API, PSP, payment gateway, escrow license workflow, advanced accounting,
-- insurance, tax engine, arbitration workflow.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Buyer RPCs derive organization from identity.current_organization_id().
-- Supplier RPCs derive supplier_id from supplier.fn_portal_supplier_id().

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists settlement;
grant usage on schema settlement to anon, authenticated, service_role;
comment on schema settlement is
  'iKIA Phase 2 — settlement / logical escrow domain. Ledger scaffolding only; no banking/PSP/gateway/license/accounting/insurance/arbitration.';

-- ===========================================================================
-- 2. Enums (4)
-- ===========================================================================
create type settlement.settlement_status as enum (
  'draft', 'ready', 'holding', 'released', 'reconciled',
  'disputed', 'cancelled', 'voided'
);

create type settlement.escrow_status as enum (
  'open', 'active', 'frozen', 'closed', 'voided'
);

create type settlement.escrow_entry_type as enum (
  'credit', 'debit', 'hold', 'release', 'reverse', 'adjustment'
);

create type settlement.dispute_status as enum (
  'none', 'opened', 'under_review', 'resolved_buyer', 'resolved_supplier', 'withdrawn'
);

-- ===========================================================================
-- 3. Tables (6)
-- ===========================================================================

-- 3.1 escrow_accounts ------------------------------------------------------
create table settlement.escrow_accounts (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,

  account_code                text not null,
  status                      settlement.escrow_status not null default 'open',
  currency                    text not null default 'USD',

  -- Recomputed balances; ledger entries are the source of truth (see Q5).
  total_credited              numeric not null default 0,
  total_debited               numeric not null default 0,
  total_held                  numeric not null default 0,
  total_released              numeric not null default 0,
  available_balance           numeric not null default 0,

  metadata                    jsonb not null default '{}'::jsonb,

  opened_at                   timestamptz not null default now(),
  opened_by                   uuid references auth.users(id) on delete set null,
  activated_at                timestamptz,
  frozen_at                   timestamptz,
  frozen_by                   uuid references auth.users(id) on delete set null,
  frozen_reason               text,
  closed_at                   timestamptz,
  closed_by                   uuid references auth.users(id) on delete set null,
  closed_reason               text,
  voided_at                   timestamptz,
  voided_by                   uuid references auth.users(id) on delete set null,
  voided_reason               text,

  created_by                  uuid references auth.users(id) on delete set null,
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table settlement.escrow_accounts is
  'Logical escrow account per (buyer organization, supplier, currency). Balances are recomputed from settlement.escrow_entries.';

-- One active (non-voided, non-deleted) account per (org, supplier, currency).
create unique index escrow_accounts_unique_active
  on settlement.escrow_accounts(organization_id, supplier_id, lower(currency))
  where deleted_at is null and status <> 'voided';

create unique index escrow_accounts_code_unique
  on settlement.escrow_accounts(tenant_id, lower(account_code))
  where deleted_at is null;

create index escrow_accounts_supplier_idx on settlement.escrow_accounts(supplier_id);
create index escrow_accounts_status_idx   on settlement.escrow_accounts(status);

-- 3.2 escrow_entries (immutable ledger) ------------------------------------
create table settlement.escrow_entries (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  escrow_account_id           uuid not null references settlement.escrow_accounts(id) on delete cascade,
  settlement_id               uuid,  -- FK added after settlements created below
  finance_payment_id          uuid references finance.payments(id) on delete set null,

  entry_type                  settlement.escrow_entry_type not null,
  amount                      numeric not null,
  currency                    text not null,
  reference_kind              text,
  notes                       text,
  actor_user_id               uuid references auth.users(id) on delete set null,
  actor_organization_id       uuid references organization.organizations(id) on delete set null,
  metadata                    jsonb not null default '{}'::jsonb,
  created_at                  timestamptz not null default now()
);

comment on table settlement.escrow_entries is
  'Immutable append-only ledger. Single source of truth for escrow balances. No UPDATE/DELETE policies.';

create index escrow_entries_account_idx on settlement.escrow_entries(escrow_account_id, created_at desc);

-- 3.3 escrow_status_events (immutable) -------------------------------------
create table settlement.escrow_status_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  escrow_account_id       uuid not null references settlement.escrow_accounts(id) on delete cascade,

  from_status             settlement.escrow_status,
  to_status               settlement.escrow_status not null,
  actor_user_id           uuid references auth.users(id) on delete set null,
  actor_organization_id   uuid references organization.organizations(id) on delete set null,
  reason                  text,
  metadata                jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table settlement.escrow_status_events is
  'Immutable escrow account lifecycle trail. No UPDATE/DELETE policies.';

create index escrow_status_events_account_idx
  on settlement.escrow_status_events(escrow_account_id, created_at desc);

-- 3.4 settlements ----------------------------------------------------------
create table settlement.settlements (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,
  escrow_account_id           uuid references settlement.escrow_accounts(id) on delete restrict,
  executed_contract_id        uuid references contract.executed_contracts(id) on delete restrict,
  shipment_id                 uuid references shipment.shipments(id) on delete restrict,
  supplier_id                 uuid not null references supplier.suppliers(id) on delete restrict,
  supplier_organization_id    uuid references organization.organizations(id) on delete set null,

  settlement_code             text not null,
  status                      settlement.settlement_status not null default 'draft',
  currency                    text not null default 'USD',

  planned_amount              numeric not null default 0,
  held_amount                 numeric not null default 0,
  released_amount             numeric not null default 0,
  reconciled_amount           numeric not null default 0,
  fees_amount                 numeric not null default 0,
  platform_fee_amount         numeric not null default 0,
  net_to_supplier_amount      numeric not null default 0,

  settlement_terms_text       text,
  notes                       text,
  metadata                    jsonb not null default '{}'::jsonb,

  dispute_status              settlement.dispute_status not null default 'none',
  disputed_at                 timestamptz,
  disputed_by                 uuid references auth.users(id) on delete set null,
  dispute_opened_by_party     text,
  dispute_reason              text,

  ready_at                    timestamptz,
  ready_by                    uuid references auth.users(id) on delete set null,
  hold_at                     timestamptz,
  hold_by                     uuid references auth.users(id) on delete set null,
  released_at                 timestamptz,
  released_by                 uuid references auth.users(id) on delete set null,
  release_reason              text,
  reconciled_at               timestamptz,
  reconciled_by               uuid references auth.users(id) on delete set null,
  cancelled_at                timestamptz,
  cancelled_by                uuid references auth.users(id) on delete set null,
  cancelled_reason            text,
  voided_at                   timestamptz,
  voided_by                   uuid references auth.users(id) on delete set null,
  voided_reason               text,

  created_by                  uuid references auth.users(id) on delete set null,
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id) on delete set null,
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1,

  constraint settlements_has_anchor check (
    executed_contract_id is not null or shipment_id is not null
  )
);

comment on table settlement.settlements is
  'Settlement record per executed contract and/or shipment. Logical only; no banking/gateway.';

create unique index settlements_code_unique
  on settlement.settlements(tenant_id, lower(settlement_code))
  where deleted_at is null;

create index settlements_contract_idx on settlement.settlements(executed_contract_id);
create index settlements_shipment_idx on settlement.settlements(shipment_id);
create index settlements_supplier_idx on settlement.settlements(supplier_id);
create index settlements_escrow_idx   on settlement.settlements(escrow_account_id);
create index settlements_status_idx   on settlement.settlements(status);

-- Now add the deferred FK from escrow_entries -> settlements.
alter table settlement.escrow_entries
  add constraint escrow_entries_settlement_fk
  foreign key (settlement_id) references settlement.settlements(id) on delete set null;

create index escrow_entries_settlement_idx on settlement.escrow_entries(settlement_id);

-- 3.5 settlement_items -----------------------------------------------------
create table settlement.settlement_items (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  settlement_id       uuid not null references settlement.settlements(id) on delete cascade,
  finance_invoice_id  uuid references finance.invoices(id) on delete set null,
  finance_payment_id  uuid references finance.payments(id) on delete set null,

  description         text not null,
  amount              numeric not null default 0,
  fees_amount         numeric not null default 0,
  platform_fee_amount numeric not null default 0,
  net_amount          numeric not null default 0,
  metadata            jsonb not null default '{}'::jsonb,
  sort_order          integer not null default 0,

  created_by          uuid references auth.users(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table settlement.settlement_items is
  'Settlement line items. Optional back-pointer to finance invoice / payment. net_amount = amount - fees - platform_fee.';

create index settlement_items_settlement_idx on settlement.settlement_items(settlement_id);

-- 3.6 settlement_events (immutable) ----------------------------------------
create table settlement.settlement_events (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,
  settlement_id           uuid not null references settlement.settlements(id) on delete cascade,

  from_status             settlement.settlement_status,
  to_status               settlement.settlement_status not null,
  event_type              text not null,
  actor_user_id           uuid references auth.users(id) on delete set null,
  actor_organization_id   uuid references organization.organizations(id) on delete set null,
  reason                  text,
  payload                 jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table settlement.settlement_events is
  'Immutable settlement lifecycle trail. No UPDATE/DELETE policies.';

create index settlement_events_settlement_idx
  on settlement.settlement_events(settlement_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function settlement.fn_audit(
  p_action_code   text,
  p_resource_id   uuid,
  p_resource_type text default 'settlement',
  p_payload       jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  if p_resource_type = 'settlement' then
    select tenant_id, organization_id into v_t, v_o
      from settlement.settlements where id = p_resource_id;
  else
    select tenant_id, organization_id into v_t, v_o
      from settlement.escrow_accounts where id = p_resource_id;
  end if;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    p_resource_type, p_resource_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_next_settlement_code / fn_next_escrow_code ------------------------
create or replace function settlement.fn_next_settlement_code(p_tenant_id uuid)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare v_code text;
begin
  v_code := 'STL-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

create or replace function settlement.fn_next_escrow_code(p_tenant_id uuid)
returns text language plpgsql volatile security definer set search_path = '' as $$
declare v_code text;
begin
  v_code := 'ESC-' || to_char(now() at time zone 'utc', 'YYYY') || '-' ||
            substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);
  return v_code;
end;
$$;

-- 4.3 fn_record_settlement_event -------------------------------------------
create or replace function settlement.fn_record_settlement_event(
  p_settlement_id uuid,
  p_from         settlement.settlement_status,
  p_to           settlement.settlement_status,
  p_event_type   text,
  p_reason       text default null,
  p_payload      jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from settlement.settlements where id = p_settlement_id;
  insert into settlement.settlement_events (
    tenant_id, organization_id, settlement_id,
    from_status, to_status, event_type, actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_settlement_id,
    p_from, p_to, p_event_type, auth.uid(), v_o, p_reason, coalesce(p_payload, '{}'::jsonb)
  );
end;
$$;

-- 4.4 fn_record_escrow_status_event ----------------------------------------
create or replace function settlement.fn_record_escrow_status_event(
  p_account_id uuid,
  p_from       settlement.escrow_status,
  p_to         settlement.escrow_status,
  p_reason     text default null,
  p_metadata   jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from settlement.escrow_accounts where id = p_account_id;
  insert into settlement.escrow_status_events (
    tenant_id, organization_id, escrow_account_id,
    from_status, to_status, actor_user_id, actor_organization_id, reason, metadata
  ) values (
    v_t, v_o, p_account_id,
    p_from, p_to, auth.uid(), v_o, p_reason, coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

-- 4.5 fn_record_escrow_entry (single point of ledger mutation) -------------
create or replace function settlement.fn_record_escrow_entry(
  p_account_id     uuid,
  p_entry_type     settlement.escrow_entry_type,
  p_amount         numeric,
  p_settlement_id  uuid default null,
  p_payment_id     uuid default null,
  p_reference_kind text default null,
  p_notes          text default null,
  p_metadata       jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_currency text;
  v_id uuid;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'settlement: ledger entry amount must be > 0' using errcode = '22023';
  end if;
  select tenant_id, organization_id, currency
    into v_tenant, v_org, v_currency
    from settlement.escrow_accounts where id = p_account_id;
  insert into settlement.escrow_entries (
    tenant_id, organization_id, escrow_account_id, settlement_id, finance_payment_id,
    entry_type, amount, currency, reference_kind, notes,
    actor_user_id, actor_organization_id, metadata
  ) values (
    v_tenant, v_org, p_account_id, p_settlement_id, p_payment_id,
    p_entry_type, p_amount, v_currency, p_reference_kind, p_notes,
    v_actor, v_org, coalesce(p_metadata, '{}'::jsonb)
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 4.6 fn_recompute_escrow_balances -----------------------------------------
-- Recomputes total_credited / debited / held / released / available_balance
-- from settlement.escrow_entries.
create or replace function settlement.fn_recompute_escrow_balances(p_account_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_credit numeric := 0;
  v_debit  numeric := 0;
  v_hold   numeric := 0;
  v_rel    numeric := 0;
  v_adj    numeric := 0;
  v_rev    numeric := 0;
  v_status settlement.escrow_status;
begin
  -- credit and adjustment add to credited
  select coalesce(sum(amount), 0) into v_credit
    from settlement.escrow_entries
   where escrow_account_id = p_account_id and entry_type = 'credit';
  select coalesce(sum(amount), 0) into v_adj
    from settlement.escrow_entries
   where escrow_account_id = p_account_id and entry_type = 'adjustment';
  select coalesce(sum(amount), 0) into v_debit
    from settlement.escrow_entries
   where escrow_account_id = p_account_id and entry_type = 'debit';
  select coalesce(sum(amount), 0) into v_hold
    from settlement.escrow_entries
   where escrow_account_id = p_account_id and entry_type = 'hold';
  select coalesce(sum(amount), 0) into v_rel
    from settlement.escrow_entries
   where escrow_account_id = p_account_id and entry_type = 'release';
  select coalesce(sum(amount), 0) into v_rev
    from settlement.escrow_entries
   where escrow_account_id = p_account_id and entry_type = 'reverse';

  -- `reverse` semantically undoes BOTH the credit and the hold for the same
  -- amount (used when cancelling a holding settlement). So:
  --   total_credited = credit + adjustment - reverse
  --   total_held     = max(hold - release - reverse, 0)
  --   available      = total_credited - total_debited - total_held
  update settlement.escrow_accounts
     set total_credited    = v_credit + v_adj - v_rev,
         total_debited     = v_debit,
         total_held        = greatest(v_hold - v_rel - v_rev, 0),
         total_released    = v_rel,
         available_balance = (v_credit + v_adj - v_rev) - v_debit
                             - greatest(v_hold - v_rel - v_rev, 0)
   where id = p_account_id;

  -- Auto-activate from 'open' on first credit.
  select status into v_status from settlement.escrow_accounts where id = p_account_id;
  if v_status = 'open' and v_credit > 0 then
    update settlement.escrow_accounts
       set status = 'active', activated_at = now()
     where id = p_account_id;
    perform settlement.fn_record_escrow_status_event(p_account_id, 'open', 'active', 'first_credit');
  end if;
end;
$$;

-- 4.7 fn_recompute_settlement_totals ---------------------------------------
create or replace function settlement.fn_recompute_settlement_totals(p_settlement_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_planned numeric := 0;
  v_fees    numeric := 0;
  v_platform numeric := 0;
  v_net      numeric := 0;
begin
  select coalesce(sum(amount), 0),
         coalesce(sum(fees_amount), 0),
         coalesce(sum(platform_fee_amount), 0),
         coalesce(sum(net_amount), 0)
    into v_planned, v_fees, v_platform, v_net
    from settlement.settlement_items
   where settlement_id = p_settlement_id and deleted_at is null;
  update settlement.settlements
     set planned_amount        = v_planned,
         fees_amount           = v_fees,
         platform_fee_amount   = v_platform,
         net_to_supplier_amount = v_net
   where id = p_settlement_id;
end;
$$;

-- 4.8 fn_assert_buyer_for_settlement ---------------------------------------
create or replace function settlement.fn_assert_buyer_for_settlement(p_settlement_id uuid)
returns settlement.settlement_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid; v_status settlement.settlement_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id, status into v_org, v_status
    from settlement.settlements where id = p_settlement_id and deleted_at is null;
  if v_org is null then
    raise exception 'settlement: not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'settlement: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'settlement: not owned by caller organization' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.9 fn_assert_buyer_for_escrow -------------------------------------------
create or replace function settlement.fn_assert_buyer_for_escrow(p_account_id uuid)
returns settlement.escrow_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid; v_status settlement.escrow_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id, status into v_org, v_status
    from settlement.escrow_accounts where id = p_account_id and deleted_at is null;
  if v_org is null then
    raise exception 'settlement: escrow account not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'settlement: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'settlement: escrow not owned by caller organization' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.10 fn_assert_settlement_editable ---------------------------------------
create or replace function settlement.fn_assert_settlement_editable(p_settlement_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status settlement.settlement_status;
begin
  select status into v_status from settlement.settlements
   where id = p_settlement_id and deleted_at is null;
  if v_status is null then
    raise exception 'settlement: not found' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'settlement: locked from edit (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table settlement.escrow_accounts        enable row level security;
alter table settlement.escrow_entries         enable row level security;
alter table settlement.escrow_status_events   enable row level security;
alter table settlement.settlements            enable row level security;
alter table settlement.settlement_items       enable row level security;
alter table settlement.settlement_events      enable row level security;

-- 5.1 escrow_accounts ------------------------------------------------------
drop policy if exists escrow_accounts_select on settlement.escrow_accounts;
create policy escrow_accounts_select on settlement.escrow_accounts
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = settlement.escrow_accounts.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = settlement.escrow_accounts.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists escrow_accounts_admin_modify on settlement.escrow_accounts;
create policy escrow_accounts_admin_modify on settlement.escrow_accounts
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 escrow_entries (immutable, no INS/UPD/DEL policies) ------------------
drop policy if exists escrow_entries_select on settlement.escrow_entries;
create policy escrow_entries_select on settlement.escrow_entries
  for select
  using (
    exists (
      select 1 from settlement.escrow_accounts ea
       where ea.id = settlement.escrow_entries.escrow_account_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ea.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ea.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- 5.3 escrow_status_events (immutable) -------------------------------------
drop policy if exists escrow_status_events_select on settlement.escrow_status_events;
create policy escrow_status_events_select on settlement.escrow_status_events
  for select
  using (
    exists (
      select 1 from settlement.escrow_accounts ea
       where ea.id = settlement.escrow_status_events.escrow_account_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = ea.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers s
              join organization.memberships m on m.organization_id = s.organization_id
             where s.id = ea.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- 5.4 settlements ----------------------------------------------------------
drop policy if exists settlements_select on settlement.settlements;
create policy settlements_select on settlement.settlements
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = settlement.settlements.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = settlement.settlements.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists settlements_admin_modify on settlement.settlements;
create policy settlements_admin_modify on settlement.settlements
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.5 settlement_items: same audience as parent settlement.
drop policy if exists settlement_items_select on settlement.settlement_items;
create policy settlement_items_select on settlement.settlement_items
  for select
  using (
    deleted_at is null
    and exists (
      select 1 from settlement.settlements s
       where s.id = settlement.settlement_items.settlement_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = s.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers su
              join organization.memberships m on m.organization_id = su.organization_id
             where su.id = s.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists settlement_items_admin_modify on settlement.settlement_items;
create policy settlement_items_admin_modify on settlement.settlement_items
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.6 settlement_events (immutable) ----------------------------------------
drop policy if exists settlement_events_select on settlement.settlement_events;
create policy settlement_events_select on settlement.settlement_events
  for select
  using (
    exists (
      select 1 from settlement.settlements s
       where s.id = settlement.settlement_events.settlement_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = s.organization_id
                and m.deleted_at is null and m.status = 'active'
           )
           or exists (
             select 1 from supplier.suppliers su
              join organization.memberships m on m.organization_id = su.organization_id
             where su.id = s.supplier_id
               and m.user_id = identity.current_user_id()
               and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. Buyer RPCs (11)
-- ===========================================================================

-- 6.1 buyer_open_escrow_account --------------------------------------------
create or replace function settlement.buyer_open_escrow_account(
  p_supplier_id uuid,
  p_currency    text default 'USD',
  p_metadata    jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_org uuid := identity.current_organization_id();
  v_tenant uuid; v_sup_org uuid;
  v_code text;
  v_id uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'settlement: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null then
    raise exception 'settlement: no active organization in JWT' using errcode = 'P0002';
  end if;
  if p_supplier_id is null then
    raise exception 'settlement: supplier_id is required' using errcode = '22023';
  end if;

  select organization_id into v_sup_org from supplier.suppliers
   where id = p_supplier_id and deleted_at is null;
  if v_sup_org is null then
    raise exception 'settlement: supplier not found' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from settlement.escrow_accounts
     where organization_id = v_caller_org and supplier_id = p_supplier_id
       and lower(currency) = lower(p_currency)
       and deleted_at is null and status <> 'voided'
  ) then
    raise exception 'settlement: active escrow account already exists for (org, supplier, currency)'
      using errcode = '23505';
  end if;

  select tenant_id into v_tenant from organization.organizations where id = v_caller_org;
  v_code := settlement.fn_next_escrow_code(v_tenant);

  insert into settlement.escrow_accounts (
    tenant_id, organization_id, supplier_id, supplier_organization_id,
    account_code, status, currency, metadata, opened_by, created_by, updated_by
  ) values (
    v_tenant, v_caller_org, p_supplier_id, v_sup_org,
    v_code, 'open', p_currency, coalesce(p_metadata, '{}'::jsonb), v_actor, v_actor, v_actor
  ) returning id into v_id;

  perform settlement.fn_record_escrow_status_event(v_id, null, 'open', 'account_opened');
  perform settlement.fn_audit('settlement.escrow_opened', v_id, 'escrow_account',
    jsonb_build_object('supplier_id', p_supplier_id::text, 'currency', p_currency));
  return v_id;
end;
$$;

-- 6.2 buyer_create_draft_settlement ----------------------------------------
create or replace function settlement.buyer_create_draft_settlement(
  p_executed_contract_id uuid default null,
  p_shipment_id          uuid default null,
  p_escrow_account_id    uuid default null,
  p_currency             text default 'USD',
  p_settlement_terms     text default null,
  p_notes                text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_org uuid := identity.current_organization_id();
  v_buyer_org uuid; v_supplier_id uuid; v_supplier_org uuid;
  v_tenant uuid;
  v_code text;
  v_id uuid;
  v_escrow_currency text;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'settlement: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if p_executed_contract_id is null and p_shipment_id is null then
    raise exception 'settlement: either executed_contract_id or shipment_id is required'
      using errcode = '22023';
  end if;

  if p_executed_contract_id is not null then
    select ec.organization_id, ec.supplier_id, ec.supplier_organization_id, ec.tenant_id
      into v_buyer_org, v_supplier_id, v_supplier_org, v_tenant
      from contract.executed_contracts ec
     where ec.id = p_executed_contract_id and ec.deleted_at is null;
    if v_buyer_org is null then
      raise exception 'settlement: executed contract not found' using errcode = 'P0002';
    end if;
  end if;

  if p_shipment_id is not null then
    if v_buyer_org is null then
      select sh.organization_id, sh.supplier_id, sh.supplier_organization_id, sh.tenant_id
        into v_buyer_org, v_supplier_id, v_supplier_org, v_tenant
        from shipment.shipments sh
       where sh.id = p_shipment_id and sh.deleted_at is null;
      if v_buyer_org is null then
        raise exception 'settlement: shipment not found' using errcode = 'P0002';
      end if;
    else
      if not exists (
        select 1 from shipment.shipments sh
         where sh.id = p_shipment_id
           and sh.executed_contract_id = p_executed_contract_id
           and sh.deleted_at is null
      ) then
        raise exception 'settlement: shipment does not belong to the supplied executed contract'
          using errcode = '42501';
      end if;
    end if;
  end if;

  if not identity.is_platform_admin() then
    if v_caller_org is null or v_caller_org <> v_buyer_org then
      raise exception 'settlement: anchor not in caller''s organization' using errcode = '42501';
    end if;
  end if;

  -- Escrow account (if supplied) must match (org, supplier) AND currency.
  if p_escrow_account_id is not null then
    select currency into v_escrow_currency from settlement.escrow_accounts
     where id = p_escrow_account_id and deleted_at is null
       and organization_id = v_buyer_org and supplier_id = v_supplier_id;
    if v_escrow_currency is null then
      raise exception 'settlement: escrow account not found for (org, supplier)' using errcode = '42501';
    end if;
    if lower(v_escrow_currency) <> lower(p_currency) then
      raise exception 'settlement: currency mismatch with escrow account (% vs %)', p_currency, v_escrow_currency
        using errcode = 'P0001';
    end if;
  end if;

  v_code := settlement.fn_next_settlement_code(v_tenant);
  insert into settlement.settlements (
    tenant_id, organization_id, escrow_account_id, executed_contract_id, shipment_id,
    supplier_id, supplier_organization_id, settlement_code, status, currency,
    settlement_terms_text, notes, created_by, updated_by
  ) values (
    v_tenant, v_buyer_org, p_escrow_account_id, p_executed_contract_id, p_shipment_id,
    v_supplier_id, v_supplier_org, v_code, 'draft', p_currency,
    p_settlement_terms, p_notes, v_actor, v_actor
  ) returning id into v_id;

  perform settlement.fn_record_settlement_event(v_id, null, 'draft', 'settlement_created');
  perform settlement.fn_audit('settlement.created', v_id, 'settlement');
  return v_id;
end;
$$;

-- 6.3 buyer_update_settlement (draft only) ---------------------------------
create or replace function settlement.buyer_update_settlement(
  p_settlement_id        uuid,
  p_escrow_account_id    uuid default null,
  p_currency             text default null,
  p_settlement_terms     text default null,
  p_notes                text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
        v_curr text;
        v_escrow_currency text;
        v_org uuid; v_sup uuid;
begin
  perform settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  perform settlement.fn_assert_settlement_editable(p_settlement_id);

  if p_escrow_account_id is not null then
    select s.organization_id, s.supplier_id, coalesce(p_currency, s.currency)
      into v_org, v_sup, v_curr
      from settlement.settlements s where s.id = p_settlement_id;
    select currency into v_escrow_currency from settlement.escrow_accounts
     where id = p_escrow_account_id and deleted_at is null
       and organization_id = v_org and supplier_id = v_sup;
    if v_escrow_currency is null then
      raise exception 'settlement: escrow account not found for (org, supplier)' using errcode = '42501';
    end if;
    if lower(v_escrow_currency) <> lower(v_curr) then
      raise exception 'settlement: currency mismatch with escrow account'
        using errcode = 'P0001';
    end if;
  end if;

  update settlement.settlements
     set escrow_account_id     = coalesce(p_escrow_account_id, escrow_account_id),
         currency              = coalesce(p_currency, currency),
         settlement_terms_text = coalesce(p_settlement_terms, settlement_terms_text),
         notes                 = coalesce(p_notes, notes),
         updated_by            = v_actor
   where id = p_settlement_id;
  perform settlement.fn_audit('settlement.updated', p_settlement_id, 'settlement');
end;
$$;

-- 6.4 buyer_upsert_settlement_item -----------------------------------------
create or replace function settlement.buyer_upsert_settlement_item(
  p_settlement_id      uuid,
  p_description        text,
  p_amount             numeric default 0,
  p_fees_amount        numeric default 0,
  p_platform_fee_amount numeric default 0,
  p_finance_invoice_id uuid default null,
  p_finance_payment_id uuid default null,
  p_sort_order         integer default 0,
  p_item_id            uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_id uuid;
  v_net numeric;
begin
  perform settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  perform settlement.fn_assert_settlement_editable(p_settlement_id);
  if p_description is null or btrim(p_description) = '' then
    raise exception 'settlement: item description is required' using errcode = '22023';
  end if;

  v_net := coalesce(p_amount, 0) - coalesce(p_fees_amount, 0) - coalesce(p_platform_fee_amount, 0);

  select tenant_id, organization_id into v_tenant, v_org
    from settlement.settlements where id = p_settlement_id;

  if p_item_id is null then
    insert into settlement.settlement_items (
      tenant_id, organization_id, settlement_id,
      finance_invoice_id, finance_payment_id, description,
      amount, fees_amount, platform_fee_amount, net_amount,
      sort_order, created_by, updated_by
    ) values (
      v_tenant, v_org, p_settlement_id,
      p_finance_invoice_id, p_finance_payment_id, p_description,
      coalesce(p_amount, 0), coalesce(p_fees_amount, 0), coalesce(p_platform_fee_amount, 0), v_net,
      p_sort_order, v_actor, v_actor
    ) returning id into v_id;
  else
    update settlement.settlement_items
       set finance_invoice_id  = coalesce(p_finance_invoice_id, finance_invoice_id),
           finance_payment_id  = coalesce(p_finance_payment_id, finance_payment_id),
           description         = p_description,
           amount              = coalesce(p_amount, 0),
           fees_amount         = coalesce(p_fees_amount, 0),
           platform_fee_amount = coalesce(p_platform_fee_amount, 0),
           net_amount          = v_net,
           sort_order          = p_sort_order,
           updated_by          = v_actor
     where id = p_item_id and settlement_id = p_settlement_id and deleted_at is null
     returning id into v_id;
    if v_id is null then
      raise exception 'settlement: item not found in this settlement' using errcode = 'P0002';
    end if;
  end if;

  perform settlement.fn_recompute_settlement_totals(p_settlement_id);
  perform settlement.fn_audit('settlement.item_upserted', p_settlement_id, 'settlement',
    jsonb_build_object('item_id', v_id::text));
  return v_id;
end;
$$;

-- 6.5 buyer_remove_settlement_item -----------------------------------------
create or replace function settlement.buyer_remove_settlement_item(p_item_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_settlement uuid;
begin
  select settlement_id into v_settlement from settlement.settlement_items
   where id = p_item_id and deleted_at is null;
  if v_settlement is null then
    raise exception 'settlement: item not found' using errcode = 'P0002';
  end if;
  perform settlement.fn_assert_buyer_for_settlement(v_settlement);
  perform settlement.fn_assert_settlement_editable(v_settlement);

  update settlement.settlement_items
     set deleted_at = now(), updated_by = v_actor
   where id = p_item_id;
  perform settlement.fn_recompute_settlement_totals(v_settlement);
  perform settlement.fn_audit('settlement.item_removed', v_settlement, 'settlement',
    jsonb_build_object('item_id', p_item_id::text));
end;
$$;

-- 6.6 buyer_mark_settlement_ready ------------------------------------------
create or replace function settlement.buyer_mark_settlement_ready(p_settlement_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status settlement.settlement_status;
        v_planned numeric;
begin
  v_status := settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  if v_status <> 'draft' then
    raise exception 'settlement: invalid_transition: cannot mark ready from %', v_status using errcode = 'P0001';
  end if;
  perform settlement.fn_recompute_settlement_totals(p_settlement_id);
  select planned_amount into v_planned from settlement.settlements where id = p_settlement_id;
  if v_planned is null or v_planned <= 0 then
    raise exception 'settlement: planned_amount must be > 0 to mark ready' using errcode = 'P0001';
  end if;
  update settlement.settlements
     set status = 'ready', ready_at = now(), ready_by = v_actor, updated_by = v_actor
   where id = p_settlement_id;
  perform settlement.fn_record_settlement_event(p_settlement_id, 'draft', 'ready', 'marked_ready');
  perform settlement.fn_audit('settlement.marked_ready', p_settlement_id, 'settlement');
end;
$$;

-- 6.7 buyer_hold_settlement ------------------------------------------------
-- ready → holding. Requires an escrow account and writes a credit + hold pair.
create or replace function settlement.buyer_hold_settlement(p_settlement_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status settlement.settlement_status;
  v_escrow uuid; v_currency text; v_planned numeric;
  v_acct_currency text; v_acct_status settlement.escrow_status;
begin
  v_status := settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  if v_status <> 'ready' then
    raise exception 'settlement: invalid_transition: cannot hold from %', v_status using errcode = 'P0001';
  end if;

  select escrow_account_id, currency, planned_amount
    into v_escrow, v_currency, v_planned
    from settlement.settlements where id = p_settlement_id;
  if v_escrow is null then
    raise exception 'settlement: escrow_account_id is required to hold' using errcode = '22023';
  end if;

  select currency, status into v_acct_currency, v_acct_status
    from settlement.escrow_accounts where id = v_escrow and deleted_at is null;
  if v_acct_currency is null then
    raise exception 'settlement: escrow account not found' using errcode = 'P0002';
  end if;
  if lower(v_acct_currency) <> lower(v_currency) then
    raise exception 'settlement: currency mismatch with escrow account' using errcode = 'P0001';
  end if;
  if v_acct_status not in ('open', 'active') then
    raise exception 'settlement: escrow account not in active state (status=%)', v_acct_status
      using errcode = 'P0001';
  end if;

  -- Credit + hold pair for the settlement's planned amount.
  perform settlement.fn_record_escrow_entry(v_escrow, 'credit', v_planned, p_settlement_id, null,
    'settlement_hold_credit', null, '{}'::jsonb);
  perform settlement.fn_record_escrow_entry(v_escrow, 'hold', v_planned, p_settlement_id, null,
    'settlement_hold', null, '{}'::jsonb);
  perform settlement.fn_recompute_escrow_balances(v_escrow);

  update settlement.settlements
     set status = 'holding', hold_at = now(), hold_by = v_actor,
         held_amount = v_planned, updated_by = v_actor
   where id = p_settlement_id;
  perform settlement.fn_record_settlement_event(p_settlement_id, 'ready', 'holding', 'settlement_held');
  perform settlement.fn_audit('settlement.held', p_settlement_id, 'settlement',
    jsonb_build_object('escrow_account_id', v_escrow::text, 'amount', v_planned));
end;
$$;

-- 6.8 buyer_release_settlement ---------------------------------------------
-- holding → released. Writes release entry equal to held_amount and a debit.
create or replace function settlement.buyer_release_settlement(
  p_settlement_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status settlement.settlement_status;
  v_escrow uuid; v_held numeric;
begin
  v_status := settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  if v_status <> 'holding' then
    raise exception 'settlement: invalid_transition: cannot release from %', v_status using errcode = 'P0001';
  end if;
  select escrow_account_id, held_amount into v_escrow, v_held
    from settlement.settlements where id = p_settlement_id;
  if v_escrow is null then
    raise exception 'settlement: escrow_account_id is required to release' using errcode = '22023';
  end if;

  -- release reduces held, debit reduces credited balance.
  perform settlement.fn_record_escrow_entry(v_escrow, 'release', v_held, p_settlement_id, null,
    'settlement_release', p_reason, '{}'::jsonb);
  perform settlement.fn_record_escrow_entry(v_escrow, 'debit', v_held, p_settlement_id, null,
    'settlement_release_debit', p_reason, '{}'::jsonb);
  perform settlement.fn_recompute_escrow_balances(v_escrow);

  update settlement.settlements
     set status = 'released', released_at = now(), released_by = v_actor,
         release_reason = p_reason,
         released_amount = v_held,
         updated_by = v_actor
   where id = p_settlement_id;
  perform settlement.fn_record_settlement_event(p_settlement_id, 'holding', 'released', 'settlement_released', p_reason);
  perform settlement.fn_audit('settlement.released', p_settlement_id, 'settlement',
    jsonb_build_object('amount', v_held));
end;
$$;

-- 6.9 buyer_cancel_settlement ----------------------------------------------
-- Allowed from draft/ready/holding (holding cancel reverses the hold).
create or replace function settlement.buyer_cancel_settlement(
  p_settlement_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status settlement.settlement_status;
  v_escrow uuid; v_held numeric;
begin
  v_status := settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  if v_status in ('released', 'reconciled', 'cancelled', 'voided') then
    raise exception 'settlement: invalid_transition: cannot cancel from %', v_status using errcode = 'P0001';
  end if;
  if v_status = 'holding' then
    select escrow_account_id, held_amount into v_escrow, v_held
      from settlement.settlements where id = p_settlement_id;
    -- Reverse the hold + credit so balances return to zero for this settlement.
    perform settlement.fn_record_escrow_entry(v_escrow, 'reverse', v_held, p_settlement_id, null,
      'settlement_cancelled_reverse_hold', p_reason, '{}'::jsonb);
    perform settlement.fn_recompute_escrow_balances(v_escrow);
  end if;
  update settlement.settlements
     set status = 'cancelled', cancelled_at = now(), cancelled_by = v_actor,
         cancelled_reason = p_reason, updated_by = v_actor
   where id = p_settlement_id;
  perform settlement.fn_record_settlement_event(p_settlement_id, v_status, 'cancelled', 'cancelled', p_reason);
  perform settlement.fn_audit('settlement.cancelled', p_settlement_id, 'settlement',
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.10 buyer_list_settlements ----------------------------------------------
create or replace function settlement.buyer_list_settlements(
  p_escrow_account_id uuid                            default null,
  p_status            settlement.settlement_status    default null,
  p_limit             integer                         default 25,
  p_offset            integer                         default 0
) returns table (
  id uuid, settlement_code text, executed_contract_id uuid, shipment_id uuid,
  escrow_account_id uuid, supplier_id uuid, status text, currency text,
  planned_amount numeric, held_amount numeric, released_amount numeric,
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
    raise exception 'settlement: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'settlement: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select s.id, s.settlement_code, s.executed_contract_id, s.shipment_id,
           s.escrow_account_id, s.supplier_id, s.status::text, s.currency,
           s.planned_amount, s.held_amount, s.released_amount,
           s.created_at, s.updated_at
      from settlement.settlements s
     where s.deleted_at is null
       and (identity.is_platform_admin() or s.organization_id = v_caller_org)
       and (p_escrow_account_id is null or s.escrow_account_id = p_escrow_account_id)
       and (p_status is null or s.status = p_status)
     order by s.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.11 buyer_get_settlement ------------------------------------------------
create or replace function settlement.buyer_get_settlement(p_settlement_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform settlement.fn_assert_buyer_for_settlement(p_settlement_id);
  return (
    select jsonb_build_object(
      'id', s.id, 'settlement_code', s.settlement_code,
      'executed_contract_id', s.executed_contract_id, 'shipment_id', s.shipment_id,
      'escrow_account_id', s.escrow_account_id, 'supplier_id', s.supplier_id,
      'status', s.status, 'currency', s.currency,
      'planned_amount', s.planned_amount, 'held_amount', s.held_amount,
      'released_amount', s.released_amount, 'reconciled_amount', s.reconciled_amount,
      'fees_amount', s.fees_amount, 'platform_fee_amount', s.platform_fee_amount,
      'net_to_supplier_amount', s.net_to_supplier_amount,
      'dispute_status', s.dispute_status, 'disputed_at', s.disputed_at,
      'created_at', s.created_at, 'updated_at', s.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'description', it.description, 'amount', it.amount,
          'fees_amount', it.fees_amount, 'platform_fee_amount', it.platform_fee_amount,
          'net_amount', it.net_amount
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from settlement.settlement_items it
         where it.settlement_id = s.id and it.deleted_at is null
      ),
      'events', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', e.id, 'from_status', e.from_status, 'to_status', e.to_status,
          'event_type', e.event_type, 'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from settlement.settlement_events e
         where e.settlement_id = s.id
      )
    )
    from settlement.settlements s where s.id = p_settlement_id
  );
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (4)
-- ===========================================================================

-- 7.1 supplier_list_my_settlements -----------------------------------------
create or replace function settlement.supplier_list_my_settlements(
  p_status settlement.settlement_status default null,
  p_limit  integer                       default 25,
  p_offset integer                       default 0
) returns table (
  id uuid, settlement_code text, executed_contract_id uuid, shipment_id uuid,
  status text, currency text, planned_amount numeric, released_amount numeric,
  dispute_status text, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select s.id, s.settlement_code, s.executed_contract_id, s.shipment_id,
           s.status::text, s.currency, s.planned_amount, s.released_amount,
           s.dispute_status::text, s.created_at, s.updated_at
      from settlement.settlements s
     where s.deleted_at is null
       and s.supplier_id = v_supplier
       and (p_status is null or s.status = p_status)
     order by s.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 supplier_get_my_settlement -------------------------------------------
create or replace function settlement.supplier_get_my_settlement(p_settlement_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_sup uuid := supplier.fn_portal_supplier_id(); v_sup uuid;
begin
  select supplier_id into v_sup from settlement.settlements
   where id = p_settlement_id and deleted_at is null;
  if v_sup is null then
    raise exception 'settlement: not found' using errcode = 'P0002';
  end if;
  if v_sup <> v_caller_sup and not identity.is_platform_admin() then
    raise exception 'settlement: not on caller''s supplier' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', s.id, 'settlement_code', s.settlement_code,
      'executed_contract_id', s.executed_contract_id, 'shipment_id', s.shipment_id,
      'status', s.status, 'currency', s.currency,
      'planned_amount', s.planned_amount, 'released_amount', s.released_amount,
      'reconciled_amount', s.reconciled_amount,
      'dispute_status', s.dispute_status, 'created_at', s.created_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', it.id, 'description', it.description, 'amount', it.amount,
          'net_amount', it.net_amount
        ) order by it.sort_order, it.created_at), '[]'::jsonb)
          from settlement.settlement_items it
         where it.settlement_id = s.id and it.deleted_at is null
      )
    )
    from settlement.settlements s where s.id = p_settlement_id
  );
end;
$$;

-- 7.3 supplier_confirm_reconciliation --------------------------------------
-- released → reconciled. Full released_amount only (no partial).
create or replace function settlement.supplier_confirm_reconciliation(
  p_settlement_id uuid, p_notes text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_sup uuid := supplier.fn_portal_supplier_id();
  v_sup uuid; v_status settlement.settlement_status; v_released numeric;
begin
  select supplier_id, status, released_amount
    into v_sup, v_status, v_released
    from settlement.settlements where id = p_settlement_id and deleted_at is null;
  if v_sup is null then
    raise exception 'settlement: not found' using errcode = 'P0002';
  end if;
  if v_sup <> v_caller_sup and not identity.is_platform_admin() then
    raise exception 'settlement: not on caller''s supplier' using errcode = '42501';
  end if;
  if v_status <> 'released' then
    raise exception 'settlement: invalid_transition: cannot reconcile from %', v_status using errcode = 'P0001';
  end if;

  update settlement.settlements
     set status = 'reconciled', reconciled_at = now(), reconciled_by = v_actor,
         reconciled_amount = v_released,
         notes = case when p_notes is null then notes else coalesce(notes,'') || E'\n' || p_notes end,
         updated_by = v_actor
   where id = p_settlement_id;
  perform settlement.fn_record_settlement_event(p_settlement_id, 'released', 'reconciled', 'supplier_reconciled');
  perform settlement.fn_audit('settlement.reconciled', p_settlement_id, 'settlement');
end;
$$;

-- 7.4 supplier_open_dispute ------------------------------------------------
-- Sets dispute_status='opened'; if settlement is in 'holding' / 'released',
-- also flips settlement.status to 'disputed' so downstream UI sees the freeze.
create or replace function settlement.supplier_open_dispute(
  p_settlement_id uuid, p_reason text
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_caller_sup uuid := supplier.fn_portal_supplier_id();
  v_sup uuid; v_status settlement.settlement_status;
  v_dispute settlement.dispute_status;
begin
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'settlement: dispute reason is required' using errcode = '22023';
  end if;
  select supplier_id, status, dispute_status into v_sup, v_status, v_dispute
    from settlement.settlements where id = p_settlement_id and deleted_at is null;
  if v_sup is null then
    raise exception 'settlement: not found' using errcode = 'P0002';
  end if;
  if v_sup <> v_caller_sup and not identity.is_platform_admin() then
    raise exception 'settlement: not on caller''s supplier' using errcode = '42501';
  end if;
  if v_dispute = 'opened' or v_dispute = 'under_review' then
    raise exception 'settlement: dispute already open (status=%)', v_dispute using errcode = 'P0001';
  end if;

  update settlement.settlements
     set dispute_status         = 'opened',
         disputed_at            = now(),
         disputed_by            = v_actor,
         dispute_opened_by_party = 'supplier',
         dispute_reason         = p_reason,
         updated_by             = v_actor
   where id = p_settlement_id;

  if v_status in ('holding', 'released') then
    update settlement.settlements set status = 'disputed', updated_by = v_actor
     where id = p_settlement_id;
    perform settlement.fn_record_settlement_event(p_settlement_id, v_status, 'disputed', 'supplier_opened_dispute', p_reason);
  end if;
  perform settlement.fn_audit('settlement.dispute_opened', p_settlement_id, 'settlement',
    jsonb_build_object('reason', p_reason, 'by_party', 'supplier'));
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs (9)
-- ===========================================================================

-- 8.1 admin_list_escrow_accounts -------------------------------------------
create or replace function settlement.admin_list_escrow_accounts(
  p_organization_id uuid                    default null,
  p_supplier_id     uuid                    default null,
  p_status          settlement.escrow_status default null,
  p_limit           integer                 default 25,
  p_offset          integer                 default 0
) returns table (
  id uuid, account_code text, organization_id uuid, supplier_id uuid,
  status text, currency text, available_balance numeric, total_held numeric,
  total_credited numeric, total_released numeric,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_escrow_accounts: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select ea.id, ea.account_code, ea.organization_id, ea.supplier_id,
           ea.status::text, ea.currency, ea.available_balance, ea.total_held,
           ea.total_credited, ea.total_released, ea.created_at
      from settlement.escrow_accounts ea
     where ea.deleted_at is null
       and (p_organization_id is null or ea.organization_id = p_organization_id)
       and (p_supplier_id is null or ea.supplier_id = p_supplier_id)
       and (p_status is null or ea.status = p_status)
     order by ea.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_escrow_account ---------------------------------------------
create or replace function settlement.admin_get_escrow_account(p_account_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_escrow_account: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', ea.id, 'account_code', ea.account_code,
      'organization_id', ea.organization_id, 'supplier_id', ea.supplier_id,
      'status', ea.status, 'currency', ea.currency,
      'total_credited', ea.total_credited, 'total_debited', ea.total_debited,
      'total_held', ea.total_held, 'total_released', ea.total_released,
      'available_balance', ea.available_balance,
      'created_at', ea.created_at, 'updated_at', ea.updated_at,
      'entries_count', (select count(*) from settlement.escrow_entries where escrow_account_id = ea.id)
    )
    from settlement.escrow_accounts ea where ea.id = p_account_id
  );
end;
$$;

-- 8.3 admin_freeze_escrow_account ------------------------------------------
create or replace function settlement.admin_freeze_escrow_account(
  p_account_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status settlement.escrow_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_freeze_escrow_account: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from settlement.escrow_accounts where id = p_account_id and deleted_at is null;
  if v_status is null then
    raise exception 'settlement: escrow account not found' using errcode = 'P0002';
  end if;
  if v_status not in ('open', 'active') then
    raise exception 'settlement: invalid_transition: cannot freeze from %', v_status using errcode = 'P0001';
  end if;
  update settlement.escrow_accounts
     set status = 'frozen', frozen_at = now(), frozen_by = v_actor, frozen_reason = p_reason,
         updated_by = v_actor
   where id = p_account_id;
  perform settlement.fn_record_escrow_status_event(p_account_id, v_status, 'frozen', p_reason);
  perform settlement.fn_audit('settlement.escrow_frozen', p_account_id, 'escrow_account',
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.4 admin_unfreeze_escrow_account ----------------------------------------
create or replace function settlement.admin_unfreeze_escrow_account(
  p_account_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status settlement.escrow_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_unfreeze_escrow_account: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from settlement.escrow_accounts where id = p_account_id and deleted_at is null;
  if v_status is null then
    raise exception 'settlement: escrow account not found' using errcode = 'P0002';
  end if;
  if v_status <> 'frozen' then
    raise exception 'settlement: invalid_transition: cannot unfreeze from %', v_status using errcode = 'P0001';
  end if;
  update settlement.escrow_accounts
     set status = 'active', frozen_reason = null, updated_by = v_actor
   where id = p_account_id;
  perform settlement.fn_record_escrow_status_event(p_account_id, 'frozen', 'active', p_reason);
  perform settlement.fn_audit('settlement.escrow_unfrozen', p_account_id, 'escrow_account',
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.5 admin_close_escrow_account -------------------------------------------
-- Requires zero held + zero available.
create or replace function settlement.admin_close_escrow_account(
  p_account_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status settlement.escrow_status;
        v_held numeric; v_avail numeric;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_close_escrow_account: requires platform_admin' using errcode = '42501';
  end if;
  perform settlement.fn_recompute_escrow_balances(p_account_id);
  select status, total_held, available_balance into v_status, v_held, v_avail
    from settlement.escrow_accounts where id = p_account_id and deleted_at is null;
  if v_status is null then
    raise exception 'settlement: escrow account not found' using errcode = 'P0002';
  end if;
  if v_status in ('closed', 'voided') then
    raise exception 'settlement: already terminal (status=%)', v_status using errcode = 'P0001';
  end if;
  if v_held <> 0 or v_avail <> 0 then
    raise exception 'settlement: cannot close — non-zero balances (held=%, available=%)', v_held, v_avail
      using errcode = 'P0001';
  end if;
  update settlement.escrow_accounts
     set status = 'closed', closed_at = now(), closed_by = v_actor, closed_reason = p_reason,
         updated_by = v_actor
   where id = p_account_id;
  perform settlement.fn_record_escrow_status_event(p_account_id, v_status, 'closed', p_reason);
  perform settlement.fn_audit('settlement.escrow_closed', p_account_id, 'escrow_account',
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.6 admin_list_settlements -----------------------------------------------
create or replace function settlement.admin_list_settlements(
  p_organization_id uuid                          default null,
  p_supplier_id     uuid                          default null,
  p_status          settlement.settlement_status  default null,
  p_limit           integer                       default 25,
  p_offset          integer                       default 0
) returns table (
  id uuid, settlement_code text, organization_id uuid, supplier_id uuid,
  status text, currency text, planned_amount numeric, released_amount numeric,
  dispute_status text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_settlements: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select s.id, s.settlement_code, s.organization_id, s.supplier_id,
           s.status::text, s.currency, s.planned_amount, s.released_amount,
           s.dispute_status::text, s.created_at
      from settlement.settlements s
     where s.deleted_at is null
       and (p_organization_id is null or s.organization_id = p_organization_id)
       and (p_supplier_id is null or s.supplier_id = p_supplier_id)
       and (p_status is null or s.status = p_status)
     order by s.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.7 admin_get_settlement -------------------------------------------------
create or replace function settlement.admin_get_settlement(p_settlement_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_settlement: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', s.id, 'settlement_code', s.settlement_code,
      'organization_id', s.organization_id, 'supplier_id', s.supplier_id,
      'escrow_account_id', s.escrow_account_id,
      'status', s.status, 'currency', s.currency,
      'planned_amount', s.planned_amount, 'held_amount', s.held_amount,
      'released_amount', s.released_amount, 'reconciled_amount', s.reconciled_amount,
      'dispute_status', s.dispute_status,
      'items_count', (select count(*) from settlement.settlement_items
                       where settlement_id = s.id and deleted_at is null),
      'events_count', (select count(*) from settlement.settlement_events
                        where settlement_id = s.id),
      'created_at', s.created_at, 'updated_at', s.updated_at
    )
    from settlement.settlements s where s.id = p_settlement_id
  );
end;
$$;

-- 8.8 admin_list_settlement_events -----------------------------------------
create or replace function settlement.admin_list_settlement_events(p_settlement_id uuid)
returns table (
  id uuid, from_status text, to_status text, event_type text,
  actor_user_id uuid, reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_settlement_events: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.from_status::text, e.to_status::text, e.event_type,
           e.actor_user_id, e.reason, e.created_at
      from settlement.settlement_events e
     where e.settlement_id = p_settlement_id
     order by e.created_at asc;
end;
$$;

-- 8.9 admin_force_settlement_status ----------------------------------------
create or replace function settlement.admin_force_settlement_status(
  p_settlement_id uuid,
  p_status        settlement.settlement_status,
  p_reason        text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_current settlement.settlement_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_settlement_status: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from settlement.settlements where id = p_settlement_id and deleted_at is null;
  if v_current is null then
    raise exception 'settlement: not found' using errcode = 'P0002';
  end if;
  if v_current = p_status then return; end if;
  update settlement.settlements
     set status = p_status,
         voided_at  = case when p_status = 'voided' then now() else voided_at end,
         voided_by  = case when p_status = 'voided' then v_actor else voided_by end,
         voided_reason = case when p_status = 'voided' then p_reason else voided_reason end,
         updated_by = v_actor
   where id = p_settlement_id;
  perform settlement.fn_record_settlement_event(p_settlement_id, v_current, p_status,
    'admin_force_status', coalesce(p_reason, 'admin_force_status'));
  perform settlement.fn_audit('settlement.admin_status_change', p_settlement_id, 'settlement',
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
    select unnest(array['escrow_accounts','settlements','settlement_items']) as table_name
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on settlement.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on settlement.%I '
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
      'escrow_accounts','escrow_entries','escrow_status_events',
      'settlements','settlement_items','settlement_events'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on settlement.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on settlement.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 10. Grants (SELECT only; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on settlement.settlements           to anon, authenticated;
grant select on settlement.settlement_items      to anon, authenticated;
grant select on settlement.escrow_accounts       to authenticated;
grant select on settlement.escrow_entries        to authenticated;
grant select on settlement.escrow_status_events  to authenticated;
grant select on settlement.settlement_events     to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function settlement.buyer_open_escrow_account(uuid, text, jsonb) to authenticated;
grant execute on function settlement.buyer_create_draft_settlement(uuid, uuid, uuid, text, text, text) to authenticated;
grant execute on function settlement.buyer_update_settlement(uuid, uuid, text, text, text) to authenticated;
grant execute on function settlement.buyer_upsert_settlement_item(uuid, text, numeric, numeric, numeric, uuid, uuid, integer, uuid) to authenticated;
grant execute on function settlement.buyer_remove_settlement_item(uuid) to authenticated;
grant execute on function settlement.buyer_mark_settlement_ready(uuid) to authenticated;
grant execute on function settlement.buyer_hold_settlement(uuid) to authenticated;
grant execute on function settlement.buyer_release_settlement(uuid, text) to authenticated;
grant execute on function settlement.buyer_cancel_settlement(uuid, text) to authenticated;
grant execute on function settlement.buyer_list_settlements(uuid, settlement.settlement_status, integer, integer) to authenticated;
grant execute on function settlement.buyer_get_settlement(uuid) to authenticated;

grant execute on function settlement.supplier_list_my_settlements(settlement.settlement_status, integer, integer) to authenticated;
grant execute on function settlement.supplier_get_my_settlement(uuid) to authenticated;
grant execute on function settlement.supplier_confirm_reconciliation(uuid, text) to authenticated;
grant execute on function settlement.supplier_open_dispute(uuid, text) to authenticated;

grant execute on function settlement.admin_list_escrow_accounts(uuid, uuid, settlement.escrow_status, integer, integer) to authenticated;
grant execute on function settlement.admin_get_escrow_account(uuid) to authenticated;
grant execute on function settlement.admin_freeze_escrow_account(uuid, text) to authenticated;
grant execute on function settlement.admin_unfreeze_escrow_account(uuid, text) to authenticated;
grant execute on function settlement.admin_close_escrow_account(uuid, text) to authenticated;
grant execute on function settlement.admin_list_settlements(uuid, uuid, settlement.settlement_status, integer, integer) to authenticated;
grant execute on function settlement.admin_get_settlement(uuid) to authenticated;
grant execute on function settlement.admin_list_settlement_events(uuid) to authenticated;
grant execute on function settlement.admin_force_settlement_status(uuid, settlement.settlement_status, text) to authenticated;
