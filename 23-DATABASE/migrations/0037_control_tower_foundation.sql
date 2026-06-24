-- CC-44 / Migration 0037 — Operational Control Tower Foundation.
-- Append-only over 0001–0036. READ-ONLY aggregation layer over existing
-- shipment / booking / dispatch / settlement / dispute state. Control Tower
-- observes — it does NOT mutate shipments, bookings, dispatches, marketplace,
-- finance, settlement, or contract.
--
-- Locked decisions (Q1–Q10 = A):
--   Q1 = no new schema; RPCs live in `public` with control_tower_ prefix
--   Q2 = compute on demand (no persistence)
--   Q3 = buyer + carrier + admin audiences (5 routes total)
--   Q4 = derived exception rows (no acknowledge / resolve / assignment)
--   Q5 = admin activity is a union over existing event ledgers
--   Q6 = no audit emission (read-only)
--   Q7 = no notify dispatch (read-only)
--   Q8 = SECURITY DEFINER with explicit role gates
--   Q9 = no GPS / telematics / ETA / route optimization / maps / AI / ML
--   Q10 = stop after validation report
--
-- Boundaries respected: this migration creates NO new schema, NO new tables,
-- NO new enums. It writes nothing — every RPC is `language plpgsql stable`.
-- All RPCs live in `public` to avoid introducing a control_tower schema (Q1).

-- ===========================================================================
-- 1. Buyer summary
-- ===========================================================================
-- Returns a jsonb KPI bundle scoped to the caller's buyer organization.
-- Counts shipments / bookings / dispatches in active or recent states.
create or replace function public.control_tower_buyer_summary()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_active_shipments int := 0;
  v_pending_bookings int := 0;
  v_confirmed_bookings int := 0;
  v_active_dispatches int := 0;
  v_ready_dispatches int := 0;
  v_recent_cancellations int := 0;
begin
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
      raise exception 'control_tower: requires buyer_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'control_tower: no active organization in JWT' using errcode = 'P0002';
    end if;
  end if;

  select count(*) into v_active_shipments
    from shipment.shipments
   where deleted_at is null
     and status in ('planned', 'booked', 'in_transit', 'arrived')
     and (identity.is_platform_admin() or organization_id = v_caller_org);

  select count(*) into v_pending_bookings
    from marketplace.booking_requests
   where deleted_at is null
     and status in ('pending_carrier', 'carrier_accepted')
     and (identity.is_platform_admin() or buyer_organization_id = v_caller_org);

  select count(*) into v_confirmed_bookings
    from marketplace.booking_requests
   where deleted_at is null
     and status = 'buyer_confirmed'
     and (identity.is_platform_admin() or buyer_organization_id = v_caller_org);

  select count(*) into v_active_dispatches
    from dispatch.dispatch_assignments
   where deleted_at is null
     and status in ('draft', 'assigned', 'ready')
     and (identity.is_platform_admin() or buyer_organization_id = v_caller_org);

  select count(*) into v_ready_dispatches
    from dispatch.dispatch_assignments
   where deleted_at is null
     and status = 'ready'
     and (identity.is_platform_admin() or buyer_organization_id = v_caller_org);

  select count(*) into v_recent_cancellations
    from marketplace.booking_requests
   where deleted_at is null
     and status = 'buyer_cancelled'
     and updated_at > now() - interval '7 days'
     and (identity.is_platform_admin() or buyer_organization_id = v_caller_org);

  return jsonb_build_object(
    'audience', 'buyer',
    'organization_id', v_caller_org,
    'active_shipments', v_active_shipments,
    'pending_bookings', v_pending_bookings,
    'confirmed_bookings', v_confirmed_bookings,
    'active_dispatches', v_active_dispatches,
    'ready_dispatches', v_ready_dispatches,
    'recent_cancellations', v_recent_cancellations
  );
end;
$$;

grant execute on function public.control_tower_buyer_summary() to authenticated;

-- ===========================================================================
-- 2. Carrier summary
-- ===========================================================================
create or replace function public.control_tower_carrier_summary()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_incoming_pending int := 0;
  v_accepted_bookings int := 0;
  v_active_dispatches int := 0;
  v_ready_dispatches int := 0;
  v_released_recently int := 0;
  v_rejected_recently int := 0;
