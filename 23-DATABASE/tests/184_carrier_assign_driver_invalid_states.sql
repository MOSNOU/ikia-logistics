-- v1.1 Phase B Test 184 — carrier_assign_driver dispatch-state guards.
--
-- Assertions (3):
--   1. Assigning to a 'draft' dispatch is blocked (P0001).
--   2. Assigning to a 'cancelled' dispatch is blocked (P0001).
--   3. Re-assigning once the trip has started (execution_status='accepted')
--      is blocked (P0001).

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '48840000-0000-0000-0000-0000000000e1', 'authenticated', 'authenticated', '184-carrieradmin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '48840000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '184-driver@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('48840000-0000-0000-0000-0000000000a1', 'tenant-184', 'تست', 'Test 184');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('48840000-0000-0000-0000-0000000000c1', '48840000-0000-0000-0000-0000000000a1',
   'carr-184', 'حمل', 'Carrier 184', 'carrier', 'active', 'IR'),
  ('48840000-0000-0000-0000-0000000000b1', '48840000-0000-0000-0000-0000000000a1',
   'buy-184', 'خریدار', 'Buyer 184', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48840000-0000-0000-0000-0000000000e1', r.id, 'organization', '48840000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '48840000-0000-0000-0000-0000000000d1', r.id, 'organization', '48840000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

insert into identity.user_profiles (id, tenant_id, full_name, status)
values ('48840000-0000-0000-0000-0000000000d1', '48840000-0000-0000-0000-0000000000a1', 'Demo Driver 184', 'active');
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status)
select '48840000-0000-0000-0000-0000000000a1', '48840000-0000-0000-0000-0000000000c1',
       '48840000-0000-0000-0000-0000000000d1', r.id, 'active'
  from identity.roles r where r.code = 'driver';

-- Three dispatches in non-assignable situations.
set local session_replication_role = replica;
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  -- draft
  ('48840000-0000-0000-0000-0000000000f1', '48840000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '48840000-0000-0000-0000-0000000000b1', '48840000-0000-0000-0000-0000000000c1', 'draft', null, null),
  -- cancelled
  ('48840000-0000-0000-0000-0000000000f2', '48840000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '48840000-0000-0000-0000-0000000000b1', '48840000-0000-0000-0000-0000000000c1', 'cancelled', null, null),
  -- released but already started (accepted)
  ('48840000-0000-0000-0000-0000000000f3', '48840000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '48840000-0000-0000-0000-0000000000b1', '48840000-0000-0000-0000-0000000000c1', 'released',
   '48840000-0000-0000-0000-0000000000d1', 'accepted');
set local session_replication_role = origin;

select plan(3);

select set_config('request.jwt.claims',
  jsonb_build_object('sub','48840000-0000-0000-0000-0000000000e1','role','authenticated',
                     'tenant_id','48840000-0000-0000-0000-0000000000a1',
                     'organization_id','48840000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '48840000-0000-0000-0000-0000000000e1', true);
set local role authenticated;

select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48840000-0000-0000-0000-0000000000f1''::uuid, ''48840000-0000-0000-0000-0000000000d1''::uuid)',
  'P0001', NULL, 'cannot assign a driver to a draft dispatch');

select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48840000-0000-0000-0000-0000000000f2''::uuid, ''48840000-0000-0000-0000-0000000000d1''::uuid)',
  'P0001', NULL, 'cannot assign a driver to a cancelled dispatch');

select throws_ok(
  'select * from dispatch.carrier_assign_driver(''48840000-0000-0000-0000-0000000000f3''::uuid, ''48840000-0000-0000-0000-0000000000d1''::uuid)',
  'P0001', NULL, 'cannot re-assign after the trip has started');

reset role;
select * from finish();
rollback;
