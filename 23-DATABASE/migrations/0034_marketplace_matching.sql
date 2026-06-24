-- CC-41 / Migration 0034 — Carrier Matching & Capacity Discovery Engine
-- Foundation. Append-only over 0001–0033. Adds advisory matching RPCs under
-- the existing `marketplace` schema. No new tables (Q6=A). No new enums.
-- No shipment / contract / pricing / dispatch mutations.
--
-- Locked decisions (Q1–Q10, all default A):
--   Q1 = RPC-only matching (no persistence)
--   Q2 = compute on demand (no stored results)
--   Q3 = buyer + admin frontend
--   Q4 = supplier visibility = none
--   Q5 = fixed weights (35 / 20 / 20 / 15 / 5 / 5 = 100)
--   Q6 = no audit table
--   Q7 = summary metrics only
--   Q8 = active capacity only
--   Q9 = carriers ranked by best matching active capacity + profile
--   Q10 = stop after validation report
--
-- Out of scope (literal): booking, dispatch, assignment, capacity reservation,
-- carrier acceptance workflow, pricing, quotation, payment, GPS, ETA
-- prediction, AI/ML, route optimization. Frontend wiring lives outside the
-- DB layer (loaders + 3 routes).
--
-- Security model: SECURITY DEFINER, search_path = ''. The matching RPCs
-- bypass RLS by virtue of being security_definer, so they perform an
-- explicit visibility check via fn_assert_can_view_shipment.

-- ===========================================================================
-- 1. Visibility helper (shipment access gate for matching callers)
-- ===========================================================================

