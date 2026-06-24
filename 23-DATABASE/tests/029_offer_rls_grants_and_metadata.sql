-- CC-10 Test 029 — Offer RLS, grants matrix, and RPC metadata.
--
-- Assertions (10):
--   1-5: RLS enabled on all 5 offer.* tables
--   6  : 0 direct INSERT/UPDATE/DELETE grants on offer.*
--   7  : every offer.supplier_/buyer_/admin_ RPC is SECURITY DEFINER
--   8  : every offer RPC has search_path = '' (stored as 'search_path=""')
--   9  : no offer.supplier_* RPC accepts a p_supplier_id parameter
--   10 : no offer.buyer_* RPC accepts a p_buyer_organization_id parameter

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, tests;
begin;

select plan(11);

-- 1-5. RLS enabled on each of the 5 offer tables
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='offer' and c.relname='supplier_offers'),
  true, 'offer.supplier_offers has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='offer' and c.relname='supplier_offer_items'),
  true, 'offer.supplier_offer_items has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='offer' and c.relname='supplier_offer_item_specifications'),
  true, 'offer.supplier_offer_item_specifications has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='offer' and c.relname='supplier_offer_document_commitments'),
  true, 'offer.supplier_offer_document_commitments has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='offer' and c.relname='supplier_offer_status_events'),
  true, 'offer.supplier_offer_status_events has RLS enabled');

-- 6. No direct INSERT/UPDATE/DELETE grants on offer.*
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='offer' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0,
  'no direct INSERT/UPDATE/DELETE grants on offer.* tables'
);

-- 7. All buyer/supplier/admin RPCs are SECURITY DEFINER
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='offer'
      and (p.proname like 'supplier_%' or p.proname like 'buyer_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0,
  'every offer.supplier_/buyer_/admin_ RPC is security_definer'
);

-- 8. search_path = '' on every offer RPC
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='offer'
      and (p.proname like 'supplier_%' or p.proname like 'buyer_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0,
  'every offer RPC has search_path = empty string'
);

-- 9. No supplier_* accepts p_supplier_id
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='offer' and p.proname like 'supplier_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0,
  'no offer.supplier_* RPC accepts a p_supplier_id parameter'
);

-- 10. No buyer_* accepts p_buyer_organization_id
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='offer' and p.proname like 'buyer_%'
      and p.proargnames is not null
      and 'p_buyer_organization_id' = any(p.proargnames)),
  0,
  'no offer.buyer_* RPC accepts a p_buyer_organization_id parameter'
);

-- 11. Single consistent owner
select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='offer'
      and (p.proname like 'supplier_%' or p.proname like 'buyer_%' or p.proname like 'admin_%')),
  1,
  'every offer RPC has a single consistent owner'
);

select * from finish();
rollback;
