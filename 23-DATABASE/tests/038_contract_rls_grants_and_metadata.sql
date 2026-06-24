-- CC-12 Test 038 — Contract preparation RLS, grants matrix, and RPC metadata.
--
-- Assertions (11):
--   1-5: RLS enabled on all 5 contract.* tables
--   6  : 0 direct INSERT/UPDATE/DELETE grants on contract.*
--   7  : every contract.buyer_/supplier_/admin_ RPC is SECURITY DEFINER
--   8  : every contract RPC has search_path = '' (stored as 'search_path=""')
--   9  : no contract.buyer_* RPC accepts a p_buyer_organization_id parameter
--   10 : no contract.supplier_* RPC accepts a p_supplier_id parameter
--   11 : single consistent RPC owner

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

select plan(11);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_preparations'),
  true, 'contract.contract_preparations has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_preparation_items'),
  true, 'contract.contract_preparation_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_preparation_clauses'),
  true, 'contract.contract_preparation_clauses has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_preparation_snapshots'),
  true, 'contract.contract_preparation_snapshots has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_preparation_events'),
  true, 'contract.contract_preparation_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='contract' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on contract.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every contract.buyer_/supplier_/admin_ RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every contract RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no contract.buyer_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0, 'no contract.supplier_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1, 'every contract RPC has a single consistent owner');

select * from finish();
rollback;
