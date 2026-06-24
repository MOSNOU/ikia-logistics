-- CC-08 Test 022 — Commodity RPC metadata and signature safety.
--
-- Assertions (5):
--   1. Every commodity.admin_* function has security_definer = true
--   2. Every commodity.portal_* function has security_definer = true
--   3. Every commodity.admin_* + portal_* function has search_path = ''
--   4. No commodity.portal_* RPC accepts a p_supplier_id parameter
--   5. All commodity RPCs have a single consistent owner (postgres)

set search_path = extensions, public, identity, organization, audit, commodity, tests;
begin;

select plan(5);

-- 1. admin_* all security_definer
select is(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'commodity'
      and p.proname like 'admin_%'
      and not p.prosecdef),
  0,
  'every commodity.admin_* function is security_definer'
);

-- 2. portal_* all security_definer
select is(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'commodity'
      and p.proname like 'portal_%'
      and not p.prosecdef),
  0,
  'every commodity.portal_* function is security_definer'
);

-- 3. search_path = '' everywhere (PG stores this as 'search_path=""')
select is(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'commodity'
      and (p.proname like 'admin_%' or p.proname like 'portal_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0,
  'every commodity admin/portal RPC has search_path = empty string'
);

-- 4. No portal_* RPC accepts p_supplier_id
select is(
  (select count(*)::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'commodity'
      and p.proname like 'portal_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0,
  'no commodity.portal_* RPC accepts a p_supplier_id parameter'
);

-- 5. Single consistent owner
select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'commodity'
      and (p.proname like 'admin_%' or p.proname like 'portal_%')),
  1,
  'every commodity admin/portal RPC has a single consistent owner'
);

select * from finish();
rollback;
