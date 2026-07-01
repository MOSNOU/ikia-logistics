-- v1.1 Phase B Test 185 — carrier_assign_driver target-driver validation.
--
-- Assertions (4):
--   1. Target user without the driver role is blocked (42501).
--   2. Target driver scoped to ANOTHER organization is blocked (42501).
--   3. Target driver without an active membership in the carrier org is
--      blocked (42501).
--   4. Unknown (non-existent) target user is blocked (P0002).

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '48850000-0000-0000-0000-0000000000e1', 'authenticated', 'authenticated', '185-carrieradmin@example.com'),
  -- non-driver (has a membership + profile but no driver role)
  ('00000000-0000-0000-0000-000000000000',
   '48850000-0000-0000-0000-00000000000a', 'authenticated', 'authenticated', '185-nondriver@example.com'),
  -- driver scoped to another org (c2)
  ('00000000-0000-0000-0000-000000000000',
   '48850000-0000-0000-0000-00000000000b', 'authenticated', 'authenticated', '185-otherorgdriver@example.com'),
  -- driver of c1 but with no membership
  ('00000000-0000-0000-0000-000000000000',
   '48850000-0000-0000-0000-00000000000c', 'authenticated', 'authenticated', '185-nomember@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('48850000-0000-0000-0000-0000000000a1', 'tenant-185', 'تست', 'Test 185');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('48850000-0000-0000-0000-0000000000c1', '48850000-0000-0000-0000-0000000000a1',
   'carr-185-1', 'حمل۱', 'Carrier 185-1', 'carrier', 'active', 'IR'),
  ('48850000-0000-0000-0000-0000000000c2', '48850000-0000-0000-0000-0000000000a1',
   'carr-185-2', 'حمل۲', 'Carrier 185-2', 'carrier', 'active', 'IR'),
  ('48850000-0000-0000-0000-0000000000b1', '48850000-0000-0000-0000-0000000000a1',
   'buy-185', 'خریدار', 'Buyer 185', 'buyer', 'active', 'IR');

-- caller carrier_admin of c1.
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48850000-0000-0000-0000-0000000000e1', r.id, 'organization', '48850000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'carrier_admin';

-- non-driver: give a non-driver membership + active profile in c1, but NO driver role.
insert into identity.user_profiles (id, tenant_id, full_name, status)
values ('48850000-0000-0000-0000-00000000000a', '48850000-0000-0000-0000-0000000000a1', 'Non Driver 185', 'active');
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status)
select '48850000-0000-0000-0000-0000000000a1', '48850000-0000-0000-0000-0000000000c1',
       '48850000-0000-0000-0000-00000000000a', r.id, 'active'
  from identity.roles r where r.code = 'carrier_admin';

-- other-org driver: driver role + membership in c2 (not c1), active profile.
insert into identity.user_profiles (id, tenant_id, full_name, status)
values ('48850000-0000-0000-0000-00000000000b', '48850000-0000-0000-0000-0000000000a1', 'Other Org Driver 185', 'active');
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48850000-0000-0000-0000-00000000000b', r.id, 'organization', '48850000-0000-0000-0000-0000000000c2'
  from identity.roles r where r.code = 'driver';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status)
select '48850000-0000-0000-0000-0000000000a1', '48850000-0000-0000-0000-0000000000c2',
       '48850000-0000-0000-0000-00000000000b', r.id, 'active'
  from identity.roles r where r.code = 'driver';

-- no-member driver: driver role scoped to c1 + active profile, but no membership.
insert into identity.user_profiles (id, tenant_id, full_name, status)
values ('48850000-0000-0000-0000-00000000000c', '48850000-0000-0000-0000-0000000000a1', 'No Member Driver 185', 'active');
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48850000-0000-0000-0000-00000000000c', r.id, 'organization', '48850000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

set local session_replication_role = replica;
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('48850000-0000-0000-0000-0000000000f1', '48850000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '48850000-0000-0000-0000-0000000000b1', '48850000-0000-0000-0000-0000000000c1',
   'released', null, null);
set local session_replication_role = origin;

select plan(4);

select set_config('request.jwt.claims',
  jsonb_build_object('sub','48850000-0000-0000-0000-0000000000e1','role','authenticated',
                     'tenant_id','48850000-0000-0000-0000-0000000000a1',
                     'organization_id','48850000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '48850000-0000-0000-0000-0000000000e1', true);
set local role authenticated;

-- 1. non-driver target.
select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48850000-0000-0000-0000-0000000000f1''::uuid, ''48850000-0000-0000-0000-00000000000a''::uuid)',
  '42501', NULL, 'assigning a non-driver user is blocked');

-- 2. driver of another org.
select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48850000-0000-0000-0000-0000000000f1''::uuid, ''48850000-0000-0000-0000-00000000000b''::uuid)',
  '42501', NULL, 'assigning a driver from another org is blocked');

-- 3. driver of c1 with no membership.
select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48850000-0000-0000-0000-0000000000f1''::uuid, ''48850000-0000-0000-0000-00000000000c''::uuid)',
  '42501', NULL, 'assigning a driver with no active membership is blocked');

-- 4. unknown user id.
select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48850000-0000-0000-0000-0000000000f1''::uuid, ''48850000-0000-0000-0000-0000000fffff''::uuid)',
  'P0002', NULL, 'assigning an unknown user is blocked');

reset role;
select * from finish();
rollback;
