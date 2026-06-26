-- CC-73 — Portal dashboard summary RPCs.
--
-- Adds three narrow SECURITY DEFINER read-only RPCs that produce the
-- jsonb summary documents consumed by /buyer/dashboard,
-- /supplier/dashboard and /carrier/dashboard. Each function:
--   • derives the caller's scope internally — there are no
--     user-controlled org_id / supplier_id / user_id parameters,
--   • returns a graceful "no scope" jsonb when the caller has no
--     applicable membership (e.g. a buyer-only user hitting the
--     carrier dashboard — they would not have a carrier org context),
--   • exposes only counts and a tiny recent-activity tail (≤ 5 rows),
--   • bypasses RLS only for the specific aggregations it needs,
--   • is callable only by the `authenticated` role.
--
-- Additive only. No table, RLS or grant change outside the new
-- functions themselves.

begin;

-- =====================================================================
-- 1. marketplace.buyer_get_dashboard_summary()
-- =====================================================================
create or replace function marketplace.buyer_get_dashboard_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org                  uuid := identity.current_organization_id();
  v_active_rfqs          int  := 0;
  v_open_bookings        int  := 0;
  v_active_shipments     int  := 0;
  v_active_contracts     int  := 0;
  v_recent_bookings      jsonb := '[]'::jsonb;
begin
  if v_org is null then
    return jsonb_build_object(
      'scope',              'no_org_context',
      'activeRfqs',         0,
      'openBookings',       0,
      'activeShipments',    0,
      'activeContracts',    0,
      'recentBookings',     '[]'::jsonb
    );
  end if;

  select count(*)::int into v_active_rfqs
    from rfq.requests
   where organization_id = v_org
     and deleted_at is null
     and status not in ('cancelled', 'closed', 'expired');

  -- marketplace.booking_status: draft / pending_carrier / carrier_accepted
  -- / carrier_rejected / buyer_confirmed / buyer_cancelled / expired
  select count(*)::int into v_open_bookings
    from marketplace.booking_requests
   where buyer_organization_id = v_org
     and status not in ('buyer_cancelled', 'carrier_rejected', 'expired');

  select count(*)::int into v_active_shipments
    from shipment.shipments
   where organization_id = v_org
     and deleted_at is null
     and status in ('planned', 'booked', 'in_transit', 'arrived');

  select count(*)::int into v_active_contracts
    from contract.executed_contracts
   where organization_id = v_org
     and deleted_at is null;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
    into v_recent_bookings
    from (
      select b.id,
             b.status,
             b.created_at
        from marketplace.booking_requests b
       where b.buyer_organization_id = v_org
       order by b.created_at desc
       limit 5
    ) t;

  return jsonb_build_object(
    'scope',              'org',
    'activeRfqs',         v_active_rfqs,
    'openBookings',       v_open_bookings,
    'activeShipments',    v_active_shipments,
    'activeContracts',    v_active_contracts,
    'recentBookings',     v_recent_bookings
  );
end;
$$;

comment on function marketplace.buyer_get_dashboard_summary() is
  'CC-73: buyer-portal summary jsonb scoped to identity.current_organization_id(). Returns counts + recent bookings, or zeroes and scope="no_org_context" when the caller has no buyer org.';

revoke all   on function marketplace.buyer_get_dashboard_summary() from public;
revoke all   on function marketplace.buyer_get_dashboard_summary() from anon;
grant execute on function marketplace.buyer_get_dashboard_summary() to authenticated;

-- =====================================================================
-- 2. supplier.portal_get_dashboard_summary()
-- =====================================================================
create or replace function supplier.portal_get_dashboard_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_supplier         uuid;
  v_active_offers    int  := 0;
  v_active_contracts int  := 0;
  v_active_shipments int  := 0;
  v_addressable_rfqs int  := 0;
  v_recent_offers    jsonb := '[]'::jsonb;
