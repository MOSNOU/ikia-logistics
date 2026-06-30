-- CC-47 Test 173 — Full happy-path execution lifecycle.
--
-- Assertions (10):
--   1-9. each milestone transition returns the expected execution_status
--   10.  the driver_trip_events ledger has exactly 9 rows (one per transition)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '173-driverA@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-173', 'تست', 'Test 173');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-173', 'حمل', 'Carrier 173', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-173', 'خریدار', 'Buyer 173', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

-- A file owned by driver A, used as the POD before completion.
insert into app_storage.files
  (id, tenant_id, organization_id, uploaded_by_user_id, bucket, object_key, filename, status)
values
  ('47000000-0000-0000-0000-00000000aa01', '47000000-0000-0000-0000-0000000000a1',
   '47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000d1',
   'app-documents', '173/pod.jpg', 'pod.jpg', 'uploaded');

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
   'released', '47000000-0000-0000-0000-0000000000d1', 'assigned');
set local session_replication_role = origin;

select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select plan(10);

select is((select dispatch.driver_accept_trip('47000000-0000-0000-0000-0000000000f1')::text),
          'accepted', 'assigned → accepted');
select is((select dispatch.driver_arrive_pickup('47000000-0000-0000-0000-0000000000f1', 35.7, 51.4)::text),
          'arrived_at_pickup', 'accepted → arrived_at_pickup');
select is((select dispatch.driver_start_loading('47000000-0000-0000-0000-0000000000f1')::text),
          'loading_started', 'arrived_at_pickup → loading_started');
select is((select dispatch.driver_confirm_loaded('47000000-0000-0000-0000-0000000000f1')::text),
          'loaded', 'loading_started → loaded');
select is((select dispatch.driver_start_transit('47000000-0000-0000-0000-0000000000f1', 35.8, 51.5)::text),
          'in_transit', 'loaded → in_transit');
select is((select dispatch.driver_arrive_delivery('47000000-0000-0000-0000-0000000000f1', 36.0, 52.0)::text),
          'arrived_at_delivery', 'in_transit → arrived_at_delivery');
select is((select dispatch.driver_start_unloading('47000000-0000-0000-0000-0000000000f1')::text),
          'unloading_started', 'arrived_at_delivery → unloading_started');
select is((select dispatch.driver_confirm_delivered('47000000-0000-0000-0000-0000000000f1')::text),
          'delivered', 'unloading_started → delivered');

-- Attach the POD, then complete.
select dispatch.driver_attach_pod(
  '47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-00000000aa01', 'delivery_photo');

select is((select dispatch.driver_complete_trip('47000000-0000-0000-0000-0000000000f1')::text),
          'completed', 'delivered → completed');

select is(
  (select count(*)::int from dispatch.driver_trip_events
    where dispatch_id = '47000000-0000-0000-0000-0000000000f1'),
  9, 'driver_trip_events has one row per transition (9)');

reset role;
select * from finish();
rollback;
