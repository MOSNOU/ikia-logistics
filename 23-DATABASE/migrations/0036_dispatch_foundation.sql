-- CC-43 / Migration 0036 — Dispatch Foundation.
-- Append-only over 0001–0035. Adds the dispatch.dispatch_assignments +
-- dispatch.dispatch_events pair under a NEW `dispatch` schema. Dispatch is
-- operational readiness only — it does NOT mutate shipments, carriers,
-- capacity, bookings, settlements, finance, or invoices.
--
-- Locked decisions (Q1–Q10 = A):
--   Q1 = new `dispatch` schema with dispatch_assignments table
--   Q2 = immutable dispatch_events ledger (INSERT-only via SECURITY DEFINER)
--   Q3 = carrier owns dispatch lifecycle; buyer can observe + cancel
--   Q4 = admin cancel-only moderation
--   Q5 = vehicle + driver fields are lightweight text placeholders
--   Q6 = full lifecycle notifications via notify category = 'other'
--   Q7 = booking_request must be in buyer_confirmed before creating dispatch
--   Q8 = buyer + carrier + admin portals
--   Q9 = NO mutations of marketplace.capacity_listings (no reservation)
--   Q10 = stop after validation report
--
-- Boundaries respected: this migration does not write to or modify any
-- shipment.*, supplier.*, contract.*, settlement.*, finance.*, or
-- marketplace.capacity_listings rows. The only cross-schema reads are to
-- marketplace.booking_requests for pre-condition validation.

-- ===========================================================================
-- 1. Schema + grants
-- ===========================================================================
create schema if not exists dispatch;
grant usage on schema dispatch to anon, authenticated, service_role;
comment on schema dispatch is
  'iKIA Phase 2 — operational dispatch readiness. Tracks carrier-side vehicle/driver placeholders for confirmed bookings. No shipment mutation, no capacity reservation.';

-- ===========================================================================
-- 2. Enum
-- ===========================================================================
create type dispatch.dispatch_status as enum (
  'draft',
  'assigned',
  'ready',
  'released',
  'cancelled'
);

-- ===========================================================================
-- 3. Tables (2)
-- ===========================================================================

