-- CC-42 / Migration 0035 — Carrier Booking Foundation.
-- Append-only over 0001–0034. Adds the booking_requests + booking_events
-- pair under the existing `marketplace` schema. Booking is intent-only: it
-- does NOT mutate shipments, contracts, capacity, settlement, or finance.
--
-- Locked decisions (Q1–Q10 = A):
--   Q1 = booking_requests table
--   Q2 = expires_at supported
--   Q3 = carrier accept / reject
--   Q4 = buyer confirmation required (carrier_accepted → buyer_confirmed)
--   Q5 = NO capacity reservation (capacity_listings remains unmodified)
--   Q6 = full lifecycle notifications via existing notify infrastructure
--   Q7 = admin cancel-only moderation (no admin edit / no admin accept)
--   Q8 = buyer + carrier + admin portals (CC-42 frontend)
--   Q9 = immutable booking_events ledger; INSERT-only via SECURITY DEFINER
--   Q10 = stop after validation report

-- ===========================================================================
-- 1. Enum
-- ===========================================================================
create type marketplace.booking_status as enum (
  'draft',
  'pending_carrier',
  'carrier_accepted',
  'carrier_rejected',
  'buyer_confirmed',
  'buyer_cancelled',
  'expired'
);

-- ===========================================================================
-- 2. Tables (2)
-- ===========================================================================

-- 2.1 booking_requests -----------------------------------------------------
create table marketplace.booking_requests (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  shipment_id                 uuid not null references shipment.shipments(id) on delete restrict,
  capacity_listing_id         uuid not null references marketplace.capacity_listings(id) on delete restrict,
  buyer_organization_id       uuid not null references organization.organizations(id) on delete restrict,
  carrier_organization_id     uuid not null references organization.organizations(id) on delete restrict,

  status                      marketplace.booking_status not null default 'draft',
  requested_quantity_units    numeric,
  requested_unit_label        text,
  requested_pickup_at         timestamptz,
  expires_at                  timestamptz,

  notes_fa                    text,
  notes_en                    text,

  requested_by                uuid references auth.users(id),
  responded_by                uuid references auth.users(id),
  responded_at                timestamptz,
  confirmed_by                uuid references auth.users(id),
  confirmed_at                timestamptz,
  cancelled_by                uuid references auth.users(id),
  cancelled_at                timestamptz,
  cancelled_reason            text,

  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,
  version                     integer not null default 1
);

comment on table marketplace.booking_requests is
  'CC-42: buyer-initiated intent to use a carrier capacity listing for a shipment. Booking is advisory only — no capacity reservation, no shipment mutation, no contract creation.';

create index booking_requests_tenant_idx          on marketplace.booking_requests(tenant_id);
create index booking_requests_shipment_idx        on marketplace.booking_requests(shipment_id);
create index booking_requests_listing_idx         on marketplace.booking_requests(capacity_listing_id);
create index booking_requests_buyer_status_idx    on marketplace.booking_requests(buyer_organization_id, status);
create index booking_requests_carrier_status_idx  on marketplace.booking_requests(carrier_organization_id, status);
create index booking_requests_expires_idx         on marketplace.booking_requests(expires_at);
create index booking_requests_created_idx         on marketplace.booking_requests(created_at desc);

-- 2.2 booking_events (immutable ledger) ------------------------------------
create table marketplace.booking_events (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  booking_request_id          uuid not null references marketplace.booking_requests(id) on delete cascade,

  from_status                 marketplace.booking_status,
  to_status                   marketplace.booking_status not null,
  event_type                  text not null,
  actor_party                 text not null,
  actor_user_id               uuid references auth.users(id),
  actor_organization_id       uuid references organization.organizations(id) on delete set null,

  reason                      text,
  payload                     jsonb not null default '{}'::jsonb,

  created_at                  timestamptz not null default now(),

  constraint booking_events_actor_party_check
    check (actor_party in ('buyer', 'carrier', 'admin', 'system'))
);

comment on table marketplace.booking_events is
  'CC-42: immutable booking lifecycle ledger. One row per transition. INSERT-only via marketplace.fn_record_booking_event.';

create index booking_events_booking_idx
  on marketplace.booking_events(booking_request_id, created_at desc);
