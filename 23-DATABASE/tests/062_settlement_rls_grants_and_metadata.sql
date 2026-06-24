-- CC-17 Test 062 — Settlement RLS, grants matrix, RPC metadata, safety, no forbidden schemas.
--
-- Assertions (13):
--   1-6  : RLS enabled on all 6 settlement.* tables
--   7    : 0 direct INSERT/UPDATE/DELETE grants
--   8    : every settlement RPC is SECURITY DEFINER
--   9    : every settlement RPC has search_path = ''
--   10   : no settlement.buyer_* RPC accepts p_buyer_organization_id
--   11   : no settlement.supplier_* RPC accepts p_supplier_id
--   12   : single consistent RPC owner
--   13   : no forbidden schemas (banking/psp/gateway/license/insurance/gps/arbitration)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, tests;
begin;

select plan(13);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='escrow_accounts'),
  true, 'settlement.escrow_accounts has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='escrow_entries'),
  true, 'settlement.escrow_entries has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='escrow_status_events'),
  true, 'settlement.escrow_status_events has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='settlements'),
  true, 'settlement.settlements has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='settlement_items'),
  true, 'settlement.settlement_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='settlement' and c.relname='settlement_events'),
  true, 'settlement.settlement_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='settlement' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on settlement.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='settlement'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every settlement RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='settlement'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every settlement RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='settlement' and p.proname like 'buyer_%'
      and p.proargnames is not null and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no settlement.buyer_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='settlement' and p.proname like 'supplier_%'
      and p.proargnames is not null and 'p_supplier_id' = any(p.proargnames)),
  0, 'no settlement.supplier_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='settlement'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1, 'every settlement RPC has a single consistent owner');

select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('banking','psp','gateway','license','insurance_claim','gps','arbitration')),
  0,
  'no banking/psp/gateway/license/insurance/gps/arbitration schemas were created'
);

select * from finish();
rollback;