-- 3.1 dispatch_assignments -------------------------------------------------
create table dispatch.dispatch_assignments (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  booking_request_id          uuid not null references marketplace.booking_requests(id) on delete restrict,
  buyer_organization_id       uuid not null references organization.organizations(id) on delete restrict,
  carrier_organization_id     uuid not null references organization.organizations(id) on delete restrict,

  status                      dispatch.dispatch_status not null default 'draft',

  vehicle_reference           text,
  vehicle_type                text,
  driver_name                 text,
  driver_phone                text,
  planned_pickup_at           timestamptz,
  notes_fa                    text,
  notes_en                    text,

  created_by                  uuid references auth.users(id),
  assigned_by                 uuid references auth.users(id),
  assigned_at                 timestamptz,
  ready_by                    uuid references auth.users(id),
  ready_at                    timestamptz,
  released_by                 uuid references auth.users(id),
  released_at                 timestamptz,
  cancelled_by                uuid references auth.users(id),
  cancelled_at                timestamptz,
  cancelled_reason            text,

  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table dispatch.dispatch_assignments is
  'CC-43: carrier-owned operational readiness record per confirmed booking. Vehicle / driver are lightweight placeholders; no fleet management, no telematics.';

create index dispatch_assignments_tenant_idx          on dispatch.dispatch_assignments(tenant_id);
create index dispatch_assignments_booking_idx         on dispatch.dispatch_assignments(booking_request_id);
create index dispatch_assignments_buyer_status_idx    on dispatch.dispatch_assignments(buyer_organization_id, status);
create index dispatch_assignments_carrier_status_idx  on dispatch.dispatch_assignments(carrier_organization_id, status);
create index dispatch_assignments_created_idx         on dispatch.dispatch_assignments(created_at desc);

-- 3.2 dispatch_events (immutable ledger) -----------------------------------
create table dispatch.dispatch_events (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  dispatch_id                 uuid not null references dispatch.dispatch_assignments(id) on delete cascade,

  from_status                 dispatch.dispatch_status,
  to_status                   dispatch.dispatch_status not null,
  event_type                  text not null,
  actor_party                 text not null,
  actor_user_id               uuid references auth.users(id),
  actor_organization_id       uuid references organization.organizations(id) on delete set null,

  reason                      text,
  payload                     jsonb not null default '{}'::jsonb,

  created_at                  timestamptz not null default now(),

  constraint dispatch_events_actor_party_check
    check (actor_party in ('buyer', 'carrier', 'admin', 'system'))
);

comment on table dispatch.dispatch_events is
  'CC-43: immutable dispatch lifecycle ledger. One row per status transition. INSERT-only via dispatch.fn_record_dispatch_event.';

create index dispatch_events_dispatch_idx
  on dispatch.dispatch_events(dispatch_id, created_at desc);
create index dispatch_events_created_idx
  on dispatch.dispatch_events(created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function dispatch.fn_audit(
  p_action_code text,
  p_dispatch_id uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, carrier_organization_id into v_t, v_o
    from dispatch.dispatch_assignments where id = p_dispatch_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'dispatch_assignment', p_dispatch_id, coalesce(p_payload, '{}'::jsonb), now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_record_dispatch_event ---------------------------------------------
create or replace function dispatch.fn_record_dispatch_event(
  p_dispatch_id uuid,
  p_from        dispatch.dispatch_status,
  p_to          dispatch.dispatch_status,
  p_event_type  text,
  p_actor_party text,
  p_reason      text default null,
  p_payload     jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_o uuid; v_id uuid;
begin
  select tenant_id, carrier_organization_id into v_t, v_o
    from dispatch.dispatch_assignments where id = p_dispatch_id;
  insert into dispatch.dispatch_events (
    tenant_id, dispatch_id, from_status, to_status,
    event_type, actor_party, actor_user_id, actor_organization_id,
    reason, payload
  ) values (
    v_t, p_dispatch_id, p_from, p_to,
    p_event_type, p_actor_party, auth.uid(), v_o,
    p_reason, coalesce(p_payload, '{}'::jsonb)
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 4.3 fn_assert_can_view_dispatch ------------------------------------------
create or replace function dispatch.fn_assert_can_view_dispatch(p_dispatch_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid; v_carrier uuid;
  v_user uuid := identity.current_user_id();
begin
  select buyer_organization_id, carrier_organization_id
    into v_buyer, v_carrier
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'dispatch: assignment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'dispatch: assignment not visible' using errcode = '42501';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id in (v_buyer, v_carrier)
       and m.deleted_at is null and m.status = 'active'
  ) then
    return;
  end if;
  raise exception 'dispatch: assignment not visible to caller' using errcode = '42501';
end;
$$;

-- 4.4 fn_assert_buyer_for_dispatch -----------------------------------------
create or replace function dispatch.fn_assert_buyer_for_dispatch(p_dispatch_id uuid)
returns dispatch.dispatch_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid; v_status dispatch.dispatch_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select buyer_organization_id, status into v_buyer, v_status
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'dispatch: assignment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'dispatch: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_buyer then
    raise exception 'dispatch: assignment not owned by caller buyer org' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.5 fn_assert_carrier_for_dispatch ---------------------------------------
create or replace function dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id uuid)
returns dispatch.dispatch_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_carrier uuid; v_status dispatch.dispatch_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select carrier_organization_id, status into v_carrier, v_status
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_carrier is null then
    raise exception 'dispatch: assignment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
    raise exception 'dispatch: requires carrier_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_carrier then
    raise exception 'dispatch: assignment not owned by caller carrier org' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 4.6 fn_assert_carrier_for_booking ----------------------------------------
-- Used at create time. The caller must be a carrier-side actor on the booking's
-- carrier_organization_id, and the booking must be in `buyer_confirmed`.
create or replace function dispatch.fn_assert_carrier_for_booking(p_booking_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_carrier uuid;
  v_status marketplace.booking_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select carrier_organization_id, status into v_carrier, v_status
    from marketplace.booking_requests
   where id = p_booking_id and deleted_at is null;
  if v_carrier is null then
    raise exception 'dispatch: booking not found' using errcode = 'P0002';
  end if;
  if v_status <> 'buyer_confirmed' then
    raise exception 'dispatch: booking must be in buyer_confirmed state (got %)', v_status
      using errcode = 'P0001';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
    raise exception 'dispatch: requires carrier_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_carrier then
    raise exception 'dispatch: booking not owned by caller carrier org' using errcode = '42501';
  end if;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table dispatch.dispatch_assignments enable row level security;
alter table dispatch.dispatch_events      enable row level security;

drop policy if exists dispatch_assignments_select on dispatch.dispatch_assignments;
create policy dispatch_assignments_select on dispatch.dispatch_assignments
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id
               in (dispatch.dispatch_assignments.buyer_organization_id,
                   dispatch.dispatch_assignments.carrier_organization_id)
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists dispatch_assignments_admin_modify on dispatch.dispatch_assignments;
create policy dispatch_assignments_admin_modify on dispatch.dispatch_assignments
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

drop policy if exists dispatch_events_select on dispatch.dispatch_events;
create policy dispatch_events_select on dispatch.dispatch_events
  for select
  using (
    exists (
      select 1 from dispatch.dispatch_assignments da
       where da.id = dispatch.dispatch_events.dispatch_id
         and da.deleted_at is null
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id in (da.buyer_organization_id, da.carrier_organization_id)
                and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. Carrier RPCs
-- ===========================================================================

-- 6.1 carrier_create_dispatch ----------------------------------------------
-- Creates a dispatch tied to a buyer_confirmed booking. If all four
-- placeholders (vehicle_reference, vehicle_type, driver_name, driver_phone)
-- are provided, the dispatch starts in 'assigned'; otherwise 'draft'.
create or replace function dispatch.carrier_create_dispatch(
  p_booking_request_id uuid,
  p_vehicle_reference  text default null,
  p_vehicle_type       text default null,
  p_driver_name        text default null,
  p_driver_phone       text default null,
  p_planned_pickup_at  timestamptz default null,
  p_notes_fa           text default null,
  p_notes_en           text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid;
  v_buyer uuid;
  v_carrier uuid;
  v_status dispatch.dispatch_status;
  v_id uuid;
begin
  perform dispatch.fn_assert_carrier_for_booking(p_booking_request_id);

  select tenant_id, buyer_organization_id, carrier_organization_id
    into v_tenant, v_buyer, v_carrier
    from marketplace.booking_requests where id = p_booking_request_id;

  v_status := case
    when p_vehicle_reference is not null and btrim(p_vehicle_reference) <> ''
     and p_vehicle_type      is not null and btrim(p_vehicle_type)      <> ''
     and p_driver_name       is not null and btrim(p_driver_name)       <> ''
     and p_driver_phone      is not null and btrim(p_driver_phone)      <> ''
    then 'assigned'::dispatch.dispatch_status
    else 'draft'::dispatch.dispatch_status
  end;

  insert into dispatch.dispatch_assignments (
    tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
    status, vehicle_reference, vehicle_type, driver_name, driver_phone,
    planned_pickup_at, notes_fa, notes_en,
    created_by, assigned_by, assigned_at
  ) values (
    v_tenant, p_booking_request_id, v_buyer, v_carrier,
    v_status, p_vehicle_reference, p_vehicle_type, p_driver_name, p_driver_phone,
    p_planned_pickup_at, p_notes_fa, p_notes_en,
    v_actor,
    case when v_status = 'assigned' then v_actor else null end,
    case when v_status = 'assigned' then now()   else null end
  ) returning id into v_id;

  perform dispatch.fn_record_dispatch_event(
    v_id, null, v_status, 'dispatch_created', 'carrier', null,
    jsonb_build_object('booking_request_id', p_booking_request_id::text)
  );
  perform dispatch.fn_audit('dispatch.created', v_id,
    jsonb_build_object('booking_request_id', p_booking_request_id::text));

  if v_status = 'assigned' then
    perform dispatch.fn_record_dispatch_event(
      v_id, 'draft', 'assigned', 'dispatch_assigned', 'carrier', null, '{}'::jsonb);
  end if;
  return v_id;
end;
$$;

-- 6.2 carrier_update_dispatch_placeholders ---------------------------------
-- Patches vehicle/driver/pickup/notes while the dispatch is editable.
-- If patching brings all four placeholders into existence while the
-- dispatch is in 'draft', auto-transitions to 'assigned' and records the
-- corresponding event.
create or replace function dispatch.carrier_update_dispatch_placeholders(
  p_dispatch_id        uuid,
  p_vehicle_reference  text default null,
  p_vehicle_type       text default null,
  p_driver_name        text default null,
  p_driver_phone       text default null,
  p_planned_pickup_at  timestamptz default null,
  p_notes_fa           text default null,
  p_notes_en           text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispatch.dispatch_status;
  v_complete boolean;
begin
  v_status := dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);
  if v_status not in ('draft', 'assigned') then
    raise exception 'dispatch: placeholders are locked in status %', v_status
      using errcode = 'P0001';
  end if;

  update dispatch.dispatch_assignments
     set vehicle_reference = coalesce(p_vehicle_reference, vehicle_reference),
         vehicle_type      = coalesce(p_vehicle_type, vehicle_type),
         driver_name       = coalesce(p_driver_name, driver_name),
         driver_phone      = coalesce(p_driver_phone, driver_phone),
         planned_pickup_at = coalesce(p_planned_pickup_at, planned_pickup_at),
         notes_fa          = coalesce(p_notes_fa, notes_fa),
         notes_en          = coalesce(p_notes_en, notes_en),
         updated_at        = now(),
         version           = version + 1
   where id = p_dispatch_id;

  if v_status = 'draft' then
    select (vehicle_reference is not null and btrim(vehicle_reference) <> ''
        and vehicle_type      is not null and btrim(vehicle_type)      <> ''
        and driver_name       is not null and btrim(driver_name)       <> ''
        and driver_phone      is not null and btrim(driver_phone)      <> '')
      into v_complete
      from dispatch.dispatch_assignments where id = p_dispatch_id;
    if v_complete then
      update dispatch.dispatch_assignments
         set status      = 'assigned',
             assigned_by = v_actor,
             assigned_at = now(),
             updated_at  = now(),
             version     = version + 1
       where id = p_dispatch_id;
      perform dispatch.fn_record_dispatch_event(
        p_dispatch_id, 'draft', 'assigned', 'dispatch_assigned', 'carrier', null, '{}'::jsonb);
    end if;
  end if;
  perform dispatch.fn_audit('dispatch.placeholders_updated', p_dispatch_id, '{}'::jsonb);
end;
$$;

-- 6.3 carrier_mark_ready ---------------------------------------------------
create or replace function dispatch.carrier_mark_ready(p_dispatch_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispatch.dispatch_status;
begin
  v_status := dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);
  if v_status <> 'assigned' then
    raise exception 'dispatch: cannot mark ready from status %', v_status
      using errcode = 'P0001';
  end if;
  update dispatch.dispatch_assignments
     set status     = 'ready',
         ready_by   = v_actor,
         ready_at   = now(),
         updated_at = now(),
         version    = version + 1
   where id = p_dispatch_id;
  perform dispatch.fn_record_dispatch_event(
    p_dispatch_id, v_status, 'ready', 'dispatch_ready', 'carrier', null, '{}'::jsonb);
  perform dispatch.fn_audit('dispatch.ready', p_dispatch_id, '{}'::jsonb);
end;
$$;

-- 6.4 carrier_release_dispatch ---------------------------------------------
create or replace function dispatch.carrier_release_dispatch(
  p_dispatch_id uuid,
  p_notes       text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispatch.dispatch_status;
begin
  v_status := dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);
  if v_status <> 'ready' then
    raise exception 'dispatch: cannot release from status %', v_status
      using errcode = 'P0001';
  end if;
  update dispatch.dispatch_assignments
     set status      = 'released',
         released_by = v_actor,
         released_at = now(),
         updated_at  = now(),
         version     = version + 1
   where id = p_dispatch_id;
  perform dispatch.fn_record_dispatch_event(
    p_dispatch_id, v_status, 'released', 'dispatch_released', 'carrier', p_notes, '{}'::jsonb);
  perform dispatch.fn_audit('dispatch.released', p_dispatch_id, '{}'::jsonb);
end;
$$;

-- 6.5 carrier_cancel_dispatch ----------------------------------------------
create or replace function dispatch.carrier_cancel_dispatch(
  p_dispatch_id uuid,
  p_reason      text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispatch.dispatch_status;
begin
  v_status := dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);
  if v_status in ('released', 'cancelled') then
    raise exception 'dispatch: cannot cancel from terminal status %', v_status
      using errcode = 'P0001';
  end if;
  update dispatch.dispatch_assignments
     set status           = 'cancelled',
         cancelled_by     = v_actor,
         cancelled_at     = now(),
         cancelled_reason = p_reason,
         updated_at       = now(),
         version          = version + 1
   where id = p_dispatch_id;
  perform dispatch.fn_record_dispatch_event(
    p_dispatch_id, v_status, 'cancelled', 'dispatch_cancelled', 'carrier', p_reason, '{}'::jsonb);
  perform dispatch.fn_audit('dispatch.cancelled', p_dispatch_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.6 carrier_list_my_dispatches -------------------------------------------
create or replace function dispatch.carrier_list_my_dispatches(
  p_status  dispatch.dispatch_status default null,
  p_limit   integer default 25,
  p_offset  integer default 0
) returns table (
  id                       uuid,
  booking_request_id       uuid,
  buyer_organization_id    uuid,
  carrier_organization_id  uuid,
  status                   dispatch.dispatch_status,
  vehicle_reference        text,
  driver_name              text,
  planned_pickup_at        timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare v_caller_org uuid := identity.current_organization_id();
begin
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
      raise exception 'dispatch: requires carrier_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'dispatch: no active organization in JWT' using errcode = 'P0002';
    end if;
  end if;
  return query
    select da.id, da.booking_request_id, da.buyer_organization_id, da.carrier_organization_id,
           da.status, da.vehicle_reference, da.driver_name, da.planned_pickup_at,
           da.created_at, da.updated_at
      from dispatch.dispatch_assignments da
     where da.deleted_at is null
       and (identity.is_platform_admin() or da.carrier_organization_id = v_caller_org)
       and (p_status is null or da.status = p_status)
     order by da.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.7 carrier_get_dispatch -------------------------------------------------
create or replace function dispatch.carrier_get_dispatch(p_dispatch_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);
  return (
    select jsonb_build_object(
      'dispatch', to_jsonb(da),
      'events', (
        select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at asc), '[]'::jsonb)
          from dispatch.dispatch_events e where e.dispatch_id = da.id
      )
    )
    from dispatch.dispatch_assignments da where da.id = p_dispatch_id
  );
end;
$$;

-- ===========================================================================
-- 7. Buyer RPCs
-- ===========================================================================

-- 7.1 buyer_list_my_dispatches ---------------------------------------------
create or replace function dispatch.buyer_list_my_dispatches(
  p_status  dispatch.dispatch_status default null,
  p_limit   integer default 25,
  p_offset  integer default 0
) returns table (
  id                       uuid,
  booking_request_id       uuid,
  buyer_organization_id    uuid,
  carrier_organization_id  uuid,
  status                   dispatch.dispatch_status,
  planned_pickup_at        timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare v_caller_org uuid := identity.current_organization_id();
begin
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
      raise exception 'dispatch: requires buyer_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'dispatch: no active organization in JWT' using errcode = 'P0002';
    end if;
  end if;
  return query
    select da.id, da.booking_request_id, da.buyer_organization_id, da.carrier_organization_id,
           da.status, da.planned_pickup_at, da.created_at, da.updated_at
      from dispatch.dispatch_assignments da
     where da.deleted_at is null
       and (identity.is_platform_admin() or da.buyer_organization_id = v_caller_org)
       and (p_status is null or da.status = p_status)
     order by da.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 buyer_get_dispatch ---------------------------------------------------
create or replace function dispatch.buyer_get_dispatch(p_dispatch_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform dispatch.fn_assert_buyer_for_dispatch(p_dispatch_id);
  return (
    select jsonb_build_object(
      'dispatch', to_jsonb(da),
      'events', (
        select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at asc), '[]'::jsonb)
          from dispatch.dispatch_events e where e.dispatch_id = da.id
      )
    )
    from dispatch.dispatch_assignments da where da.id = p_dispatch_id
  );
end;
$$;

-- 7.3 buyer_cancel_dispatch ------------------------------------------------
create or replace function dispatch.buyer_cancel_dispatch(
  p_dispatch_id uuid,
  p_reason      text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispatch.dispatch_status;
begin
  v_status := dispatch.fn_assert_buyer_for_dispatch(p_dispatch_id);
  if v_status in ('released', 'cancelled') then
    raise exception 'dispatch: cannot cancel from terminal status %', v_status
      using errcode = 'P0001';
  end if;
  update dispatch.dispatch_assignments
     set status           = 'cancelled',
         cancelled_by     = v_actor,
         cancelled_at     = now(),
         cancelled_reason = p_reason,
         updated_at       = now(),
         version          = version + 1
   where id = p_dispatch_id;
  perform dispatch.fn_record_dispatch_event(
    p_dispatch_id, v_status, 'cancelled', 'dispatch_cancelled', 'buyer', p_reason, '{}'::jsonb);
  perform dispatch.fn_audit('dispatch.buyer_cancelled', p_dispatch_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs
-- ===========================================================================

-- 8.1 admin_list_dispatches ------------------------------------------------
create or replace function dispatch.admin_list_dispatches(
  p_status  dispatch.dispatch_status default null,
  p_limit   integer default 25,
  p_offset  integer default 0
) returns table (
  id                       uuid,
  booking_request_id       uuid,
  buyer_organization_id    uuid,
  carrier_organization_id  uuid,
  status                   dispatch.dispatch_status,
  vehicle_reference        text,
  driver_name              text,
  planned_pickup_at        timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  if not identity.is_platform_admin() then
    raise exception 'dispatch.admin_list_dispatches: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    select da.id, da.booking_request_id, da.buyer_organization_id, da.carrier_organization_id,
           da.status, da.vehicle_reference, da.driver_name, da.planned_pickup_at,
           da.created_at, da.updated_at
      from dispatch.dispatch_assignments da
     where da.deleted_at is null
       and (p_status is null or da.status = p_status)
     order by da.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_dispatch ---------------------------------------------------
create or replace function dispatch.admin_get_dispatch(p_dispatch_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'dispatch.admin_get_dispatch: requires platform_admin'
      using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'dispatch', to_jsonb(da),
      'events', (
        select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at asc), '[]'::jsonb)
          from dispatch.dispatch_events e where e.dispatch_id = da.id
      )
    )
    from dispatch.dispatch_assignments da where da.id = p_dispatch_id and da.deleted_at is null
  );
end;
$$;

-- 8.3 admin_cancel_dispatch ------------------------------------------------
create or replace function dispatch.admin_cancel_dispatch(
  p_dispatch_id uuid,
  p_reason      text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status dispatch.dispatch_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'dispatch.admin_cancel_dispatch: requires platform_admin'
      using errcode = '42501';
  end if;
  select status into v_status from dispatch.dispatch_assignments
   where id = p_dispatch_id and deleted_at is null;
  if v_status is null then
    raise exception 'dispatch: assignment not found' using errcode = 'P0002';
  end if;
  if v_status in ('released', 'cancelled') then
    raise exception 'dispatch: cannot cancel from terminal status %', v_status
      using errcode = 'P0001';
  end if;
  update dispatch.dispatch_assignments
     set status           = 'cancelled',
         cancelled_by     = v_actor,
         cancelled_at     = now(),
         cancelled_reason = p_reason,
         updated_at       = now(),
         version          = version + 1
   where id = p_dispatch_id;
  perform dispatch.fn_record_dispatch_event(
    p_dispatch_id, v_status, 'cancelled', 'dispatch_cancelled', 'admin', p_reason,
    jsonb_build_object('admin_action', true));
  perform dispatch.fn_audit('dispatch.admin_cancelled', p_dispatch_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 9. Notification dispatch trigger (Q6=A)
-- ===========================================================================
create or replace function notify.fn_trg_from_dispatch_event()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_event text;
begin
  v_event := case new.event_type
    when 'dispatch_created'   then 'dispatch.created'
    when 'dispatch_assigned'  then 'dispatch.assigned'
    when 'dispatch_ready'     then 'dispatch.ready'
    when 'dispatch_released'  then 'dispatch.released'
    when 'dispatch_cancelled' then 'dispatch.cancelled'
    else null
  end;
  if v_event is null then return new; end if;
  perform notify.fn_materialize_event(
    v_event,
    'dispatch_assignment',
    new.dispatch_id,
    new.id,
    'other'::notify.notification_category,
    jsonb_build_object(
      'dispatch_id', new.dispatch_id,
      'from_status', new.from_status,
      'to_status',   new.to_status,
      'actor_party', new.actor_party
    ),
    new.tenant_id
  );
  return new;
exception when others then
  return new;
end;
$$;

drop trigger if exists trg_dispatch_event_notify on dispatch.dispatch_events;
create trigger trg_dispatch_event_notify
  after insert on dispatch.dispatch_events
  for each row execute function notify.fn_trg_from_dispatch_event();

-- ===========================================================================
-- 10. Grants
-- ===========================================================================
grant select on dispatch.dispatch_assignments to authenticated;
grant select on dispatch.dispatch_events      to authenticated;

grant execute on function dispatch.carrier_create_dispatch(
  uuid, text, text, text, text, timestamptz, text, text
) to authenticated;
grant execute on function dispatch.carrier_update_dispatch_placeholders(
  uuid, text, text, text, text, timestamptz, text, text
) to authenticated;
grant execute on function dispatch.carrier_mark_ready(uuid) to authenticated;
grant execute on function dispatch.carrier_release_dispatch(uuid, text) to authenticated;
grant execute on function dispatch.carrier_cancel_dispatch(uuid, text) to authenticated;
grant execute on function dispatch.carrier_list_my_dispatches(
  dispatch.dispatch_status, integer, integer
) to authenticated;
grant execute on function dispatch.carrier_get_dispatch(uuid) to authenticated;

grant execute on function dispatch.buyer_list_my_dispatches(
  dispatch.dispatch_status, integer, integer
) to authenticated;
grant execute on function dispatch.buyer_get_dispatch(uuid) to authenticated;
grant execute on function dispatch.buyer_cancel_dispatch(uuid, text) to authenticated;

grant execute on function dispatch.admin_list_dispatches(
  dispatch.dispatch_status, integer, integer
) to authenticated;
grant execute on function dispatch.admin_get_dispatch(uuid) to authenticated;
grant execute on function dispatch.admin_cancel_dispatch(uuid, text) to authenticated;
