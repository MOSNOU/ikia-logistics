-- CC-45 Test 132 — Telematics buyer visibility.
--
-- Assertions (7):
--   1. buyer_list_positions returns positions for the buyer's own dispatch
--   2. buyer_get_telemetry_snapshot returns the snapshot object
--   3. p_since filter narrows the buyer position list
--   4. non-owner buyer denied (42501)
--   5. supplier role denied (42501)
--   6. carrier user denied for buyer_list_positions (42501)
--   7. buyer_get_telemetry_snapshot recent_events array is jsonb array

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000101', 'authenticated', 'authenticated', '132-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000102', 'authenticated', 'authenticated', '132-otherbuyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000103', 'authenticated', 'authenticated', '132-supplier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '45000000-0000-0000-0000-000000000104', 'authenticated', 'authenticated', '132-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('45000000-0000-0000-0000-00000000010a', 'tenant-132', 'تست', 'Test 132');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('45000000-0000-0000-0000-00000000011a', '45000000-0000-0000-0000-00000000010a',
   'buy-132', 'خریدار', 'Buyer 132', 'buyer', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000011b', '45000000-0000-0000-0000-00000000010a',
   'buy-132b', 'خریدار ب', 'Buyer 132B', 'buyer', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000012a', '45000000-0000-0000-0000-00000000010a',
   'sup-132', 'تأمین', 'Supplier 132', 'supplier', 'active', 'IR'),
  ('45000000-0000-0000-0000-00000000013a', '45000000-0000-0000-0000-00000000010a',
   'carr-132', 'حمل', 'Carrier 132', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('45000000-0000-0000-0000-000000000101', '45000000-0000-0000-0000-00000000010a',
   '45000000-0000-0000-0000-00000000011a', 'Buyer', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000102', '45000000-0000-0000-0000-00000000010a',
   '45000000-0000-0000-0000-00000000011b', 'OtherBuyer', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000103', '45000000-0000-0000-0000-00000000010a',
   '45000000-0000-0000-0000-00000000012a', 'Supplier', 'fa', 'active'),
  ('45000000-0000-0000-0000-000000000104', '45000000-0000-0000-0000-00000000010a',
   '45000000-0000-0000-0000-00000000013a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000010a', '45000000-0000-0000-0000-00000000011a',
       '45000000-0000-0000-0000-000000000101', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000101', r.id, 'organization', '45000000-0000-0000-0000-00000000011a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000010a', '45000000-0000-0000-0000-00000000011b',
       '45000000-0000-0000-0000-000000000102', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000102', r.id, 'organization', '45000000-0000-0000-0000-00000000011b'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000010a', '45000000-0000-0000-0000-00000000012a',
       '45000000-0000-0000-0000-000000000103', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000103', r.id, 'organization', '45000000-0000-0000-0000-00000000012a'
  from identity.roles r where r.code = 'supplier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '45000000-0000-0000-0000-00000000010a', '45000000-0000-0000-0000-00000000013a',
       '45000000-0000-0000-0000-000000000104', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '45000000-0000-0000-0000-000000000104', r.id, 'organization', '45000000-0000-0000-0000-00000000013a'
  from identity.roles r where r.code = 'carrier_admin';

-- Chain (compressed).
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('45000000-0000-0000-0000-00000000014a', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000011a', '45000000-0000-0000-0000-000000000101',
        'RFQ-132', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('45000000-0000-0000-0000-00000000014b', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000012a', '45000000-0000-0000-0000-00000000014a',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000012a'),
        'OF-132', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('45000000-0000-0000-0000-00000000014c', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000011a', '45000000-0000-0000-0000-00000000014a',
        '45000000-0000-0000-0000-00000000014b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('45000000-0000-0000-0000-00000000014d', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000011a', '45000000-0000-0000-0000-00000000014a',
        '45000000-0000-0000-0000-00000000014b', '45000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000012a'),
        'PREP-132', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('45000000-0000-0000-0000-00000000015a', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000011a', '45000000-0000-0000-0000-00000000014d',
        '45000000-0000-0000-0000-00000000014a', '45000000-0000-0000-0000-00000000014b',
        '45000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000012a'),
        'CTR-132', 'executed', 'spot', 'CT-132', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('45000000-0000-0000-0000-00000000016a', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000011a', '45000000-0000-0000-0000-00000000015a',
        '45000000-0000-0000-0000-00000000014a', '45000000-0000-0000-0000-00000000014b',
        (select id from supplier.suppliers where organization_id = '45000000-0000-0000-0000-00000000012a'),
        'SH-132', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('45000000-0000-0000-0000-00000000010a', '45000000-0000-0000-0000-00000000013a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('45000000-0000-0000-0000-00000000013a', '45000000-0000-0000-0000-00000000010a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('45000000-0000-0000-0000-00000000017a', '45000000-0000-0000-0000-00000000010a',
        '45000000-0000-0000-0000-00000000013a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Booking → confirmed → dispatch (assigned) → carrier reports 2 positions.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000101', true);
set local role authenticated;

do $$
declare v_b uuid;
begin
  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '45000000-0000-0000-0000-00000000016a',
    p_capacity_listing_id => '45000000-0000-0000-0000-00000000017a');
  perform set_config('test.booking_id_132', v_b::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000104','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000104', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_132')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000101', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_132')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000104','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000104', true);
set local role authenticated;

do $$
declare v_d uuid;
begin
  v_d := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_132')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98');
  perform set_config('test.dispatch_id_132', v_d::text, true);
  perform telematics.carrier_report_position(v_d, 35.6, 51.4, now() - interval '5 minutes');
  perform telematics.carrier_report_position(v_d, 35.7, 51.5, now());
end $$;

reset role;
-- Switch to buyer.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000101', true);
set local role authenticated;

select plan(7);

-- 1. buyer sees both positions.
select is(
  (select count(*)::int from telematics.buyer_list_positions(
     current_setting('test.dispatch_id_132')::uuid)),
  2, 'buyer_list_positions returns both positions');

-- 2. snapshot returns object.
select is(
  jsonb_typeof(telematics.buyer_get_telemetry_snapshot(
    current_setting('test.dispatch_id_132')::uuid)),
  'object', 'buyer_get_telemetry_snapshot returns object');

-- 3. p_since narrows.
select is(
  (select count(*)::int from telematics.buyer_list_positions(
     current_setting('test.dispatch_id_132')::uuid,
     now() - interval '2 minutes')),
  1, 'p_since filter narrows to 1 row');

-- 4. Non-owner buyer denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000102','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000011b')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000102', true);
set local role authenticated;

select throws_ok(
  'select * from telematics.buyer_list_positions('''
    || current_setting('test.dispatch_id_132')
    || '''::uuid)',
  '42501', NULL,
  'non-owner buyer denied');

-- 5. Supplier role denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000103','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000012a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000103', true);
set local role authenticated;

select throws_ok(
  'select * from telematics.buyer_list_positions('''
    || current_setting('test.dispatch_id_132')
    || '''::uuid)',
  '42501', NULL,
  'supplier role denied for buyer_list_positions');

-- 6. Carrier role denied for the buyer RPC (role gate enforces buyer-only).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000104','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000104', true);
set local role authenticated;

select throws_ok(
  'select * from telematics.buyer_list_positions('''
    || current_setting('test.dispatch_id_132')
    || '''::uuid)',
  '42501', NULL,
  'carrier role denied for buyer_list_positions');

-- 7. Snapshot recent_events is array.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','45000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','45000000-0000-0000-0000-00000000010a',
                     'organization_id','45000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '45000000-0000-0000-0000-000000000101', true);
set local role authenticated;

select is(
  jsonb_typeof(telematics.buyer_get_telemetry_snapshot(
    current_setting('test.dispatch_id_132')::uuid)->'recent_events'),
  'array', 'snapshot recent_events is a jsonb array');

reset role;
select * from finish();
rollback;
