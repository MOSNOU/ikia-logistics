-- CC-09 Test 025 — RFQ RLS, grants matrix, and RPC metadata.
--
-- Assertions (12):
--   1-6: RLS enabled on all 6 rfq.* tables
--   7  : 0 direct INSERT/UPDATE/DELETE grants on rfq.*
--   8  : all rfq.buyer_/supplier_/admin_ RPCs are SECURITY DEFINER
--   9  : all rfq RPCs have search_path = '' (stored as 'search_path=""')
--   10 : 0 rfq.buyer_* RPC accepts a p_buyer_organization_id parameter
--   11 : 0 rfq.supplier_* RPC accepts a p_supplier_id parameter
--   12 : single consistent owner across all rfq RPCs

set search_path = extensions, public, identity, organization, audit, rfq, tests;
begin;

select plan(12);

-- 1-6. RLS on each of the 6 rfq tables
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='requests'),
  true, 'rfq.requests has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='request_items'),
  true, 'rfq.request_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='request_item_specifications'),
  true, 'rfq.request_item_specifications has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='request_document_requirements'),
  true, 'rfq.request_document_requirements has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='request_supplier_invitations'),
  true, 'rfq.request_supplier_invitations has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rfq' and c.relname='request_status_events'),
  true, 'rfq.request_status_events has RLS enabled');

-- 7. No direct INSERT/UPDATE/DELETE grants on rfq.*
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='rfq' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0,
  'no direct INSERT/UPDATE/DELETE grants on rfq.* tables'
);

-- 8. All buyer/supplier/admin RPCs are SECURITY DEFINER
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='rfq'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0,
  'every rfq.buyer_/supplier_/admin_ RPC is security_definer'
);

-- 9. search_path = '' on every rfq RPC (stored as 'search_path=""')
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='rfq'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0,
  'every rfq RPC has search_path = empty string'
);

-- 10. No buyer_* accepts p_buyer_organization_id
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='rfq' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0,
  'no rfq.buyer_* RPC accepts a p_buyer_organization_id parameter'
);

-- 11. No supplier_* accepts p_supplier_id
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='rfq' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0,
  'no rfq.supplier_* RPC accepts a p_supplier_id parameter'
);

-- 12. Single consistent owner
select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='rfq'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1,
  'every rfq RPC has a single consistent owner'
);

select * from finish();
rollback;
