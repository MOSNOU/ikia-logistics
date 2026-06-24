-- CC-42 Test 116 — Booking carrier flow.
--
-- Assertions (8):
--   1. carrier_list shows the incoming booking
--   2. carrier_accept moves pending_carrier → carrier_accepted
--   3. accept event recorded (event_type='booking_accepted', actor='carrier')
--   4. buyer_confirm from carrier_accepted moves → buyer_confirmed
--   5. confirm event recorded (event_type='booking_confirmed', actor='buyer')
--   6. carrier_accept on already-accepted raises P0001
--   7. buyer_cancel from buyer_confirmed raises P0001 (terminal)
--   8. non-owner carrier denied (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

-- Fixture (parallel structure to test 115; tenant 116; uuids '42…1…')
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000101', 'authenticated', 'authenticated', '116-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000102', 'authenticated', 'authenticated', '116-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000103', 'authenticated', 'authenticated', '116-other-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('42000000-0000-0000-0000-00000000010a', 'tenant-116', 'تست', 'Test 116');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('42000000-0000-0000-0000-00000000011a', '42000000-0000-0000-0000-00000000010a',
   'buy-116', 'خریدار', 'Buyer 116', 'buyer', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000012a', '42000000-0000-0000-0000-00000000010a',
   'sup-116', 'تأمین', 'Supplier 116', 'supplier', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000013a', '42000000-0000-0000-0000-00000000010a',
   'carr-116', 'حمل', 'Carrier 116', 'carrier', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000013b', '42000000-0000-0000-0000-00000000010a',
   'carr-116b', 'حمل ب', 'Carrier 116B', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('42000000-0000-0000-0000-000000000101', '42000000-0000-0000-0000-00000000010a',
   '42000000-0000-0000-0000-00000000011a', 'Buyer', 'fa', 'active'),
  ('42000000-0000-0000-0000-000000000102', '42000000-0000-0000-0000-00000000010a',
   '42000000-0000-0000-0000-00000000013a', 'Carrier', 'fa', 'active'),
  ('42000000-0000-0000-0000-000000000103', '42000000-0000-0000-0000-00000000010a',
   '42000000-0000-0000-0000-00000000013b', 'OtherCarrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000010a', '42000000-0000-0000-0000-00000000011a',
       '42000000-0000-0000-0000-000000000101', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000101', r.id, 'organization', '42000000-0000-0000-0000-00000000011a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000010a', '42000000-0000-0000-0000-00000000013a',
       '42000000-0000-0000-0000-000000000102', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000102', r.id, 'organization', '42000000-0000-0000-0000-00000000013a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000010a', '42000000-0000-0000-0000-00000000013b',
       '42000000-0000-0000-0000-000000000103', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000103', r.id, 'organization', '42000000-0000-0000-0000-00000000013b'
  from identity.roles r where r.code = 'carrier_admin';

-- Shipment chain
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('42000000-0000-0000-0000-00000000014a', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000011a', '42000000-0000-0000-0000-000000000101',
        'RFQ-116', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('42000000-0000-0000-0000-00000000014b', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000012a', '42000000-0000-0000-0000-00000000014a',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000012a'),
        'OF-116', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('42000000-0000-0000-0000-00000000014c', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000011a', '42000000-0000-0000-0000-00000000014a',
        '42000000-0000-0000-0000-00000000014b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('42000000-0000-0000-0000-00000000014d', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000011a', '42000000-0000-0000-0000-00000000014a',
        '42000000-0000-0000-0000-00000000014b', '42000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000012a'),
        'PREP-116', 'Prep 116', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('42000000-0000-0000-0000-00000000015a', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000011a', '42000000-0000-0000-0000-00000000014d',
        '42000000-0000-0000-0000-00000000014a', '42000000-0000-0000-0000-00000000014b',
        '42000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000012a'),
        'CTR-116', 'executed', 'spot', 'CT-116', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('42000000-0000-0000-0000-00000000016a', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000011a', '42000000-0000-0000-0000-00000000015a',
        '42000000-0000-0000-0000-00000000014a', '42000000-0000-0000-0000-00000000014b',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000012a'),
        'SH-116', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('42000000-0000-0000-0000-00000000010a', '42000000-0000-0000-0000-00000000013a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('42000000-0000-0000-0000-00000000013a', '42000000-0000-0000-0000-00000000010a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('42000000-0000-0000-0000-00000000017a', '42000000-0000-0000-0000-00000000010a',
        '42000000-0000-0000-0000-00000000013a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Buyer creates booking.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000010a',
                     'organization_id','42000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000101', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '42000000-0000-0000-0000-00000000016a',
    p_capacity_listing_id => '42000000-0000-0000-0000-00000000017a'
  );
end $$;

reset role;

select plan(8);

-- 1. Carrier sees the incoming booking in their list.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000102','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000010a',
                     'organization_id','42000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000102', true);
set local role authenticated;

select is(
  (select count(*)::int from marketplace.carrier_list_booking_requests()),
  1, 'carrier sees their incoming booking');

-- 2. Carrier accept.
do $$
begin
  perform marketplace.carrier_accept_booking(
    (select id from marketplace.booking_requests
      where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1),
    'will reserve capacity'
  );
end $$;

select is(
  (select status::text from marketplace.booking_requests
    where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1),
  'carrier_accepted', 'carrier_accept moved booking to carrier_accepted');

-- 3. Accept event recorded.
select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000016a'
     and e.event_type = 'booking_accepted' and e.actor_party = 'carrier'),
  1, 'accept event recorded with actor=carrier');

-- 4. Buyer confirm (switch role).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000010a',
                     'organization_id','42000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000101', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(
    (select id from marketplace.booking_requests
      where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1)
  );
end $$;

select is(
  (select status::text from marketplace.booking_requests
    where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1),
  'buyer_confirmed', 'buyer_confirm moved booking to buyer_confirmed');

-- 5. Confirm event recorded.
select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000016a'
     and e.event_type = 'booking_confirmed' and e.actor_party = 'buyer'),
  1, 'confirm event recorded with actor=buyer');

-- 6. Carrier accept on confirmed booking → P0001 (back to carrier role).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000102','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000010a',
                     'organization_id','42000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000102', true);
