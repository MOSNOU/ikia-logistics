-- CC-45 Test 133 — Telematics admin visibility.
--
-- Assertions (7):
--   1. admin_list_positions returns rows
--   2. admin_get_telemetry_snapshot returns object
--   3. admin_list_active_sessions returns the dispatch with an open session
--   4. session that has been ended is NOT in active list
--   5. age_minutes is finite numeric
--   6. non-admin denied for admin_list_positions
--   7. non-admin denied for admin_list_active_sessions

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', '133-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000202', 'authenticated', 'authenticated', '133-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000299', 'authenticated', 'authenticated', '133-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('45000000-0000-0000-0000-00000000020a', 'tenant-133', 'تست', 'Test 133');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-00000000020a',
   'buy-133', 'خریدار', 'Buyer 133', 'buyer', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000022a', '45000000-0000-0000-0000-00000000020a',
   'sup-133', 'تأمین', 'Supplier 133', 'supplier', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000023a', '45000000-0000-0000-0000-00000000020a',
   'carr-133', 'حمل', 'Carrier 133', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('45000000-0000-0000-0000-000000000201', '45000000-0000-0000-0000-00000000020a',
   '45000000-0000-0000-0000-00000000021a', 'Buyer', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000202', '45000000-0000-0000-0000-00000000020a',
   '45000000-0000-0000-0000-00000000023a', 'Carrier', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000299', '45000000-0000-0000-0000-00000000020a',
   '45000000-0000-0000-0000-00000000021a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000020a', '45000000-0000-0000-0000-00000000021a',
       '45000000-0000-0000-0000-000000000201', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000201', r.id, 'organization', '45000000-0000-0000-0000-00000000021a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000020a', '45000000-0000-0000-0000-00000000023a',
       '45000000-0000-0000-0000-000000000202', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000202', r.id, 'organization', '45000000-0000-0000-0000-00000000023a'
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000299', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('45000000-0000-0000-0000-00000000024a', '45000000-0000-0000-0000-00000000020a',
        '45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-000000000201',
        'RFQ-133', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('45000000-0000-0000-0000-00000000024b', '45000000-0000-0000-0000-00000000020a',
        '45000000-0000-0000-0000-00000000022a', '45000000-0000-0000-0000-00000000024a',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000022a'),
        'OF-133', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('45000000-0000-0000-0000-00000000024c', '45000000-0000-0000-0000-00000000020a',
        '45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-00000000024a',
        '45000000-0000-0000-0000-00000000024b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('45000000-0000-0000-0000-00000000024d', '45000000-0000-0000-0000-00000000020a',
        '45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-00000000024a',
        '45000000-0000-0000-0000-00000000024b', '45000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000022a'),
        'PREP-133', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('45000000-0000-0000-0000-00000000025a', '45000000-0000-0000-0000-00000000020a',
        '45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-00000000024d',
        '45000000-0000-0000-0000-00000000024a', '45000000-0000-0000-0000-00000000024b',
        '45000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000022a'),
        'CTR-133', 'executed', 'spot', 'CT-133', 'USD', now());

-- Two shipments to exercise active vs closed sessions.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values
  ('45000000-0000-0000-0000-00000000026a', '45000000-0000-0000-0000-00000000020a',
   '45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-00000000025a',
   '45000000-0000-0000-0000-00000000024a', '45000000-0000-0000-0000-00000000024b',
   (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000022a'),
   'SH-133-A', 'planned', 'road', 'IR', 'DE', now() + interval '7 days'),
  ('45000000-0000-0000-0000-00000000026b', '45000000-0000-0000-0000-00000000020a',
   '45000000-0000-0000-0000-00000000021a', '45000000-0000-0000-0000-00000000025a',
   '45000000-0000-0000-0000-00000000024a', '45000000-0000-0000-0000-00000000024b',
   (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000022a'),
   'SH-133-B', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('45000000-0000-0000-0000-00000000020a', '45000000-0000-0000-0000-00000000023a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('45000000-0000-0000-0000-00000000023a', '45000000-0000-0000-0000-00000000020a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('45000000-0000-0000-0000-00000000027a', '45000000-0000-0000-0000-00000000020a',
        '45000000-0000-0000-0000-00000000023a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Buyer creates two bookings → carrier accepts both → buyer confirms both → carrier creates 2 dispatches.
-- Then start sessions on both; end session on the second.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000020a',
                     'organization_id','45000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
declare v_b1 uuid; v_b2 uuid;
begin
  v_b1 := marketplace.buyer_create_booking_request(
    p_shipment_id => '45000000-0000-0000-0000-00000000026a',
    p_capacity_listing_id => '45000000-0000-0000-0000-00000000027a');
  v_b2 := marketplace.buyer_create_booking_request(
    p_shipment_id => '45000000-0000-0000-0000-00000000026b',
    p_capacity_listing_id => '45000000-0000-0000-0000-00000000027a');
  perform set_config('test.booking_id_133_a', v_b1::text, true);
  perform set_config('test.booking_id_133_b', v_b2::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000202','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000020a',
                     'organization_id','45000000-0000-0000-0000-00000000023a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000202', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_133_a')::uuid, null);
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_133_b')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000020a',
                     'organization_id','45000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_133_a')::uuid);
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_133_b')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000202','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000020a',
                     'organization_id','45000000-0000-0000-0000-00000000023a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000202', true);
set local role authenticated;

do $$
declare v_d1 uuid; v_d2 uuid;
begin
  v_d1 := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_133_a')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  v_d2 := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_133_b')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform telematics.carrier_start_telemetry_session(v_d1);
  perform telematics.carrier_start_telemetry_session(v_d2);
  perform telematics.carrier_report_position(v_d1, 35.6, 51.4, now());
  perform telematics.carrier_end_telemetry_session(v_d2, 'arrived');
  perform set_config('test.dispatch_id_133_a', v_d1::text, true);
  perform set_config('test.dispatch_id_133_b', v_d2::text, true);
end $$;

reset role;
-- Switch to admin role for the assertions.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000299','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000020a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000299', true);
set local role authenticated;

select plan(7);

-- 1. admin_list_positions returns the row for dispatch A.
select is(
  (select count(*)::int from telematics.admin_list_positions(
     current_setting('test.dispatch_id_133_a')::uuid)),
  1, 'admin_list_positions returns the recorded row');

-- 2. snapshot returns object.
select is(
  jsonb_typeof(telematics.admin_get_telemetry_snapshot(
    current_setting('test.dispatch_id_133_a')::uuid)),
  'object', 'admin_get_telemetry_snapshot returns object');

-- 3. Dispatch A's session is active.
select is(
  (select count(*)::int from telematics.admin_list_active_sessions()
    where dispatch_id = current_setting('test.dispatch_id_133_a')::uuid),
  1, 'dispatch A with open session appears in admin_list_active_sessions');

-- 4. Dispatch B (ended) is NOT in active list.
select is(
  (select count(*)::int from telematics.admin_list_active_sessions()
    where dispatch_id = current_setting('test.dispatch_id_133_b')::uuid),
  0, 'dispatch B with ended session does NOT appear in admin_list_active_sessions');

-- 5. age_minutes is numeric.
select ok(
  (select age_minutes is not null and age_minutes >= 0
     from telematics.admin_list_active_sessions()
    where dispatch_id = current_setting('test.dispatch_id_133_a')::uuid limit 1),
  'age_minutes is a non-null non-negative numeric');

-- 6. Non-admin denied for admin_list_positions.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000020a',
                     'organization_id','45000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000201', true);
set local role authenticated;

select throws_ok(
  'select * from telematics.admin_list_positions('''
    || current_setting('test.dispatch_id_133_a')
    || '''::uuid)',
  '42501', NULL,
  'non-admin denied for admin_list_positions');

-- 7. Non-admin denied for admin_list_active_sessions.
select throws_ok(
  $$ select * from telematics.admin_list_active_sessions() $$,
  '42501', NULL,
  'non-admin denied for admin_list_active_sessions');

reset role;
select * from finish();
rollback;
