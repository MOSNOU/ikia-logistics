-- CC-43 Test 120 — Dispatch grants, RLS, RPC metadata.
--
-- Assertions (9):
--   1. RLS enabled on dispatch_assignments
--   2. RLS enabled on dispatch_events
--   3. 0 direct INSERT/UPDATE/DELETE grants on dispatch tables
--   4. every dispatch audience RPC is SECURITY DEFINER
--   5. every dispatch audience RPC has search_path = ''
--   6. all 7 carrier RPCs have EXECUTE granted to authenticated
--   7. all 3 buyer RPCs have EXECUTE granted to authenticated
--   8. all 3 admin RPCs have EXECUTE granted to authenticated
--   9. SELECT granted to authenticated on both dispatch tables

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, tests;
begin;

select plan(9);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispatch' and c.relname='dispatch_assignments'),
  true, 'dispatch_assignments has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispatch' and c.relname='dispatch_events'),
  true, 'dispatch_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='dispatch'
      and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on dispatch tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispatch'
      and (p.proname like 'buyer_%' or p.proname like 'carrier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every dispatch audience RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispatch'
      and (p.proname like 'buyer_%' or p.proname like 'carrier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every dispatch audience RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispatch'
      and p.proname in (
        'carrier_create_dispatch', 'carrier_update_dispatch_placeholders',
        'carrier_mark_ready', 'carrier_release_dispatch', 'carrier_cancel_dispatch',
        'carrier_list_my_dispatches', 'carrier_get_dispatch'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  7, 'all 7 carrier dispatch RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispatch'
      and p.proname in (
        'buyer_list_my_dispatches', 'buyer_get_dispatch', 'buyer_cancel_dispatch'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  3, 'all 3 buyer dispatch RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispatch'
      and p.proname in (
        'admin_list_dispatches', 'admin_get_dispatch', 'admin_cancel_dispatch'
      )
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  3, 'all 3 admin dispatch RPCs have EXECUTE granted to authenticated');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='dispatch'
      and table_name in ('dispatch_assignments', 'dispatch_events')
      and grantee = 'authenticated'
      and privilege_type = 'SELECT'),
  2, 'SELECT granted to authenticated on both dispatch tables');

select * from finish();
rollback;