set local role authenticated;

select throws_ok(
  $$ select marketplace.carrier_accept_booking(
       (select id from marketplace.booking_requests
         where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1),
       null
     ) $$,
  'P0001', NULL,
  'accept on already-accepted/confirmed booking raises P0001');

-- 7. Buyer cancel from buyer_confirmed → P0001 (back to buyer role).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000010a',
                     'organization_id','42000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000101', true);
set local role authenticated;

select throws_ok(
  $$ select marketplace.buyer_cancel_booking(
       (select id from marketplace.booking_requests
         where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1),
       null
     ) $$,
  'P0001', NULL,
  'cancel from terminal state buyer_confirmed raises P0001');

-- 8. Non-owner carrier denied on accept of a foreign booking. We capture
-- the booking_id while we still have RLS-visible access (as the owner
-- carrier), and pass it into the throws_ok as a literal, because the
-- non-owner carrier cannot SELECT the row themselves under RLS.
do $$
declare v_id uuid;
begin
  v_id := (select id from marketplace.booking_requests
            where shipment_id = '42000000-0000-0000-0000-00000000016a' limit 1);
  perform set_config('test.booking_id_116', v_id::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000103','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000010a',
                     'organization_id','42000000-0000-0000-0000-00000000013b')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000103', true);
set local role authenticated;

select throws_ok(
  'select marketplace.carrier_accept_booking('''
  || current_setting('test.booking_id_116')
  || '''::uuid, null)',
  '42501', NULL,
  'non-owner carrier cannot accept another carrier’s booking');

reset role;
select * from finish();
rollback;
