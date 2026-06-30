-- CC-47 Test 170 — Driver app grants + RLS posture.
--
-- Assertions (18):
--   1-3.   RLS enabled on the 3 new tables
--   4-6.   authenticated has SELECT on the 3 new tables
--   7-15.  authenticated has NO INSERT/UPDATE/DELETE on the 3 new tables
--   16-18. authenticated has EXECUTE on representative driver/admin RPCs

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

select plan(18);

-- 1-3. RLS enabled
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'dispatch' and c.relname = 'driver_trip_events'),
          'RLS enabled on driver_trip_events');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'dispatch' and c.relname = 'driver_trip_issues'),
          'RLS enabled on driver_trip_issues');
select ok((select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
            where n.nspname = 'dispatch' and c.relname = 'driver_trip_pods'),
          'RLS enabled on driver_trip_pods');

-- 4-6. SELECT granted
select ok(has_table_privilege('authenticated', 'dispatch.driver_trip_events', 'SELECT'),
          'authenticated can SELECT driver_trip_events');
select ok(has_table_privilege('authenticated', 'dispatch.driver_trip_issues', 'SELECT'),
          'authenticated can SELECT driver_trip_issues');
select ok(has_table_privilege('authenticated', 'dispatch.driver_trip_pods', 'SELECT'),
          'authenticated can SELECT driver_trip_pods');

-- 7-15. no write grants
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_events', 'INSERT'),
          'authenticated cannot INSERT driver_trip_events');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_events', 'UPDATE'),
          'authenticated cannot UPDATE driver_trip_events');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_events', 'DELETE'),
          'authenticated cannot DELETE driver_trip_events');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_issues', 'INSERT'),
          'authenticated cannot INSERT driver_trip_issues');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_issues', 'UPDATE'),
          'authenticated cannot UPDATE driver_trip_issues');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_issues', 'DELETE'),
          'authenticated cannot DELETE driver_trip_issues');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_pods', 'INSERT'),
          'authenticated cannot INSERT driver_trip_pods');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_pods', 'UPDATE'),
          'authenticated cannot UPDATE driver_trip_pods');
select ok(not has_table_privilege('authenticated', 'dispatch.driver_trip_pods', 'DELETE'),
          'authenticated cannot DELETE driver_trip_pods');

-- 16-18. EXECUTE on RPCs
select ok(has_function_privilege('authenticated',
            'dispatch.driver_accept_trip(uuid)', 'EXECUTE'),
          'authenticated can EXECUTE driver_accept_trip');
select ok(has_function_privilege('authenticated',
            'dispatch.driver_send_position(uuid, numeric, numeric, timestamptz, numeric, numeric, integer)', 'EXECUTE'),
          'authenticated can EXECUTE driver_send_position');
select ok(has_function_privilege('authenticated',
            'dispatch.admin_ack_driver_issue(uuid)', 'EXECUTE'),
          'authenticated can EXECUTE admin_ack_driver_issue');

select * from finish();
rollback;
