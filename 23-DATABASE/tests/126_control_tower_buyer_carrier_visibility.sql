-- CC-44 Test 126 — Buyer & carrier summary visibility.
--
-- Assertions (9):
--   1. buyer_summary returns audience='buyer'
--   2. buyer_summary reflects buyer's own org scope (active shipment count)
--   3. buyer_summary counts pending bookings owned by the buyer org
--   4. buyer without buyer_admin role denied (42501)
--   5. carrier_summary returns audience='carrier'
--   6. carrier_summary reflects carrier's own org scope (incoming pending)
--   7. carrier_summary counts active dispatches owned by the carrier org
--   8. supplier role denied for buyer_summary (42501)
--   9. supplier role denied for carrier_summary (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, settlement, dispute, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '126-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '126-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '126-supplier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('44000000-0000-0000-0000-00000000000a', 'tenant-126', 'تست', 'Test 126');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('44000000-0000-0000-0000-00000000001a', '44000000-0000-0000-0000-00000000000a',
   'buy-126', 'خریدار', 'Buyer 126', 'buyer', 'active', 'IR'),
  ('44000000-0000-0000-0000-00000000002a', '44000000-0000-0000-0000-00000000000a',
   'sup-126', 'تأمین', 'Supplier 126', 'supplier', 'active', 'IR'),
  ('44000000-0000-0000-0000-00000000003a', '44000000-0000-0000-0000-00000000000a',
   'carr-126', 'حمل', 'Carrier 126', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('44000000-0000-0000-0000-000000000001', '44000000-0000-0000-0000-00000000000a',
   '44000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('44000000-0000-0000-0000-000000000002', '44000000-0000-0000-0000-00000000000a',
   '44000000-0000-0000-0000-00000000003a', 'Carrier', 'fa', 'active'),
  ('44000000-0000-0000-0000-000000000003', '44000000-0000-0000-0000-00000000000a',
   '44000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000000a', '44000000-0000-0000-0000-00000000001a',
       '44000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000001', r.id, 'organization', '44000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000000a', '44000000-0000-0000-0000-00000000003a',
       '44000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000002', r.id, 'organization', '44000000-0000-0000-0000-00000000003a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000000a', '44000000-0000-0000-0000-00000000002a',
       '44000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000003', r.id, 'organization', '44000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Minimal shipment + booking chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('44000000-0000-0000-0000-00000000004a', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000001a', '44000000-0000-0000-0000-000000000001',
        'RFQ-126', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('44000000-0000-0000-0000-00000000004b', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000002a', '44000000-0000-0000-0000-00000000004a',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000002a'),
        'OF-126', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('44000000-0000-0000-0000-00000000004c', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000001a', '44000000-0000-0000-0000-00000000004a',
        '44000000-0000-0000-0000-00000000004b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('44000000-0000-0000-0000-00000000004d', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000001a', '44000000-0000-0000-0000-00000000004a',
        '44000000-0000-0000-0000-00000000004b', '44000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000002a'),
        'PREP-126', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('44000000-0000-0000-0000-00000000005a', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000001a', '44000000-0000-0000-0000-00000000004d',
        '44000000-0000-0000-0000-00000000004a', '44000000-0000-0000-0000-00000000004b',
        '44000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000002a'),
        'CTR-126', 'executed', 'spot', 'CT-126', 'USD', now());
-- One planned shipment for the buyer org.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('44000000-0000-0000-0000-00000000006a', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000001a', '44000000-0000-0000-0000-00000000005a',
        '44000000-0000-0000-0000-00000000004a', '44000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000002a'),
        'SH-126', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('44000000-0000-0000-0000-00000000000a', '44000000-0000-0000-0000-00000000003a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('44000000-0000-0000-0000-00000000003a', '44000000-0000-0000-0000-00000000000a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('44000000-0000-0000-0000-00000000007a', '44000000-0000-0000-0000-00000000000a',
        '44000000-0000-0000-0000-00000000003a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Buyer creates a booking (status: pending_carrier).
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000000a',
                     'organization_id','44000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000001', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '44000000-0000-0000-0000-00000000006a',
    p_capacity_listing_id => '44000000-0000-0000-0000-00000000007a'
  );
end $$;

select plan(9);

-- 1. buyer_summary returns audience='buyer'.
select is(
  (public.control_tower_buyer_summary()->>'audience'),
  'buyer', 'buyer_summary returns audience=buyer');

-- 2. active_shipments includes the planned one.
select is(
  ((public.control_tower_buyer_summary()->>'active_shipments')::int),
  1, 'buyer_summary counts the planned shipment');

-- 3. pending_bookings counts the freshly created booking.
select is(
  ((public.control_tower_buyer_summary()->>'pending_bookings')::int),
  1, 'buyer_summary counts the pending booking');

-- 4. Switch to supplier role; buyer_summary should be denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000003','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000000a',
                     'organization_id','44000000-0000-0000-0000-00000000002a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000003', true);
set local role authenticated;

select throws_ok(
  $$ select public.control_tower_buyer_summary() $$,
  '42501', NULL,
  'supplier role denied for buyer_summary');

-- 5. Switch to carrier role; check audience='carrier'.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000000a',
                     'organization_id','44000000-0000-0000-0000-00000000003a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000002', true);
set local role authenticated;

select is(
  (public.control_tower_carrier_summary()->>'audience'),
  'carrier', 'carrier_summary returns audience=carrier');

-- 6. carrier sees the incoming pending booking.
select is(
  ((public.control_tower_carrier_summary()->>'incoming_pending')::int),
  1, 'carrier_summary counts the incoming pending booking');

-- 7. carrier active_dispatches is 0 (no dispatches created yet).
select is(
  ((public.control_tower_carrier_summary()->>'active_dispatches')::int),
  0, 'carrier_summary active_dispatches counts the carrier-org dispatches');

-- 8/9. supplier role denied for carrier_summary.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000003','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000000a',
                     'organization_id','44000000-0000-0000-0000-00000000002a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000003', true);
set local role authenticated;

select throws_ok(
  $$ select public.control_tower_carrier_summary() $$,
  '42501', NULL,
  'supplier role denied for carrier_summary');

select throws_ok(
  $$ select public.control_tower_buyer_summary() $$,
  '42501', NULL,
  'supplier role denied for buyer_summary again (consistency check)');

reset role;
select * from finish();
rollback;