-- Buyer + admin gate. Suppliers are denied (Q4=A). Mirrors the role gate used
-- by shipment.fn_assert_shipment_owned but explicitly enforces the no-supplier
-- rule for matching.
create or replace function marketplace.fn_assert_can_view_shipment(p_shipment_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_org from shipment.shipments
   where id = p_shipment_id and deleted_at is null;
  if v_org is null then
    raise exception 'marketplace: shipment not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('organization_admin') or identity.has_role('buyer_admin')) then
    raise exception 'marketplace: matching requires buyer_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'marketplace: shipment not visible to caller organization'
      using errcode = '42501';
  end if;
end;
$$;

-- ===========================================================================
-- 2. Scoring helpers
-- ===========================================================================

-- 2.1 Profile completeness — 1 point per filled field, capped at 5.
--   Fields: display_name (fa OR en), bio (fa OR en), transport_modes non-empty,
--   service_country_codes non-empty, fleet_size_hint not null.
create or replace function marketplace.fn_profile_completeness(p_profile_id uuid)
returns integer
language plpgsql stable security definer set search_path = ''
as $$
declare
  v integer := 0;
  cp marketplace.carrier_profiles%rowtype;
begin
  select * into cp from marketplace.carrier_profiles where id = p_profile_id and deleted_at is null;
  if cp.id is null then return 0; end if;
  if (cp.display_name_fa is not null and btrim(cp.display_name_fa) <> '')
     or (cp.display_name_en is not null and btrim(cp.display_name_en) <> '') then
    v := v + 1;
  end if;
  if (cp.bio_fa is not null and btrim(cp.bio_fa) <> '')
     or (cp.bio_en is not null and btrim(cp.bio_en) <> '') then
    v := v + 1;
  end if;
  if cp.transport_modes is not null and array_length(cp.transport_modes, 1) > 0 then
    v := v + 1;
  end if;
  if cp.service_country_codes is not null and array_length(cp.service_country_codes, 1) > 0 then
    v := v + 1;
  end if;
  if cp.fleet_size_hint is not null then
    v := v + 1;
  end if;
  return least(v, 5);
end;
$$;

-- 2.2 Score a single (shipment, capacity_listing) pair. Returns total + a
-- per-component jsonb breakdown.
create or replace function marketplace.fn_score_capacity_for_shipment(
  p_shipment_id uuid,
  p_listing_id  uuid
) returns table (
  score          integer,
  score_breakdown jsonb
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  s record;
  cl record;
  v_mode integer := 0;
  v_origin integer := 0;
  v_destination integer := 0;
  v_availability integer := 0;
  v_profile integer := 0;
  v_visibility integer := 0;
  v_total integer := 0;
  v_profile_id uuid;
  v_is_public boolean;
begin
  select id, organization_id, transport_mode,
         origin_country, origin_city,
         destination_country, destination_city,
         planned_pickup_date
    into s
    from shipment.shipments where id = p_shipment_id and deleted_at is null;
  if s.id is null then
    score := 0;
    score_breakdown := jsonb_build_object('total', 0, 'reason', 'shipment_not_found');
    return next;
    return;
  end if;

  select id, carrier_organization_id, transport_mode,
         origin_country_code, origin_city,
         destination_country_code, destination_city,
         valid_from, valid_until, status
    into cl
    from marketplace.capacity_listings where id = p_listing_id and deleted_at is null;
  if cl.id is null then
    score := 0;
    score_breakdown := jsonb_build_object('total', 0, 'reason', 'listing_not_found');
    return next;
    return;
  end if;

  -- Transport mode: 35 if equal, else 0.
  if s.transport_mode = cl.transport_mode then v_mode := 35; end if;

  -- Origin: 15 base on country match + 5 city refinement.
  -- city refinement awards when both cities are null (listing serves whole
  -- country) OR cities equal case-insensitively.
  if s.origin_country is not null and cl.origin_country_code is not null
     and lower(s.origin_country) = lower(cl.origin_country_code::text) then
    v_origin := 15;
    if (s.origin_city is null and cl.origin_city is null)
       or (s.origin_city is not null and cl.origin_city is not null
           and lower(s.origin_city) = lower(cl.origin_city)) then
      v_origin := v_origin + 5;
    end if;
  end if;

  -- Destination: same shape as origin.
  if s.destination_country is not null and cl.destination_country_code is not null
     and lower(s.destination_country) = lower(cl.destination_country_code::text) then
    v_destination := 15;
    if (s.destination_city is null and cl.destination_city is null)
       or (s.destination_city is not null and cl.destination_city is not null
           and lower(s.destination_city) = lower(cl.destination_city)) then
      v_destination := v_destination + 5;
    end if;
  end if;

  -- Availability window: 15 if planned_pickup_date is inside the listing
  -- window or the listing window is fully open; 7 if pickup date is unknown
  -- but the listing window exists; 0 if pickup date falls outside.
  if cl.valid_from is null and cl.valid_until is null then
    v_availability := 15;
  elsif s.planned_pickup_date is null then
    v_availability := 7;
  elsif (cl.valid_from is null or s.planned_pickup_date >= cl.valid_from)
        and (cl.valid_until is null or s.planned_pickup_date <= cl.valid_until) then
    v_availability := 15;
  end if;

  -- Profile completeness: 0..5.
  select cp.id into v_profile_id
    from marketplace.carrier_profiles cp
   where cp.organization_id = cl.carrier_organization_id and cp.deleted_at is null;
  if v_profile_id is not null then
    v_profile := marketplace.fn_profile_completeness(v_profile_id);
  end if;

  -- Directory visibility: 5 if is_public=true.
  select v.is_public into v_is_public
    from marketplace.carrier_directory_visibility v
   where v.carrier_organization_id = cl.carrier_organization_id;
  if coalesce(v_is_public, false) then v_visibility := 5; end if;

  v_total := v_mode + v_origin + v_destination + v_availability + v_profile + v_visibility;
  score := v_total;
  score_breakdown := jsonb_build_object(
    'transport_mode', v_mode,
    'origin', v_origin,
    'destination', v_destination,
    'availability', v_availability,
    'profile', v_profile,
    'visibility', v_visibility,
    'total', v_total
  );
  return next;
end;
$$;

-- ===========================================================================
-- 3. RPCs
-- ===========================================================================

-- 3.1 find_matching_capacity --------------------------------------------------
-- Returns ranked active capacity listings against a single shipment. Q8=A:
-- only `status='active'` listings are considered. Caller must be allowed to
-- view the shipment (buyer + admin).
create or replace function marketplace.find_matching_capacity(
  p_shipment_id uuid,
  p_limit       integer default 25
) returns table (
  capacity_listing_id     uuid,
  carrier_organization_id uuid,
  carrier_name            text,
  transport_mode          shipment.transport_mode,
  origin_country_code     citext,
  destination_country_code citext,
  valid_from              timestamptz,
  valid_until             timestamptz,
  score                   integer,
  score_breakdown         jsonb
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  perform marketplace.fn_assert_can_view_shipment(p_shipment_id);
  return query
    with scored as (
      select cl.id as listing_id,
             cl.carrier_organization_id,
             coalesce(o.name_fa, o.name_en, o.code::text) as carrier_name,
             cl.transport_mode,
             cl.origin_country_code,
             cl.destination_country_code,
             cl.valid_from,
             cl.valid_until,
             (sc.score) as score,
             (sc.score_breakdown) as score_breakdown
        from marketplace.capacity_listings cl
        join organization.organizations o on o.id = cl.carrier_organization_id
        cross join lateral marketplace.fn_score_capacity_for_shipment(p_shipment_id, cl.id) sc
       where cl.deleted_at is null
         and cl.status = 'active'
         and (cl.valid_until is null or cl.valid_until > now())
    )
    select listing_id, carrier_organization_id, carrier_name,
           transport_mode, origin_country_code, destination_country_code,
           valid_from, valid_until, score, score_breakdown
      from scored
     where score > 0
     order by score desc, listing_id asc
     limit p_limit;
end;
$$;

-- 3.2 find_matching_carriers --------------------------------------------------
-- Rank carriers by the best matching active capacity (Q9=A). Carriers with no
-- matching active capacity fall back to a profile + visibility score, capped
-- at 10, so they can still surface as low-confidence suggestions.
create or replace function marketplace.find_matching_carriers(
  p_shipment_id uuid,
  p_limit       integer default 25
) returns table (
  carrier_organization_id uuid,
  carrier_name            text,
  best_listing_id         uuid,
  score                   integer,
  score_breakdown         jsonb
)
language plpgsql stable security definer set search_path = ''
as $$
#variable_conflict use_column
begin
  perform marketplace.fn_assert_can_view_shipment(p_shipment_id);
  return query
    with ranked_listings as (
      select cl.carrier_organization_id,
             cl.id as listing_id,
             sc.score,
             sc.score_breakdown,
             row_number() over (
               partition by cl.carrier_organization_id
               order by sc.score desc, cl.id asc
             ) as rn
        from marketplace.capacity_listings cl
        cross join lateral marketplace.fn_score_capacity_for_shipment(p_shipment_id, cl.id) sc
       where cl.deleted_at is null
         and cl.status = 'active'
         and (cl.valid_until is null or cl.valid_until > now())
         and sc.score > 0
    ),
    best_per_carrier as (
      select carrier_organization_id, listing_id, score, score_breakdown
        from ranked_listings where rn = 1
    ),
    profile_fallback as (
      select cp.organization_id as carrier_organization_id,
             null::uuid as listing_id,
             least(
               marketplace.fn_profile_completeness(cp.id)
                 + case when coalesce(v.is_public, false) then 5 else 0 end,
               10
             ) as score,
             jsonb_build_object(
               'transport_mode', 0, 'origin', 0, 'destination', 0,
               'availability', 0,
               'profile', marketplace.fn_profile_completeness(cp.id),
               'visibility', case when coalesce(v.is_public, false) then 5 else 0 end,
               'total', least(
                 marketplace.fn_profile_completeness(cp.id)
                   + case when coalesce(v.is_public, false) then 5 else 0 end,
                 10
               ),
               'fallback', true
             ) as score_breakdown
        from marketplace.carrier_profiles cp
        left join marketplace.carrier_directory_visibility v
          on v.carrier_organization_id = cp.organization_id
       where cp.deleted_at is null
         and cp.status = 'active'
         and not exists (
           select 1 from best_per_carrier b
            where b.carrier_organization_id = cp.organization_id
         )
    ),
    combined as (
      select * from best_per_carrier
      union all
      select * from profile_fallback
    )
    select c.carrier_organization_id,
           coalesce(o.name_fa, o.name_en, o.code::text) as carrier_name,
           c.listing_id as best_listing_id,
           c.score,
           c.score_breakdown
      from combined c
      join organization.organizations o on o.id = c.carrier_organization_id
     where c.score > 0
     order by c.score desc, c.carrier_organization_id asc
     limit p_limit;
end;
$$;

-- 3.3 admin_matching_summary --------------------------------------------------
-- Q1=A + Q6=A → no persistence, so `total_match_requests` is interpreted as
-- the number of shipments eligible for matching today (the derived
-- candidate set the engine could score). `unmatched_shipments` counts how
-- many of those return zero ranked capacity. `top_carriers` aggregates the
-- single highest-score carrier for each eligible shipment.
--
-- To keep the summary affordable, eligibility is restricted to the most
-- recent 100 shipments in status planned/booked/in_transit. This is plenty
-- for an at-a-glance KPI and matches the at-a-glance UX in CC-41.
create or replace function marketplace.admin_matching_summary()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_total int := 0;
  v_unmatched int := 0;
  v_avg numeric := 0;
  v_top jsonb := '[]'::jsonb;
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_matching_summary: requires platform_admin'
      using errcode = '42501';
  end if;

  with eligible as (
    select s.id, s.organization_id
      from shipment.shipments s
     where s.deleted_at is null
       and s.status in ('planned', 'booked', 'in_transit')
     order by s.updated_at desc
     limit 100
  ),
  scored as (
    select e.id as shipment_id,
           (select cap.score
              from marketplace.find_matching_capacity(e.id, 1) cap
              limit 1) as top_score,
           (select cap.carrier_organization_id
              from marketplace.find_matching_capacity(e.id, 1) cap
              limit 1) as top_carrier
      from eligible e
  )
  select count(*),
         count(*) filter (where coalesce(top_score, 0) = 0),
         coalesce(round(avg(coalesce(top_score, 0)), 1), 0),
         (
           select coalesce(jsonb_agg(jsonb_build_object(
             'carrier_organization_id', tc.carrier_id,
             'matches', tc.matches
           )), '[]'::jsonb)
             from (
               select top_carrier as carrier_id, count(*) as matches
                 from scored
                where top_carrier is not null
                group by top_carrier
                order by count(*) desc
                limit 5
             ) tc
         )
    into v_total, v_unmatched, v_avg, v_top
    from scored;

  return jsonb_build_object(
    'total_match_requests', v_total,
    'average_score', v_avg,
    'unmatched_shipments', v_unmatched,
    'top_carriers', v_top,
    'eligibility_window', 'last 100 shipments in planned/booked/in_transit'
  );
end;
$$;

-- ===========================================================================
-- 4. RPC grants
-- ===========================================================================
grant execute on function marketplace.find_matching_capacity(uuid, integer) to authenticated;
grant execute on function marketplace.find_matching_carriers(uuid, integer) to authenticated;
grant execute on function marketplace.admin_matching_summary() to authenticated;
