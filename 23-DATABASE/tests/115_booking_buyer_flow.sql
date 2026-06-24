-- CC-42 Test 115 — Booking buyer flow.
--
-- Assertions (8):
--   1. buyer_create_booking_request creates booking with status='pending_carrier'
--   2. exactly one event row exists (draft → pending_carrier, actor='buyer')
--   3. buyer_create against an inactive listing raises P0001
--   4. buyer_confirm from pending_carrier raises P0001 (wrong status)
--   5. buyer_cancel from pending_carrier succeeds → buyer_cancelled
--   6. cancel event recorded (event_type='booking_cancelled', actor='buyer')
--   7. buyer_cancel on already-cancelled booking raises P0001
--   8. non-owner buyer cannot list the booking

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

-- Fixture chain
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '115-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '115-otherbuyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '115-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('42000000-0000-0000-0000-00000000000a', 'tenant-115', 'تست', 'Test 115');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('42000000-0000-0000-0000-00000000001a', '42000000-0000-0000-0000-00000000000a',
   'buy-115', 'خریدار', 'Buyer 115', 'buyer', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000001b', '42000000-0000-0000-0000-00000000000a',
   'buy-115b', 'خریدار ب', 'Buyer 115B', 'buyer', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000002a', '42000000-0000-0000-0000-00000000000a',
   'sup-115', 'تأمین', 'Supplier 115', 'supplier', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000003a', '42000000-0000-0000-0000-00000000000a',
   'carr-115', 'حمل', 'Carrier 115', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('42000000-0000-0000-0000-000000000001', '42000000-0000-0000-0000-00000000000a',
   '42000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('42000000-0000-0000-0000-000000000002', '42000000-0000-0000-0000-00000000000a',
   '42000000-0000-0000-0000-00000000001b', 'OtherBuyer', 'fa', 'active'),
  ('42000000-0000-0000-0000-000000000003', '42000000-0000-0000-0000-00000000000a',
   '42000000-0000-0000-0000-00000000003a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000000a', '42000000-0000-0000-0000-00000000001a',
       '42000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000001', r.id, 'organization', '42000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000000a', '42000000-0000-0000-0000-00000000001b',
       '42000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000002', r.id, 'organization', '42000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000000a', '42000000-0000-0000-0000-00000000003a',
       '42000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000003', r.id, 'organization', '42000000-0000-0000-0000-00000000003a'
  from identity.roles r where r.code = 'carrier_admin';

-- Shipment chain
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status,
                          visibility, preferred_currency)
values ('42000000-0000-0000-0000-00000000004a',
        '42000000-0000-0000-0000-00000000000a',
        '42000000-0000-0000-0000-00000000001a',
        '42000000-0000-0000-0000-000000000001',
        'RFQ-115', 'Stub', 'submitted', 'private_invited', 'USD');

insert into offer.supplier_offers (id, tenant_id, organization_id, request_id,
                                    supplier_id, offer_code, currency, status)
values ('42000000-0000-0000-0000-00000000004b',
        '42000000-0000-0000-0000-00000000000a',
        '42000000-0000-0000-0000-00000000002a',
        '42000000-0000-0000-0000-00000000004a',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000002a'),
        'OF-115', 'USD', 'submitted');

insert into evaluation.offer_decisions (id, tenant_id, organization_id,
                                        request_id, offer_id, decision_status)
values ('42000000-0000-0000-0000-00000000004c',
        '42000000-0000-0000-0000-00000000000a',
        '42000000-0000-0000-0000-00000000001a',
        '42000000-0000-0000-0000-00000000004a',
        '42000000-0000-0000-0000-00000000004b',
        'selected_for_contract');

insert into contract.contract_preparations (id, tenant_id, organization_id,
                                             request_id, offer_id, decision_id,
                                             supplier_id, preparation_code, title, status)
values ('42000000-0000-0000-0000-00000000004d',
        '42000000-0000-0000-0000-00000000000a',
        '42000000-0000-0000-0000-00000000001a',
        '42000000-0000-0000-0000-00000000004a',
        '42000000-0000-0000-0000-00000000004b',
        '42000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000002a'),
        'PREP-115', 'Prep 115', 'ready_for_contract');

insert into contract.executed_contracts (id, tenant_id, organization_id,
                                          preparation_id, request_id, offer_id,
                                          decision_id, supplier_id, contract_code,
                                          status, contract_type, title, currency, executed_at)
values ('42000000-0000-0000-0000-00000000005a',
        '42000000-0000-0000-0000-00000000000a',
        '42000000-0000-0000-0000-00000000001a',
        '42000000-0000-0000-0000-00000000004d',
        '42000000-0000-0000-0000-00000000004a',
        '42000000-0000-0000-0000-00000000004b',
        '42000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000002a'),
        'CTR-115', 'executed', 'spot', 'CT-115', 'USD', now());

insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id,
                                 request_id, offer_id, supplier_id, shipment_code,
                                 status, transport_mode,
                                 origin_country, origin_city,
                                 destination_country, destination_city, planned_pickup_date)
