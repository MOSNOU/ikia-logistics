-- CC-47 / Migration 0047 — Driver App MVP Foundation.
-- Append-only over 0001-0046. Adds the driver-app execution layer on top of the
-- existing `dispatch` schema (CC-43, migration 0036) and the `telematics`
-- position stream (CC-45, migration 0038). A driver is a carrier-organization
-- user who executes a released dispatch: accepting the trip, reporting milestone
-- transitions, sending GPS positions, raising issues, and attaching proof of
-- delivery (POD) documents.
--
-- Boundaries respected (additive only):
--   * No destructive changes to any pre-existing platform object.
--   * Only additive ALTERs on dispatch.dispatch_assignments (new nullable cols).
--   * New tables live under the existing `dispatch` schema.
--   * Reuses dispatch.fn_audit (CC-43) and telematics.position_reports (CC-45).
--   * Writes happen only through SECURITY DEFINER RPCs; no direct
--     INSERT/UPDATE/DELETE grants to authenticated. The driver_trip_events
--     ledger is append-only (SELECT grant only, no UPDATE/DELETE policy).
--
-- This migration is idempotent / re-runnable (guarded enums, add column if not
-- exists, create table if not exists, create or replace function, drop policy
-- if exists before create).

-- ===========================================================================
-- 1. Role seed (idempotent)
-- ===========================================================================
insert into identity.roles (code, scope, label_fa, label_en, description, is_system)
values ('driver', 'organization', 'راننده', 'Driver',
        'Driver app user tied to a carrier organization', true)
on conflict (code) do nothing;

-- ===========================================================================
-- 2. Enums (guarded — additive, idempotent)
-- ===========================================================================
do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'dispatch' and t.typname = 'trip_execution_status') then
    create type dispatch.trip_execution_status as enum (
      'assigned',
      'accepted',
      'arrived_at_pickup',
      'loading_started',
      'loaded',
      'in_transit',
      'arrived_at_delivery',
      'unloading_started',
      'delivered',
      'completed'
    );
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'dispatch' and t.typname = 'trip_issue_category') then
    create type dispatch.trip_issue_category as enum (
      'delay', 'vehicle', 'loading', 'border', 'accident', 'other'
    );
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'dispatch' and t.typname = 'trip_issue_status') then
    create type dispatch.trip_issue_status as enum (
      'open', 'acknowledged', 'resolved'
    );
  end if;
end $$;

do $$ begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                  where n.nspname = 'dispatch' and t.typname = 'trip_pod_kind') then
    create type dispatch.trip_pod_kind as enum (
      'delivery_photo', 'bill_of_lading', 'receipt', 'other'
    );
  end if;
end $$;

-- ===========================================================================
-- 3. Extend dispatch.dispatch_assignments (additive only)
-- ===========================================================================
alter table dispatch.dispatch_assignments
  add column if not exists driver_user_id   uuid references auth.users(id),
  add column if not exists execution_status dispatch.trip_execution_status,
  add column if not exists accepted_at      timestamptz,
  add column if not exists completed_at     timestamptz;

create index if not exists dispatch_assignments_driver_exec_idx
  on dispatch.dispatch_assignments(driver_user_id, execution_status);
create index if not exists dispatch_assignments_tenant_exec_idx
  on dispatch.dispatch_assignments(tenant_id, execution_status);
create index if not exists dispatch_assignments_carrier_exec_idx
  on dispatch.dispatch_assignments(carrier_organization_id, execution_status);

-- ===========================================================================
-- 4. New tables (3)
-- ===========================================================================

-- 4.1 driver_trip_events (append-only ledger) ------------------------------
create table if not exists dispatch.driver_trip_events (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references identity.tenants(id) on delete restrict,
  dispatch_id     uuid not null references dispatch.dispatch_assignments(id) on delete cascade,

  from_status     dispatch.trip_execution_status,
  to_status       dispatch.trip_execution_status not null,
  actor_user_id   uuid not null references auth.users(id),
  latitude        numeric(9,6),
  longitude       numeric(9,6),
  reason          text,
  payload         jsonb not null default '{}'::jsonb,

  created_at      timestamptz not null default now()
);

