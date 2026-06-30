-- CC-47 Test 174 — Invalid (out-of-order) transition is rejected.
--
-- Assertions (2):
--   1. driver_start_transit while status='accepted' raises P0001
--   2. the valid transition from 'accepted' (arrive_pickup) still works

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '174-driverA@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-174', 'تست', 'Test 174');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-174', 'حمل', 'Carrier 174', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-174', 'خریدار', 'Buyer 174', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
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
   'released', '47000000-0000-0000-0000-0000000000d1', 'accepted');
set local session_replication_role = origin;

select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select plan(2);

select throws_ok(
  'select dispatch.driver_start_transit(''47000000-0000-0000-0000-0000000000f1''::uuid)',
  'P0001', NULL,
  'start_transit from accepted raises P0001 (invalid transition)');

select is(
  (select dispatch.driver_arrive_pickup('47000000-0000-0000-0000-0000000000f1')::text),
  'arrived_at_pickup', 'valid transition accepted → arrived_at_pickup still works');

reset role;
select * from finish();
rollback;
