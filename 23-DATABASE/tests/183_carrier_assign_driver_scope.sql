-- v1.1 Phase B Test 183 — carrier_assign_driver caller authorization / scope.
--
-- Assertions (3):
--   1. A carrier_admin of a DIFFERENT carrier org cannot assign to this
--      dispatch (cross-carrier) — 42501.
--   2. A user with no carrier/admin role cannot assign — 42501.
--   3. A platform_admin CAN assign (admin convention) — succeeds.

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '48830000-0000-0000-0000-0000000000e2', 'authenticated', 'authenticated', '183-carrieradmin-c2@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '48830000-0000-0000-0000-0000000000e3', 'authenticated', 'authenticated', '183-norole@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '48830000-0000-0000-0000-0000000000ea', 'authenticated', 'authenticated', '183-platformadmin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '48830000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '183-driver@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('48830000-0000-0000-0000-0000000000a1', 'tenant-183', 'تست', 'Test 183');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('48830000-0000-0000-0000-0000000000c1', '48830000-0000-0000-0000-0000000000a1',
   'carr-183-1', 'حمل۱', 'Carrier 183-1', 'carrier', 'active', 'IR'),
  ('48830000-0000-0000-0000-0000000000c2', '48830000-0000-0000-0000-0000000000a1',
   'carr-183-2', 'حمل۲', 'Carrier 183-2', 'carrier', 'active', 'IR'),
  ('48830000-0000-0000-0000-0000000000b1', '48830000-0000-0000-0000-0000000000a1',
   'buy-183', 'خریدار', 'Buyer 183', 'buyer', 'active', 'IR');

-- Roles: carrier_admin of c2, platform_admin, driver of c1. The "norole" user
-- (…e3) deliberately gets no role.
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48830000-0000-0000-0000-0000000000e2', r.id, 'organization', '48830000-0000-0000-0000-0000000000c2'
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48830000-0000-0000-0000-0000000000ea', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48830000-0000-0000-0000-0000000000d1', r.id, 'organization', '48830000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

insert into identity.user_profiles (id, tenant_id, full_name, status)
values ('48830000-0000-0000-0000-0000000000d1', '48830000-0000-0000-0000-0000000000a1', 'Demo Driver 183', 'active');
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status)
select '48830000-0000-0000-0000-0000000000a1', '48830000-0000-0000-0000-0000000000c1',
       '48830000-0000-0000-0000-0000000000d1', r.id, 'active'
  from identity.roles r where r.code = 'driver';

set local session_replication_role = replica;
insert into marketplace.booking_requests
  (id, tenant_id, shipment_id, capacity_listing_id, buyer_organization_id,
   carrier_organization_id, status)
values
  ('48830000-0000-0000-0000-0000000000ba', '48830000-0000-0000-0000-0000000000a1',
   gen_random_uuid(), gen_random_uuid(),
   '48830000-0000-0000-0000-0000000000b1', '48830000-0000-0000-0000-0000000000c1', 'draft');
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('48830000-0000-0000-0000-0000000000f1', '48830000-0000-0000-0000-0000000000a1',
   '48830000-0000-0000-0000-0000000000ba',
   '48830000-0000-0000-0000-0000000000b1', '48830000-0000-0000-0000-0000000000c1',
   'released', null, null);
set local session_replication_role = origin;

select plan(3);

-- 1. Cross-carrier: carrier_admin of c2 assigning to c1's dispatch.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','48830000-0000-0000-0000-0000000000e2','role','authenticated',
                     'tenant_id','48830000-0000-0000-0000-0000000000a1',
                     'organization_id','48830000-0000-0000-0000-0000000000c2')::text, true);
select set_config('request.jwt.claim.sub', '48830000-0000-0000-0000-0000000000e2', true);
set local role authenticated;
select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48830000-0000-0000-0000-0000000000f1''::uuid, ''48830000-0000-0000-0000-0000000000d1''::uuid)',
  '42501', NULL, 'cross-carrier assignment is blocked');
reset role;

-- 2. No carrier/admin role.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','48830000-0000-0000-0000-0000000000e3','role','authenticated',
                     'tenant_id','48830000-0000-0000-0000-0000000000a1',
                     'organization_id','48830000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '48830000-0000-0000-0000-0000000000e3', true);
set local role authenticated;
select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48830000-0000-0000-0000-0000000000f1''::uuid, ''48830000-0000-0000-0000-0000000000d1''::uuid)',
  '42501', NULL, 'user without carrier/admin role is blocked');
reset role;

-- 3. Platform admin can assign.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','48830000-0000-0000-0000-0000000000ea','role','authenticated',
                     'tenant_id','48830000-0000-0000-0000-0000000000a1',
                     'organization_id','48830000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '48830000-0000-0000-0000-0000000000ea', true);
set local role authenticated;
select is(
  (select driver_user_id from dispatch.carrier_assign_driver(
     '48830000-0000-0000-0000-0000000000f1'::uuid,
     '48830000-0000-0000-0000-0000000000d1'::uuid)),
  '48830000-0000-0000-0000-0000000000d1'::uuid,
  'platform_admin can assign a driver');
reset role;

select * from finish();
rollback;