comment on table dispatch.driver_trip_events is
  'CC-47: append-only driver trip ledger. One row per execution-status transition or issue marker. INSERT-only via SECURITY DEFINER RPCs (no UPDATE/DELETE policy or grant).';

create index if not exists driver_trip_events_tenant_idx
  on dispatch.driver_trip_events(tenant_id);
create index if not exists driver_trip_events_dispatch_idx
  on dispatch.driver_trip_events(dispatch_id, created_at desc);

-- 4.2 driver_trip_issues ----------------------------------------------------
create table if not exists dispatch.driver_trip_issues (
  id               uuid primary key default gen_random_uuid(),
  tenant_id        uuid not null references identity.tenants(id) on delete restrict,
  dispatch_id      uuid not null references dispatch.dispatch_assignments(id) on delete cascade,

  reported_by      uuid not null references auth.users(id),
  category         dispatch.trip_issue_category not null,
  status           dispatch.trip_issue_status not null default 'open',
  severity         smallint not null default 1,
  description      text,
  photo_file_id    uuid references app_storage.files(id),
  reported_at      timestamptz not null default now(),
  acknowledged_by  uuid references auth.users(id),
  acknowledged_at  timestamptz,
  resolved_by      uuid references auth.users(id),
  resolved_at      timestamptz,
  resolution_note  text,

  created_at       timestamptz not null default now()
);

comment on table dispatch.driver_trip_issues is
  'CC-47: driver-reported trip issues (delay / vehicle / loading / border / accident / other). Acknowledged + resolved by carrier ops / platform admin via RPC.';

create index if not exists driver_trip_issues_tenant_idx
  on dispatch.driver_trip_issues(tenant_id);
create index if not exists driver_trip_issues_dispatch_idx
  on dispatch.driver_trip_issues(dispatch_id, created_at desc);
create index if not exists driver_trip_issues_status_idx
  on dispatch.driver_trip_issues(status);
create index if not exists driver_trip_issues_category_idx
  on dispatch.driver_trip_issues(category);

-- 4.3 driver_trip_pods ------------------------------------------------------
create table if not exists dispatch.driver_trip_pods (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references identity.tenants(id) on delete restrict,
  dispatch_id  uuid not null references dispatch.dispatch_assignments(id) on delete cascade,

  file_id      uuid not null references app_storage.files(id),
  kind         dispatch.trip_pod_kind not null,
  uploaded_by  uuid not null references auth.users(id),

  created_at   timestamptz not null default now()
);

comment on table dispatch.driver_trip_pods is
  'CC-47: proof-of-delivery documents attached by the driver, referencing app_storage.files. At least one POD is required before a trip can be completed.';

create index if not exists driver_trip_pods_tenant_idx
  on dispatch.driver_trip_pods(tenant_id);
create index if not exists driver_trip_pods_dispatch_idx
  on dispatch.driver_trip_pods(dispatch_id, created_at desc);

-- ===========================================================================
-- 5. Row Level Security
-- New tables: SELECT policies only. No INSERT/UPDATE/DELETE for authenticated;
-- all writes go through SECURITY DEFINER RPCs.
-- ===========================================================================
alter table dispatch.driver_trip_events enable row level security;
alter table dispatch.driver_trip_issues enable row level security;
alter table dispatch.driver_trip_pods   enable row level security;

-- 5.1 driver_trip_events: assigned driver + carrier org + admin/ops.
drop policy if exists driver_trip_events_select on dispatch.driver_trip_events;
create policy driver_trip_events_select on dispatch.driver_trip_events
  for select
  using (
    identity.has_role('platform_admin')
    or identity.has_role('operations_user')
    or exists (
      select 1 from dispatch.dispatch_assignments da
       where da.id = dispatch.driver_trip_events.dispatch_id
         and (
           da.driver_user_id = identity.current_user_id()
           or da.carrier_organization_id = identity.current_organization_id()
         )
    )
  );

