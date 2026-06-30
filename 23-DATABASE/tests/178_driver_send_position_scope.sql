-- CC-47 Test 178 — Driver position reporting scope.
--
-- Assertions (4):
--   1. driver A on own active trip inserts a position_reports row
--   2. that row has source='driver_app' and reported_by = driver A
--   3. driver B sending position on driver A's trip raises 42501
--   4. after the trip is 'completed', sending a position raises P0001

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '178-driverA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d2', 'authenticated', 'authenticated', '178-driverB@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-178', 'تست', 'Test 178');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-178', 'حمل', 'Carrier 178', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-178', 'خریدار', 'Buyer 178', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d2', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

set local session_replication_role = replica;
insert into marketplace.booking_requests
  (id, tenant_id, shipment_id, capacity_listing_id, buyer_organization_id, carrier_organization_id, status)
values ('47000000-0000-0000-0000-0000000000bb', '47000000-0000-0000-0000-0000000000a1',
        '47000000-0000-0000-0000-00000000bb01', '47000000-0000-0000-0000-00000000bb02',
        '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1', 'buyer_confirmed');
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-0000000000a1', '47000000-0000-0000-0000-0000000000bb',
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'in_transit');
set local session_replication_role = origin;

select plan(4);

-- Driver A sends a position on own active trip.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select dispatch.driver_send_position(
  '47000000-0000-0000-0000-0000000000f1', 35.7, 51.4, now(), 5.0, 60.0, 90);

reset role;

-- 1 + 2. Verify the inserted row (as superuser; position_reports RLS is org-scoped).
select is(
  (select count(*)::int from telematics.position_reports
    where dispatch_id = '47000000-0000-0000-0000-0000000000f1'),
  1, 'driver position inserted exactly one position_reports row');

select is(
  (select source || '|' || reported_by::text from telematics.position_reports
    where dispatch_id = '47000000-0000-0000-0000-0000000000f1'),
  'driver_app|47000000-0000-0000-0000-0000000000d1',
  'position row has source=driver_app and reported_by=driver A');

-- 3. Driver B sends position on A's trip → 42501.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d2','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d2', true);
set local role authenticated;

select throws_ok(
  'select dispatch.driver_send_position(''47000000-0000-0000-0000-0000000000f1''::uuid,
     35.7, 51.4, now())',
  '42501', NULL,
  'driver B cannot send position on driver A''s trip');

reset role;

-- 4. Move the trip to 'completed', then driver A sending a position → P0001.
update dispatch.dispatch_assignments
   set execution_status = 'completed'
 where id = '47000000-0000-0000-0000-0000000000f1';

select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select throws_ok(
  'select dispatch.driver_send_position(''47000000-0000-0000-0000-0000000000f1''::uuid,
     35.7, 51.4, now())',
  'P0001', NULL,
  'sending position after completion raises P0001');

reset role;
select * from finish();
rollback;
