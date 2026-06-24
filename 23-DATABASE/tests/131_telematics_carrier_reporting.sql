-- CC-45 Test 131 — Telematics carrier reporting.
--
-- Assertions (10):
--   1. start_session records session_started event
--   2. carrier_report_position inserts a row
--   3. position has correct lat/lng values
--   4. carrier_report_positions_batch inserts N rows
--   5. carrier_report_telemetry_event records a signal_lost event
--   6. carrier_report_telemetry_event rejects session_started (22023)
--   7. end_session records session_ended event
--   8. carrier_get_telemetry_snapshot returns latest position
--   9. report on draft-state dispatch raises P0001
--   10. non-owner carrier denied for any report (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

-- Fixture
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '131-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '131-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '131-other-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('45000000-0000-0000-0000-00000000000a', 'tenant-131', 'تست', 'Test 131');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-00000000000a',
   'buy-131', 'خریدار', 'Buyer 131', 'buyer', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000002a', '45000000-0000-0000-0000-00000000000a',
   'sup-131', 'تأمین', 'Supplier 131', 'supplier', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000003a', '45000000-0000-0000-0000-00000000000a',
   'carr-131', 'حمل', 'Carrier 131', 'carrier', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000003b', '45000000-0000-0000-0000-00000000000a',
   'carr-131b', 'حمل ب', 'Carrier 131B', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('45000000-0000-0000-0000-000000000001', '45000000-0000-0000-0000-00000000000a',
   '45000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000002', '45000000-0000-0000-0000-00000000000a',
   '45000000-0000-0000-0000-00000000003a', 'Carrier', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000003', '45000000-0000-0000-0000-00000000000a',
   '45000000-0000-0000-0000-00000000003b', 'OtherCarrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000000a', '45000000-0000-0000-0000-00000000001a',
       '45000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000001', r.id, 'organization', '45000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000000a', '45000000-0000-0000-0000-00000000003a',
       '45000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000002', r.id, 'organization', '45000000-0000-0000-0000-00000000003a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000000a', '45000000-0000-0000-0000-00000000003b',
       '45000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000003', r.id, 'organization', '45000000-0000-0000-0000-00000000003b'
  from identity.roles r where r.code = 'carrier_admin';

-- Shipment chain (compressed)
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('45000000-0000-0000-0000-00000000004a', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-000000000001',
        'RFQ-131', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('45000000-0000-0000-0000-00000000004b', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000002a', '45000000-0000-0000-0000-00000000004a',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000002a'),
        'OF-131', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('45000000-0000-0000-0000-00000000004c', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-00000000004a',
        '45000000-0000-0000-0000-00000000004b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('45000000-0000-0000-0000-00000000004d', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-00000000004a',
        '45000000-0000-0000-0000-00000000004b', '45000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000002a'),
        'PREP-131', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('45000000-0000-0000-0000-00000000005a', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-00000000004d',
        '45000000-0000-0000-0000-00000000004a', '45000000-0000-0000-0000-00000000004b',
        '45000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000002a'),
        'CTR-131', 'executed', 'spot', 'CT-131', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('45000000-0000-0000-0000-00000000006a', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-00000000005a',
        '45000000-0000-0000-0000-00000000004a', '45000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000002a'),
        'SH-131', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('45000000-0000-0000-0000-00000000000a', '45000000-0000-0000-0000-00000000003a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('45000000-0000-0000-0000-00000000003a', '45000000-0000-0000-0000-00000000000a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('45000000-0000-0000-0000-00000000007a', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000003a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Booking → confirmed.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
declare v_b uuid;
begin
  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '45000000-0000-0000-0000-00000000006a',
    p_capacity_listing_id => '45000000-0000-0000-0000-00000000007a');
  perform set_config('test.booking_id_131', v_b::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000002', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_131')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_131')::uuid);
end $$;

reset role;
-- Carrier creates dispatch (status=assigned because all placeholders provided).
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000002', true);
set local role authenticated;

do $$
declare v_d uuid;
begin
  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_131')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform set_config('test.dispatch_id_131', v_d::text, true);
end $$;

-- Also create a draft dispatch to test the eligibility gate.
-- Second confirmed booking on a second shipment.
reset role;
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('45000000-0000-0000-0000-00000000006b', '45000000-0000-0000-0000-00000000000a',
        '45000000-0000-0000-0000-00000000001a', '45000000-0000-0000-0000-00000000005a',
        '45000000-0000-0000-0000-00000000004a', '45000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000002a'),
        'SH-131-B', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
declare v_b2 uuid;
begin
  v_b2 := marketplace.buyer_create_booking_request(
    p_shipment_id => '45000000-0000-0000-0000-00000000006b',
    p_capacity_listing_id => '45000000-0000-0000-0000-00000000007a');
  perform set_config('test.booking_id_131b', v_b2::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000002', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_131b')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_131b')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000002', true);
set local role authenticated;

-- Draft dispatch (no placeholders).
do $$
declare v_d uuid;
begin
  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_131b')::uuid);
  perform set_config('test.dispatch_id_131_draft', v_d::text, true);
end $$;

select plan(10);

-- 1. Start session records event.
do $$
begin
  perform telematics.carrier_start_telemetry_session(
    current_setting('test.dispatch_id_131')::uuid, null);
end $$;

select is(
  (select count(*)::int from telematics.telemetry_events
    where dispatch_id = current_setting('test.dispatch_id_131')::uuid
      and event_type = 'session_started'),
  1, 'start_session records session_started event');

-- 2/3. Report single position.
do $$
begin
  perform telematics.carrier_report_position(
    p_dispatch_id => current_setting('test.dispatch_id_131')::uuid,
    p_latitude => 35.6892,
    p_longitude => 51.3890,
    p_reported_at => now(),
    p_speed_kmh => 60,
    p_heading_degrees => 270);
end $$;

select is(
  (select count(*)::int from telematics.position_reports
    where dispatch_id = current_setting('test.dispatch_id_131')::uuid),
  1, 'report_position inserts one row');

select is(
  (select latitude from telematics.position_reports
    where dispatch_id = current_setting('test.dispatch_id_131')::uuid limit 1),
  35.689200, 'position latitude is recorded with correct value');

-- 4. Batch report.
do $$
begin
  perform telematics.carrier_report_positions_batch(
    current_setting('test.dispatch_id_131')::uuid,
    jsonb_build_array(
      jsonb_build_object('lat', 35.70, 'lng', 51.40, 'reported_at', now()::text),
      jsonb_build_object('lat', 35.71, 'lng', 51.41, 'reported_at', now()::text),
      jsonb_build_object('lat', 35.72, 'lng', 51.42, 'reported_at', now()::text)));
end $$;

select is(
  (select count(*)::int from telematics.position_reports
    where dispatch_id = current_setting('test.dispatch_id_131')::uuid),
  4, 'batch report adds 3 more rows (4 total)');

-- 5. Signal lost event.
do $$
begin
  perform telematics.carrier_report_telemetry_event(
    current_setting('test.dispatch_id_131')::uuid,
    'signal_lost', 'tunnel', '{}'::jsonb);
end $$;

select is(
  (select count(*)::int from telematics.telemetry_events
    where dispatch_id = current_setting('test.dispatch_id_131')::uuid
      and event_type = 'signal_lost'),
  1, 'report_telemetry_event records signal_lost');

-- 6. Reject session_started via generic event RPC. Use a real dispatch id so
-- the pre-condition gate passes and the function reaches the event-type check.
select throws_ok(
  'select telematics.carrier_report_telemetry_event('''
    || current_setting('test.dispatch_id_131')
    || '''::uuid, ''session_started''::telematics.telemetry_event_type, null, ''{}''::jsonb)',
  '22023', NULL,
  'generic event RPC rejects session_started');

-- 7. End session.
do $$
begin
  perform telematics.carrier_end_telemetry_session(
    current_setting('test.dispatch_id_131')::uuid, 'done');
end $$;

select is(
  (select count(*)::int from telematics.telemetry_events
    where dispatch_id = current_setting('test.dispatch_id_131')::uuid
      and event_type = 'session_ended'),
  1, 'end_session records session_ended event');

-- 8. Snapshot returns latest position.
select ok(
  (telematics.carrier_get_telemetry_snapshot(
    current_setting('test.dispatch_id_131')::uuid
  )->'latest_position') is not null,
  'snapshot returns the latest_position object');

-- 9. Report on draft dispatch → P0001.
select throws_ok(
  'select telematics.carrier_report_position('''
    || current_setting('test.dispatch_id_131_draft')
    || '''::uuid, 35.0, 51.0, now(), null, null, null, null, null)',
  'P0001', NULL,
  'report on draft-state dispatch raises P0001');

-- 10. Non-owner carrier denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000003','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000000a',
                     'organization_id','45000000-0000-0000-0000-00000000003b')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000003', true);
set local role authenticated;

select throws_ok(
  'select telematics.carrier_report_position('''
    || current_setting('test.dispatch_id_131')
    || '''::uuid, 35.0, 51.0, now(), null, null, null, null, null)',
  '42501', NULL,
  'non-owner carrier denied');

reset role;
select * from finish();
rollback;
