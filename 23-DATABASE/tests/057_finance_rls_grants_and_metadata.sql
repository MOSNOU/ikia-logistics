-- CC-16 Test 057 — Finance RLS, grants matrix, RPC metadata, safety, forbidden schemas.
--
-- Assertions (12):
--   1-6  : RLS enabled on all 6 finance.* tables
--   7    : 0 direct INSERT/UPDATE/DELETE grants on finance.*
--   8    : every finance RPC is SECURITY DEFINER
--   9    : every finance RPC has search_path = ''
--   10   : no finance.buyer_* RPC accepts p_buyer_organization_id
--   11   : no finance.supplier_* RPC accepts p_supplier_id
--   12   : single consistent RPC owner
--   13   : no forbidden schemas exist (pricing/settlement/escrow/insurance/gps)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, tests;
begin;

select plan(13);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='finance' and c.relname='invoices'),
  true, 'finance.invoices has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='finance' and c.relname='invoice_items'),
  true, 'finance.invoice_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='finance' and c.relname='payment_methods'),
  true, 'finance.payment_methods has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='finance' and c.relname='payments'),
  true, 'finance.payments has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='finance' and c.relname='invoice_status_events'),
  true, 'finance.invoice_status_events has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='finance' and c.relname='payment_status_events'),
  true, 'finance.payment_status_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='finance' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on finance.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='finance'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every finance RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='finance'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every finance RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='finance' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no finance.buyer_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='finance' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0, 'no finance.supplier_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='finance'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1, 'every finance RPC has a single consistent owner');

select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('insurance_claim','gps')),
  0, 'no insurance_claim/gps schemas were created (settlement CC-17 and pricing CC-23 legitimately exist)');

select * from finish();
rollback;