begin
  if not identity.is_platform_admin() then
    if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
      raise exception 'control_tower: requires carrier_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'control_tower: no active organization in JWT' using errcode = 'P0002';
    end if;
  end if;

  select count(*) into v_incoming_pending
    from marketplace.booking_requests
   where deleted_at is null
     and status = 'pending_carrier'
     and (identity.is_platform_admin() or carrier_organization_id = v_caller_org);

  select count(*) into v_accepted_bookings
    from marketplace.booking_requests
   where deleted_at is null
     and status in ('carrier_accepted', 'buyer_confirmed')
     and (identity.is_platform_admin() or carrier_organization_id = v_caller_org);

  select count(*) into v_active_dispatches
    from dispatch.dispatch_assignments
   where deleted_at is null
     and status in ('draft', 'assigned', 'ready')
     and (identity.is_platform_admin() or carrier_organization_id = v_caller_org);

  select count(*) into v_ready_dispatches
    from dispatch.dispatch_assignments
   where deleted_at is null
     and status = 'ready'
     and (identity.is_platform_admin() or carrier_organization_id = v_caller_org);

  select count(*) into v_released_recently
    from dispatch.dispatch_assignments
   where deleted_at is null
     and status = 'released'
     and released_at > now() - interval '7 days'
     and (identity.is_platform_admin() or carrier_organization_id = v_caller_org);

  select count(*) into v_rejected_recently
    from marketplace.booking_requests
   where deleted_at is null
     and status = 'carrier_rejected'
     and updated_at > now() - interval '7 days'
     and (identity.is_platform_admin() or carrier_organization_id = v_caller_org);

  return jsonb_build_object(
    'audience', 'carrier',
    'organization_id', v_caller_org,
    'incoming_pending', v_incoming_pending,
    'accepted_bookings', v_accepted_bookings,
    'active_dispatches', v_active_dispatches,
    'ready_dispatches', v_ready_dispatches,
    'released_recently', v_released_recently,
    'rejected_recently', v_rejected_recently
  );
end;
$$;

grant execute on function public.control_tower_carrier_summary() to authenticated;

-- ===========================================================================
-- 3. Admin summary
-- ===========================================================================
-- Platform-wide aggregation. Reports cross-tenant counts; admin only.
create or replace function public.control_tower_admin_summary()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_active_shipments int := 0;
  v_pending_bookings int := 0;
  v_confirmed_bookings int := 0;
  v_active_dispatches int := 0;
  v_disputed_settlements int := 0;
  v_open_disputes int := 0;
  v_exception_count int := 0;
begin
  if not identity.is_platform_admin() then
    raise exception 'control_tower.admin_summary: requires platform_admin'
      using errcode = '42501';
  end if;

  select count(*) into v_active_shipments
    from shipment.shipments where deleted_at is null
     and status in ('planned', 'booked', 'in_transit', 'arrived');

  select count(*) into v_pending_bookings
    from marketplace.booking_requests where deleted_at is null
     and status in ('pending_carrier', 'carrier_accepted');

  select count(*) into v_confirmed_bookings
    from marketplace.booking_requests where deleted_at is null
     and status = 'buyer_confirmed';

  select count(*) into v_active_dispatches
    from dispatch.dispatch_assignments where deleted_at is null
     and status in ('draft', 'assigned', 'ready');

  select count(*) into v_disputed_settlements
    from settlement.settlements where deleted_at is null
     and status = 'disputed';

  select count(*) into v_open_disputes
    from dispute.disputes where deleted_at is null
     and status in ('opened', 'under_review');

  -- Exception count: derived from the same union the exceptions RPC returns.
  select count(*) into v_exception_count
    from public.control_tower_admin_exceptions(1000, 0);

  return jsonb_build_object(
    'audience', 'admin',
    'active_shipments', v_active_shipments,
    'pending_bookings', v_pending_bookings,
    'confirmed_bookings', v_confirmed_bookings,
    'active_dispatches', v_active_dispatches,
    'disputed_settlements', v_disputed_settlements,
    'open_disputes', v_open_disputes,
    'exception_count', v_exception_count
  );
end;
$$;

