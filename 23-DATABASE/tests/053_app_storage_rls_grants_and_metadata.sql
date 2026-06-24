-- CC-15 Test 053 — app_storage RLS, grants matrix, and RPC metadata.
--
-- Assertions (11):
--   1-3 : RLS enabled on all 3 app_storage.* tables
--   4   : 0 direct INSERT/UPDATE/DELETE grants on app_storage.*
--   5   : every app_storage RPC is SECURITY DEFINER
--   6   : every app_storage RPC has search_path = ''
--   7   : no app_storage.portal_* RPC accepts p_organization_id
--   8   : no app_storage.portal_* RPC accepts p_supplier_id
--   9   : no app_storage.portal_* RPC accepts p_buyer_organization_id
--   10  : single consistent RPC owner
--   11  : no forbidden side-effect schemas exist

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, tests;
begin;

select plan(11);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='app_storage' and c.relname='files'),
  true, 'app_storage.files has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='app_storage' and c.relname='file_versions'),
  true, 'app_storage.file_versions has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='app_storage' and c.relname='file_associations'),
  true, 'app_storage.file_associations has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='app_storage' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on app_storage.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='app_storage'
      and (p.proname like 'portal_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every app_storage RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='app_storage'
      and (p.proname like 'portal_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every app_storage RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='app_storage' and p.proname like 'portal_%'
      and p.proargnames is not null
      and 'p_organization_id' = any(p.proargnames)),
  0, 'no app_storage.portal_* RPC accepts a p_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='app_storage' and p.proname like 'portal_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0, 'no app_storage.portal_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='app_storage' and p.proname like 'portal_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no app_storage.portal_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='app_storage'
      and (p.proname like 'portal_%' or p.proname like 'admin_%')),
  1, 'every app_storage RPC has a single consistent owner');

-- No payment / invoice / accounting / insurance / gps schemas.
-- (`settlement` lands legitimately in CC-17; `pricing` in CC-23.)
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('payment','invoice','accounting','insurance_claim','gps')),
  0,
  'no payment/invoice/accounting/insurance_claim/gps schemas exist (pricing legitimately lands in CC-23)'
);

select * from finish();
rollback;