create index booking_events_created_idx
  on marketplace.booking_events(created_at desc);

-- ===========================================================================
-- 3. Internal helpers
-- ===========================================================================

-- 3.1 fn_audit (booking-scoped) --------------------------------------------
create or replace function marketplace.fn_booking_audit(
  p_action_code text,
  p_booking_id  uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, buyer_organization_id into v_t, v_o
    from marketplace.booking_requests where id = p_booking_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'booking_request', p_booking_id, coalesce(p_payload, '{}'::jsonb), now()
  );
exception when others then
  null;
end;
$$;

-- 3.2 fn_record_booking_event ----------------------------------------------
-- The single INSERT path into booking_events. Q9=A immutability is enforced
-- by RLS (no INSERT policy for `authenticated`); this helper runs as
-- SECURITY DEFINER and is the only entry point.
create or replace function marketplace.fn_record_booking_event(
  p_booking_id  uuid,
  p_from        marketplace.booking_status,
  p_to          marketplace.booking_status,
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
  select tenant_id, buyer_organization_id into v_t, v_o
    from marketplace.booking_requests where id = p_booking_id;
  insert into marketplace.booking_events (
    tenant_id, booking_request_id, from_status, to_status,
    event_type, actor_party, actor_user_id, actor_organization_id,
    reason, payload
  ) values (
    v_t, p_booking_id, p_from, p_to,
    p_event_type, p_actor_party, auth.uid(), v_o,
    p_reason, coalesce(p_payload, '{}'::jsonb)
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 3.3 fn_assert_can_view_booking -------------------------------------------
-- Visibility gate: platform_admin OR active member of buyer_organization_id
-- OR active member of carrier_organization_id.
create or replace function marketplace.fn_assert_can_view_booking(p_booking_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid; v_carrier uuid;
  v_user uuid := identity.current_user_id();
begin
  select buyer_organization_id, carrier_organization_id
    into v_buyer, v_carrier
    from marketplace.booking_requests where id = p_booking_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'marketplace: booking not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'marketplace: booking not visible' using errcode = '42501';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id in (v_buyer, v_carrier)
       and m.deleted_at is null and m.status = 'active'
  ) then
    return;
  end if;
  raise exception 'marketplace: booking not visible to caller' using errcode = '42501';
end;
$$;

-- 3.4 fn_assert_buyer_for_booking ------------------------------------------
-- Buyer-side mutation gate. Requires buyer_admin / organization_admin /
-- platform_admin on the booking's buyer_organization_id.
create or replace function marketplace.fn_assert_buyer_for_booking(p_booking_id uuid)
returns marketplace.booking_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer uuid; v_status marketplace.booking_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select buyer_organization_id, status into v_buyer, v_status
    from marketplace.booking_requests where id = p_booking_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'marketplace: booking not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'marketplace: requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_buyer then
    raise exception 'marketplace: booking not owned by caller buyer org' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- 3.5 fn_assert_carrier_for_booking ----------------------------------------
-- Carrier-side mutation gate. Requires carrier_admin / organization_admin /
-- platform_admin on the booking's carrier_organization_id.
create or replace function marketplace.fn_assert_carrier_for_booking(p_booking_id uuid)
returns marketplace.booking_status
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_carrier uuid; v_status marketplace.booking_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select carrier_organization_id, status into v_carrier, v_status
    from marketplace.booking_requests where id = p_booking_id and deleted_at is null;
  if v_carrier is null then
    raise exception 'marketplace: booking not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return v_status; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
    raise exception 'marketplace: requires carrier_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_carrier then
    raise exception 'marketplace: booking not owned by caller carrier org' using errcode = '42501';
  end if;
  return v_status;
end;
$$;

-- ===========================================================================
-- 4. Row Level Security
-- ===========================================================================
alter table marketplace.booking_requests enable row level security;
alter table marketplace.booking_events   enable row level security;

-- 4.1 booking_requests -----------------------------------------------------
drop policy if exists booking_requests_select on marketplace.booking_requests;
create policy booking_requests_select on marketplace.booking_requests
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id
               in (marketplace.booking_requests.buyer_organization_id,
                   marketplace.booking_requests.carrier_organization_id)
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists booking_requests_admin_modify on marketplace.booking_requests;
create policy booking_requests_admin_modify on marketplace.booking_requests
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.2 booking_events (immutable) -------------------------------------------
drop policy if exists booking_events_select on marketplace.booking_events;
create policy booking_events_select on marketplace.booking_events
  for select
  using (
    exists (
      select 1 from marketplace.booking_requests br
       where br.id = marketplace.booking_events.booking_request_id
         and br.deleted_at is null
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id in (br.buyer_organization_id, br.carrier_organization_id)
                and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 5. Buyer RPCs
-- ===========================================================================

-- 5.1 buyer_create_booking_request -----------------------------------------
create or replace function marketplace.buyer_create_booking_request(
  p_shipment_id              uuid,
  p_capacity_listing_id      uuid,
  p_requested_quantity_units numeric default null,
  p_requested_unit_label     text default null,
  p_requested_pickup_at      timestamptz default null,
  p_expires_at               timestamptz default null,
  p_notes_fa                 text default null,
  p_notes_en                 text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_buyer_org uuid;
  v_carrier_org uuid;
  v_tenant uuid;
  v_listing_status marketplace.capacity_status;
  v_listing_valid_until timestamptz;
  v_carrier_profile_status marketplace.carrier_profile_status;
  v_id uuid;
begin
  -- Visibility: caller must be allowed to see the shipment (buyer / admin).
  perform marketplace.fn_assert_can_view_shipment(p_shipment_id);

  -- Resolve buyer org + tenant from the shipment.
  select s.tenant_id, s.organization_id
    into v_tenant, v_buyer_org
    from shipment.shipments s
   where s.id = p_shipment_id and s.deleted_at is null;
  if v_buyer_org is null then
    raise exception 'marketplace: shipment not found' using errcode = 'P0002';
  end if;

  -- Capacity listing must be active and either evergreen or in window.
  select cl.status, cl.valid_until, cl.carrier_organization_id
    into v_listing_status, v_listing_valid_until, v_carrier_org
    from marketplace.capacity_listings cl
   where cl.id = p_capacity_listing_id and cl.deleted_at is null;
  if v_carrier_org is null then
    raise exception 'marketplace: capacity listing not found' using errcode = 'P0002';
  end if;
  if v_listing_status <> 'active' then
    raise exception 'marketplace: capacity listing is not active (status=%)', v_listing_status
      using errcode = 'P0001';
  end if;
  if v_listing_valid_until is not null and v_listing_valid_until <= now() then
    raise exception 'marketplace: capacity listing has expired' using errcode = 'P0001';
  end if;

  -- Carrier profile must exist + be active.
  select cp.status into v_carrier_profile_status
    from marketplace.carrier_profiles cp
   where cp.organization_id = v_carrier_org and cp.deleted_at is null;
  if v_carrier_profile_status is null then
    raise exception 'marketplace: carrier profile not found' using errcode = 'P0002';
  end if;
  if v_carrier_profile_status <> 'active' then
    raise exception 'marketplace: carrier profile is not active (status=%)', v_carrier_profile_status
      using errcode = 'P0001';
  end if;

  -- Insert booking_request as pending_carrier (the initial buyer submission).
  insert into marketplace.booking_requests (
    tenant_id, shipment_id, capacity_listing_id,
    buyer_organization_id, carrier_organization_id,
    status, requested_quantity_units, requested_unit_label,
    requested_pickup_at, expires_at, notes_fa, notes_en,
    requested_by
  ) values (
    v_tenant, p_shipment_id, p_capacity_listing_id,
    v_buyer_org, v_carrier_org,
    'pending_carrier', p_requested_quantity_units, p_requested_unit_label,
    p_requested_pickup_at, p_expires_at, p_notes_fa, p_notes_en,
    v_actor
  ) returning id into v_id;

  -- Q9: record the initial event row.
  perform marketplace.fn_record_booking_event(
    v_id, 'draft'::marketplace.booking_status,
    'pending_carrier'::marketplace.booking_status,
    'booking_requested', 'buyer', null,
    jsonb_build_object(
      'capacity_listing_id', p_capacity_listing_id::text,
      'shipment_id', p_shipment_id::text
    )
  );
  perform marketplace.fn_booking_audit('marketplace.booking_requested', v_id,
    jsonb_build_object('shipment_id', p_shipment_id::text));

  return v_id;
end;
$$;

-- 5.2 buyer_list_my_bookings -----------------------------------------------
create or replace function marketplace.buyer_list_my_bookings(
  p_status   marketplace.booking_status default null,
  p_limit    integer default 25,
  p_offset   integer default 0
) returns table (
  id                       uuid,
  shipment_id              uuid,
  capacity_listing_id      uuid,
  carrier_organization_id  uuid,
  buyer_organization_id    uuid,
  status                   marketplace.booking_status,
  requested_pickup_at      timestamptz,
  expires_at               timestamptz,
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
      raise exception 'marketplace: requires buyer_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'marketplace: no active organization in JWT' using errcode = 'P0002';
    end if;
  end if;
  return query
    select br.id, br.shipment_id, br.capacity_listing_id,
           br.carrier_organization_id, br.buyer_organization_id,
           br.status, br.requested_pickup_at, br.expires_at,
           br.created_at, br.updated_at
      from marketplace.booking_requests br
     where br.deleted_at is null
       and (identity.is_platform_admin() or br.buyer_organization_id = v_caller_org)
       and (p_status is null or br.status = p_status)
     order by br.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 5.3 buyer_get_booking ----------------------------------------------------
create or replace function marketplace.buyer_get_booking(p_booking_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform marketplace.fn_assert_buyer_for_booking(p_booking_id);
  return (
    select jsonb_build_object(
      'booking', to_jsonb(br),
      'events', (
        select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at asc), '[]'::jsonb)
          from marketplace.booking_events e
         where e.booking_request_id = br.id
      )
    )
    from marketplace.booking_requests br where br.id = p_booking_id
  );
end;
$$;

-- 5.4 buyer_confirm_booking ------------------------------------------------
create or replace function marketplace.buyer_confirm_booking(p_booking_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status marketplace.booking_status;
begin
  v_status := marketplace.fn_assert_buyer_for_booking(p_booking_id);
  if v_status <> 'carrier_accepted' then
    raise exception 'marketplace: cannot confirm booking in status %', v_status
      using errcode = 'P0001';
  end if;
  update marketplace.booking_requests
     set status       = 'buyer_confirmed',
         confirmed_by = v_actor,
         confirmed_at = now(),
         updated_at   = now(),
         version      = version + 1
   where id = p_booking_id;
  perform marketplace.fn_record_booking_event(
    p_booking_id, v_status, 'buyer_confirmed', 'booking_confirmed', 'buyer',
    null, '{}'::jsonb);
  perform marketplace.fn_booking_audit('marketplace.booking_confirmed', p_booking_id, '{}'::jsonb);
end;
$$;

-- 5.5 buyer_cancel_booking -------------------------------------------------
create or replace function marketplace.buyer_cancel_booking(
  p_booking_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status marketplace.booking_status;
begin
  v_status := marketplace.fn_assert_buyer_for_booking(p_booking_id);
  if v_status not in ('pending_carrier', 'carrier_accepted') then
    raise exception 'marketplace: cannot cancel booking in status %', v_status
      using errcode = 'P0001';
  end if;
  update marketplace.booking_requests
     set status           = 'buyer_cancelled',
         cancelled_by     = v_actor,
         cancelled_at     = now(),
         cancelled_reason = p_reason,
         updated_at       = now(),
         version          = version + 1
   where id = p_booking_id;
  perform marketplace.fn_record_booking_event(
    p_booking_id, v_status, 'buyer_cancelled', 'booking_cancelled', 'buyer',
    p_reason, '{}'::jsonb);
  perform marketplace.fn_booking_audit('marketplace.booking_cancelled', p_booking_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 6. Carrier RPCs
-- ===========================================================================

-- 6.1 carrier_list_booking_requests ----------------------------------------
create or replace function marketplace.carrier_list_booking_requests(
  p_status  marketplace.booking_status default null,
  p_limit   integer default 25,
  p_offset  integer default 0
) returns table (
  id                       uuid,
  shipment_id              uuid,
  capacity_listing_id      uuid,
  carrier_organization_id  uuid,
  buyer_organization_id    uuid,
  status                   marketplace.booking_status,
  requested_pickup_at      timestamptz,
  expires_at               timestamptz,
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
      raise exception 'marketplace: requires carrier_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'marketplace: no active organization in JWT' using errcode = 'P0002';
    end if;
  end if;
  return query
    select br.id, br.shipment_id, br.capacity_listing_id,
           br.carrier_organization_id, br.buyer_organization_id,
           br.status, br.requested_pickup_at, br.expires_at,
           br.created_at, br.updated_at
      from marketplace.booking_requests br
     where br.deleted_at is null
       and (identity.is_platform_admin() or br.carrier_organization_id = v_caller_org)
       and (p_status is null or br.status = p_status)
     order by br.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.2 carrier_get_booking --------------------------------------------------
create or replace function marketplace.carrier_get_booking(p_booking_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform marketplace.fn_assert_carrier_for_booking(p_booking_id);
  return (
    select jsonb_build_object(
      'booking', to_jsonb(br),
      'events', (
        select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at asc), '[]'::jsonb)
          from marketplace.booking_events e
         where e.booking_request_id = br.id
      )
    )
    from marketplace.booking_requests br where br.id = p_booking_id
  );
end;
$$;

-- 6.3 carrier_accept_booking -----------------------------------------------
create or replace function marketplace.carrier_accept_booking(
  p_booking_id uuid,
  p_notes      text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status marketplace.booking_status;
begin
  v_status := marketplace.fn_assert_carrier_for_booking(p_booking_id);
  if v_status <> 'pending_carrier' then
    raise exception 'marketplace: cannot accept booking in status %', v_status
      using errcode = 'P0001';
  end if;
  update marketplace.booking_requests
     set status       = 'carrier_accepted',
         responded_by = v_actor,
         responded_at = now(),
         updated_at   = now(),
         version      = version + 1
   where id = p_booking_id;
  perform marketplace.fn_record_booking_event(
    p_booking_id, v_status, 'carrier_accepted', 'booking_accepted', 'carrier',
    p_notes, '{}'::jsonb);
  perform marketplace.fn_booking_audit('marketplace.booking_accepted', p_booking_id,
    jsonb_build_object('notes', p_notes));
end;
$$;

-- 6.4 carrier_reject_booking -----------------------------------------------
create or replace function marketplace.carrier_reject_booking(
  p_booking_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status marketplace.booking_status;
begin
  v_status := marketplace.fn_assert_carrier_for_booking(p_booking_id);
  if v_status <> 'pending_carrier' then
    raise exception 'marketplace: cannot reject booking in status %', v_status
      using errcode = 'P0001';
  end if;
  update marketplace.booking_requests
     set status       = 'carrier_rejected',
         responded_by = v_actor,
         responded_at = now(),
         updated_at   = now(),
         version      = version + 1
   where id = p_booking_id;
  perform marketplace.fn_record_booking_event(
    p_booking_id, v_status, 'carrier_rejected', 'booking_rejected', 'carrier',
    p_reason, '{}'::jsonb);
  perform marketplace.fn_booking_audit('marketplace.booking_rejected', p_booking_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 7. Admin RPCs
-- ===========================================================================

-- 7.1 admin_list_bookings --------------------------------------------------
create or replace function marketplace.admin_list_bookings(
  p_status  marketplace.booking_status default null,
  p_limit   integer default 25,
  p_offset  integer default 0
) returns table (
  id                       uuid,
  shipment_id              uuid,
  capacity_listing_id      uuid,
  carrier_organization_id  uuid,
  buyer_organization_id    uuid,
  status                   marketplace.booking_status,
  requested_pickup_at      timestamptz,
  expires_at               timestamptz,
  created_at               timestamptz,
  updated_at               timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_list_bookings: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    select br.id, br.shipment_id, br.capacity_listing_id,
           br.carrier_organization_id, br.buyer_organization_id,
           br.status, br.requested_pickup_at, br.expires_at,
           br.created_at, br.updated_at
      from marketplace.booking_requests br
     where br.deleted_at is null
       and (p_status is null or br.status = p_status)
     order by br.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 admin_get_booking ----------------------------------------------------
create or replace function marketplace.admin_get_booking(p_booking_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_get_booking: requires platform_admin'
      using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'booking', to_jsonb(br),
      'events', (
        select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at asc), '[]'::jsonb)
          from marketplace.booking_events e
         where e.booking_request_id = br.id
      )
    )
    from marketplace.booking_requests br where br.id = p_booking_id and br.deleted_at is null
  );
end;
$$;

-- 7.3 admin_cancel_booking -------------------------------------------------
-- Q7=A: admin moderation is cancel-only. Admin may cancel from any
-- non-terminal state. Always records the cancellation as 'admin' actor.
create or replace function marketplace.admin_cancel_booking(
  p_booking_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status marketplace.booking_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_cancel_booking: requires platform_admin'
      using errcode = '42501';
  end if;
  select status into v_status from marketplace.booking_requests
   where id = p_booking_id and deleted_at is null;
  if v_status is null then
    raise exception 'marketplace: booking not found' using errcode = 'P0002';
  end if;
  if v_status in ('carrier_rejected', 'buyer_confirmed', 'buyer_cancelled', 'expired') then
    raise exception 'marketplace: cannot cancel booking in terminal status %', v_status
      using errcode = 'P0001';
  end if;
  update marketplace.booking_requests
     set status           = 'buyer_cancelled',
         cancelled_by     = v_actor,
         cancelled_at     = now(),
         cancelled_reason = p_reason,
         updated_at       = now(),
         version          = version + 1
   where id = p_booking_id;
  perform marketplace.fn_record_booking_event(
    p_booking_id, v_status, 'buyer_cancelled', 'booking_cancelled', 'admin',
    p_reason, jsonb_build_object('admin_action', true));
  perform marketplace.fn_booking_audit('marketplace.admin_booking_cancelled', p_booking_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 8. Notification dispatch trigger (Q6=A)
-- ===========================================================================
create or replace function notify.fn_trg_from_booking_event()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_event text;
begin
  -- Q6: emit on the five terminal-style transitions of CC-42 spec.
  v_event := case new.event_type
    when 'booking_requested' then 'booking.requested'
    when 'booking_accepted'  then 'booking.accepted'
    when 'booking_rejected'  then 'booking.rejected'
    when 'booking_confirmed' then 'booking.confirmed'
    when 'booking_cancelled' then 'booking.cancelled'
    else null
  end;
  if v_event is null then return new; end if;
  perform notify.fn_materialize_event(
    v_event,
    'booking_request',
    new.booking_request_id,
    new.id,
    'other'::notify.notification_category,
    jsonb_build_object(
      'booking_request_id', new.booking_request_id,
      'from_status', new.from_status,
      'to_status', new.to_status,
      'actor_party', new.actor_party
    ),
    new.tenant_id
  );
  return new;
exception when others then
  return new;
end;
$$;

drop trigger if exists trg_booking_event_notify on marketplace.booking_events;
create trigger trg_booking_event_notify
  after insert on marketplace.booking_events
  for each row execute function notify.fn_trg_from_booking_event();

-- ===========================================================================
-- 9. Grants
-- ===========================================================================

grant select on marketplace.booking_requests to authenticated;
grant select on marketplace.booking_events   to authenticated;

grant execute on function marketplace.buyer_create_booking_request(
  uuid, uuid, numeric, text, timestamptz, timestamptz, text, text
) to authenticated;
grant execute on function marketplace.buyer_list_my_bookings(
  marketplace.booking_status, integer, integer
) to authenticated;
grant execute on function marketplace.buyer_get_booking(uuid) to authenticated;
grant execute on function marketplace.buyer_confirm_booking(uuid) to authenticated;
grant execute on function marketplace.buyer_cancel_booking(uuid, text) to authenticated;

grant execute on function marketplace.carrier_list_booking_requests(
  marketplace.booking_status, integer, integer
) to authenticated;
grant execute on function marketplace.carrier_get_booking(uuid) to authenticated;
grant execute on function marketplace.carrier_accept_booking(uuid, text) to authenticated;
grant execute on function marketplace.carrier_reject_booking(uuid, text) to authenticated;

grant execute on function marketplace.admin_list_bookings(
  marketplace.booking_status, integer, integer
) to authenticated;
grant execute on function marketplace.admin_get_booking(uuid) to authenticated;
grant execute on function marketplace.admin_cancel_booking(uuid, text) to authenticated;
