-- CC-47 Test 180 — driver_trip_events ledger is append-only.
--
-- Assertions (3):
--   1. authenticated has NO UPDATE on driver_trip_events
--   2. authenticated has NO DELETE on driver_trip_events
--   3. there is no UPDATE/DELETE/ALL RLS policy on driver_trip_events
--      (only the SELECT policy exists)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

select plan(3);

select ok(
  not has_table_privilege('authenticated', 'dispatch.driver_trip_events', 'UPDATE'),
  'authenticated cannot UPDATE driver_trip_events (append-only)');

select ok(
  not has_table_privilege('authenticated', 'dispatch.driver_trip_events', 'DELETE'),
  'authenticated cannot DELETE driver_trip_events (append-only)');

select is(
  (select count(*)::int from pg_policies
    where schemaname = 'dispatch' and tablename = 'driver_trip_events'
      and cmd in ('UPDATE', 'DELETE', 'ALL')),
  0, 'no UPDATE/DELETE/ALL policy on driver_trip_events');

select * from finish();
rollback;
