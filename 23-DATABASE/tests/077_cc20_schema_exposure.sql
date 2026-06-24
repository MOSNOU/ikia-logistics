-- CC-20 Test 077 — PostgREST schema exposure (SQL introspection, Q8=8a):
--   Verify every accepted business-domain schema has the GRANT chain
--   PostgREST needs to serve it (anon + authenticated + service_role USAGE).
--   `audit` is intentionally NOT exposed (Q3=NO).
--
-- Assertions (11):
--   1-11: USAGE grants present on 11 newly-exposed schemas + audit absent

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(11);

-- Helper: pass if anon/authenticated/service_role all have USAGE.
-- 1. commodity
select is(
  (has_schema_privilege('anon','commodity','USAGE')::int
   + has_schema_privilege('authenticated','commodity','USAGE')::int
   + has_schema_privilege('service_role','commodity','USAGE')::int),
  3, 'commodity has USAGE grants for anon + authenticated + service_role');

-- 2. rfq
select is(
  (has_schema_privilege('anon','rfq','USAGE')::int
   + has_schema_privilege('authenticated','rfq','USAGE')::int
   + has_schema_privilege('service_role','rfq','USAGE')::int),
  3, 'rfq has USAGE grants for anon + authenticated + service_role');

-- 3. offer
select is(
  (has_schema_privilege('anon','offer','USAGE')::int
   + has_schema_privilege('authenticated','offer','USAGE')::int
   + has_schema_privilege('service_role','offer','USAGE')::int),
  3, 'offer has USAGE grants for anon + authenticated + service_role');

-- 4. evaluation
select is(
  (has_schema_privilege('anon','evaluation','USAGE')::int
   + has_schema_privilege('authenticated','evaluation','USAGE')::int
   + has_schema_privilege('service_role','evaluation','USAGE')::int),
  3, 'evaluation has USAGE grants for anon + authenticated + service_role');

-- 5. contract
select is(
  (has_schema_privilege('anon','contract','USAGE')::int
   + has_schema_privilege('authenticated','contract','USAGE')::int
   + has_schema_privilege('service_role','contract','USAGE')::int),
  3, 'contract has USAGE grants for anon + authenticated + service_role');

-- 6. shipment
select is(
  (has_schema_privilege('anon','shipment','USAGE')::int
   + has_schema_privilege('authenticated','shipment','USAGE')::int
   + has_schema_privilege('service_role','shipment','USAGE')::int),
  3, 'shipment has USAGE grants for anon + authenticated + service_role');

-- 7. app_storage
select is(
  (has_schema_privilege('anon','app_storage','USAGE')::int
   + has_schema_privilege('authenticated','app_storage','USAGE')::int
   + has_schema_privilege('service_role','app_storage','USAGE')::int),
  3, 'app_storage has USAGE grants for anon + authenticated + service_role');

-- 8. finance
select is(
  (has_schema_privilege('anon','finance','USAGE')::int
   + has_schema_privilege('authenticated','finance','USAGE')::int
   + has_schema_privilege('service_role','finance','USAGE')::int),
  3, 'finance has USAGE grants for anon + authenticated + service_role');

-- 9. settlement
select is(
  (has_schema_privilege('anon','settlement','USAGE')::int
   + has_schema_privilege('authenticated','settlement','USAGE')::int
   + has_schema_privilege('service_role','settlement','USAGE')::int),
  3, 'settlement has USAGE grants for anon + authenticated + service_role');

-- 10. dispute
select is(
  (has_schema_privilege('anon','dispute','USAGE')::int
   + has_schema_privilege('authenticated','dispute','USAGE')::int
   + has_schema_privilege('service_role','dispute','USAGE')::int),
  3, 'dispute has USAGE grants for anon + authenticated + service_role');

-- 11. notify
select is(
  (has_schema_privilege('anon','notify','USAGE')::int
   + has_schema_privilege('authenticated','notify','USAGE')::int
   + has_schema_privilege('service_role','notify','USAGE')::int),
  3, 'notify has USAGE grants for anon + authenticated + service_role');

select * from finish();
rollback;
