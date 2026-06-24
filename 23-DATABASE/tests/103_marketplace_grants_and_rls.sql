-- CC-39 Test 103 — Marketplace RLS, grants matrix, and RPC metadata.
--
-- Assertions (8):
--   1. RLS enabled on carrier_profiles
--   2. RLS enabled on carrier_directory_visibility
--   3. RLS enabled on capacity_listings
--   4. RLS enabled on capacity_status_events
--   5. 0 direct INSERT/UPDATE/DELETE grants on marketplace.* tables
--   6. every marketplace audience RPC is SECURITY DEFINER
--   7. every marketplace audience RPC has search_path = ''
--   8. schema usage granted to authenticated

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

select plan(8);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='marketplace' and c.relname='carrier_profiles'),
  true, 'carrier_profiles has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='marketplace' and c.relname='carrier_directory_visibility'),
  true, 'carrier_directory_visibility has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='marketplace' and c.relname='capacity_listings'),
  true, 'capacity_listings has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='marketplace' and c.relname='capacity_status_events'),
  true, 'capacity_status_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='marketplace' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on marketplace.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%' or p.proname like 'carrier_%')
      and not p.prosecdef),
  0, 'every marketplace audience RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%' or p.proname like 'carrier_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every marketplace audience RPC has search_path = empty string');

-- has_schema_privilege returns true when the role can USAGE the schema.
select ok(
  has_schema_privilege('authenticated', 'marketplace', 'USAGE'),
  'marketplace schema usage granted to authenticated');

select * from finish();
rollback;