-- ===========================================================================
-- 4. Admin activity ledger (cross-domain event union)
-- ===========================================================================
-- Reads from existing immutable event ledgers (booking, dispatch, settlement,
-- shipment) and returns a unified, time-ordered projection. Admin only.
create or replace function public.control_tower_admin_activity(
  p_limit  integer default 50,
  p_offset integer default 0
) returns table (
  event_id        uuid,
  source_domain   text,
  source_event    text,
  subject_id      uuid,
  from_status     text,
  to_status       text,
  actor_party     text,
  organization_id uuid,
  created_at      timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  if not identity.is_platform_admin() then
    raise exception 'control_tower.admin_activity: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    select b.id, 'booking'::text, b.event_type,
           b.booking_request_id,
           b.from_status::text, b.to_status::text,
           b.actor_party, b.actor_organization_id, b.created_at
      from marketplace.booking_events b
    union all
    select d.id, 'dispatch'::text, d.event_type,
           d.dispatch_id,
           d.from_status::text, d.to_status::text,
           d.actor_party, d.actor_organization_id, d.created_at
      from dispatch.dispatch_events d
    union all
    select s.id, 'settlement'::text, s.event_type,
           s.settlement_id,
           s.from_status::text, s.to_status::text,
           'system'::text, s.organization_id, s.created_at
      from settlement.settlement_events s
    union all
    select sh.id, 'shipment'::text, coalesce(sh.event_type, sh.to_status::text),
           sh.shipment_id,
           sh.from_status::text, sh.to_status::text,
           'system'::text, sh.organization_id, sh.created_at
      from shipment.shipment_events sh
    order by created_at desc
    limit p_limit offset p_offset;
end;
$$;

grant execute on function public.control_tower_admin_activity(integer, integer) to authenticated;

-- ===========================================================================
-- 5. Admin exceptions (derived projection — no persistence)
-- ===========================================================================
-- Aggregates derived exception rows across five categories. No acknowledge
-- / resolve / assignment / escalation surface (Q4).
create or replace function public.control_tower_admin_exceptions(
  p_limit  integer default 100,
  p_offset integer default 0
) returns table (
  category        text,
  subject_type    text,
  subject_id      uuid,
  subject_code    text,
  organization_id uuid,
  severity        text,
  age_hours       numeric,
  detail_href     text,
  created_at      timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  if not identity.is_platform_admin() then
    raise exception 'control_tower.admin_exceptions: requires platform_admin'
      using errcode = '42501';
  end if;
  return query
    -- (A) Bookings stuck in pending_carrier > 24h.
    select 'booking_stale_pending'::text,
           'booking_request'::text,
           br.id,
           br.id::text,
           br.buyer_organization_id,
           'warning'::text,
           extract(epoch from (now() - br.created_at)) / 3600.0,
           '/admin/bookings/' || br.id::text,
           br.created_at
      from marketplace.booking_requests br
     where br.deleted_at is null
       and br.status = 'pending_carrier'
       and br.created_at < now() - interval '24 hours'
    union all
    -- (B) Dispatches stuck in draft > 24h.
    select 'dispatch_stale_draft'::text,
           'dispatch_assignment'::text,
           da.id,
           da.id::text,
           da.carrier_organization_id,
           'warning'::text,
           extract(epoch from (now() - da.created_at)) / 3600.0,
           '/admin/dispatches/' || da.id::text,
           da.created_at
      from dispatch.dispatch_assignments da
     where da.deleted_at is null
       and da.status = 'draft'
       and da.created_at < now() - interval '24 hours'
    union all
    -- (C) Disputed settlements.
    select 'settlement_disputed'::text,
           'settlement'::text,
           s.id,
           s.settlement_code,
           s.organization_id,
           'danger'::text,
           extract(epoch from (now() - s.updated_at)) / 3600.0,
           '/admin/settlements/' || s.id::text,
           s.updated_at
      from settlement.settlements s
     where s.deleted_at is null
       and s.status = 'disputed'
    union all
    -- (D) Open disputes.
    select 'dispute_open'::text,
           'dispute'::text,
           d.id,
           d.dispute_code,
           d.organization_id,
           'danger'::text,
           extract(epoch from (now() - d.opened_at)) / 3600.0,
           '/admin/disputes/' || d.id::text,
           d.opened_at
      from dispute.disputes d
     where d.deleted_at is null
       and d.status in ('opened', 'under_review')
    union all
    -- (E) Shipments planned with no matching booking request.
    select 'shipment_planned_no_booking'::text,
           'shipment'::text,
           sh.id,
           sh.shipment_code,
           sh.organization_id,
           'info'::text,
           extract(epoch from (now() - sh.created_at)) / 3600.0,
           '/admin/shipments/' || sh.id::text,
           sh.created_at
      from shipment.shipments sh
     where sh.deleted_at is null
       and sh.status = 'planned'
       and not exists (
         select 1 from marketplace.booking_requests br
          where br.shipment_id = sh.id and br.deleted_at is null
       )
    order by created_at desc
    limit p_limit offset p_offset;
end;
$$;

grant execute on function public.control_tower_admin_exceptions(integer, integer) to authenticated;

-- Now that the exceptions RPC is defined, the admin_summary that depends on
-- it can be granted.
grant execute on function public.control_tower_admin_summary() to authenticated;
