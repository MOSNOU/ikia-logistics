-- CC-47 Test 169 — Driver role seed.
--
-- Assertions (3):
--   1. identity.roles has code='driver'
--   2. its scope is 'organization'
--   3. it is a system role (is_system=true)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

select plan(3);

select ok(
  exists (select 1 from identity.roles where code = 'driver'),
  'driver role exists');

select is(
  (select scope::text from identity.roles where code = 'driver'),
  'organization', 'driver role scope is organization');

select is(
  (select is_system from identity.roles where code = 'driver'),
  true, 'driver role is a system role');

select * from finish();
rollback;
