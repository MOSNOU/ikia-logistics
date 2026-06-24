-- CC-23 Test 092 — Pricing schema shape (enums, tables, RLS, grants).
--
-- Assertions (28):
--   1     : schema pricing exists
--   2     : usage granted to authenticated
--   3-8   : 6 enums exist
--   9-17  : 9 tables exist (incl. events)
--   18-26 : RLS enabled on all 9 tables
--   27    : 0 direct INSERT/UPDATE/DELETE grants to anon/authenticated
--   28    : every pricing.* RPC is SECURITY DEFINER and has search_path = ''

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

select plan(28);

select is(
  (select count(*)::int from pg_namespace where nspname = 'pricing'),
  1, 'pricing schema exists'
);
select is(
  has_schema_privilege('authenticated', 'pricing', 'USAGE'),
  true, 'authenticated has USAGE on pricing schema'
);

-- 6 enums
select is(
  (select count(*)::int from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'pricing' and t.typname = 'price_list_status'), 1, 'enum price_list_status exists');
select is(
  (select count(*)::int from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'pricing' and t.typname = 'quotation_status'), 1, 'enum quotation_status exists');
select is(
  (select count(*)::int from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'pricing' and t.typname = 'quote_capture_kind'), 1, 'enum quote_capture_kind exists');
select is(
  (select count(*)::int from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'pricing' and t.typname = 'discount_kind'), 1, 'enum discount_kind exists');
select is(
  (select count(*)::int from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'pricing' and t.typname = 'discount_application'), 1, 'enum discount_application exists');
select is(
  (select count(*)::int from pg_type t join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'pricing' and t.typname = 'pricing_event_kind'), 1, 'enum pricing_event_kind exists');

-- 9 tables
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'currencies'), 1, 'table currencies exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'currency_rates'), 1, 'table currency_rates exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'price_lists'), 1, 'table price_lists exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'price_list_items'), 1, 'table price_list_items exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'quotations'), 1, 'table quotations exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'quotation_items'), 1, 'table quotation_items exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'discount_rules'), 1, 'table discount_rules exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'quote_captures'), 1, 'table quote_captures exists');
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'pricing' and table_name = 'events'), 1, 'table events exists');

-- 9 RLS
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'currencies'),
  true, 'RLS enabled on currencies');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'currency_rates'),
  true, 'RLS enabled on currency_rates');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'price_lists'),
  true, 'RLS enabled on price_lists');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'price_list_items'),
  true, 'RLS enabled on price_list_items');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'quotations'),
  true, 'RLS enabled on quotations');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'quotation_items'),
  true, 'RLS enabled on quotation_items');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'discount_rules'),
  true, 'RLS enabled on discount_rules');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'quote_captures'),
  true, 'RLS enabled on quote_captures');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'pricing' and c.relname = 'events'),
  true, 'RLS enabled on events');

-- 0 direct DML grants
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema = 'pricing' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on pricing.* tables');

-- Every RPC is SECURITY DEFINER with search_path=''
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'pricing'
      and (p.proname like 'portal_%' or p.proname like 'admin_%'
           or p.proname like 'get_%' or p.proname like 'list_%'
           or p.proname like 'convert_%' or p.proname like 'compute_%')
      and (not p.prosecdef
           or not exists (
             select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s where s = 'search_path=""'
           ))),
  0, 'every pricing.* user-facing RPC is security_definer + search_path empty');

select * from finish();
rollback;
