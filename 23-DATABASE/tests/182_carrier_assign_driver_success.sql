-- v1.1 Phase B Test 182 — carrier_assign_driver happy path.
--
-- Assertions (4):
--   1. A carrier_admin can assign a same-org driver; the RPC returns the driver.
--   2. The dispatch row now has driver_user_id set.
--   3. execution_status was initialised to 'assigned'.
--   4. The assigned driver can now see the trip via driver_list_my_trips.

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

-- Fixtures -------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '48820000-0000-0000-0000-0000000000e1', 'authenticated', 'authenticated', '182-carrieradmin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '48820000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '182-driver@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('48820000-0000-0000-0000-0000000000a1', 'tenant-182', 'تست', 'Test 182');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('48820000-0000-0000-0000-0000000000c1', '48820000-0000-0000-0000-0000000000a1',
   'carr-182', 'حمل', 'Carrier 182', 'carrier', 'active', 'IR'),
  ('48820000-0000-0000-0000-0000000000b1', '48820000-0000-0000-0000-0000000000a1',
   'buy-182', 'خریدار', 'Buyer 182', 'buyer', 'active', 'IR');

-- caller = carrier_admin scoped to carrier org; target = driver scoped to same org.
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48820000-0000-0000-0000-0000000000e1', r.id, 'organization', '48820000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48820000-0000-0000-0000-0000000000d1', r.id, 'organization', '48820000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

-- Active profile + active membership for the driver.
insert into identity.user_profiles (id, tenant_id, full_name, status)
values ('48820000-0000-0000-0000-0000000000d1', '48820000-0000-0000-0000-0000000000a1', 'Demo Driver 182', 'active');
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status)
select '48820000-0000-0000-0000-0000000000a1', '48820000-0000-0000-0000-0000000000c1',
       '48820000-0000-0000-0000-0000000000d1', r.id, 'active'
  from identity.roles r where r.code = 'driver';

-- Released dispatch, no driver yet. A real booking_requests row backs the
-- dispatch FK (the RPC re-validates it on UPDATE); its own upstream FKs
-- (shipment / capacity) are bypassed under replica.
set local session_replication_role = replica;
insert into marketplace.booking_requests
  (id, tenant_id, shipment_id, capacity_listing_id, buyer_organization_id,
   carrier_organization_id, status)
values
  ('48820000-0000-0000-0000-0000000000ba', '48820000-0000-0000-0000-0000000000a1',
   gen_random_uuid(), gen_random_uuid(),
   '48820000-0000-0000-0000-0000000000b1', '48820000-0000-0000-0000-0000000000c1', 'draft');
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('48820000-0000-0000-0000-0000000000f1', '48820000-0000-0000-0000-0000000000a1',
   '48820000-0000-0000-0000-0000000000ba',
   '48820000-0000-0000-0000-0000000000b1', '48820000-0000-0000-0000-0000000000c1',
   'released', null, null);
set local session_replication_role = origin;

select plan(4);

-- Act as the carrier_admin.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','48820000-0000-0000-0000-0000000000e1','role','authenticated',
                     'tenant_id','48820000-0000-0000-0000-0000000000a1',
                     'organization_id','48820000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '48820000-0000-0000-0000-0000000000e1', true);
set local role authenticated;

-- 1. RPC returns the assigned driver.
select is(
  (select driver_user_id from dispatch.carrier_assign_driver(
     '48820000-0000-0000-0000-0000000000f1'::uuid,
     '48820000-0000-0000-0000-0000000000d1'::uuid)),
  '48820000-0000-0000-0000-0000000000d1'::uuid,
  'carrier_assign_driver returns the assigned driver');

reset role;

-- 2. Row persisted the driver.
select is(
  (select driver_user_id from dispatch.dispatch_assignments
    where id = '48820000-0000-0000-0000-0000000000f1'),
  '48820000-0000-0000-0000-0000000000d1'::uuid,
  'dispatch row now has driver_user_id set');

-- 3. execution_status initialised to assigned.
select is(
  (select execution_status::text from dispatch.dispatch_assignments
    where id = '48820000-0000-0000-0000-0000000000f1'),
  'assigned', 'execution_status initialised to assigned');

-- 4. Driver can now see the trip.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','48820000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','48820000-0000-0000-0000-0000000000a1',
                     'organization_id','48820000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '48820000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select is(
  (select count(*)::int from dispatch.driver_list_my_trips()
    where dispatch_id = '48820000-0000-0000-0000-0000000000f1'),
  1, 'assigned driver can see the trip via driver_list_my_trips');

reset role;
select * from finish();
rollback;
