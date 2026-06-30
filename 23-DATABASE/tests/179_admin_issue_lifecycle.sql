-- CC-47 Test 179 — Admin/ops issue lifecycle.
--
-- Assertions (5):
--   1. operations_user ack moves the issue open → acknowledged
--   2. ack stamps acknowledged_by + acknowledged_at
--   3. operations_user resolve moves it → resolved
--   4. resolve stamps resolved_by + resolved_at + note
--   5. a plain driver calling admin_ack_driver_issue raises 42501

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', '179-driverA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '47000000-0000-0000-0000-0000000000e1', 'authenticated', 'authenticated', '179-ops@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('47000000-0000-0000-0000-0000000000a1', 'tenant-179', 'تست', 'Test 179');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('47000000-0000-0000-0000-0000000000c1', '47000000-0000-0000-0000-0000000000a1',
   'carr-179', 'حمل', 'Carrier 179', 'carrier', 'active', 'IR'),
  ('47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000a1',
   'buy-179', 'خریدار', 'Buyer 179', 'buyer', 'active', 'IR');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000d1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'driver';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '47000000-0000-0000-0000-0000000000e1', r.id, 'organization', '47000000-0000-0000-0000-0000000000c1'
  from identity.roles r where r.code = 'operations_user';

set local session_replication_role = replica;
insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status)
values
  ('47000000-0000-0000-0000-0000000000f1', '47000000-0000-0000-0000-0000000000a1', gen_random_uuid(),
   '47000000-0000-0000-0000-0000000000b1', '47000000-0000-0000-0000-0000000000c1',
   'released', '47000000-0000-0000-0000-0000000000d1', 'in_transit');
set local session_replication_role = origin;

-- Driver A reports an issue.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

do $$
declare v_issue uuid;
begin
  v_issue := dispatch.driver_report_issue(
    '47000000-0000-0000-0000-0000000000f1', 'vehicle', 3::smallint, 'flat tyre');
  perform set_config('test.issue_id_179', v_issue::text, true);
end $$;

reset role;

select plan(5);

-- Ops user acknowledges.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000e1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000e1', true);
set local role authenticated;

select is(
  (select dispatch.admin_ack_driver_issue(current_setting('test.issue_id_179')::uuid)::text),
  'acknowledged', 'ops ack moves issue open → acknowledged');

select is(
  (select (acknowledged_by = '47000000-0000-0000-0000-0000000000e1' and acknowledged_at is not null)
     from dispatch.driver_trip_issues where id = current_setting('test.issue_id_179')::uuid),
  true, 'ack stamps acknowledged_by + acknowledged_at');

select is(
  (select dispatch.admin_resolve_driver_issue(
     current_setting('test.issue_id_179')::uuid, 'tyre replaced')::text),
  'resolved', 'ops resolve moves issue → resolved');

select is(
  (select (resolved_by = '47000000-0000-0000-0000-0000000000e1'
           and resolved_at is not null and resolution_note = 'tyre replaced')
     from dispatch.driver_trip_issues where id = current_setting('test.issue_id_179')::uuid),
  true, 'resolve stamps resolved_by + resolved_at + note');

reset role;

-- Plain driver cannot ack.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','47000000-0000-0000-0000-0000000000d1','role','authenticated',
                     'tenant_id','47000000-0000-0000-0000-0000000000a1',
                     'organization_id','47000000-0000-0000-0000-0000000000c1')::text, true);
select set_config('request.jwt.claim.sub', '47000000-0000-0000-0000-0000000000d1', true);
set local role authenticated;

select throws_ok(
  'select dispatch.admin_ack_driver_issue('''
    || current_setting('test.issue_id_179') || '''::uuid)',
  '42501', NULL,
  'a plain driver cannot call admin_ack_driver_issue');

reset role;
select * from finish();
rollback;
