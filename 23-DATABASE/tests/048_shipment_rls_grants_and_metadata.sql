-- CC-14 Test 048 — Shipment RLS, grants matrix, and RPC metadata.
--
-- Assertions (13):
--   1-7  : RLS enabled on all 7 shipment.* tables
--   8    : 0 direct INSERT/UPDATE/DELETE grants on shipment.*
--   9    : every shipment RPC is SECURITY DEFINER
--   10   : every shipment RPC has search_path = ''
--   11   : no shipment.buyer_* RPC accepts p_buyer_organization_id
--   12   : no shipment.supplier_* RPC accepts p_supplier_id
--   13   : single consistent RPC owner

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment, tests;
begin;

select plan(13);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipments'),
  true, 'shipment.shipments has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipment_items'),
  true, 'shipment.shipment_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipment_stops'),
  true, 'shipment.shipment_stops has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipment_milestones'),
  true, 'shipment.shipment_milestones has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipment_document_requirements'),
  true, 'shipment.shipment_document_requirements has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipment_documents'),
  true, 'shipment.shipment_documents has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='shipment' and c.relname='shipment_events'),
  true, 'shipment.shipment_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='shipment' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on shipment.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='shipment'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every shipment RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='shipment'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every shipment RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='shipment' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no shipment.buyer_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='shipment' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0, 'no shipment.supplier_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='shipment'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1, 'every shipment RPC has a single consistent owner');

select * from finish();
rollback;
