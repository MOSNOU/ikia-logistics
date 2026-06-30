-- CC-47 Test 171 — Driver trip list scoping.
--
-- Assertions (3):
--   1. driver A sees exactly their own 2 assigned trips
--   2. driver B's trip is not visible to driver A
--   3. an unassigned trip is not visible to driver A

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

-- Fixture (as superuser, pre-set-role) ------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '171-driverA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d2', 'authenticated', 'authenticated', '171-driverB@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-171', 'تست', 'Test 171');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-171', 'حمل', 'Carrier 171', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-171', 'خریدار', 'Buyer 171', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d2', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

-- Dispatch rows inserted directly (FK triggers bypassed via replica role).
set local session_replication_role = replica;
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'assigned'),
  ('47000000-0000-0000-0000-0000000000f2', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'accepted'),
  ('47000000-0000-0000-0000-0000000000f3', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d2', 'assigned'),
  ('47000000-0000-0000-0000-0000000000f4', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', null, null);
set local session_replication_role = origin;

-- Act as driver A.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select plan(3);

select is(
  (select count(*)::int from dispatch.driver_list_my_trips()),
  2, 'driver A sees exactly their own 2 trips');

select is(
  (select count(*)::int from dispatch.driver_list_my_trips()
    where dispatch_id = '47000000-0000-0000-0000-0000000000f3'),
  0, 'driver B''s trip is not visible to driver A');

select is(
  (select count(*)::int from dispatch.driver_list_my_trips()
    where dispatch_id = '47000000-0000-0000-0000-0000000000f4'),
  0, 'unassigned trip is not visible to driver A');

reset role;
select * from finish();
rollback;
