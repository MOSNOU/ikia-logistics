-- CC-53 Test 135 — telematics.carrier_list_my_telemetry_session_statuses
--
-- Assertions (12):
--   1. function exists with expected signature
--   2. function is SECURITY DEFINER
--   3. authenticated has EXECUTE
--   4. carrier A sees exactly their own 2 dispatches (no carrier B)
--   5. carrier A querying carrier B's dispatch id returns 0 rows
--   6. session_active = true for A1 (latest is session_started, no end)
--   7. session_active = false for A2 (latest is session_ended)
--   8. staleness_status = 'fresh' for A1 (recent position)
--   9. staleness_status = 'stale' for A2 (old position)
--  10. position_count is correct for A1
--  11. event_count is correct for A1 (start + signal_lost = 2)
--  12. staleness_status = 'missing' for B1 (no positions, run as carrier B)
--
-- Note on anon: the project does NOT revoke PUBLIC EXECUTE from telematics
-- audience RPCs (CC-45 functions inherit PUBLIC EXECUTE). Authorization is
-- enforced inside each SECURITY DEFINER body via identity.has_role(...) /
-- identity.current_organization_id(). Asserting "anon has no EXECUTE" would
-- contradict the established CC-45 posture, so it is omitted here.

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '135-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '135-carrier-a@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '135-carrier-b@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000000a', 'tenant-135', 'تست', 'Test 135');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000000a',
   'buy-135', 'خریدار', 'Buyer 135', 'buyer', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000002a', '53000000-0000-0000-0000-00000000000a',
   'sup-135', 'تأمین', 'Supplier 135', 'supplier', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000003a', '53000000-0000-0000-0000-00000000000a',
   'carr-135a', 'حمل A', 'Carrier 135A', 'carrier', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000003b', '53000000-0000-0000-0000-00000000000a',
   'carr-135b', 'حمل B', 'Carrier 135B', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('53000000-0000-0000-0000-000000000001', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000002', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000003a', 'CarrierA', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000003', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000003b', 'CarrierB', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000000a', '53000000-0000-0000-0000-00000000001a',
       '53000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000001', r.id, 'organization', '53000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000000a', '53000000-0000-0000-0000-00000000003a',
       '53000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000002', r.id, 'organization', '53000000-0000-0000-0000-00000000003a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000000a', '53000000-0000-0000-0000-00000000003b',
       '53000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000003', r.id, 'organization', '53000000-0000-0000-0000-00000000003b'
  from identity.roles r where r.code = 'carrier_admin';

-- Shared shipment chain (compressed).
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('53000000-0000-0000-0000-00000000004a', '53000000-0000-0000-0000-00000000000a',
        '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-000000000001',
        'RFQ-135', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('53000000-0000-0000-0000-00000000004b', '53000000-0000-0000-0000-00000000000a',
        '53000000-0000-0000-0000-00000000002a', '53000000-0000-0000-0000-00000000004a',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000002a'),
        'OF-135', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('53000000-0000-0000-0000-00000000004c', '53000000-0000-0000-0000-00000000000a',
        '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000004a',
        '53000000-0000-0000-0000-00000000004b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('53000000-0000-0000-0000-00000000004d', '53000000-0000-0000-0000-00000000000a',
        '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000004a',
        '53000000-0000-0000-0000-00000000004b', '53000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000002a'),
        'PREP-135', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('53000000-0000-0000-0000-00000000005a', '53000000-0000-0000-0000-00000000000a',
        '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000004d',
        '53000000-0000-0000-0000-00000000004a', '53000000-0000-0000-0000-00000000004b',
        '53000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000002a'),
        'CTR-135', 'executed', 'spot', 'CT-135', 'USD', now());

-- Three shipments: A1 / A2 belong to carrier A, B1 belongs to carrier B.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values
  ('53000000-0000-0000-0000-00000000006a', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000005a',
   '53000000-0000-0000-0000-00000000004a', '53000000-0000-0000-0000-00000000004b',
   (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000002a'),
   'SH-135-A1', 'planned', 'road', 'IR', 'DE', now() + interval '7 days'),
  ('53000000-0000-0000-0000-00000000006b', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000005a',
   '53000000-0000-0000-0000-00000000004a', '53000000-0000-0000-0000-00000000004b',
   (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000002a'),
   'SH-135-A2', 'planned', 'road', 'IR', 'DE', now() + interval '7 days'),
  ('53000000-0000-0000-0000-00000000006c', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000001a', '53000000-0000-0000-0000-00000000005a',
   '53000000-0000-0000-0000-00000000004a', '53000000-0000-0000-0000-00000000004b',
   (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000002a'),
   'SH-135-B1', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- Two carrier profiles + visibility + two capacity listings (one per carrier).
insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes) values
  ('53000000-0000-0000-0000-00000000000a', '53000000-0000-0000-0000-00000000003a',
   'حمل A', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]),
  ('53000000-0000-0000-0000-00000000000a', '53000000-0000-0000-0000-00000000003b',
   'حمل B', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);

insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at) values
  ('53000000-0000-0000-0000-00000000003a', '53000000-0000-0000-0000-00000000000a', true, now()),
  ('53000000-0000-0000-0000-00000000003b', '53000000-0000-0000-0000-00000000000a', true, now());

insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status) values
  ('53000000-0000-0000-0000-00000000007a', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000003a', 'road', 'IR'::citext, 'DE'::citext,
   now() - interval '1 day', now() + interval '30 days', 'active'),
  ('53000000-0000-0000-0000-00000000007b', '53000000-0000-0000-0000-00000000000a',
   '53000000-0000-0000-0000-00000000003b', 'road', 'IR'::citext, 'DE'::citext,
   now() - interval '1 day', now() + interval '30 days', 'active');

-- ---------------------------------------------------------------------------
-- Bookings → confirmed; carriers create dispatches.
-- ---------------------------------------------------------------------------
-- Three bookings (A1, A2, B1).
do $$
declare v_b uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000001', true);
  set local role authenticated;

  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '53000000-0000-0000-0000-00000000006a',
    p_capacity_listing_id => '53000000-0000-0000-0000-00000000007a');
  perform set_config('test.booking_id_135_a1', v_b::text, true);

  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '53000000-0000-0000-0000-00000000006b',
    p_capacity_listing_id => '53000000-0000-0000-0000-00000000007a');
  perform set_config('test.booking_id_135_a2', v_b::text, true);

  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '53000000-0000-0000-0000-00000000006c',
    p_capacity_listing_id => '53000000-0000-0000-0000-00000000007b');
  perform set_config('test.booking_id_135_b1', v_b::text, true);

  reset role;
