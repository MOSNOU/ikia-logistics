-- CC-43 Test 121 — Dispatch carrier lifecycle.
--
-- Assertions (10):
--   1. carrier_create_dispatch on a non-confirmed booking raises P0001
--   2. carrier_create_dispatch on a confirmed booking with all placeholders
--      starts in 'assigned' and records 2 events (created + assigned)
--   3. carrier_create_dispatch with missing placeholders starts in 'draft'
--   4. carrier_update_dispatch_placeholders auto-transitions draft → assigned
--      when the final placeholder is filled
--   5. carrier_mark_ready moves assigned → ready
--   6. carrier_release_dispatch moves ready → released
--   7. carrier_release_dispatch on non-ready dispatch raises P0001
--   8. carrier_cancel_dispatch from a non-terminal moves → cancelled
--   9. non-owner carrier cannot mutate (42501)
--   10. carrier list returns the carrier's own dispatches

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, tests;
begin;

-- Fixture
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '121-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '121-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '121-other-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('43000000-0000-0000-0000-00000000000a', 'tenant-121', 'تست', 'Test 121');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-00000000000a',
   'buy-121', 'خریدار', 'Buyer 121', 'buyer', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000002a', '43000000-0000-0000-0000-00000000000a',
   'sup-121', 'تأمین', 'Supplier 121', 'supplier', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000003a', '43000000-0000-0000-0000-00000000000a',
   'carr-121', 'حمل', 'Carrier 121', 'carrier', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000003b', '43000000-0000-0000-0000-00000000000a',
   'carr-121b', 'حمل ب', 'Carrier 121B', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('43000000-0000-0000-0000-000000000001', '43000000-0000-0000-0000-00000000000a',
   '43000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000002', '43000000-0000-0000-0000-00000000000a',
   '43000000-0000-0000-0000-00000000003a', 'Carrier', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000003', '43000000-0000-0000-0000-00000000000a',
   '43000000-0000-0000-0000-00000000003b', 'OtherCarrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000000a', '43000000-0000-0000-0000-00000000001a',
       '43000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000001', r.id, 'organization', '43000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000000a', '43000000-0000-0000-0000-00000000003a',
       '43000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000002', r.id, 'organization', '43000000-0000-0000-0000-00000000003a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000000a', '43000000-0000-0000-0000-00000000003b',
       '43000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000003', r.id, 'organization', '43000000-0000-0000-0000-00000000003b'
  from identity.roles r where r.code = 'carrier_admin';

-- Shipment chain
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('43000000-0000-0000-0000-00000000004a', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-000000000001',
        'RFQ-121', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('43000000-0000-0000-0000-00000000004b', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000002a', '43000000-0000-0000-0000-00000000004a',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000002a'),
        'OF-121', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('43000000-0000-0000-0000-00000000004c', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-00000000004a',
        '43000000-0000-0000-0000-00000000004b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('43000000-0000-0000-0000-00000000004d', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-00000000004a',
        '43000000-0000-0000-0000-00000000004b', '43000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000002a'),
        'PREP-121', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('43000000-0000-0000-0000-00000000005a', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-00000000004d',
        '43000000-0000-0000-0000-00000000004a', '43000000-0000-0000-0000-00000000004b',
        '43000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000002a'),
        'CTR-121', 'executed', 'spot', 'CT-121', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('43000000-0000-0000-0000-00000000006a', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-00000000005a',
        '43000000-0000-0000-0000-00000000004a', '43000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000002a'),
        'SH-121', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- Marketplace
insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('43000000-0000-0000-0000-00000000000a', '43000000-0000-0000-0000-00000000003a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('43000000-0000-0000-0000-00000000003a', '43000000-0000-0000-0000-00000000000a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('43000000-0000-0000-0000-00000000007a', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000003a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Two bookings: B1 will be confirmed (used for the happy path), B2 will stay
-- in pending_carrier (used to test the P0001 pre-condition).
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
declare v_b1 uuid; v_b2 uuid;
begin
  v_b1 := marketplace.buyer_create_booking_request(
    p_shipment_id => '43000000-0000-0000-0000-00000000006a',
    p_capacity_listing_id => '43000000-0000-0000-0000-00000000007a'
  );
  v_b2 := marketplace.buyer_create_booking_request(
    p_shipment_id => '43000000-0000-0000-0000-00000000006a',
    p_capacity_listing_id => '43000000-0000-0000-0000-00000000007a'
  );
  perform set_config('test.booking_id_121_a', v_b1::text, true);
  perform set_config('test.booking_id_121_b', v_b2::text, true);
end $$;

reset role;
-- Carrier accepts B1.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000002', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_121_a')::uuid, null);
end $$;

reset role;
-- Buyer confirms B1.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_121_a')::uuid);
end $$;

reset role;
-- Switch to carrier owner.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000002', true);
set local role authenticated;

select plan(10);

-- 1. Pre-condition: B2 is still pending_carrier; create should fail.
select throws_ok(
  'select dispatch.carrier_create_dispatch('''
    || current_setting('test.booking_id_121_b')
    || '''::uuid)',
  'P0001', NULL,
  'create on non-confirmed booking raises P0001');

-- 2. Create on confirmed booking with all placeholders → assigned.
do $$
declare v_id uuid;
begin
  v_id := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_121_a')::uuid,
    p_vehicle_reference => 'IR-12-34-A',
    p_vehicle_type => 'truck-tractor',
    p_driver_name => 'علی',
    p_driver_phone => '+989120000000'
  );
  perform set_config('test.dispatch_id_a', v_id::text, true);
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_a')::uuid),
  'assigned', 'create with all placeholders starts in assigned');

select is(
  (select count(*)::int from dispatch.dispatch_events
    where dispatch_id = current_setting('test.dispatch_id_a')::uuid),
  2, 'create with all placeholders records 2 events (created + assigned)');

-- 3. Create another booking for the draft case. Use a fresh shipment so the
-- chain is independent. Reset role first so the shipment INSERT has the
-- table privilege (only postgres can write directly).
reset role;

insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('43000000-0000-0000-0000-00000000006b', '43000000-0000-0000-0000-00000000000a',
        '43000000-0000-0000-0000-00000000001a', '43000000-0000-0000-0000-00000000005a',
        '43000000-0000-0000-0000-00000000004a', '43000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000002a'),
        'SH-121-B', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
declare v_b3 uuid;
begin
  v_b3 := marketplace.buyer_create_booking_request(
    p_shipment_id => '43000000-0000-0000-0000-00000000006b',
    p_capacity_listing_id => '43000000-0000-0000-0000-00000000007a'
  );
  perform set_config('test.booking_id_121_c', v_b3::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000002', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_121_c')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_121_c')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000002', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_121_c')::uuid,
    p_vehicle_reference => 'IR-99-99-Z'
    -- driver fields intentionally omitted
  );
  perform set_config('test.dispatch_id_b', v_id::text, true);
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_b')::uuid),
  'draft', 'create with missing placeholders starts in draft');

-- 4. Filling the remaining placeholders auto-transitions to assigned.
do $$
begin
  perform dispatch.carrier_update_dispatch_placeholders(
    p_dispatch_id => current_setting('test.dispatch_id_b')::uuid,
    p_vehicle_type => 'flat-bed',
    p_driver_name => 'سارا',
    p_driver_phone => '+989121111111'
  );
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_b')::uuid),
  'assigned', 'update_placeholders auto-transitions draft → assigned when complete');

-- 5. mark_ready: assigned → ready.
do $$
begin
  perform dispatch.carrier_mark_ready(current_setting('test.dispatch_id_a')::uuid);
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_a')::uuid),
  'ready', 'mark_ready moved assigned → ready');

-- 6. release: ready → released.
do $$
begin
  perform dispatch.carrier_release_dispatch(current_setting('test.dispatch_id_a')::uuid, 'handover ok');
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_a')::uuid),
  'released', 'release moved ready → released');

-- 7. release on dispatch_b (which is in assigned, not ready) → P0001.
select throws_ok(
  'select dispatch.carrier_release_dispatch('''
    || current_setting('test.dispatch_id_b')
    || '''::uuid, null)',
  'P0001', NULL,
  'release from non-ready dispatch raises P0001');

-- 8. cancel dispatch_b from non-terminal.
do $$
begin
  perform dispatch.carrier_cancel_dispatch(current_setting('test.dispatch_id_b')::uuid, 'reassigning');
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_b')::uuid),
  'cancelled', 'cancel from non-terminal moved → cancelled');

-- 9. Switch to non-owner carrier; mutation should fail.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000003','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000003b')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000003', true);
set local role authenticated;

select throws_ok(
  'select dispatch.carrier_mark_ready('''
    || current_setting('test.dispatch_id_a')
    || '''::uuid)',
  '42501', NULL,
  'non-owner carrier cannot mutate another carrier’s dispatch');

-- 10. Switch back to owner; list returns both dispatches.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000000a',
                     'organization_id','43000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000002', true);
set local role authenticated;

select is(
  (select count(*)::int from dispatch.carrier_list_my_dispatches()),
  2, 'carrier_list_my_dispatches returns both owned dispatches');

reset role;
select * from finish();
rollback;