-- 5.2 driver_trip_issues.
drop policy if exists driver_trip_issues_select on dispatch.driver_trip_issues;
create policy driver_trip_issues_select on dispatch.driver_trip_issues
  for select
  using (
    identity.has_role('platform_admin')
    or identity.has_role('operations_user')
    or exists (
      select 1 from dispatch.dispatch_assignments da
       where da.id = dispatch.driver_trip_issues.dispatch_id
         and (
           da.driver_user_id = identity.current_user_id()
           or da.carrier_organization_id = identity.current_organization_id()
         )
    )
  );

-- 5.3 driver_trip_pods.
drop policy if exists driver_trip_pods_select on dispatch.driver_trip_pods;
create policy driver_trip_pods_select on dispatch.driver_trip_pods
  for select
  using (
    identity.has_role('platform_admin')
    or identity.has_role('operations_user')
    or exists (
      select 1 from dispatch.dispatch_assignments da
       where da.id = dispatch.driver_trip_pods.dispatch_id
         and (
           da.driver_user_id = identity.current_user_id()
           or da.carrier_organization_id = identity.current_organization_id()
         )
    )
  );

-- 5.4 Extend dispatch_assignments select so the assigned driver can see their
-- own dispatch rows. This ADDS a policy; it does NOT drop the existing
-- dispatch_assignments_select / dispatch_assignments_admin_modify policies.
drop policy if exists dispatch_assignments_driver_select on dispatch.dispatch_assignments;
create policy dispatch_assignments_driver_select on dispatch.dispatch_assignments
  for select
  using (
    deleted_at is null
    and driver_user_id = identity.current_user_id()
  );

-- ===========================================================================
-- 6. Internal helpers (SECURITY DEFINER, search_path='')
-- ===========================================================================