end $$;

-- Carrier A accepts A1 + A2; Carrier B accepts B1.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000003a')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_135_a1')::uuid, null);
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_135_a2')::uuid, null);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000003b')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_135_b1')::uuid, null);
  reset role;
end $$;

-- Buyer confirms all three.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_135_a1')::uuid);
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_135_a2')::uuid);
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_135_b1')::uuid);
  reset role;
end $$;

-- Carrier A creates dispatches A1 + A2 (placeholders so status=assigned).
do $$
declare v_d uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000003a')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000002', true);
  set local role authenticated;

  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_135_a1')::uuid,
    p_vehicle_reference => 'V-A1', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform set_config('test.dispatch_id_135_a1', v_d::text, true);

  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_135_a2')::uuid,
    p_vehicle_reference => 'V-A2', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform set_config('test.dispatch_id_135_a2', v_d::text, true);

  reset role;
end $$;

-- Carrier B creates dispatch B1.
do $$
declare v_d uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000003b')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000003', true);
  set local role authenticated;

  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_135_b1')::uuid,
    p_vehicle_reference => 'V-B1', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform set_config('test.dispatch_id_135_b1', v_d::text, true);
  reset role;
end $$;

-- ---------------------------------------------------------------------------
-- Telemetry state
--   A1: session_started (no end) + ONE recent position + ONE signal_lost event
--       (2 events total, 1 position, session_active=true, fresh).
--   A2: session_started → session_ended + ONE old position
--       (2 events total, 1 position, session_active=false, stale).
--   B1: no events, no positions
--       (session_active=false, missing).
-- ---------------------------------------------------------------------------
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000000a',
                       'organization_id','53000000-0000-0000-0000-00000000003a')::text, true);
  perform set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000002', true);
  set local role authenticated;

  -- A1: start + fresh position + signal_lost
  perform telematics.carrier_start_telemetry_session(
    current_setting('test.dispatch_id_135_a1')::uuid, null);
  perform telematics.carrier_report_position(
    p_dispatch_id => current_setting('test.dispatch_id_135_a1')::uuid,
    p_latitude    => 35.6892,
    p_longitude   => 51.3890,
    p_reported_at => now(),
    p_accuracy_meters => 8);
  perform telematics.carrier_report_telemetry_event(
    current_setting('test.dispatch_id_135_a1')::uuid,
    'signal_lost', 'tunnel', '{}'::jsonb);

  -- A2: start → end + old position (will appear stale).
  perform telematics.carrier_start_telemetry_session(
    current_setting('test.dispatch_id_135_a2')::uuid, null);
  perform telematics.carrier_report_position(
    p_dispatch_id => current_setting('test.dispatch_id_135_a2')::uuid,
    p_latitude    => 35.70,
    p_longitude   => 51.40,
    p_reported_at => now() - interval '40 minutes',
    p_accuracy_meters => 12);
  perform telematics.carrier_end_telemetry_session(
    current_setting('test.dispatch_id_135_a2')::uuid, 'done');

  reset role;
