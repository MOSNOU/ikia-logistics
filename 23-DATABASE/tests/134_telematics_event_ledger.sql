-- CC-45 Test 134 — Telematics ledger immutability + position_reports
-- write-protection.
--
-- Assertions (8):
--   1. Direct INSERT into telemetry_events as authenticated is denied
--   2. UPDATE on telemetry_events is denied
--   3. DELETE on telemetry_events is denied
--   4. Direct INSERT into position_reports is denied (write-protected stream)
--   5. UPDATE on position_reports is denied
--   6. DELETE on position_reports is denied
--   7. Buyer can SELECT events under RLS
--   8. Carrier can SELECT positions under RLS

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', '134-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000302', 'authenticated', 'authenticated', '134-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('45000000-0000-0000-0000-00000000030a', 'tenant-134', 'تست', 'Test 134');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('45000000-0000-0000-0000-00000000031a', '45000000-0000-0000-0000-00000000030a',
   'buy-134', 'خریدار', 'Buyer 134', 'buyer', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000032a', '45000000-0000-0000-0000-00000000030a',
   'sup-134', 'تأمین', 'Supplier 134', 'supplier', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000033a', '45000000-0000-0000-0000-00000000030a',
   'carr-134', 'حمل', 'Carrier 134', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('45000000-0000-0000-0000-000000000301', '45000000-0000-0000-0000-00000000030a',
   '45000000-0000-0000-0000-00000000031a', 'Buyer', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000302', '45000000-0000-0000-0000-00000000030a',
   '45000000-0000-0000-0000-00000000033a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000030a', '45000000-0000-0000-0000-00000000031a',
       '45000000-0000-0000-0000-000000000301', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000301', r.id, 'organization', '45000000-0000-0000-0000-00000000031a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000030a', '45000000-0000-0000-0000-00000000033a',
       '45000000-0000-0000-0000-000000000302', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000302', r.id, 'organization', '45000000-0000-0000-0000-00000000033a'
  from identity.roles r where r.code = 'carrier_admin';

-- Chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('45000000-0000-0000-0000-00000000034a', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000031a', '45000000-0000-0000-0000-000000000301',
        'RFQ-134', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('45000000-0000-0000-0000-00000000034b', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000032a', '45000000-0000-0000-0000-00000000034a',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000032a'),
        'OF-134', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('45000000-0000-0000-0000-00000000034c', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000031a', '45000000-0000-0000-0000-00000000034a',
        '45000000-0000-0000-0000-00000000034b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('45000000-0000-0000-0000-00000000034d', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000031a', '45000000-0000-0000-0000-00000000034a',
        '45000000-0000-0000-0000-00000000034b', '45000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000032a'),
        'PREP-134', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('45000000-0000-0000-0000-00000000035a', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000031a', '45000000-0000-0000-0000-00000000034d',
        '45000000-0000-0000-0000-00000000034a', '45000000-0000-0000-0000-00000000034b',
        '45000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000032a'),
        'CTR-134', 'executed', 'spot', 'CT-134', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('45000000-0000-0000-0000-00000000036a', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000031a', '45000000-0000-0000-0000-00000000035a',
        '45000000-0000-0000-0000-00000000034a', '45000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000032a'),
        'SH-134', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('45000000-0000-0000-0000-00000000030a', '45000000-0000-0000-0000-00000000033a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('45000000-0000-0000-0000-00000000033a', '45000000-0000-0000-0000-00000000030a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('45000000-0000-0000-0000-00000000037a', '45000000-0000-0000-0000-00000000030a',
        '45000000-0000-0000-0000-00000000033a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000030a',
                     'organization_id','45000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000301', true);
set local role authenticated;

do $$
declare v_b uuid;
begin
  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '45000000-0000-0000-0000-00000000036a',
    p_capacity_listing_id => '45000000-0000-0000-0000-00000000037a');
  perform set_config('test.booking_id_134', v_b::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000030a',
                     'organization_id','45000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000302', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_134')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000030a',
                     'organization_id','45000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000301', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_134')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000030a',
                     'organization_id','45000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000302', true);
set local role authenticated;

do $$
declare v_d uuid;
begin
  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_134')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform telematics.carrier_start_telemetry_session(v_d);
  perform telematics.carrier_report_position(v_d, 35.6, 51.4, now());
  perform set_config('test.dispatch_id_134', v_d::text, true);
end $$;

select plan(8);

-- 1. Direct INSERT into telemetry_events as authenticated denied.
select throws_ok(
  'insert into telematics.telemetry_events (tenant_id, dispatch_id, carrier_organization_id, '
  || 'event_type, actor_party) values ('
  || quote_literal('45000000-0000-0000-0000-00000000030a') || '::uuid, '
  || quote_literal(current_setting('test.dispatch_id_134')) || '::uuid, '
  || quote_literal('45000000-0000-0000-0000-00000000033a') || '::uuid, '
  || quote_literal('signal_lost') || '::telematics.telemetry_event_type, '
  || quote_literal('system') || ')',
  '42501', NULL,
  'direct INSERT into telemetry_events denied');

-- 2. UPDATE on telemetry_events denied.
select throws_ok(
  'update telematics.telemetry_events set reason = ''tamper'' where dispatch_id = '''
    || current_setting('test.dispatch_id_134') || '''::uuid',
  '42501', NULL,
  'UPDATE on telemetry_events denied');

-- 3. DELETE on telemetry_events denied.
select throws_ok(
  'delete from telematics.telemetry_events where dispatch_id = '''
    || current_setting('test.dispatch_id_134') || '''::uuid',
  '42501', NULL,
  'DELETE on telemetry_events denied');

-- 4. Direct INSERT into position_reports denied.
select throws_ok(
  'insert into telematics.position_reports (tenant_id, dispatch_id, carrier_organization_id, '
  || 'latitude, longitude, reported_at) values ('
  || quote_literal('45000000-0000-0000-0000-00000000030a') || '::uuid, '
  || quote_literal(current_setting('test.dispatch_id_134')) || '::uuid, '
  || quote_literal('45000000-0000-0000-0000-00000000033a') || '::uuid, '
  || '35.0, 51.0, now())',
  '42501', NULL,
  'direct INSERT into position_reports denied');

-- 5. UPDATE on position_reports denied.
select throws_ok(
  'update telematics.position_reports set latitude = 0 where dispatch_id = '''
    || current_setting('test.dispatch_id_134') || '''::uuid',
  '42501', NULL,
  'UPDATE on position_reports denied');

-- 6. DELETE on position_reports denied.
select throws_ok(
  'delete from telematics.position_reports where dispatch_id = '''
    || current_setting('test.dispatch_id_134') || '''::uuid',
  '42501', NULL,
  'DELETE on position_reports denied');

-- 7. Buyer SELECT events under RLS.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000030a',
                     'organization_id','45000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000301', true);
set local role authenticated;

select ok(
  (select count(*)::int from telematics.telemetry_events
    where dispatch_id = current_setting('test.dispatch_id_134')::uuid) >= 1,
  'buyer can SELECT events under RLS');

-- 8. Carrier SELECT positions under RLS.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000030a',
                     'organization_id','45000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000302', true);
set local role authenticated;

select ok(
  (select count(*)::int from telematics.position_reports
    where dispatch_id = current_setting('test.dispatch_id_134')::uuid) >= 1,
  'carrier can SELECT positions under RLS');

reset role;
select * from finish();
rollback;