-- 6.1 fn_assert_driver_owns ------------------------------------------------
create or replace function dispatch.fn_assert_driver_owns(p_dispatch_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_driver uuid;
begin
  if not identity.has_role('driver') then
    raise exception 'dispatch: requires driver role' using errcode = '42501';
  end if;
  select driver_user_id into v_driver
    from dispatch.dispatch_assignments
   where id = p_dispatch_id and deleted_at is null;
  if v_driver is null or v_driver <> auth.uid() then
    raise exception 'dispatch: trip not assigned to caller' using errcode = '42501';
  end if;
end;
$$;

-- 6.2 fn_assert_dispatch_released ------------------------------------------
create or replace function dispatch.fn_assert_dispatch_released(p_dispatch_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status dispatch.dispatch_status;
begin
  select status into v_status
    from dispatch.dispatch_assignments
   where id = p_dispatch_id and deleted_at is null;
  if v_status is null then
    raise exception 'dispatch: assignment not found' using errcode = 'P0002';
  end if;
  if v_status <> 'released' then
    raise exception 'dispatch: trip is not released (status=%)', v_status
      using errcode = 'P0001';
  end if;
end;
$$;

-- 6.3 fn_driver_transition --------------------------------------------------
-- The single write-path for execution-status milestone transitions. Asserts
-- the caller owns the trip and the dispatch is released, validates the
-- from→to transition against the current execution_status, updates the row,
-- records an append-only driver_trip_events ledger row, and audits.
create or replace function dispatch.fn_driver_transition(
  p_dispatch_id uuid,
  p_from        dispatch.trip_execution_status,
  p_to          dispatch.trip_execution_status,
  p_lat         numeric default null,
  p_lng         numeric default null,
  p_reason      text default null
) returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid;
  v_current dispatch.trip_execution_status;
begin
  perform dispatch.fn_assert_driver_owns(p_dispatch_id);
  perform dispatch.fn_assert_dispatch_released(p_dispatch_id);

  select tenant_id, execution_status into v_t, v_current
    from dispatch.dispatch_assignments where id = p_dispatch_id;

  -- A null execution_status is treated as the implicit 'assigned' starting
  -- state so the very first accept transition (assigned→accepted) works even
  -- if execution_status was never populated.
  if coalesce(v_current, 'assigned') is distinct from p_from then
    raise exception 'dispatch: invalid transition from % (expected %)',
      coalesce(v_current, 'assigned'), p_from using errcode = 'P0001';
  end if;

  update dispatch.dispatch_assignments
     set execution_status = p_to,
         accepted_at  = case when p_to = 'accepted'  then now() else accepted_at  end,
         completed_at = case when p_to = 'completed' then now() else completed_at end,
         updated_at   = now(),
         version      = version + 1
   where id = p_dispatch_id;

  insert into dispatch.driver_trip_events (
    tenant_id, dispatch_id, from_status, to_status,
    actor_user_id, latitude, longitude, reason
  ) values (
    v_t, p_dispatch_id, p_from, p_to,
    auth.uid(), p_lat, p_lng, p_reason
  );

  perform dispatch.fn_audit('driver.trip.' || p_to::text, p_dispatch_id,
    jsonb_build_object('from', p_from::text, 'to', p_to::text));

  return p_to;
end;
$$;

-- ===========================================================================
-- 7. Driver RPCs
-- ===========================================================================

-- 7.1 driver_list_my_trips --------------------------------------------------
create or replace function dispatch.driver_list_my_trips(
  p_status dispatch.trip_execution_status default null,
  p_limit  int default 50,
  p_offset int default 0
) returns table (
  dispatch_id        uuid,
  booking_request_id uuid,
  dispatch_status    dispatch.dispatch_status,
  execution_status   dispatch.trip_execution_status,
  vehicle_reference  text,
  planned_pickup_at  timestamptz,
  last_latitude      numeric,
  last_longitude     numeric,
  last_reported_at   timestamptz,
  accepted_at        timestamptz,
  completed_at       timestamptz,
  created_at         timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if not identity.has_role('driver') then
    raise exception 'dispatch: requires driver role' using errcode = '42501';
  end if;
  return query
    select da.id, da.booking_request_id, da.status, da.execution_status,
           da.vehicle_reference, da.planned_pickup_at,
           lp.latitude, lp.longitude, lp.reported_at,
           da.accepted_at, da.completed_at, da.created_at
      from dispatch.dispatch_assignments da
      left join lateral (
        select pr.latitude, pr.longitude, pr.reported_at
          from telematics.position_reports pr
         where pr.dispatch_id = da.id
         order by pr.reported_at desc
         limit 1
      ) lp on true
     where da.deleted_at is null
       and da.driver_user_id = v_uid
       and (p_status is null or da.execution_status = p_status)
     order by da.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 driver_get_trip -------------------------------------------------------
create or replace function dispatch.driver_get_trip(p_dispatch_id uuid)
returns table (
  dispatch_id        uuid,
  booking_request_id uuid,
  dispatch_status    dispatch.dispatch_status,
  execution_status   dispatch.trip_execution_status,
  vehicle_reference  text,
  vehicle_type       text,
  driver_name        text,
  driver_phone       text,
  planned_pickup_at  timestamptz,
  last_latitude      numeric,
  last_longitude     numeric,
  last_reported_at   timestamptz,
  accepted_at        timestamptz,
  completed_at       timestamptz,
  created_at         timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform dispatch.fn_assert_driver_owns(p_dispatch_id);
  return query
    select da.id, da.booking_request_id, da.status, da.execution_status,
           da.vehicle_reference, da.vehicle_type, da.driver_name, da.driver_phone,
           da.planned_pickup_at,
           lp.latitude, lp.longitude, lp.reported_at,
           da.accepted_at, da.completed_at, da.created_at
      from dispatch.dispatch_assignments da
      left join lateral (
        select pr.latitude, pr.longitude, pr.reported_at
          from telematics.position_reports pr
         where pr.dispatch_id = da.id
         order by pr.reported_at desc
         limit 1
      ) lp on true
     where da.id = p_dispatch_id and da.deleted_at is null;
end;
$$;

-- 7.3 Milestone transition RPCs --------------------------------------------
create or replace function dispatch.driver_accept_trip(p_dispatch_id uuid)
returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'assigned', 'accepted');
end;
$$;

create or replace function dispatch.driver_arrive_pickup(
  p_dispatch_id uuid, p_lat numeric default null, p_lng numeric default null
) returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'accepted', 'arrived_at_pickup', p_lat, p_lng);
end;
$$;

create or replace function dispatch.driver_start_loading(p_dispatch_id uuid)
returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'arrived_at_pickup', 'loading_started');
end;
$$;

create or replace function dispatch.driver_confirm_loaded(p_dispatch_id uuid)
returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'loading_started', 'loaded');
end;
$$;

