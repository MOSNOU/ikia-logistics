-- CC-47 Test 177 — POD attachment + completion gate.
--
-- Assertions (4):
--   1. attaching a POD whose file is owned by another user raises 42501
--   2. driver A attaching a POD to driver B's trip raises 42501
--   3. driver_complete_trip with zero PODs raises P0001
--   4. after attaching a valid (own) POD, completion succeeds

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '177-driverA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d2', 'authenticated', 'authenticated', '177-driverB@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-177', 'تست', 'Test 177');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-177', 'حمل', 'Carrier 177', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-177', 'خریدار', 'Buyer 177', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d2', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

-- fileA owned by A, fileB owned by B.
insert into app_storage.files
  (id, tenant_id, organization_id, uploaded_by_user_id, bucket, object_key, filename, status)
values
  ('47000000-0000-0000-0000-00000000aa01', '47000000-0000-0000-0000-0000000000a1',
   '47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000d1',
   'app-documents', '177/podA.jpg', 'podA.jpg', 'uploaded'),
  ('47000000-0000-0000-0000-00000000aa02', '47000000-0000-0000-0000-0000000000a1',
   '47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000d2',
   'app-documents', '177/podB.jpg', 'podB.jpg', 'uploaded');

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
  -- DA1 belongs to driver A, in 'delivered' (ready to complete)
  ('47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-0000000000a1', '47000000-0000-0000-0000-0000000000bb',
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'delivered'),
  -- DA2 belongs to driver B
  ('47000000-0000-0000-0000-0000000000f2', '47000000-0000-0000-0000-0000000000a1', '47000000-0000-0000-0000-0000000000bb',
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d2', 'delivered');
set local session_replication_role = origin;

select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select plan(4);

-- 1. Attach a POD whose file is owned by B → 42501.
select throws_ok(
  'select dispatch.driver_attach_pod(''47000000-0000-0000-0000-0000000000f1''::uuid,
     ''47000000-0000-0000-0000-00000000aa02''::uuid, ''delivery_photo''::dispatch.trip_pod_kind)',
  '42501', NULL,
  'attaching a POD file owned by another user raises 42501');

-- 2. Attach a (own) POD to driver B's trip → 42501.
select throws_ok(
  'select dispatch.driver_attach_pod(''47000000-0000-0000-0000-0000000000f2''::uuid,
     ''47000000-0000-0000-0000-00000000aa01''::uuid, ''delivery_photo''::dispatch.trip_pod_kind)',
  '42501', NULL,
  'attaching a POD to another driver''s trip raises 42501');

-- 3. Complete with zero PODs → P0001.
select throws_ok(
  'select dispatch.driver_complete_trip(''47000000-0000-0000-0000-0000000000f1''::uuid)',
  'P0001', NULL,
  'complete with zero PODs raises P0001');

-- 4. Attach a valid POD, then complete succeeds.
select dispatch.driver_attach_pod(
  '47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-00000000aa01', 'delivery_photo');

select is(
  (select dispatch.driver_complete_trip('47000000-0000-0000-0000-0000000000f1')::text),
  'completed', 'completion succeeds once a valid POD is attached');

reset role;
select * from finish();
rollback;
