-- CC-20 Test 079 — RLS still enforced post-exposure:
--   Now that 11 more schemas are reachable from PostgREST, prove that RLS
--   continues to gate access at the row level. Schema USAGE alone is not enough;
--   each table must still have RLS enabled and policies that reject unauthorized
--   reads.
--
-- Assertions (8):
--   1-7: representative table per newly-exposed schema has RLS enabled
--   8  : zero new schemas added INSERT/UPDATE/DELETE grants to anon/authenticated

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(8);

-- One representative table per major newly-exposed schema.
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='requests'),
  true, 'rfq.requests retains RLS post-exposure');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='offer' and c.relname='supplier_offers'),
  true, 'offer.supplier_offers retains RLS post-exposure');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='evaluation' and c.relname='offer_evaluations'),
  true, 'evaluation.offer_evaluations retains RLS post-exposure');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='executed_contracts'),
  true, 'contract.executed_contracts retains RLS post-exposure');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipments'),
  true, 'shipment.shipments retains RLS post-exposure');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='settlements'),
  true, 'settlement.settlements retains RLS post-exposure');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='notify' and c.relname='notifications'),
  true, 'notify.notifications retains RLS post-exposure');

-- No new direct write grants appeared on any newly-exposed schema.
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema in ('rfq','offer','evaluation','contract','shipment',
                           'app_storage','finance','settlement','dispute','notify','commodity')
      and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0,
  'no direct INSERT/UPDATE/DELETE grants on any newly-exposed schema'
);

select * from finish();
rollback;