end $$;

-- ---------------------------------------------------------------------------
-- Assertions
-- ---------------------------------------------------------------------------
select plan(12);

-- 1. function exists with expected signature
select has_function(
  'telematics', 'carrier_list_my_telemetry_session_statuses',
  array['uuid[]','integer','integer','interval'],
  'function exists');

-- 2. SECURITY DEFINER
select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='telematics'
      and p.proname='carrier_list_my_telemetry_session_statuses'),
  true, 'function is security definer');

-- 3. authenticated has EXECUTE
select is(
  has_function_privilege('authenticated',
    'telematics.carrier_list_my_telemetry_session_statuses(uuid[],integer,integer,interval)',
    'EXECUTE'),
  true, 'authenticated has execute grant');

-- Switch to Carrier A.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','53000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','53000000-0000-0000-0000-00000000000a',
                     'organization_id','53000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000002', true);
set local role authenticated;

-- 5. Carrier A sees exactly their own 2 dispatches.
select is(
  (select count(*)::int
     from telematics.carrier_list_my_telemetry_session_statuses(
       null, 100, 0, interval '15 minutes')),
  2, 'carrier A sees exactly their 2 dispatches');

-- 6. Carrier A cannot see carrier B's dispatch even if requested by id.
select is(
  (select count(*)::int
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_b1')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  0, 'carrier A cannot see carrier B''s dispatch via p_dispatch_ids');

-- 7. session_active=true for A1.
select is(
  (select session_active
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_a1')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  true, 'session_active true when latest session_started has no later session_ended');

-- 8. session_active=false for A2.
select is(
  (select session_active
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_a2')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  false, 'session_active false when latest session has ended');

-- 9. staleness_status='fresh' for A1.
select is(
  (select staleness_status
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_a1')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  'fresh', 'staleness_status is fresh when last position is within freshness interval');

-- 10. staleness_status='stale' for A2.
select is(
  (select staleness_status
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_a2')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  'stale', 'staleness_status is stale when last position is older than freshness interval');

-- 12. position_count for A1 = 1.
select is(
  (select position_count
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_a1')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  1::bigint, 'position_count returns 1 for A1');

-- 13. event_count for A1 = 2 (session_started + signal_lost).
select is(
  (select event_count
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_a1')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  2::bigint, 'event_count returns 2 for A1 (session_started + signal_lost)');

reset role;

-- Switch to Carrier B for assertion 11.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','53000000-0000-0000-0000-000000000003','role','authenticated',
                     'tenant_id','53000000-0000-0000-0000-00000000000a',
                     'organization_id','53000000-0000-0000-0000-00000000003b')::text, true);
select set_config('request.jwt.claim.sub', '53000000-0000-0000-0000-000000000003', true);
set local role authenticated;

-- 11. staleness_status='missing' for B1 (no positions reported).
select is(
  (select staleness_status
     from telematics.carrier_list_my_telemetry_session_statuses(
       array[current_setting('test.dispatch_id_135_b1')::uuid]::uuid[],
       100, 0, interval '15 minutes')),
  'missing', 'staleness_status is missing when no position has been reported');

reset role;

select * from finish();
rollback;
