-- CC-53 — Telematics carrier session status batch read RPC.
--
-- Adds a single SECURITY DEFINER read function that returns one row per
-- carrier-visible dispatch summarizing its telemetry session state, latest
-- position, latest event, position/event counts, and a derived
-- freshness label. The function is intended to replace per-dispatch
-- snapshot fan-out from the driver trips list (CC-50) — the frontend can
-- show telemetry health for many trips in a single round trip.
--
-- Boundaries (CC-53):
--   * Read-only — no mutation of sessions, positions, events, shipments,
--     dispatches, or marketplace rows.
--   * Carrier-scoped — identity.current_organization_id() must match the
--     dispatch's carrier_organization_id, unless caller is platform admin.
--   * Buyer / supplier callers are not granted — same posture as other
--     carrier_* RPCs in the CC-45 telematics foundation.
--   * No buyer/admin convenience overload introduced. If admins need a
--     cross-tenant batch later, it should ship in a separate audience
--     RPC behind identity.is_platform_admin().

-- ===========================================================================
-- 1. carrier_list_my_telemetry_session_statuses
-- ===========================================================================
create or replace function telematics.carrier_list_my_telemetry_session_statuses(
  p_dispatch_ids       uuid[]   default null,
  p_limit              integer  default 100,
  p_offset             integer  default 0,
  p_freshness_interval interval default interval '15 minutes'
) returns table (
  dispatch_id                uuid,
  shipment_id                uuid,
  session_active             boolean,
  latest_session_id          uuid,
  latest_session_started_at  timestamptz,
  latest_session_ended_at    timestamptz,
  last_position_at           timestamptz,
  last_latitude              numeric,
  last_longitude             numeric,
  last_accuracy_meters       numeric,
  last_source                text,
  last_event_type            text,
  last_event_at              timestamptz,
  position_count             bigint,
  event_count                bigint,
  staleness_status           text
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
declare
  v_caller_org        uuid    := identity.current_organization_id();
  v_is_platform_admin boolean := identity.is_platform_admin();
  v_freshness         interval := coalesce(p_freshness_interval, interval '15 minutes');
begin
  if not v_is_platform_admin then
    if not (identity.has_role('organization_admin') or identity.has_role('carrier_admin')) then
      raise exception 'telematics: requires carrier_admin / organization_admin / platform_admin'
        using errcode = '42501';
    end if;
    if v_caller_org is null then
      raise exception 'telematics: caller has no organization context'
        using errcode = '42501';
    end if;
  end if;

  return query
    with
      visible_dispatches as (
        select da.id,
               da.carrier_organization_id,
               br.shipment_id
          from dispatch.dispatch_assignments da
          left join marketplace.booking_requests br
                 on br.id = da.booking_request_id
                and br.deleted_at is null
         where da.deleted_at is null
           and (
             v_is_platform_admin
             or da.carrier_organization_id = v_caller_org
           )
           and (
             p_dispatch_ids is null
             or da.id = any(p_dispatch_ids)
           )
      ),
      latest_session_gate as (
        -- Latest session-scoped event per dispatch; used to infer
        -- session_active = (latest is session_started).
        select e.dispatch_id,
               e.event_type,
               e.created_at,
               row_number() over (
                 partition by e.dispatch_id
                 order by e.created_at desc
               ) as rn
          from telematics.telemetry_events e
         where e.event_type in ('session_started', 'session_ended')
      ),
      latest_session_started as (
        select e.dispatch_id,
               e.id   as event_id,
               e.created_at,
               row_number() over (
                 partition by e.dispatch_id
                 order by e.created_at desc
               ) as rn
          from telematics.telemetry_events e
         where e.event_type = 'session_started'
      ),
      latest_session_ended as (
        select e.dispatch_id,
               e.id   as event_id,
               e.created_at,
               row_number() over (
                 partition by e.dispatch_id
                 order by e.created_at desc
               ) as rn
          from telematics.telemetry_events e
         where e.event_type = 'session_ended'
      ),
      latest_position as (
        select pr.dispatch_id,
               pr.reported_at,
               pr.latitude,
               pr.longitude,
               pr.accuracy_meters,
               pr.source,
               row_number() over (
                 partition by pr.dispatch_id
                 order by pr.reported_at desc
               ) as rn
          from telematics.position_reports pr
      ),
      latest_any_event as (
        select e.dispatch_id,
               e.event_type::text as event_type,
               e.created_at,
               row_number() over (
                 partition by e.dispatch_id
                 order by e.created_at desc
               ) as rn
          from telematics.telemetry_events e
      ),
      counts as (
        select vd.id as dispatch_id,
               coalesce((
                 select count(*)
                   from telematics.position_reports pr
                  where pr.dispatch_id = vd.id
               ), 0)::bigint as position_count,
               coalesce((
                 select count(*)
                   from telematics.telemetry_events e
                  where e.dispatch_id = vd.id
               ), 0)::bigint as event_count
          from visible_dispatches vd
      )
    select
      vd.id                                       as dispatch_id,
      vd.shipment_id                              as shipment_id,
      coalesce(lsg.event_type = 'session_started', false) as session_active,
      lss.event_id                                as latest_session_id,
      lss.created_at                              as latest_session_started_at,
      lse.created_at                              as latest_session_ended_at,
      lp.reported_at                              as last_position_at,
      lp.latitude                                 as last_latitude,
      lp.longitude                                as last_longitude,
      lp.accuracy_meters                          as last_accuracy_meters,
      lp.source                                   as last_source,
      lae.event_type                              as last_event_type,
      lae.created_at                              as last_event_at,
      c.position_count                            as position_count,
      c.event_count                               as event_count,
      case
        when lp.reported_at is null                          then 'missing'
        when lp.reported_at >= now() - v_freshness           then 'fresh'
        else                                                      'stale'
      end                                         as staleness_status
      from visible_dispatches vd
      left join latest_session_gate    lsg on lsg.dispatch_id = vd.id and lsg.rn = 1
      left join latest_session_started lss on lss.dispatch_id = vd.id and lss.rn = 1
      left join latest_session_ended   lse on lse.dispatch_id = vd.id and lse.rn = 1
      left join latest_position        lp  on lp.dispatch_id  = vd.id and lp.rn = 1
      left join latest_any_event       lae on lae.dispatch_id = vd.id and lae.rn = 1
      left join counts                 c   on c.dispatch_id   = vd.id
     order by lae.created_at desc nulls last, vd.id
     limit p_limit offset p_offset;
end;
$$;

comment on function telematics.carrier_list_my_telemetry_session_statuses(
  uuid[], integer, integer, interval
) is
  'CC-53: batch read of telemetry session status for the caller carrier organization. '
  'Returns one row per visible dispatch with the latest session state (started/ended), '
  'the latest reported position summary, the latest event of any type, total counts, '
  'and a derived staleness label (missing / fresh / stale) against p_freshness_interval. '
  'Carrier-scoped — same authorization posture as other carrier_* telematics RPCs.';

-- ===========================================================================
-- 2. Grant
-- ===========================================================================
grant execute on function telematics.carrier_list_my_telemetry_session_statuses(
  uuid[], integer, integer, interval
) to authenticated;
