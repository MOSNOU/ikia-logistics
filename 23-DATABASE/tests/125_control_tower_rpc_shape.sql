-- CC-44 Test 125 — Control Tower RPC shape.
--
-- Assertions (10):
--   1-5. each of the 5 control_tower_* RPCs is SECURITY DEFINER
--   6-10. each of the 5 control_tower_* RPCs has search_path = ''

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, settlement, dispute, tests;
begin;

select plan(10);

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname='control_tower_buyer_summary'),
  true, 'control_tower_buyer_summary is security_definer');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname='control_tower_carrier_summary'),
  true, 'control_tower_carrier_summary is security_definer');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname='control_tower_admin_summary'),
  true, 'control_tower_admin_summary is security_definer');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname='control_tower_admin_activity'),
  true, 'control_tower_admin_activity is security_definer');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='public' and p.proname='control_tower_admin_exceptions'),
  true, 'control_tower_admin_exceptions is security_definer');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='public' and p.proname='control_tower_buyer_summary'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'control_tower_buyer_summary has search_path = empty string');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='public' and p.proname='control_tower_carrier_summary'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'control_tower_carrier_summary has search_path = empty string');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='public' and p.proname='control_tower_admin_summary'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'control_tower_admin_summary has search_path = empty string');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='public' and p.proname='control_tower_admin_activity'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'control_tower_admin_activity has search_path = empty string');

select ok(
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname='public' and p.proname='control_tower_admin_exceptions'
       and 'search_path=""' = any(coalesce(p.proconfig, array[]::text[]))
  ),
  'control_tower_admin_exceptions has search_path = empty string');

select * from finish();
rollback;
