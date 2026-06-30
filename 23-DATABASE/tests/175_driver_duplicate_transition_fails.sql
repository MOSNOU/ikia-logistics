-- CC-47 Test 175 — Duplicate transition is rejected.
--
-- Assertions (2):
--   1. first driver_accept_trip succeeds (assigned → accepted)
--   2. second driver_accept_trip raises P0001 (already accepted)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '175-driverA@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-175', 'تست', 'Test 175');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-175', 'حمل', 'Carrier 175', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-175', 'خریدار', 'Buyer 175', 'buyer', 'active', 'IR');

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
   'released', '47000000-0000-0000-0000-0000000000d1', 'assigned');
set local session_replication_role = origin;

select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select plan(2);

select is(
  (select dispatch.driver_accept_trip('47000000-0000-0000-0000-0000000000f1')::text),
  'accepted', 'first accept succeeds');

select throws_ok(
  'select dispatch.driver_accept_trip(''47000000-0000-0000-0000-0000000000f1''::uuid)',
  'P0001', NULL,
  'second accept raises P0001');

reset role;
select * from finish();
rollback;
