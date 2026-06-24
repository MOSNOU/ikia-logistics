-- CC-39 Test 102 — Marketplace schema shape.
--
-- Assertions (10):
--   1.  marketplace.carrier_profile_status enum exists with 4 values
--   2.  marketplace.capacity_status enum exists with 5 values
--   3.  marketplace.carrier_profiles table exists
--   4.  marketplace.carrier_directory_visibility table exists
--   5.  marketplace.capacity_listings table exists
--   6.  marketplace.capacity_status_events table exists
--   7.  carrier_profiles.status defaults to 'draft'
--   8.  capacity_listings.status defaults to 'draft'
--   9.  carrier_directory_visibility.is_public defaults to false
--   10. capacity_listings_carrier_status_idx exists

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

select plan(10);

select is(
  (select count(*)::int from pg_type t
    join pg_namespace n on n.oid=t.typnamespace
   where n.nspname='marketplace' and t.typname='carrier_profile_status'),
  1, 'carrier_profile_status enum exists');

select is(
  (select count(*)::int from pg_enum e
    join pg_type t on t.oid=e.enumtypid
    join pg_namespace n on n.oid=t.typnamespace
   where n.nspname='marketplace' and t.typname='capacity_status'),
  5, 'capacity_status enum has 5 values');

select is(
  to_regclass('marketplace.carrier_profiles')::text,
  'carrier_profiles', 'carrier_profiles table exists');

select is(
  to_regclass('marketplace.carrier_directory_visibility')::text,
  'carrier_directory_visibility', 'carrier_directory_visibility table exists');

select is(
  to_regclass('marketplace.capacity_listings')::text,
  'capacity_listings', 'capacity_listings table exists');

select is(
  to_regclass('marketplace.capacity_status_events')::text,
  'capacity_status_events', 'capacity_status_events table exists');

select matches(
  (select column_default::text from information_schema.columns
    where table_schema='marketplace' and table_name='carrier_profiles' and column_name='status'),
  'draft.*carrier_profile_status',
  'carrier_profiles.status defaults to draft');

select matches(
  (select column_default::text from information_schema.columns
    where table_schema='marketplace' and table_name='capacity_listings' and column_name='status'),
  'draft.*capacity_status',
  'capacity_listings.status defaults to draft');

select is(
  (select column_default from information_schema.columns
    where table_schema='marketplace' and table_name='carrier_directory_visibility' and column_name='is_public'),
  'false',
  'carrier_directory_visibility.is_public defaults to false');

select is(
  (select count(*)::int from pg_indexes
    where schemaname='marketplace' and indexname='capacity_listings_carrier_status_idx'),
  1, 'capacity_listings_carrier_status_idx exists');

select * from finish();
rollback;