values ('42000000-0000-0000-0000-00000000006a',
        '42000000-0000-0000-0000-00000000000a',
        '42000000-0000-0000-0000-00000000001a',
        '42000000-0000-0000-0000-00000000005a',
        '42000000-0000-0000-0000-00000000004a',
        '42000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000002a'),
        'SH-115', 'planned', 'road', 'IR', 'Tehran', 'DE', 'Berlin',
        now() + interval '7 days');

-- Carrier + marketplace
insert into marketplace.carrier_profiles (
  tenant_id, organization_id, display_name_fa, status,
  transport_modes, service_country_codes
) values (
  '42000000-0000-0000-0000-00000000000a',
  '42000000-0000-0000-0000-00000000003a',
  'حمل', 'active',
  array['road'::shipment.transport_mode],
  array['IR'::citext, 'DE'::citext]
);
insert into marketplace.carrier_directory_visibility (
  carrier_organization_id, tenant_id, is_public, published_at
) values (
  '42000000-0000-0000-0000-00000000003a',
  '42000000-0000-0000-0000-00000000000a', true, now()
);

insert into marketplace.capacity_listings (
  id, tenant_id, carrier_organization_id, transport_mode,
  origin_country_code, destination_country_code,
  valid_from, valid_until, status
) values (
  '42000000-0000-0000-0000-00000000007a',
  '42000000-0000-0000-0000-00000000000a',
  '42000000-0000-0000-0000-00000000003a', 'road',
  'IR'::citext, 'DE'::citext,
  now() - interval '1 day', now() + interval '30 days',
  'active'
);

-- A second listing left in draft (not active) for the inactive-listing test.
insert into marketplace.capacity_listings (
  id, tenant_id, carrier_organization_id, transport_mode,
  origin_country_code, destination_country_code, status
) values (
  '42000000-0000-0000-0000-00000000007b',
  '42000000-0000-0000-0000-00000000000a',
  '42000000-0000-0000-0000-00000000003a', 'road',
  'IR'::citext, 'DE'::citext, 'draft'
);

select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000000a',
                     'organization_id','42000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select plan(8);

-- 1. Create booking → pending_carrier.
do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '42000000-0000-0000-0000-00000000006a',
    p_capacity_listing_id => '42000000-0000-0000-0000-00000000007a',
    p_requested_quantity_units => 5,
    p_requested_unit_label => 'TEU'
  );
end $$;

select is(
  (select status::text from marketplace.booking_requests
    where shipment_id = '42000000-0000-0000-0000-00000000006a' limit 1),
  'pending_carrier', 'buyer_create produced pending_carrier');

-- 2. Exactly one event row (draft → pending_carrier).
select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000006a'
     and e.from_status = 'draft' and e.to_status = 'pending_carrier'
     and e.actor_party = 'buyer'),
  1, 'one buyer-actor event recorded for the create transition');

-- 3. Create against inactive listing → P0001.
select throws_ok(
  $$ select marketplace.buyer_create_booking_request(
       p_shipment_id => '42000000-0000-0000-0000-00000000006a',
       p_capacity_listing_id => '42000000-0000-0000-0000-00000000007b'
     ) $$,
  'P0001', NULL,
  'create against an inactive listing raises P0001');

-- 4. Confirm from pending_carrier → P0001 (only carrier_accepted is confirmable).
select throws_ok(
  $$ select marketplace.buyer_confirm_booking(
       (select id from marketplace.booking_requests
         where shipment_id = '42000000-0000-0000-0000-00000000006a' limit 1)
     ) $$,
  'P0001', NULL,
  'confirm from pending_carrier raises P0001');

-- 5. Cancel from pending_carrier succeeds.
do $$
begin
  perform marketplace.buyer_cancel_booking(
    (select id from marketplace.booking_requests
      where shipment_id = '42000000-0000-0000-0000-00000000006a' limit 1),
    'changed plans'
  );
end $$;

select is(
  (select status::text from marketplace.booking_requests
    where shipment_id = '42000000-0000-0000-0000-00000000006a' limit 1),
  'buyer_cancelled', 'buyer_cancel moved booking to buyer_cancelled');

-- 6. Cancel event recorded.
select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000006a'
     and e.to_status = 'buyer_cancelled' and e.event_type = 'booking_cancelled'
     and e.actor_party = 'buyer'),
  1, 'cancel event recorded with actor=buyer');

-- 7. Re-cancel → P0001 (terminal state).
select throws_ok(
  $$ select marketplace.buyer_cancel_booking(
       (select id from marketplace.booking_requests
         where shipment_id = '42000000-0000-0000-0000-00000000006a' limit 1),
       null
     ) $$,
  'P0001', NULL,
  'second cancel on already-cancelled booking raises P0001');

-- 8. Non-owner buyer cannot see the booking via list RPC.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000000a',
                     'organization_id','42000000-0000-0000-0000-00000000001b')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000002', true);

select is(
  (select count(*)::int from marketplace.buyer_list_my_bookings()),
  0, 'non-owner buyer sees zero bookings');

reset role;
select * from finish();
rollback;
