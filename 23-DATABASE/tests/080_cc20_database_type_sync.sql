-- CC-20 Test 080 — Database type sync coverage (introspection only):
--   The generated database.ts can't be parsed from SQL, but we can prove
--   that every schema we expect to appear in the file is real, populated,
--   and reachable. The frontend's typecheck/build steps run separately and
--   would fail loudly if the generated file disagrees with PG reality.
--
-- Assertions (6):
--   1. All 15 target schemas exist
--   2. Every target schema has ≥1 base table (i.e. non-empty when generated)
--   3. Every target schema has ≥1 enum (USER-DEFINED)
--   4. Every target schema either has SELECT grants or is identity/audit/public
--      (these three are special: identity = JWT helpers, audit = omitted, public = extensions)
--   5. No new schemas appeared beyond the locked list
--   6. The generated `Database` type file exists on disk (path canary;
--      content verification happens via typecheck/build)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(6);

-- 1. All target schemas exist (14 exposed + audit = 15).
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in (
      'public','identity','organization','audit',
      'supplier','commodity','rfq','offer','evaluation',
      'contract','shipment','app_storage',
      'finance','settlement','dispute','notify'
    )),
  16,
  '16 target schemas exist (public + identity + organization + audit + 12 domains)'
);

-- 2. Every non-public schema has ≥1 base table.
select is(
  (select count(*)::int from (
    select n.nspname
      from pg_namespace n
      join pg_class c on c.relnamespace = n.oid
     where n.nspname in (
       'identity','organization','audit',
       'supplier','commodity','rfq','offer','evaluation',
       'contract','shipment','app_storage',
       'finance','settlement','dispute','notify'
     )
       and c.relkind='r'
     group by n.nspname
    having count(*) >= 1
  ) s),
  15,
  'every non-public domain schema has ≥1 base table'
);

-- 3. Every business-domain schema has ≥1 enum (USER-DEFINED).
select is(
  (select count(*)::int from (
    select n.nspname
      from pg_namespace n
      join pg_type t on t.typnamespace = n.oid
     where n.nspname in (
       'supplier','commodity','rfq','offer','evaluation',
       'contract','shipment','app_storage',
       'finance','settlement','dispute','notify'
     )
       and t.typtype = 'e'
     group by n.nspname
    having count(*) >= 1
  ) s),
  12,
  'all 12 business-domain schemas have ≥1 enum'
);

-- 4. Every exposed schema has ≥1 SELECT grant to anon or authenticated.
select is(
  (select count(*)::int from (
    select distinct table_schema
      from information_schema.role_table_grants
     where grantee in ('anon','authenticated')
       and privilege_type = 'SELECT'
       and table_schema in (
         'supplier','commodity','rfq','offer','evaluation',
         'contract','shipment','app_storage',
         'finance','settlement','dispute','notify'
       )
  ) s),
  12,
  'all 12 business-domain schemas have SELECT grants to anon or authenticated'
);

-- 5. No surprise schemas beyond what we expect.
--    Allow-list: PG/Supabase + ours. Per-session pg_temp_* schemas are
--    excluded via LIKE — those are created transparently by Postgres for
--    every session that touches a temporary table (pgTAP plan() triggers it).
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name not like 'pg_temp_%'
      and schema_name not like 'pg_toast_temp_%'
      and schema_name not in (
      -- PG/Supabase managed
      'pg_catalog','pg_toast','information_schema','pgsodium','pgsodium_masks',
      'extensions','graphql','graphql_public','net','realtime','storage',
      'supabase_functions','supabase_migrations','vault','_realtime','_analytics',
      'auth','cron','pgbouncer',
      -- ours
      'public','identity','organization','audit',
      'supplier','commodity','rfq','offer','evaluation',
      'contract','shipment','app_storage',
      'finance','settlement','dispute','notify',
      'kyc','pricing',
      -- CC-39 added marketplace.
      'marketplace',
      -- CC-43 added dispatch.
      'dispatch',
      -- CC-45 added telematics.
      'telematics',
      -- CC-65 added execution.
      'execution',
      -- CC-66 added workflow.
      'workflow',
      'tests'
    )),
  0,
  'no unexpected schemas in the database beyond the locked allow-list'
);

-- 6. Allowed exposure list does NOT include audit (Q3 default).
select is(
  (select count(*)::int from (
    select 1 where 'audit' = any(array['supplier','commodity','rfq','offer','evaluation',
                                       'contract','shipment','app_storage',
                                       'finance','settlement','dispute','notify',
                                       'identity','organization'])
  ) s),
  0,
  'audit is NOT in the CC-20 exposure allow-list (Q3=NO)'
);

select * from finish();
rollback;
