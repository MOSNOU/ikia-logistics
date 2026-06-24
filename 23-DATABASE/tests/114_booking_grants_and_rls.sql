-- CC-42 Test 114 — Booking grants, RLS, RPC metadata.
--
-- Assertions (9):
--   1. RLS enabled on booking_requests
--   2. RLS enabled on booking_events
--   3. 0 direct INSERT/UPDATE/DELETE grants on the new booking tables
--   4. every booking RPC is SECURITY DEFINER
--   5. every booking RPC has search_path = ''
--   6. all 5 buyer booking RPCs have EXECUTE granted to authenticated
--   7. all 4 carrier booking RPCs have EXECUTE granted to authenticated
--   8. all 3 admin booking RPCs have EXECUTE granted to authenticated
--   9. SELECT granted to authenticated on both booking tables

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

select plan(9);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='marketplace' and c.relname='booking_requests'),
  true, 'booking_requests has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='marketplace' and c.relname='booking_events'),
  true, 'booking_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='marketplace'
      and table_name in ('booking_requests', 'booking_events')
      and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on booking tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and (p.proname like 'buyer_%booking%' or p.proname like 'carrier_%booking%' or p.proname like 'admin_%booking%')
      and not p.prosecdef),
  0, 'every booking audience RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and (p.proname like 'buyer_%booking%' or p.proname like 'carrier_%booking%' or p.proname like 'admin_%booking%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every booking audience RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and p.proname in (
        'buyer_create_booking_request', 'buyer_list_my_bookings',
        'buyer_get_booking', 'buyer_confirm_booking', 'buyer_cancel_booking'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  5, 'all 5 buyer booking RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and p.proname in (
        'carrier_list_booking_requests', 'carrier_get_booking',
        'carrier_accept_booking', 'carrier_reject_booking'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  4, 'all 4 carrier booking RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and p.proname in (
        'admin_list_bookings', 'admin_get_booking', 'admin_cancel_booking'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  3, 'all 3 admin booking RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='marketplace'
      and table_name in ('booking_requests', 'booking_events')
      and grantee = 'authenticated'
      and privilege_type = 'SELECT'),
  2, 'SELECT granted to authenticated on both booking tables');

select * from finish();
rollback;
