-- CC-45 Test 129 — Telematics schema shape.
--
-- Assertions (10):
--   1. telematics.telemetry_event_type enum has 5 values
--   2. telematics.position_reports table exists
--   3. telematics.telemetry_events table exists
--   4. position_reports.latitude check constraint exists
--   5. position_reports.longitude check constraint exists
--   6. position_reports.heading_degrees check constraint exists
--   7. telemetry_events.actor_party check constraint exists
--   8. position_reports_dispatch_idx exists
--   9. telemetry_events_dispatch_idx exists
--   10. position_reports.dispatch_id FK targets dispatch.dispatch_assignments

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

select plan(10);

select is(
  (select count(*)::int from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
   where n.nspname='telematics' and t.typname='telemetry_event_type'),
  5, 'telemetry_event_type enum has 5 values');

select is(
  to_regclass('telematics.position_reports')::text,
  'position_reports', 'position_reports table exists');

select is(
  to_regclass('telematics.telemetry_events')::text,
  'telemetry_events', 'telemetry_events table exists');

select ok(
  exists (
    select 1 from pg_constraint c
      join pg_namespace n on n.oid = c.connamespace
     where n.nspname='telematics' and c.conname='position_reports_lat_check'
  ),
  'position_reports latitude check constraint exists');

select ok(
  exists (
    select 1 from pg_constraint c
      join pg_namespace n on n.oid = c.connamespace
     where n.nspname='telematics' and c.conname='position_reports_lng_check'
  ),
  'position_reports longitude check constraint exists');

select ok(
  exists (
    select 1 from pg_constraint c
      join pg_namespace n on n.oid = c.connamespace
     where n.nspname='telematics' and c.conname='position_reports_heading_check'
  ),
  'position_reports heading_degrees check constraint exists');

select ok(
  exists (
    select 1 from pg_constraint c
      join pg_namespace n on n.oid = c.connamespace
     where n.nspname='telematics' and c.conname='telemetry_events_actor_party_check'
  ),
  'telemetry_events actor_party check constraint exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='telematics' and indexname='position_reports_dispatch_idx'),
  1, 'position_reports_dispatch_idx exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='telematics' and indexname='telemetry_events_dispatch_idx'),
  1, 'telemetry_events_dispatch_idx exists');

select ok(
  exists (
    select 1
      from information_schema.referential_constraints rc
      join information_schema.key_column_usage k
        on k.constraint_name = rc.constraint_name
       and k.table_schema    = 'telematics'
       and k.table_name      = 'position_reports'
       and k.column_name     = 'dispatch_id'
      join information_schema.constraint_column_usage cu
        on cu.constraint_name = rc.unique_constraint_name
     where cu.table_schema = 'dispatch' and cu.table_name = 'dispatch_assignments'
  ),
  'position_reports.dispatch_id FK targets dispatch.dispatch_assignments');

select * from finish();
rollback;