create or replace function dispatch.driver_start_transit(
  p_dispatch_id uuid, p_lat numeric default null, p_lng numeric default null
) returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'loaded', 'in_transit', p_lat, p_lng);
end;
$$;

create or replace function dispatch.driver_arrive_delivery(
  p_dispatch_id uuid, p_lat numeric default null, p_lng numeric default null
) returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'in_transit', 'arrived_at_delivery', p_lat, p_lng);
end;
$$;

create or replace function dispatch.driver_start_unloading(p_dispatch_id uuid)
returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'arrived_at_delivery', 'unloading_started');
end;
$$;

create or replace function dispatch.driver_confirm_delivered(p_dispatch_id uuid)
returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  return dispatch.fn_driver_transition(p_dispatch_id, 'unloading_started', 'delivered');
end;
$$;

create or replace function dispatch.driver_complete_trip(p_dispatch_id uuid)
returns dispatch.trip_execution_status
language plpgsql volatile security definer set search_path = ''
as $$
begin
  -- A trip cannot be completed without at least one proof-of-delivery doc.
  if not exists (
    select 1 from dispatch.driver_trip_pods where dispatch_id = p_dispatch_id
  ) then
    raise exception 'dispatch: POD required before completing trip' using errcode = 'P0001';
  end if;
  return dispatch.fn_driver_transition(p_dispatch_id, 'delivered', 'completed');
end;
$$;