begin
  -- supplier.fn_portal_supplier_id() raises when the caller has no
  -- supplier_admin / organization_admin / platform_admin role. The
  -- dashboard is called by any authenticated user, so we treat that
  -- "no scope" outcome as an empty summary rather than a hard error.
  begin
    v_supplier := supplier.fn_portal_supplier_id();
  exception when others then
    v_supplier := null;
  end;

  if v_supplier is null then
    return jsonb_build_object(
      'scope',             'no_supplier_context',
      'activeOffers',      0,
      'activeContracts',   0,
      'activeShipments',   0,
      'addressableRfqs',   0,
      'recentOffers',      '[]'::jsonb
    );
  end if;

  -- offers I've submitted that are still live
  select count(*)::int into v_active_offers
    from offer.supplier_offers
   where supplier_id = v_supplier
     and status not in ('withdrawn', 'rejected', 'expired');

  -- executed contracts I'm the supplier on
  select count(*)::int into v_active_contracts
    from contract.executed_contracts
   where supplier_id = v_supplier
     and deleted_at is null;

  -- shipments where I'm the supplier and the cargo is in motion
  select count(*)::int into v_active_shipments
    from shipment.shipments
   where supplier_id = v_supplier
     and deleted_at is null
     and status in ('planned', 'booked', 'in_transit', 'arrived');

  -- RFQs I've already touched (have an offer on) — a safe proxy for
  -- "addressable" demand without reaching into rfq-invitation tables.
  select count(distinct request_id)::int into v_addressable_rfqs
    from offer.supplier_offers
   where supplier_id = v_supplier;

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
    into v_recent_offers
    from (
      select o.id,
             o.offer_code,
             o.status,
             o.created_at
        from offer.supplier_offers o
       where o.supplier_id = v_supplier
       order by o.created_at desc
       limit 5
    ) t;

  return jsonb_build_object(
    'scope',            'supplier',
    'activeOffers',     v_active_offers,
    'activeContracts',  v_active_contracts,
    'activeShipments',  v_active_shipments,
    'addressableRfqs',  v_addressable_rfqs,
    'recentOffers',     v_recent_offers
  );
end;
$$;

comment on function supplier.portal_get_dashboard_summary() is
  'CC-73: supplier-portal summary jsonb scoped to supplier.fn_portal_supplier_id(). Returns counts + recent offers, or zeroes and scope="no_supplier_context" when the caller has no supplier identity.';

revoke all   on function supplier.portal_get_dashboard_summary() from public;
revoke all   on function supplier.portal_get_dashboard_summary() from anon;
grant execute on function supplier.portal_get_dashboard_summary() to authenticated;

-- =====================================================================
-- 3. marketplace.carrier_get_dashboard_summary()
-- =====================================================================
create or replace function marketplace.carrier_get_dashboard_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org                  uuid := identity.current_organization_id();
  v_open_bookings        int  := 0;
  v_active_dispatches    int  := 0;
  v_in_transit_shipments int  := 0;
  v_active_capacity      int  := 0;
  v_recent_dispatches    jsonb := '[]'::jsonb;
begin
  if v_org is null then
    return jsonb_build_object(
      'scope',               'no_org_context',
      'openBookings',        0,
      'activeDispatches',    0,
      'inTransitShipments',  0,
      'activeCapacity',      0,
      'recentDispatches',    '[]'::jsonb
    );
  end if;

  select count(*)::int into v_open_bookings
    from marketplace.booking_requests
   where carrier_organization_id = v_org
     and status not in ('buyer_cancelled', 'carrier_rejected', 'expired');

  select count(*)::int into v_active_dispatches
    from dispatch.dispatch_assignments
   where carrier_organization_id = v_org
     and deleted_at is null
     and status not in ('cancelled', 'released');

  select count(*)::int into v_in_transit_shipments
    from shipment.shipments
   where carrier_organization_id = v_org
     and deleted_at is null
     and status = 'in_transit';

  select count(*)::int into v_active_capacity
    from marketplace.capacity_listings
   where carrier_organization_id = v_org
     and status = 'active';

  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb)
    into v_recent_dispatches
    from (
      select d.id,
             d.status,
             d.created_at
        from dispatch.dispatch_assignments d
       where d.carrier_organization_id = v_org
         and d.deleted_at is null
       order by d.created_at desc
       limit 5
    ) t;

  return jsonb_build_object(
    'scope',               'org',
    'openBookings',        v_open_bookings,
    'activeDispatches',    v_active_dispatches,
    'inTransitShipments',  v_in_transit_shipments,
    'activeCapacity',      v_active_capacity,
    'recentDispatches',    v_recent_dispatches
  );
end;
$$;

comment on function marketplace.carrier_get_dashboard_summary() is
  'CC-73: carrier-portal summary jsonb scoped to identity.current_organization_id(). Returns counts + recent dispatches, or zeroes and scope="no_org_context" when the caller has no carrier org.';

revoke all   on function marketplace.carrier_get_dashboard_summary() from public;
revoke all   on function marketplace.carrier_get_dashboard_summary() from anon;
grant execute on function marketplace.carrier_get_dashboard_summary() to authenticated;

commit;
