-- CC-45 / Migration 0038 — GPS & Telematics Foundation.
-- Append-only over 0001–0037. Adds the telematics.position_reports stream +
-- telematics.telemetry_events ledger under a NEW `telematics` schema.
--
-- Locked decisions (Q1–Q10 = A):
--   Q1 = new `telematics` schema; no other schema modified
--   Q2 = position_reports stream + immutable telemetry_events ledger
--   Q3 = carrier writes; buyer + admin read-only
--   Q4 = telemetry tied to dispatch.dispatch_assignments (not shipment)
--   Q5 = reports allowed only when dispatch is in non-terminal state
--   Q6 = notify dispatch on session_started / session_ended only
--   Q7 = batch position upload via jsonb array
--   Q8 = derived "active session" + "stale telemetry" — no persisted flags
--   Q9 = SECURITY DEFINER mutation; no direct write grants; events immutable
--   Q10 = stop after validation report
--
-- Boundaries: this migration does NOT write to or modify shipment.*,
-- supplier.*, contract.*, settlement.*, finance.*, marketplace.*,
-- dispatch.* (beyond FK reference), or control_tower projections.
-- No maps, no Leaflet, no ETA, no geofencing, no route optimization,
-- no AI/ML logic. Vehicle / driver fields are NOT introduced here —
-- those live in dispatch.dispatch_assignments (CC-43).

-- ===========================================================================
-- 1. Schema + grants
-- ===========================================================================
create schema if not exists telematics;
grant usage on schema telematics to anon, authenticated, service_role;
comment on schema telematics is
  'iKIA Phase 2 — GPS & telematics ingestion. Carrier-reported position stream + lifecycle event ledger tied to dispatch assignments. No maps, no ETA, no route optimization, no geofencing.';

-- ===========================================================================
-- 2. Enum
-- ===========================================================================
create type telematics.telemetry_event_type as enum (
  'session_started',
  'session_ended',
  'signal_lost',
  'signal_restored',
  'position_anomaly'
);

-- ===========================================================================
-- 3. Tables (2)
-- ===========================================================================

-- 3.1 position_reports -----------------------------------------------------
-- High-volume insert-only stream of GPS position samples.
create table telematics.position_reports (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  dispatch_id                 uuid not null references dispatch.dispatch_assignments(id) on delete cascade,
  carrier_organization_id     uuid not null references organization.organizations(id) on delete restrict,

  latitude                    numeric(9,6) not null,
  longitude                   numeric(9,6) not null,
  speed_kmh                   numeric,
  heading_degrees             integer,
  accuracy_meters             numeric,
  altitude_meters             numeric,

  reported_at                 timestamptz not null,
  received_at                 timestamptz not null default now(),

  source                      text not null default 'carrier_app',
  reported_by                 uuid references auth.users(id),
  payload                     jsonb not null default '{}'::jsonb,

  created_at                  timestamptz not null default now(),

  constraint position_reports_lat_check
    check (latitude between -90 and 90),
  constraint position_reports_lng_check
    check (longitude between -180 and 180),
  constraint position_reports_heading_check
    check (heading_degrees is null or (heading_degrees between 0 and 359)),
  constraint position_reports_speed_check
    check (speed_kmh is null or speed_kmh >= 0)
);

comment on table telematics.position_reports is
  'CC-45: append-only GPS position stream. One row per device sample. Insert-only via SECURITY DEFINER RPCs (no UPDATE / DELETE policy).';

create index position_reports_dispatch_idx
  on telematics.position_reports(dispatch_id, reported_at desc);
create index position_reports_carrier_idx
  on telematics.position_reports(carrier_organization_id, reported_at desc);
create index position_reports_received_idx
  on telematics.position_reports(received_at desc);

-- 3.2 telemetry_events (immutable ledger) ----------------------------------
create table telematics.telemetry_events (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  dispatch_id                 uuid not null references dispatch.dispatch_assignments(id) on delete cascade,
  carrier_organization_id     uuid not null references organization.organizations(id) on delete restrict,

  event_type                  telematics.telemetry_event_type not null,
  actor_party                 text not null,
  actor_user_id               uuid references auth.users(id),
  reason                      text,
  payload                     jsonb not null default '{}'::jsonb,

  created_at                  timestamptz not null default now(),

  constraint telemetry_events_actor_party_check
    check (actor_party in ('carrier', 'system', 'admin'))
);