-- 7.4 driver_report_issue ---------------------------------------------------
-- Inserts an issue row and ALSO records a driver_trip_events marker (the issue
-- does NOT change execution_status). Returns the issue id.
create or replace function dispatch.driver_report_issue(
  p_dispatch_id   uuid,
  p_category      dispatch.trip_issue_category,
  p_severity      smallint default 1,
  p_description   text default null,
  p_photo_file_id uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid;
  v_exec dispatch.trip_execution_status;
  v_issue uuid;
begin
  perform dispatch.fn_assert_driver_owns(p_dispatch_id);
  perform dispatch.fn_assert_dispatch_released(p_dispatch_id);

  select tenant_id, execution_status into v_t, v_exec
    from dispatch.dispatch_assignments where id = p_dispatch_id;

  insert into dispatch.driver_trip_issues (
    tenant_id, dispatch_id, reported_by, category, severity, description, photo_file_id
  ) values (
    v_t, p_dispatch_id, auth.uid(), p_category,
    coalesce(p_severity, 1::smallint), p_description, p_photo_file_id
  ) returning id into v_issue;

  -- Append a ledger marker without changing execution_status.
  insert into dispatch.driver_trip_events (
    tenant_id, dispatch_id, from_status, to_status, actor_user_id, reason, payload
  ) values (
    v_t, p_dispatch_id, coalesce(v_exec, 'assigned'), coalesce(v_exec, 'assigned'),
    auth.uid(), 'issue:' || p_category::text,
    jsonb_build_object('issue_id', v_issue::text, 'category', p_category::text,
                       'severity', coalesce(p_severity, 1::smallint))
  );

  perform dispatch.fn_audit('driver.trip.issue', p_dispatch_id,
    jsonb_build_object('issue_id', v_issue::text, 'category', p_category::text));

  return v_issue;
end;
$$;

-- 7.5 driver_send_position --------------------------------------------------
-- Records a GPS sample into telematics.position_reports with source='driver_app'.
-- Allowed only while the trip is in an ACTIVE execution state.
create or replace function dispatch.driver_send_position(
  p_dispatch_id     uuid,
  p_latitude        numeric,
  p_longitude       numeric,
  p_reported_at     timestamptz,
  p_accuracy_meters numeric default null,
  p_speed_kmh       numeric default null,
  p_heading_degrees integer default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_c uuid; v_exec dispatch.trip_execution_status; v_id uuid;
begin
  perform dispatch.fn_assert_driver_owns(p_dispatch_id);

  select tenant_id, carrier_organization_id, execution_status
    into v_t, v_c, v_exec
    from dispatch.dispatch_assignments where id = p_dispatch_id;

  if v_exec is null or v_exec not in (
    'accepted', 'arrived_at_pickup', 'loading_started', 'loaded',
    'in_transit', 'arrived_at_delivery', 'unloading_started', 'delivered'
  ) then
    raise exception 'dispatch: trip is not in an active state (execution_status=%)', v_exec
      using errcode = 'P0001';
  end if;

  if p_latitude is null or p_longitude is null then
    raise exception 'dispatch: latitude and longitude are required' using errcode = '22023';
  end if;
  if p_reported_at is null then
    raise exception 'dispatch: reported_at is required' using errcode = '22023';
  end if;

  insert into telematics.position_reports (
    tenant_id, dispatch_id, carrier_organization_id,
    latitude, longitude, accuracy_meters, speed_kmh, heading_degrees,
    reported_at, source, reported_by
  ) values (
    v_t, p_dispatch_id, v_c,
    p_latitude, p_longitude, p_accuracy_meters, p_speed_kmh, p_heading_degrees,
    p_reported_at, 'driver_app', auth.uid()
  ) returning id into v_id;

  return v_id;
end;
$$;

-- 7.6 driver_attach_pod -----------------------------------------------------
-- Attaches a proof-of-delivery document. The referenced file must exist in
-- app_storage.files and be owned (uploaded) by the calling driver.
create or replace function dispatch.driver_attach_pod(
  p_dispatch_id uuid,
  p_file_id     uuid,
  p_kind        dispatch.trip_pod_kind
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid; v_file_owner uuid; v_pod uuid;
begin
  perform dispatch.fn_assert_driver_owns(p_dispatch_id);
  perform dispatch.fn_assert_dispatch_released(p_dispatch_id);

  select uploaded_by_user_id into v_file_owner
    from app_storage.files where id = p_file_id and deleted_at is null;
  if v_file_owner is null then
    raise exception 'dispatch: POD file not found' using errcode = 'P0001';
  end if;
  if v_file_owner <> auth.uid() then
    raise exception 'dispatch: POD file not owned by caller' using errcode = '42501';
  end if;

  select tenant_id into v_t
    from dispatch.dispatch_assignments where id = p_dispatch_id;

  insert into dispatch.driver_trip_pods (
    tenant_id, dispatch_id, file_id, kind, uploaded_by
  ) values (
    v_t, p_dispatch_id, p_file_id, p_kind, auth.uid()
  ) returning id into v_pod;

  perform dispatch.fn_audit('driver.trip.pod_attached', p_dispatch_id,
    jsonb_build_object('pod_id', v_pod::text, 'file_id', p_file_id::text,
                       'kind', p_kind::text));

  return v_pod;
end;
$$;

-- ===========================================================================
-- 8. Admin / Operations RPCs
-- Require platform_admin OR operations_user. Operations users are scoped to
-- their own tenant; platform_admin sees all tenants.
-- ===========================================================================

-- 8.0 internal: assert admin-or-ops, return whether caller is platform_admin.
create or replace function dispatch.fn_assert_driver_admin()
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
begin
  if identity.has_role('platform_admin') then
    return true;
  end if;
  if identity.has_role('operations_user') then
    return false;
  end if;
  raise exception 'dispatch: requires platform_admin or operations_user'
    using errcode = '42501';
end;
$$;

-- 8.1 admin_list_driver_trip_statuses --------------------------------------
create or replace function dispatch.admin_list_driver_trip_statuses(
  p_organization_id uuid default null,
  p_status          dispatch.trip_execution_status default null,
  p_limit           int default 100,
  p_offset          int default 0
) returns table (
  dispatch_id             uuid,
  carrier_organization_id uuid,
  driver_user_id          uuid,
  dispatch_status         dispatch.dispatch_status,
  execution_status        dispatch.trip_execution_status,
  last_latitude           numeric,
  last_longitude          numeric,
  last_reported_at        timestamptz,
  open_issue_count        bigint,
  planned_pickup_at       timestamptz,
  created_at              timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_is_admin boolean; v_tenant uuid := identity.current_tenant_id();
begin
  v_is_admin := dispatch.fn_assert_driver_admin();
  return query
    select da.id, da.carrier_organization_id, da.driver_user_id,
           da.status, da.execution_status,
           lp.latitude, lp.longitude, lp.reported_at,
           (select count(*) from dispatch.driver_trip_issues i
             where i.dispatch_id = da.id and i.status = 'open'),
           da.planned_pickup_at, da.created_at
      from dispatch.dispatch_assignments da
      left join lateral (
        select pr.latitude, pr.longitude, pr.reported_at
          from telematics.position_reports pr
         where pr.dispatch_id = da.id
         order by pr.reported_at desc
         limit 1
      ) lp on true
     where da.deleted_at is null
       and da.driver_user_id is not null
       and (v_is_admin or da.tenant_id = v_tenant)
       and (p_organization_id is null or da.carrier_organization_id = p_organization_id)
       and (p_status is null or da.execution_status = p_status)
     order by da.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_driver_trip_detail -----------------------------------------
create or replace function dispatch.admin_get_driver_trip_detail(p_dispatch_id uuid)
returns table (
  dispatch_id             uuid,
  carrier_organization_id uuid,
  driver_user_id          uuid,
  dispatch_status         dispatch.dispatch_status,
  execution_status        dispatch.trip_execution_status,
  last_latitude           numeric,
  last_longitude          numeric,
  last_reported_at        timestamptz,
  open_issue_count        bigint,
  pod_count               bigint,
  planned_pickup_at       timestamptz,
  accepted_at             timestamptz,
  completed_at            timestamptz,
  created_at              timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_is_admin boolean; v_tenant uuid := identity.current_tenant_id();
begin
  v_is_admin := dispatch.fn_assert_driver_admin();
  return query
    select da.id, da.carrier_organization_id, da.driver_user_id,
           da.status, da.execution_status,
           lp.latitude, lp.longitude, lp.reported_at,
           (select count(*) from dispatch.driver_trip_issues i
             where i.dispatch_id = da.id and i.status = 'open'),
           (select count(*) from dispatch.driver_trip_pods p
             where p.dispatch_id = da.id),
           da.planned_pickup_at, da.accepted_at, da.completed_at, da.created_at
      from dispatch.dispatch_assignments da
      left join lateral (
        select pr.latitude, pr.longitude, pr.reported_at
          from telematics.position_reports pr
         where pr.dispatch_id = da.id
         order by pr.reported_at desc
         limit 1
      ) lp on true
     where da.id = p_dispatch_id
       and da.deleted_at is null
       and (v_is_admin or da.tenant_id = v_tenant);
end;
$$;

-- 8.3 admin_ack_driver_issue -----------------------------------------------
create or replace function dispatch.admin_ack_driver_issue(p_issue_id uuid)
returns dispatch.trip_issue_status
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_is_admin boolean; v_tenant uuid := identity.current_tenant_id();
  v_issue_tenant uuid; v_status dispatch.trip_issue_status; v_dispatch uuid;
begin
  v_is_admin := dispatch.fn_assert_driver_admin();
  select tenant_id, status, dispatch_id
    into v_issue_tenant, v_status, v_dispatch
    from dispatch.driver_trip_issues where id = p_issue_id;
  if v_issue_tenant is null then
    raise exception 'dispatch: issue not found' using errcode = 'P0002';
  end if;
  if not v_is_admin and v_issue_tenant is distinct from v_tenant then
    raise exception 'dispatch: issue not in caller tenant' using errcode = '42501';
  end if;
  if v_status <> 'open' then
    raise exception 'dispatch: issue is not open (status=%)', v_status using errcode = 'P0001';
  end if;
  update dispatch.driver_trip_issues
     set status = 'acknowledged',
         acknowledged_by = auth.uid(),
         acknowledged_at = now()
   where id = p_issue_id;
  perform dispatch.fn_audit('driver.trip.issue_acknowledged', v_dispatch,
    jsonb_build_object('issue_id', p_issue_id::text));
  return 'acknowledged'::dispatch.trip_issue_status;
end;
$$;

-- 8.4 admin_resolve_driver_issue -------------------------------------------
create or replace function dispatch.admin_resolve_driver_issue(
  p_issue_id uuid,
  p_note     text default null
) returns dispatch.trip_issue_status
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_is_admin boolean; v_tenant uuid := identity.current_tenant_id();
  v_issue_tenant uuid; v_status dispatch.trip_issue_status; v_dispatch uuid;
begin
  v_is_admin := dispatch.fn_assert_driver_admin();
  select tenant_id, status, dispatch_id
    into v_issue_tenant, v_status, v_dispatch
    from dispatch.driver_trip_issues where id = p_issue_id;
  if v_issue_tenant is null then
    raise exception 'dispatch: issue not found' using errcode = 'P0002';
  end if;
  if not v_is_admin and v_issue_tenant is distinct from v_tenant then
    raise exception 'dispatch: issue not in caller tenant' using errcode = '42501';
  end if;
  if v_status = 'resolved' then
    raise exception 'dispatch: issue already resolved' using errcode = 'P0001';
  end if;
  update dispatch.driver_trip_issues
     set status = 'resolved',
         resolved_by = auth.uid(),
         resolved_at = now(),
         resolution_note = p_note
   where id = p_issue_id;
  perform dispatch.fn_audit('driver.trip.issue_resolved', v_dispatch,
    jsonb_build_object('issue_id', p_issue_id::text));
  return 'resolved'::dispatch.trip_issue_status;
end;
$$;

-- ===========================================================================
-- 9. Grants
-- SELECT only on the new tables (no INSERT/UPDATE/DELETE); EXECUTE on RPCs.
-- ===========================================================================
grant select on dispatch.driver_trip_events to authenticated;
grant select on dispatch.driver_trip_issues to authenticated;
grant select on dispatch.driver_trip_pods   to authenticated;

grant execute on function dispatch.driver_list_my_trips(
  dispatch.trip_execution_status, int, int) to authenticated;
grant execute on function dispatch.driver_get_trip(uuid) to authenticated;
grant execute on function dispatch.driver_accept_trip(uuid) to authenticated;
grant execute on function dispatch.driver_arrive_pickup(uuid, numeric, numeric) to authenticated;
grant execute on function dispatch.driver_start_loading(uuid) to authenticated;
grant execute on function dispatch.driver_confirm_loaded(uuid) to authenticated;
grant execute on function dispatch.driver_start_transit(uuid, numeric, numeric) to authenticated;
grant execute on function dispatch.driver_arrive_delivery(uuid, numeric, numeric) to authenticated;
grant execute on function dispatch.driver_start_unloading(uuid) to authenticated;
grant execute on function dispatch.driver_confirm_delivered(uuid) to authenticated;
grant execute on function dispatch.driver_complete_trip(uuid) to authenticated;
grant execute on function dispatch.driver_report_issue(
  uuid, dispatch.trip_issue_category, smallint, text, uuid) to authenticated;
grant execute on function dispatch.driver_send_position(
  uuid, numeric, numeric, timestamptz, numeric, numeric, integer) to authenticated;
grant execute on function dispatch.driver_attach_pod(
  uuid, uuid, dispatch.trip_pod_kind) to authenticated;

grant execute on function dispatch.admin_list_driver_trip_statuses(
  uuid, dispatch.trip_execution_status, int, int) to authenticated;
grant execute on function dispatch.admin_get_driver_trip_detail(uuid) to authenticated;
grant execute on function dispatch.admin_ack_driver_issue(uuid) to authenticated;
grant execute on function dispatch.admin_resolve_driver_issue(uuid, text) to authenticated;
