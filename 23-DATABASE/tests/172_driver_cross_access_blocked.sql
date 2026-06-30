-- CC-47 Test 172 — Cross-driver access is blocked.
--
-- Assertions (3):
--   1. driver B calling driver_get_trip on driver A's dispatch raises 42501
--   2. driver B calling driver_accept_trip on driver A's dispatch raises 42501
--   3. driver A can read their own trip detail (1 row)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '172-driverA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d2', 'authenticated', 'authenticated', '172-driverB@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-172', 'تست', 'Test 172');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-172', 'حمل', 'Carrier 172', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-172', 'خریدار', 'Buyer 172', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d2', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

set local session_replication_role = replica;
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'assigned');
set local session_replication_role = origin;

select plan(3);

-- Act as driver B.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d2','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d2', true);
set local role authenticated;

select throws_ok(
  'select * from dispatch.driver_get_trip(''47000000-0000-0000-0000-0000000000f1''::uuid)',
  '42501', NULL,
  'driver B cannot get_trip on driver A''s dispatch');

select throws_ok(
  'select dispatch.driver_accept_trip(''47000000-0000-0000-0000-0000000000f1''::uuid)',
  '42501', NULL,
  'driver B cannot accept driver A''s dispatch');

-- Act as driver A.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select is(
  (select count(*)::int from dispatch.driver_get_trip('47000000-0000-0000-0000-0000000000f1'::uuid)),
  1, 'driver A can read their own trip detail');

reset role;
select * from finish();
rollback;
