-- CC-42 Test 117 — Booking admin moderation.
--
-- Assertions (5):
--   1. admin_cancel from pending_carrier succeeds → buyer_cancelled
--   2. admin cancel event has actor_party='admin'
--   3. admin_cancel records admin_action=true in payload
--   4. admin_cancel on terminal state (already cancelled) raises P0001
--   5. non-admin cannot call admin_cancel_booking (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

-- Fixture
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', '117-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000299', 'authenticated', 'authenticated', '117-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('42000000-0000-0000-0000-00000000020a', 'tenant-117', 'تست', 'Test 117');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('42000000-0000-0000-0000-00000000021a', '42000000-0000-0000-0000-00000000020a',
   'buy-117', 'خریدار', 'Buyer 117', 'buyer', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000022a', '42000000-0000-0000-0000-00000000020a',
   'sup-117', 'تأمین', 'Supplier 117', 'supplier', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000023a', '42000000-0000-0000-0000-00000000020a',
   'carr-117', 'حمل', 'Carrier 117', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('42000000-0000-0000-0000-000000000201', '42000000-0000-0000-0000-00000000020a',
   '42000000-0000-0000-0000-00000000021a', 'Buyer', 'fa', 'active'),
  ('42000000-0000-0000-0000-000000000299', '42000000-0000-0000-0000-00000000020a',
   '42000000-0000-0000-0000-00000000021a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000020a', '42000000-0000-0000-0000-00000000021a',
       '42000000-0000-0000-0000-000000000201', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000201', r.id, 'organization', '42000000-0000-0000-0000-00000000021a'
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000299', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('42000000-0000-0000-0000-00000000024a', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000021a', '42000000-0000-0000-0000-000000000201',
        'RFQ-117', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('42000000-0000-0000-0000-00000000024b', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000022a', '42000000-0000-0000-0000-00000000024a',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000022a'),
        'OF-117', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('42000000-0000-0000-0000-00000000024c', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000021a', '42000000-0000-0000-0000-00000000024a',
        '42000000-0000-0000-0000-00000000024b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('42000000-0000-0000-0000-00000000024d', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000021a', '42000000-0000-0000-0000-00000000024a',
        '42000000-0000-0000-0000-00000000024b', '42000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000022a'),
        'PREP-117', 'Prep 117', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('42000000-0000-0000-0000-00000000025a', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000021a', '42000000-0000-0000-0000-00000000024d',
        '42000000-0000-0000-0000-00000000024a', '42000000-0000-0000-0000-00000000024b',
        '42000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000022a'),
        'CTR-117', 'executed', 'spot', 'CT-117', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('42000000-0000-0000-0000-00000000026a', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000021a', '42000000-0000-0000-0000-00000000025a',
        '42000000-0000-0000-0000-00000000024a', '42000000-0000-0000-0000-00000000024b',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000022a'),
        'SH-117', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('42000000-0000-0000-0000-00000000020a', '42000000-0000-0000-0000-00000000023a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('42000000-0000-0000-0000-00000000023a', '42000000-0000-0000-0000-00000000020a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('42000000-0000-0000-0000-00000000027a', '42000000-0000-0000-0000-00000000020a',
        '42000000-0000-0000-0000-00000000023a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Buyer creates a booking.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000020a',
                     'organization_id','42000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '42000000-0000-0000-0000-00000000026a',
    p_capacity_listing_id => '42000000-0000-0000-0000-00000000027a'
  );
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000299','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000020a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000299', true);
set local role authenticated;

select plan(5);

-- 1. Admin cancel pending_carrier.
do $$
begin
  perform marketplace.admin_cancel_booking(
    (select id from marketplace.booking_requests
      where shipment_id = '42000000-0000-0000-0000-00000000026a' limit 1),
    'policy violation'
  );
end $$;

select is(
  (select status::text from marketplace.booking_requests
    where shipment_id = '42000000-0000-0000-0000-00000000026a' limit 1),
  'buyer_cancelled', 'admin_cancel moved booking to buyer_cancelled');

-- 2. Admin cancel event has actor_party='admin'.
select is(
  (select actor_party from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000026a'
     and e.to_status = 'buyer_cancelled' limit 1),
  'admin', 'admin cancel event has actor_party=admin');

-- 3. Admin cancel payload includes admin_action=true.
select is(
  (select (payload->>'admin_action') from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000026a'
     and e.to_status = 'buyer_cancelled' limit 1),
  'true', 'admin cancel payload includes admin_action=true');

-- 4. Admin cancel on terminal state → P0001.
select throws_ok(
  $$ select marketplace.admin_cancel_booking(
       (select id from marketplace.booking_requests
         where shipment_id = '42000000-0000-0000-0000-00000000026a' limit 1),
       null
     ) $$,
  'P0001', NULL,
  'admin cancel on terminal state raises P0001');

-- 5. Non-admin denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000020a',
                     'organization_id','42000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000201', true);
set local role authenticated;

select throws_ok(
  $$ select marketplace.admin_cancel_booking(
       (select id from marketplace.booking_requests
         where shipment_id = '42000000-0000-0000-0000-00000000026a' limit 1),
       null
     ) $$,
  '42501', NULL,
  'non-admin cannot call admin_cancel_booking');

reset role;
select * from finish();
rollback;
