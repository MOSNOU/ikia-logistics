-- v1.1 Phase B Test 181 — carrier_assign_driver RPC shape + security posture.
--
-- Assertions (8):
--   1-4. carrier_assign_driver: exists, SECURITY DEFINER, search_path='',
--        authenticated has EXECUTE.
--   5-8. carrier_list_assignable_drivers: exists, SECURITY DEFINER,
--        search_path='', authenticated has EXECUTE.

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

select plan(8);

-- carrier_assign_driver ------------------------------------------------------
select has_function('dispatch', 'carrier_assign_driver', ARRAY['uuid', 'uuid'],
  'dispatch.carrier_assign_driver(uuid,uuid) exists');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'dispatch' and p.proname = 'carrier_assign_driver'),
  true, 'carrier_assign_driver is SECURITY DEFINER');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'dispatch' and p.proname = 'carrier_assign_driver'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'carrier_assign_driver has search_path = empty string');

select ok(
  has_function_privilege('authenticated',
    'dispatch.carrier_assign_driver(uuid, uuid)', 'EXECUTE'),
  'authenticated can EXECUTE carrier_assign_driver');

-- carrier_list_assignable_drivers -------------------------------------------
select has_function('dispatch', 'carrier_list_assignable_drivers', ARRAY['uuid'],
  'dispatch.carrier_list_assignable_drivers(uuid) exists');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'dispatch' and p.proname = 'carrier_list_assignable_drivers'),
  true, 'carrier_list_assignable_drivers is SECURITY DEFINER');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'dispatch' and p.proname = 'carrier_list_assignable_drivers'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'carrier_list_assignable_drivers has search_path = empty string');

select ok(
  has_function_privilege('authenticated',
    'dispatch.carrier_list_assignable_drivers(uuid)', 'EXECUTE'),
  'authenticated can EXECUTE carrier_list_assignable_drivers');

select * from finish();
rollback;
