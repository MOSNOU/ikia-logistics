-- CC-13 Test 043 — Contract execution RLS, grants matrix, and RPC metadata.
--
-- Assertions (14):
--   1-8 : RLS enabled on all 8 new contract.* tables
--   9   : 0 direct INSERT/UPDATE/DELETE grants on contract.*
--   10  : every contract RPC (CC-12 + CC-13) is SECURITY DEFINER
--   11  : every contract RPC has search_path = ''
--   12  : no contract.buyer_* RPC accepts p_buyer_organization_id
--   13  : no contract.supplier_* RPC accepts p_supplier_id
--   14  : single consistent RPC owner across the schema

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

select plan(14);

-- 1-8: RLS enabled on all 8 new tables.
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='executed_contracts'),
  true, 'contract.executed_contracts has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='executed_contract_items'),
  true, 'contract.executed_contract_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='executed_contract_clauses'),
  true, 'contract.executed_contract_clauses has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_parties'),
  true, 'contract.contract_parties has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_signature_requests'),
  true, 'contract.contract_signature_requests has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='contract_signature_events'),
  true, 'contract.contract_signature_events has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='executed_contract_snapshots'),
  true, 'contract.executed_contract_snapshots has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='contract' and c.relname='executed_contract_events'),
  true, 'contract.executed_contract_events has RLS enabled');

-- 9: No direct write grants on contract.* tables.
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='contract' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on contract.* tables');

-- 10: Every RPC is SECURITY DEFINER.
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every contract RPC is security_definer');

-- 11: search_path = '' on every RPC.
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every contract RPC has search_path = empty string');

-- 12: No buyer_* accepts p_buyer_organization_id.
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no contract.buyer_* RPC accepts a p_buyer_organization_id parameter');

-- 13: No supplier_* accepts p_supplier_id.
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0, 'no contract.supplier_* RPC accepts a p_supplier_id parameter');

-- 14: Single consistent owner.
select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='contract'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1, 'every contract RPC has a single consistent owner');

select * from finish();
rollback;
