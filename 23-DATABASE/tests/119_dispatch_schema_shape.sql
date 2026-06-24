-- CC-43 Test 119 — Dispatch schema shape.
--
-- Assertions (9):
--   1. dispatch.dispatch_status enum has 5 values
--   2. dispatch.dispatch_assignments table exists
--   3. dispatch.dispatch_events table exists
--   4. dispatch_assignments.status defaults to 'draft'
--   5. dispatch_events_actor_party_check constraint exists
--   6. dispatch_assignments_booking_idx exists
--   7. dispatch_assignments_carrier_status_idx exists
--   8. dispatch_assignments.booking_request_id FK targets marketplace.booking_requests
--   9. dispatch_events.dispatch_id FK targets dispatch.dispatch_assignments

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, tests;
begin;

select plan(9);

select is(
  (select count(*)::int from pg_enum e
    join pg_type t on t.oid=e.enumtypid
    join pg_namespace n on n.oid=t.typnamespace
   where n.nspname='dispatch' and t.typname='dispatch_status'),
  5, 'dispatch_status enum has 5 values');

select is(
  to_regclass('dispatch.dispatch_assignments')::text,
  'dispatch_assignments', 'dispatch_assignments table exists');

select is(
  to_regclass('dispatch.dispatch_events')::text,
  'dispatch_events', 'dispatch_events table exists');

select matches(
  (select column_default::text from information_schema.columns
    where table_schema='dispatch' and table_name='dispatch_assignments' and column_name='status'),
  'draft.*dispatch_status',
  'dispatch_assignments.status defaults to draft');

select ok(
  exists (
    select 1 from pg_constraint c
      join pg_namespace n on n.oid = c.connamespace
     where n.nspname='dispatch'
       and c.conname='dispatch_events_actor_party_check'
  ),
  'dispatch_events_actor_party_check constraint exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='dispatch' and indexname='dispatch_assignments_booking_idx'),
  1, 'dispatch_assignments_booking_idx exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='dispatch' and indexname='dispatch_assignments_carrier_status_idx'),
  1, 'dispatch_assignments_carrier_status_idx exists');

select ok(
  exists (
    select 1
      from information_schema.referential_constraints rc
      join information_schema.key_column_usage k
        on k.constraint_name = rc.constraint_name
       and k.table_schema    = 'dispatch'
       and k.table_name      = 'dispatch_assignments'
       and k.column_name     = 'booking_request_id'
      join information_schema.constraint_column_usage cu
        on cu.constraint_name = rc.unique_constraint_name
     where cu.table_schema = 'marketplace' and cu.table_name = 'booking_requests'
  ),
  'dispatch_assignments.booking_request_id FK targets marketplace.booking_requests');

select ok(
  exists (
    select 1
      from information_schema.referential_constraints rc
      join information_schema.key_column_usage k
        on k.constraint_name = rc.constraint_name
       and k.table_schema    = 'dispatch'
       and k.table_name      = 'dispatch_events'
       and k.column_name     = 'dispatch_id'
      join information_schema.constraint_column_usage cu
        on cu.constraint_name = rc.unique_constraint_name
     where cu.table_schema = 'dispatch' and cu.table_name = 'dispatch_assignments'
  ),
  'dispatch_events.dispatch_id FK targets dispatch.dispatch_assignments');

select * from finish();
rollback;
