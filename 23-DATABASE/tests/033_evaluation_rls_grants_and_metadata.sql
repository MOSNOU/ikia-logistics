-- CC-11 Test 033 — Evaluation RLS, grants matrix, and RPC metadata.
--
-- Assertions (11):
--   1-5: RLS enabled on all 5 evaluation.* tables
--   6  : 0 direct INSERT/UPDATE/DELETE grants on evaluation.*
--   7  : every evaluation.buyer_/supplier_/admin_ RPC is SECURITY DEFINER
--   8  : every evaluation RPC has search_path = '' (stored as 'search_path=""')
--   9  : no evaluation.supplier_* RPC accepts a p_supplier_id parameter
--   10 : no evaluation.buyer_* RPC accepts a p_buyer_organization_id parameter
--   11 : single consistent RPC owner

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, tests;
begin;

select plan(11);

-- 1-5. RLS enabled on each of the 5 evaluation tables
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='evaluation' and c.relname='offer_evaluations'),
  true, 'evaluation.offer_evaluations has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='evaluation' and c.relname='offer_evaluation_scores'),
  true, 'evaluation.offer_evaluation_scores has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='evaluation' and c.relname='offer_comparison_snapshots'),
  true, 'evaluation.offer_comparison_snapshots has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='evaluation' and c.relname='offer_decisions'),
  true, 'evaluation.offer_decisions has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='evaluation' and c.relname='offer_decision_events'),
  true, 'evaluation.offer_decision_events has RLS enabled');

-- 6. No direct INSERT/UPDATE/DELETE grants on evaluation.*
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='evaluation' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0,
  'no direct INSERT/UPDATE/DELETE grants on evaluation.* tables'
);

-- 7. All buyer/supplier/admin RPCs are SECURITY DEFINER
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='evaluation'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0,
  'every evaluation.buyer_/supplier_/admin_ RPC is security_definer'
);

-- 8. search_path = '' on every evaluation RPC
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='evaluation'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0,
  'every evaluation RPC has search_path = empty string'
);

-- 9. No supplier_* accepts p_supplier_id
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='evaluation' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0,
  'no evaluation.supplier_* RPC accepts a p_supplier_id parameter'
);

-- 10. No buyer_* accepts p_buyer_organization_id
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='evaluation' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0,
  'no evaluation.buyer_* RPC accepts a p_buyer_organization_id parameter'
);

-- 11. Single consistent owner
select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='evaluation'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1,
  'every evaluation RPC has a single consistent owner'
);

select * from finish();
rollback;
