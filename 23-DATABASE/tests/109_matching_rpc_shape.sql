-- CC-41 Test 109 — Marketplace matching RPC shape.
--
-- Assertions (8):
--   1. marketplace.find_matching_capacity exists and is security_definer
--   2. marketplace.find_matching_carriers exists and is security_definer
--   3. marketplace.admin_matching_summary exists and is security_definer
--   4. find_matching_capacity has search_path = ''
--   5. find_matching_carriers has search_path = ''
--   6. admin_matching_summary has search_path = ''
--   7. EXECUTE granted to authenticated on find_matching_capacity
--   8. EXECUTE granted to authenticated on admin_matching_summary

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

select plan(8);

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='find_matching_capacity'),
  true, 'find_matching_capacity is security_definer');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='find_matching_carriers'),
  true, 'find_matching_carriers is security_definer');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='admin_matching_summary'),
  true, 'admin_matching_summary is security_definer');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='marketplace' and p.proname='find_matching_capacity'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'find_matching_capacity has search_path = empty string');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='marketplace' and p.proname='find_matching_carriers'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'find_matching_carriers has search_path = empty string');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='marketplace' and p.proname='admin_matching_summary'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'admin_matching_summary has search_path = empty string');

select ok(
  has_function_privilege(
    'authenticated',
    'marketplace.find_matching_capacity(uuid, integer)',
    'EXECUTE'
  ),
  'EXECUTE granted to authenticated on find_matching_capacity');

select ok(
  has_function_privilege(
    'authenticated',
    'marketplace.admin_matching_summary()',
    'EXECUTE'
  ),
  'EXECUTE granted to authenticated on admin_matching_summary');

select * from finish();
rollback;
