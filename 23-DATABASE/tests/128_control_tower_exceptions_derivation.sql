-- CC-44 Test 128 — Admin exceptions derivation.
--
-- Assertions (8):
--   1. non-admin denied for admin_exceptions (42501)
--   2. fresh booking (< 24h) does NOT appear as booking_stale_pending
--   3. backdated pending booking (> 24h) appears as booking_stale_pending
--   4. backdated draft dispatch (> 24h) appears as dispatch_stale_draft
--   5. disputed settlement appears as settlement_disputed
--   6. open dispute appears as dispute_open
--   7. planned shipment with no booking appears as shipment_planned_no_booking
--   8. category set returned matches the 5 derived categories

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, settlement, dispute, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', '128-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000302', 'authenticated', 'authenticated', '128-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000399', 'authenticated', 'authenticated', '128-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('44000000-0000-0000-0000-00000000030a', 'tenant-128', 'تست', 'Test 128');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000030a',
   'buy-128', 'خریدار', 'Buyer 128', 'buyer', 'active', 'IR'),
  ('44000000-0000-0000-0000-00000000032a', '44000000-0000-0000-0000-00000000030a',
   'sup-128', 'تأمین', 'Supplier 128', 'supplier', 'active', 'IR'),
  ('44000000-0000-0000-0000-00000000033a', '44000000-0000-0000-0000-00000000030a',
   'carr-128', 'حمل', 'Carrier 128', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('44000000-0000-0000-0000-000000000301', '44000000-0000-0000-0000-00000000030a',
   '44000000-0000-0000-0000-00000000031a', 'Buyer', 'fa', 'active'),
  ('44000000-0000-0000-0000-000000000302', '44000000-0000-0000-0000-00000000030a',
   '44000000-0000-0000-0000-00000000033a', 'Carrier', 'fa', 'active'),
  ('44000000-0000-0000-0000-000000000399', '44000000-0000-0000-0000-00000000030a',
   '44000000-0000-0000-0000-00000000031a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000030a', '44000000-0000-0000-0000-00000000031a',
       '44000000-0000-0000-0000-000000000301', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000301', r.id, 'organization', '44000000-0000-0000-0000-00000000031a'
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000030a', '44000000-0000-0000-0000-00000000033a',
       '44000000-0000-0000-0000-000000000302', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000302', r.id, 'organization', '44000000-0000-0000-0000-00000000033a'
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000399', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Shipment chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('44000000-0000-0000-0000-00000000034a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-000000000301',
        'RFQ-128', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('44000000-0000-0000-0000-00000000034b', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000032a', '44000000-0000-0000-0000-00000000034a',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'OF-128', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('44000000-0000-0000-0000-00000000034c', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000034a',
        '44000000-0000-0000-0000-00000000034b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('44000000-0000-0000-0000-00000000034d', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000034a',
        '44000000-0000-0000-0000-00000000034b', '44000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'PREP-128', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('44000000-0000-0000-0000-00000000035a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000034d',
        '44000000-0000-0000-0000-00000000034a', '44000000-0000-0000-0000-00000000034b',
        '44000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'CTR-128', 'executed', 'spot', 'CT-128', 'USD', now());
-- Shipment with no booking → will appear as shipment_planned_no_booking.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('44000000-0000-0000-0000-00000000036a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000035a',
        '44000000-0000-0000-0000-00000000034a', '44000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'SH-128', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('44000000-0000-0000-0000-00000000030a', '44000000-0000-0000-0000-00000000033a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('44000000-0000-0000-0000-00000000033a', '44000000-0000-0000-0000-00000000030a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('44000000-0000-0000-0000-00000000037a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000033a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Second shipment used as the booking target. Direct-insert a pending booking
-- with a backdated created_at to trigger booking_stale_pending. Avoids the
-- buyer RPC so we can control the created_at column.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('44000000-0000-0000-0000-00000000036b', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000035a',
        '44000000-0000-0000-0000-00000000034a', '44000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'SH-128-B', 'booked', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.booking_requests (id, tenant_id, shipment_id, capacity_listing_id,
                                           buyer_organization_id, carrier_organization_id,
                                           status, created_at, updated_at)
values ('44000000-0000-0000-0000-00000000038a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000036b', '44000000-0000-0000-0000-00000000037a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000033a',
        'pending_carrier', now() - interval '36 hours', now() - interval '36 hours');

-- Fresh booking on a third shipment — should NOT appear as stale.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('44000000-0000-0000-0000-00000000036c', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000035a',
        '44000000-0000-0000-0000-00000000034a', '44000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'SH-128-C', 'booked', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.booking_requests (id, tenant_id, shipment_id, capacity_listing_id,
                                           buyer_organization_id, carrier_organization_id,
                                           status, created_at, updated_at)
values ('44000000-0000-0000-0000-00000000038b', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000036c', '44000000-0000-0000-0000-00000000037a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000033a',
        'pending_carrier', now(), now());

-- Build a confirmed booking + draft dispatch for the dispatch_stale_draft case.
-- Create the booking via direct-insert (status='buyer_confirmed') to set up
-- the dispatch chain, then create the dispatch and backdate its created_at.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('44000000-0000-0000-0000-00000000036d', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000035a',
        '44000000-0000-0000-0000-00000000034a', '44000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'SH-128-D', 'booked', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.booking_requests (id, tenant_id, shipment_id, capacity_listing_id,
                                           buyer_organization_id, carrier_organization_id,
                                           status, created_at, updated_at)
values ('44000000-0000-0000-0000-00000000038c', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000036d', '44000000-0000-0000-0000-00000000037a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000033a',
        'buyer_confirmed', now() - interval '2 days', now() - interval '2 days');

insert into dispatch.dispatch_assignments (id, tenant_id, booking_request_id,
                                            buyer_organization_id, carrier_organization_id,
                                            status, created_at, updated_at)
values ('44000000-0000-0000-0000-00000000039a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000038c',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000033a',
        'draft', now() - interval '36 hours', now() - interval '36 hours');

-- Disputed settlement.
insert into settlement.escrow_accounts (id, tenant_id, organization_id, supplier_id,
                                         account_code, status, currency)
values ('44000000-0000-0000-0000-00000000040a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'ESC-128', 'open', 'USD');

insert into settlement.settlements (id, tenant_id, organization_id, supplier_id,
                                     escrow_account_id, executed_contract_id,
                                     settlement_code, status, currency, planned_amount)
values ('44000000-0000-0000-0000-00000000041a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        '44000000-0000-0000-0000-00000000040a',
        '44000000-0000-0000-0000-00000000035a',
        'STL-128', 'disputed', 'USD', 100);

-- Open dispute on that settlement.
insert into dispute.disputes (id, tenant_id, organization_id, settlement_id,
                               supplier_id, dispute_code, status, opened_by_party,
                               opened_at, title, amount_in_dispute, currency)
values ('44000000-0000-0000-0000-00000000042a', '44000000-0000-0000-0000-00000000030a',
        '44000000-0000-0000-0000-00000000031a', '44000000-0000-0000-0000-00000000041a',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000032a'),
        'DSP-128', 'opened', 'buyer', now(), 'Test dispute', 50, 'USD');

-- Switch to admin role.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000399','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000030a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000399', true);
set local role authenticated;

select plan(8);

-- 1. Non-admin denied (use buyer role here briefly).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000030a',
                     'organization_id','44000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000301', true);
set local role authenticated;

select throws_ok(
  $$ select * from public.control_tower_admin_exceptions() $$,
  '42501', NULL,
  'non-admin denied for admin_exceptions');

-- Restore admin context.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000399','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000030a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000399', true);
set local role authenticated;

-- 2. Fresh booking (created now) does NOT appear as stale.
select is(
  (select count(*)::int from public.control_tower_admin_exceptions()
    where category = 'booking_stale_pending'
      and subject_id = '44000000-0000-0000-0000-00000000038b'),
  0, 'fresh booking does NOT appear as booking_stale_pending');

-- 3. Backdated booking does.
select is(
  (select count(*)::int from public.control_tower_admin_exceptions()
    where category = 'booking_stale_pending'
      and subject_id = '44000000-0000-0000-0000-00000000038a'),
  1, 'backdated booking appears as booking_stale_pending');

-- 4. Draft dispatch backdated > 24h.
select is(
  (select count(*)::int from public.control_tower_admin_exceptions()
    where category = 'dispatch_stale_draft'
      and subject_id = '44000000-0000-0000-0000-00000000039a'),
  1, 'backdated draft dispatch appears as dispatch_stale_draft');

-- 5. Disputed settlement.
select is(
  (select count(*)::int from public.control_tower_admin_exceptions()
    where category = 'settlement_disputed'
      and subject_id = '44000000-0000-0000-0000-00000000041a'),
  1, 'disputed settlement appears as settlement_disputed');

-- 6. Open dispute.
select is(
  (select count(*)::int from public.control_tower_admin_exceptions()
    where category = 'dispute_open'
      and subject_id = '44000000-0000-0000-0000-00000000042a'),
  1, 'open dispute appears as dispute_open');

-- 7. Planned shipment with no booking (SH-128, never booked).
select is(
  (select count(*)::int from public.control_tower_admin_exceptions()
    where category = 'shipment_planned_no_booking'
      and subject_id = '44000000-0000-0000-0000-00000000036a'),
  1, 'planned shipment with no booking appears as shipment_planned_no_booking');

-- 8. Five distinct categories surface in the result set.
select is(
  (select count(distinct category)::int from public.control_tower_admin_exceptions()
    where subject_id in (
      '44000000-0000-0000-0000-00000000038a',
      '44000000-0000-0000-0000-00000000039a',
      '44000000-0000-0000-0000-00000000041a',
      '44000000-0000-0000-0000-00000000042a',
      '44000000-0000-0000-0000-00000000036a'
    )),
  5, 'all 5 derived exception categories surface in the result set');

reset role;
select * from finish();
rollback;
