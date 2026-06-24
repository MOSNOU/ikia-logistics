-- CC-45 Test 130 — Telematics grants, RLS, RPC metadata.
--
-- Assertions (9):
--   1. RLS enabled on position_reports
--   2. RLS enabled on telemetry_events
--   3. 0 direct INSERT/UPDATE/DELETE grants on telematics tables
--   4. every telematics audience RPC is SECURITY DEFINER
--   5. every telematics audience RPC has search_path = ''
--   6. all 8 carrier RPCs have EXECUTE granted to authenticated
--      (CC-45 set of 7 + the CC-53 batch session-status read RPC)
--   7. all 2 buyer RPCs have EXECUTE granted to authenticated
--   8. all 3 admin RPCs have EXECUTE granted to authenticated
--   9. SELECT granted to authenticated on both telematics tables

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

select plan(9);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='telematics' and c.relname='position_reports'),
  true, 'position_reports has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='telematics' and c.relname='telemetry_events'),
  true, 'telemetry_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='telematics'
      and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on telematics tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='telematics'
      and (p.proname like 'buyer_%' or p.proname like 'carrier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every telematics audience RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='telematics'
      and (p.proname like 'buyer_%' or p.proname like 'carrier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every telematics audience RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='telematics'
      and p.proname in (
        'carrier_start_telemetry_session', 'carrier_end_telemetry_session',
        'carrier_report_position', 'carrier_report_positions_batch',
        'carrier_report_telemetry_event', 'carrier_list_my_positions',
        'carrier_get_telemetry_snapshot',
        'carrier_list_my_telemetry_session_statuses'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  8, 'all 8 carrier telematics RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='telematics'
      and p.proname in ('buyer_list_positions', 'buyer_get_telemetry_snapshot')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  2, 'all 2 buyer telematics RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='telematics'
      and p.proname in ('admin_list_positions', 'admin_get_telemetry_snapshot', 'admin_list_active_sessions')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  3, 'all 3 admin telematics RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='telematics'
      and table_name in ('position_reports', 'telemetry_events')
      and grantee = 'authenticated'
      and privilege_type = 'SELECT'),
  2, 'SELECT granted to authenticated on both telematics tables');

select * from finish();
rollback;
