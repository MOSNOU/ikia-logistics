-- CC-47 Test 176 — Driver issue reporting.
--
-- Assertions (3):
--   1. driver_report_issue inserts an issue row
--   2. it also appends a driver_trip_events marker (reason starts 'issue:')
--   3. execution_status is unchanged by reporting an issue

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '176-driverA@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-176', 'تست', 'Test 176');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-176', 'حمل', 'Carrier 176', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-176', 'خریدار', 'Buyer 176', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';

set local session_replication_role = replica;
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'in_transit');
set local session_replication_role = origin;

select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select plan(3);

select dispatch.driver_report_issue(
  '47000000-0000-0000-0000-0000000000f1', 'delay', 2::smallint, 'border congestion');

select is(
  (select count(*)::int from dispatch.driver_trip_issues
    where dispatch_id = '47000000-0000-0000-0000-0000000000f1' and category = 'delay'),
  1, 'driver_report_issue inserted an issue row');

select is(
  (select count(*)::int from dispatch.driver_trip_events
    where dispatch_id = '47000000-0000-0000-0000-0000000000f1' and reason like 'issue:%'),
  1, 'driver_report_issue appended a ledger marker');

select is(
  (select execution_status::text from dispatch.dispatch_assignments
    where id = '47000000-0000-0000-0000-0000000000f1'),
  'in_transit', 'execution_status unchanged by issue report');

reset role;
select * from finish();
rollback;