comment on table telematics.telemetry_events is
  'CC-45: immutable telemetry lifecycle ledger. session_started / session_ended / signal_lost / signal_restored / position_anomaly. INSERT-only via SECURITY DEFINER helper.';

create index telemetry_events_dispatch_idx
  on telematics.telemetry_events(dispatch_id, created_at desc);
create index telemetry_events_session_idx
  on telematics.telemetry_events(dispatch_id, event_type, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_record_telemetry_event --------------------------------------------
-- The single INSERT path into telemetry_events. INSERT-only by RLS (Q9).
create or replace function telematics.fn_record_telemetry_event(
  p_dispatch_id uuid,
  p_event_type  telematics.telemetry_event_type,
  p_actor_party text,
  p_reason      text default null,
  p_payload     jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_c uuid; v_id uuid;
begin
  select tenant_id, carrier_organization_id
    into v_t, v_c
    from dispatch.dispatch_assignments where id = p_dispatch_id;
  -- clock_timestamp() so multiple events recorded within the same
  -- transaction get monotonically-increasing timestamps; the default of
  -- now() (= transaction start) ties make latest-event ordering
  -- non-deterministic (see admin_list_active_sessions).
  insert into telematics.telemetry_events (
    tenant_id, dispatch_id, carrier_organization_id,
    event_type, actor_party, actor_user_id, reason, payload, created_at
  ) values (
    v_t, p_dispatch_id, v_c,
    p_event_type, p_actor_party, auth.uid(), p_reason,
    coalesce(p_payload, '{}'::jsonb), clock_timestamp()
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 4.2 fn_assert_can_view_telemetry -----------------------------------------
-- Buyer + carrier members of the dispatch's orgs, or platform_admin.
create or replace function telematics.fn_assert_can_view_telemetry(p_dispatch_id uuid)
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
    raise exception 'telematics: dispatch not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_user is null then
    raise exception 'telematics: dispatch not visible' using errcode = '42501';
  end if;
  if exists (
    select 1 from organization.memberships m
     where m.user_id = v_user
       and m.organization_id in (v_buyer, v_carrier)
       and m.deleted_at is null and m.status = 'active'
  ) then return; end if;
  raise exception 'telematics: dispatch not visible to caller' using errcode = '42501';
end;
$$;

-- 4.3 fn_assert_carrier_for_dispatch_telemetry -----------------------------
-- Mutation gate. Requires carrier_admin / organization_admin / platform_admin
-- on the dispatch's carrier_organization_id AND dispatch status in
-- (assigned, ready, released). Reporting from draft or cancelled is rejected.
create or replace function telematics.fn_assert_carrier_for_dispatch_telemetry(p_dispatch_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_carrier uuid;
  v_status dispatch.dispatch_status;
  v_caller_org uuid := identity.current_organization_id();
begin
  select carrier_organization_id, status
    into v_carrier, v_status
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_carrier is null then
    raise exception 'telematics: dispatch not found' using errcode = 'P0002';
  end if;
  if v_status not in ('assigned', 'ready', 'released') then
    raise exception 'telematics: dispatch not in a telemetry-eligible state (status=%)', v_status
      using errcode = 'P0001';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
    raise exception 'telematics: requires carrier_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_carrier then
    raise exception 'telematics: dispatch not owned by caller carrier org' using errcode = '42501';
  end if;
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table telematics.position_reports enable row level security;
alter table telematics.telemetry_events enable row level security;

drop policy if exists position_reports_select on telematics.position_reports;
create policy position_reports_select on telematics.position_reports
  for select
  using (
    exists (
      select 1 from dispatch.dispatch_assignments da
       where da.id = telematics.position_reports.dispatch_id
         and da.deleted_at is null
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id
                    in (da.buyer_organization_id, da.carrier_organization_id)
                and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

drop policy if exists telemetry_events_select on telematics.telemetry_events;
create policy telemetry_events_select on telematics.telemetry_events
  for select
  using (
    exists (
      select 1 from dispatch.dispatch_assignments da
       where da.id = telematics.telemetry_events.dispatch_id
         and da.deleted_at is null
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id
                    in (da.buyer_organization_id, da.carrier_organization_id)
                and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. Carrier mutation RPCs (5)
-- ===========================================================================

-- 6.1 carrier_start_telemetry_session --------------------------------------
create or replace function telematics.carrier_start_telemetry_session(
  p_dispatch_id uuid,
  p_notes       text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  perform telematics.fn_assert_carrier_for_dispatch_telemetry(p_dispatch_id);
  v_id := telematics.fn_record_telemetry_event(
    p_dispatch_id, 'session_started', 'carrier', p_notes, '{}'::jsonb);
  return v_id;
end;
$$;

-- 6.2 carrier_end_telemetry_session ----------------------------------------
create or replace function telematics.carrier_end_telemetry_session(
  p_dispatch_id uuid,
  p_notes       text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  perform telematics.fn_assert_carrier_for_dispatch_telemetry(p_dispatch_id);
  v_id := telematics.fn_record_telemetry_event(
    p_dispatch_id, 'session_ended', 'carrier', p_notes, '{}'::jsonb);
  return v_id;
end;
$$;

-- 6.3 carrier_report_position ----------------------------------------------
create or replace function telematics.carrier_report_position(
  p_dispatch_id     uuid,
  p_latitude        numeric,
  p_longitude       numeric,
  p_reported_at     timestamptz,
  p_speed_kmh       numeric default null,
  p_heading_degrees integer default null,
  p_accuracy_meters numeric default null,
  p_altitude_meters numeric default null,
  p_source          text default 'carrier_app'
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_c uuid; v_id uuid;
  v_actor uuid := auth.uid();
begin
  perform telematics.fn_assert_carrier_for_dispatch_telemetry(p_dispatch_id);
  if p_latitude is null or p_longitude is null then
    raise exception 'telematics: latitude and longitude are required' using errcode = '22023';
  end if;
  if p_reported_at is null then
    raise exception 'telematics: reported_at is required' using errcode = '22023';
  end if;
  select tenant_id, carrier_organization_id into v_t, v_c
    from dispatch.dispatch_assignments where id = p_dispatch_id;
  insert into telematics.position_reports (
    tenant_id, dispatch_id, carrier_organization_id,
    latitude, longitude, speed_kmh, heading_degrees,
    accuracy_meters, altitude_meters, reported_at,
    source, reported_by
  ) values (
    v_t, p_dispatch_id, v_c,
    p_latitude, p_longitude, p_speed_kmh, p_heading_degrees,
    p_accuracy_meters, p_altitude_meters, p_reported_at,
    coalesce(p_source, 'carrier_app'), v_actor
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 6.4 carrier_report_positions_batch ---------------------------------------
-- Accepts a jsonb array of {lat, lng, reported_at, speed_kmh?, heading_degrees?,
-- accuracy_meters?, altitude_meters?} objects. Returns the number of inserted
-- rows.
create or replace function telematics.carrier_report_positions_batch(
  p_dispatch_id uuid,
  p_positions   jsonb,
  p_source      text default 'carrier_app'
) returns integer
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_c uuid;
  v_actor uuid := auth.uid();
  v_count integer := 0;
  v_rec jsonb;
begin
  perform telematics.fn_assert_carrier_for_dispatch_telemetry(p_dispatch_id);
  if p_positions is null or jsonb_typeof(p_positions) <> 'array' then
    raise exception 'telematics: positions must be a jsonb array' using errcode = '22023';
  end if;
  select tenant_id, carrier_organization_id into v_t, v_c
    from dispatch.dispatch_assignments where id = p_dispatch_id;
  for v_rec in select * from jsonb_array_elements(p_positions) loop
    if v_rec ? 'lat' = false or v_rec ? 'lng' = false or v_rec ? 'reported_at' = false then
      raise exception 'telematics: each position must include lat, lng, reported_at'
        using errcode = '22023';
    end if;
    insert into telematics.position_reports (
      tenant_id, dispatch_id, carrier_organization_id,
      latitude, longitude, speed_kmh, heading_degrees,
      accuracy_meters, altitude_meters, reported_at,
      source, reported_by, payload
    ) values (
      v_t, p_dispatch_id, v_c,
      (v_rec->>'lat')::numeric, (v_rec->>'lng')::numeric,
      nullif(v_rec->>'speed_kmh', '')::numeric,
      nullif(v_rec->>'heading_degrees', '')::integer,
      nullif(v_rec->>'accuracy_meters', '')::numeric,
      nullif(v_rec->>'altitude_meters', '')::numeric,
      (v_rec->>'reported_at')::timestamptz,
      coalesce(p_source, 'carrier_app'), v_actor,
      coalesce(v_rec->'meta', '{}'::jsonb)
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- 6.5 carrier_report_telemetry_event ---------------------------------------
-- For carrier-side signal_lost / signal_restored / position_anomaly markers.
-- session_started and session_ended go through their dedicated RPCs above.
create or replace function telematics.carrier_report_telemetry_event(
  p_dispatch_id uuid,
  p_event_type  telematics.telemetry_event_type,
  p_reason      text default null,
  p_payload     jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
begin
  perform telematics.fn_assert_carrier_for_dispatch_telemetry(p_dispatch_id);
  if p_event_type in ('session_started', 'session_ended') then
    raise exception 'telematics: use the dedicated session RPC for %', p_event_type
      using errcode = '22023';
  end if;
  return telematics.fn_record_telemetry_event(
    p_dispatch_id, p_event_type, 'carrier', p_reason, p_payload);
end;
$$;

-- ===========================================================================
-- 7. Carrier read RPCs (2)
-- ===========================================================================

-- 7.1 carrier_list_my_positions --------------------------------------------
create or replace function telematics.carrier_list_my_positions(
  p_dispatch_id uuid,
  p_limit       integer default 100,
  p_offset      integer default 0
) returns table (
  id                  uuid,
  dispatch_id         uuid,
  latitude            numeric,
  longitude           numeric,
  speed_kmh           numeric,
  heading_degrees     integer,
  reported_at         timestamptz,
  received_at         timestamptz,
  source              text
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare v_caller_org uuid := identity.current_organization_id();
        v_carrier uuid;
begin
  select carrier_organization_id into v_carrier
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_carrier is null then
    raise exception 'telematics: dispatch not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
      raise exception 'telematics: requires carrier_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null or v_caller_org <> v_carrier then
      raise exception 'telematics: dispatch not owned by caller carrier org' using errcode = '42501';
    end if;
  end if;
  return query
    select pr.id, pr.dispatch_id,
           pr.latitude, pr.longitude, pr.speed_kmh, pr.heading_degrees,
           pr.reported_at, pr.received_at, pr.source
      from telematics.position_reports pr
     where pr.dispatch_id = p_dispatch_id
     order by pr.reported_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 carrier_get_telemetry_snapshot ---------------------------------------
create or replace function telematics.carrier_get_telemetry_snapshot(p_dispatch_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare v_carrier uuid; v_caller_org uuid := identity.current_organization_id();
begin
  select carrier_organization_id into v_carrier
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_carrier is null then
    raise exception 'telematics: dispatch not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
      raise exception 'telematics: requires carrier_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null or v_caller_org <> v_carrier then
      raise exception 'telematics: dispatch not owned by caller carrier org' using errcode = '42501';
    end if;
  end if;
  return jsonb_build_object(
    'dispatch_id', p_dispatch_id,
    'latest_position', (
      select to_jsonb(pr) from telematics.position_reports pr
       where pr.dispatch_id = p_dispatch_id
       order by pr.reported_at desc limit 1
    ),
    'recent_events', (
      select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at desc), '[]'::jsonb)
        from (
          select * from telematics.telemetry_events
           where dispatch_id = p_dispatch_id
           order by created_at desc limit 25
        ) e
    )
  );
end;
$$;

-- ===========================================================================
-- 8. Buyer read RPCs (2)
-- ===========================================================================

-- 8.1 buyer_list_positions -------------------------------------------------
create or replace function telematics.buyer_list_positions(
  p_dispatch_id uuid,
  p_since       timestamptz default null,
  p_limit       integer default 500,
  p_offset      integer default 0
) returns table (
  id                  uuid,
  dispatch_id         uuid,
  latitude            numeric,
  longitude           numeric,
  speed_kmh           numeric,
  heading_degrees     integer,
  reported_at         timestamptz,
  source              text
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare v_buyer uuid; v_caller_org uuid := identity.current_organization_id();
begin
  select buyer_organization_id into v_buyer
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'telematics: dispatch not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
      raise exception 'telematics: requires buyer_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null or v_caller_org <> v_buyer then
      raise exception 'telematics: dispatch not owned by caller buyer org' using errcode = '42501';
    end if;
  end if;
  return query
    select pr.id, pr.dispatch_id,
           pr.latitude, pr.longitude, pr.speed_kmh, pr.heading_degrees,
           pr.reported_at, pr.source
      from telematics.position_reports pr
     where pr.dispatch_id = p_dispatch_id
       and (p_since is null or pr.reported_at >= p_since)
     order by pr.reported_at asc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 buyer_get_telemetry_snapshot -----------------------------------------
create or replace function telematics.buyer_get_telemetry_snapshot(p_dispatch_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare v_buyer uuid; v_caller_org uuid := identity.current_organization_id();
begin
  select buyer_organization_id into v_buyer
    from dispatch.dispatch_assignments where id = p_dispatch_id and deleted_at is null;
  if v_buyer is null then
    raise exception 'telematics: dispatch not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
      raise exception 'telematics: requires buyer_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null or v_caller_org <> v_buyer then
      raise exception 'telematics: dispatch not owned by caller buyer org' using errcode = '42501';
    end if;
  end if;
  return jsonb_build_object(
    'dispatch_id', p_dispatch_id,
    'latest_position', (
      select to_jsonb(pr) from telematics.position_reports pr
       where pr.dispatch_id = p_dispatch_id
       order by pr.reported_at desc limit 1
    ),
    'recent_events', (
      select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at desc), '[]'::jsonb)
        from (
          select * from telematics.telemetry_events
           where dispatch_id = p_dispatch_id
           order by created_at desc limit 25
        ) e
    )
  );
end;
$$;

-- ===========================================================================
-- 9. Admin read RPCs (3)
-- ===========================================================================

-- 9.1 admin_list_positions -------------------------------------------------
create or replace function telematics.admin_list_positions(
  p_dispatch_id uuid,
  p_since       timestamptz default null,
  p_limit       integer default 1000,
  p_offset      integer default 0
) returns table (
  id                  uuid,
  dispatch_id         uuid,
  latitude            numeric,
  longitude           numeric,
  speed_kmh           numeric,
  heading_degrees     integer,
  reported_at         timestamptz,
  received_at         timestamptz,
  source              text
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  if not identity.is_platform_admin() then
    raise exception 'telematics.admin_list_positions: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    select pr.id, pr.dispatch_id,
           pr.latitude, pr.longitude, pr.speed_kmh, pr.heading_degrees,
           pr.reported_at, pr.received_at, pr.source
      from telematics.position_reports pr
     where pr.dispatch_id = p_dispatch_id
       and (p_since is null or pr.reported_at >= p_since)
     order by pr.reported_at asc
     limit p_limit offset p_offset;
end;
$$;

-- 9.2 admin_get_telemetry_snapshot -----------------------------------------
create or replace function telematics.admin_get_telemetry_snapshot(p_dispatch_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'telematics.admin_get_telemetry_snapshot: requires platform_admin'
      using errcode = '42501';
  end if;
  return jsonb_build_object(
    'dispatch_id', p_dispatch_id,
    'latest_position', (
      select to_jsonb(pr) from telematics.position_reports pr
       where pr.dispatch_id = p_dispatch_id
       order by pr.reported_at desc limit 1
    ),
    'recent_events', (
      select coalesce(jsonb_agg(to_jsonb(e) order by e.created_at desc), '[]'::jsonb)
        from (
          select * from telematics.telemetry_events
           where dispatch_id = p_dispatch_id
           order by created_at desc limit 50
        ) e
    )
  );
end;
$$;

-- 9.3 admin_list_active_sessions -------------------------------------------
-- A dispatch has an "active" session iff its most recent telemetry event is
-- session_started (i.e., no matching session_ended after it). Returned with
-- the latest position so the admin live map can plot active dispatches.
create or replace function telematics.admin_list_active_sessions(
  p_limit  integer default 100,
  p_offset integer default 0
) returns table (
  dispatch_id            uuid,
  carrier_organization_id uuid,
  session_started_at     timestamptz,
  last_position_at       timestamptz,
  latitude               numeric,
  longitude              numeric,
  age_minutes            numeric
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  if not identity.is_platform_admin() then
    raise exception 'telematics.admin_list_active_sessions: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    with latest_session_event as (
      select e.dispatch_id, e.event_type, e.created_at,
             row_number() over (partition by e.dispatch_id order by e.created_at desc) as rn
        from telematics.telemetry_events e
       where e.event_type in ('session_started', 'session_ended')
    ),
    active as (
      select dispatch_id, created_at as session_started_at
        from latest_session_event
       where rn = 1 and event_type = 'session_started'
    ),
    latest_position as (
      select pr.dispatch_id,
             pr.reported_at, pr.latitude, pr.longitude,
             row_number() over (partition by pr.dispatch_id order by pr.reported_at desc) as rn
        from telematics.position_reports pr
    )
    select a.dispatch_id,
           da.carrier_organization_id,
           a.session_started_at,
           lp.reported_at,
           lp.latitude,
           lp.longitude,
           extract(epoch from (now() - lp.reported_at)) / 60.0
      from active a
      join dispatch.dispatch_assignments da on da.id = a.dispatch_id
      left join latest_position lp on lp.dispatch_id = a.dispatch_id and lp.rn = 1
     where da.deleted_at is null
     order by a.session_started_at desc
     limit p_limit offset p_offset;
end;
$$;

-- ===========================================================================
-- 10. Notification dispatch trigger (Q6=A)
-- ===========================================================================
-- Emits notify events for session_started / session_ended only. Position
-- reports and signal_lost / signal_restored / position_anomaly markers are
-- intentionally NOT emitted (would be too noisy).
create or replace function notify.fn_trg_from_telemetry_event()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_event text;
begin
  v_event := case new.event_type
    when 'session_started' then 'telematics.session_started'
    when 'session_ended'   then 'telematics.session_ended'
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
      'event_type', new.event_type,
      'actor_party', new.actor_party
    ),
    new.tenant_id
  );
  return new;
exception when others then
  return new;
end;
$$;

drop trigger if exists trg_telemetry_event_notify on telematics.telemetry_events;
create trigger trg_telemetry_event_notify
  after insert on telematics.telemetry_events
  for each row execute function notify.fn_trg_from_telemetry_event();

-- ===========================================================================
-- 11. Grants
-- ===========================================================================
grant select on telematics.position_reports to authenticated;
grant select on telematics.telemetry_events to authenticated;

grant execute on function telematics.carrier_start_telemetry_session(uuid, text) to authenticated;
grant execute on function telematics.carrier_end_telemetry_session(uuid, text) to authenticated;
grant execute on function telematics.carrier_report_position(
  uuid, numeric, numeric, timestamptz, numeric, integer, numeric, numeric, text
) to authenticated;
grant execute on function telematics.carrier_report_positions_batch(uuid, jsonb, text) to authenticated;
grant execute on function telematics.carrier_report_telemetry_event(
  uuid, telematics.telemetry_event_type, text, jsonb
) to authenticated;
grant execute on function telematics.carrier_list_my_positions(uuid, integer, integer) to authenticated;
grant execute on function telematics.carrier_get_telemetry_snapshot(uuid) to authenticated;

grant execute on function telematics.buyer_list_positions(uuid, timestamptz, integer, integer) to authenticated;
grant execute on function telematics.buyer_get_telemetry_snapshot(uuid) to authenticated;

grant execute on function telematics.admin_list_positions(uuid, timestamptz, integer, integer) to authenticated;
grant execute on function telematics.admin_get_telemetry_snapshot(uuid) to authenticated;
grant execute on function telematics.admin_list_active_sessions(integer, integer) to authenticated;
