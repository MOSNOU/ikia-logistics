-- CC-42 Test 113 — Booking schema shape.
--
-- Assertions (10):
--   1.  marketplace.booking_status enum exists with 7 values
--   2.  marketplace.booking_requests table exists
--   3.  marketplace.booking_events table exists
--   4.  booking_requests.status defaults to 'draft'
--   5.  booking_events.actor_party check exists
--   6.  booking_requests_buyer_status_idx exists
--   7.  booking_requests_carrier_status_idx exists
--   8.  booking_events_booking_idx exists
--   9.  booking_requests.shipment_id FK targets shipment.shipments
--   10. booking_requests.capacity_listing_id FK targets marketplace.capacity_listings

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

select plan(10);

select is(
  (select count(*)::int from pg_enum e
    join pg_type t on t.oid=e.enumtypid
    join pg_namespace n on n.oid=t.typnamespace
   where n.nspname='marketplace' and t.typname='booking_status'),
  7, 'booking_status enum has 7 values');

select is(
  to_regclass('marketplace.booking_requests')::text,
  'booking_requests', 'booking_requests table exists');

select is(
  to_regclass('marketplace.booking_events')::text,
  'booking_events', 'booking_events table exists');

select matches(
  (select column_default::text from information_schema.columns
    where table_schema='marketplace' and table_name='booking_requests' and column_name='status'),
  'draft.*booking_status',
  'booking_requests.status defaults to draft');

select ok(
  exists (
    select 1 from pg_constraint c
      join pg_namespace n on n.oid = c.connamespace
     where n.nspname='marketplace'
       and c.conname='booking_events_actor_party_check'
  ),
  'booking_events_actor_party_check constraint exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='marketplace' and indexname='booking_requests_buyer_status_idx'),
  1, 'booking_requests_buyer_status_idx exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='marketplace' and indexname='booking_requests_carrier_status_idx'),
  1, 'booking_requests_carrier_status_idx exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='marketplace' and indexname='booking_events_booking_idx'),
  1, 'booking_events_booking_idx exists');

select ok(
  exists (
    select 1
      from information_schema.referential_constraints rc
      join information_schema.key_column_usage k
        on k.constraint_name = rc.constraint_name
       and k.table_schema    = 'marketplace'
       and k.table_name      = 'booking_requests'
       and k.column_name     = 'shipment_id'
      join information_schema.constraint_column_usage cu
        on cu.constraint_name = rc.unique_constraint_name
     where cu.table_schema = 'shipment' and cu.table_name = 'shipments'
  ),
  'booking_requests.shipment_id FK targets shipment.shipments');

select ok(
  exists (
    select 1
      from information_schema.referential_constraints rc
      join information_schema.key_column_usage k
        on k.constraint_name = rc.constraint_name
       and k.table_schema    = 'marketplace'
       and k.table_name      = 'booking_requests'
       and k.column_name     = 'capacity_listing_id'
      join information_schema.constraint_column_usage cu
        on cu.constraint_name = rc.unique_constraint_name
     where cu.table_schema = 'marketplace' and cu.table_name = 'capacity_listings'
  ),
  'booking_requests.capacity_listing_id FK targets marketplace.capacity_listings');

select * from finish();
rollback;
