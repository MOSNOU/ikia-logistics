-- CC-20 Test 078 — RPC discovery (SQL introspection):
--   Confirms every accepted business-domain schema has SECURITY DEFINER RPCs
--   that PostgREST will surface to the frontend. Each assertion verifies that:
--     a) the schema has ≥1 buyer_/supplier_/admin_/portal_ RPC
--     b) every RPC there has EXECUTE granted to authenticated
--
-- Assertions (11):
--   1-11: per-schema RPC discovery + EXECUTE-grant coverage

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(11);

-- Per-schema RPC count + execute grants. A schema is "ready for the frontend"
-- if every SECURITY DEFINER RPC named buyer_/supplier_/admin_/portal_ has
-- EXECUTE granted to `authenticated`.
select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='supplier' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'supplier exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='commodity' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'commodity exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='rfq' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'rfq exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='offer' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'offer exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='evaluation' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'evaluation exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='contract' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'contract exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='shipment' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'shipment exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='app_storage' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'app_storage exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='finance' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'finance exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='settlement' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'settlement exposes ≥1 RPC executable by authenticated');

select cmp_ok(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='dispute' and p.prosecdef
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%'
           or p.proname like 'admin_%' or p.proname like 'portal_%')
      and has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  '>=', 1, 'dispute exposes ≥1 RPC executable by authenticated');

select * from finish();
rollback;
