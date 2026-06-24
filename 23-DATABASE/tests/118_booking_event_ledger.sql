-- CC-42 Test 118 — Booking event ledger integrity (Q9=A immutable).
--
-- Assertions (6):
--   1. After buyer_create + carrier_accept + buyer_confirm, exactly 3 events
--      exist in chronological from→to chain (draft→pending→accepted→confirmed)
--   2. Direct INSERT into booking_events as authenticated is denied
--   3. UPDATE on booking_events is denied
--   4. DELETE on booking_events is denied
--   5. RLS lets the buyer SELECT their own events
--   6. RLS lets the carrier SELECT events on bookings against their org

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', '118-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '42000000-0000-0000-0000-000000000302', 'authenticated', 'authenticated', '118-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('42000000-0000-0000-0000-00000000030a', 'tenant-118', 'تست', 'Test 118');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('42000000-0000-0000-0000-00000000031a', '42000000-0000-0000-0000-00000000030a',
   'buy-118', 'خریدار', 'Buyer 118', 'buyer', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000032a', '42000000-0000-0000-0000-00000000030a',
   'sup-118', 'تأمین', 'Supplier 118', 'supplier', 'active', 'IR'),
  ('42000000-0000-0000-0000-00000000033a', '42000000-0000-0000-0000-00000000030a',
   'carr-118', 'حمل', 'Carrier 118', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('42000000-0000-0000-0000-000000000301', '42000000-0000-0000-0000-00000000030a',
   '42000000-0000-0000-0000-00000000031a', 'Buyer', 'fa', 'active'),
  ('42000000-0000-0000-0000-000000000302', '42000000-0000-0000-0000-00000000030a',
   '42000000-0000-0000-0000-00000000033a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000030a', '42000000-0000-0000-0000-00000000031a',
       '42000000-0000-0000-0000-000000000301', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000301', r.id, 'organization', '42000000-0000-0000-0000-00000000031a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '42000000-0000-0000-0000-00000000030a', '42000000-0000-0000-0000-00000000033a',
       '42000000-0000-0000-0000-000000000302', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '42000000-0000-0000-0000-000000000302', r.id, 'organization', '42000000-0000-0000-0000-00000000033a'
  from identity.roles r where r.code = 'carrier_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('42000000-0000-0000-0000-00000000034a', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000031a', '42000000-0000-0000-0000-000000000301',
        'RFQ-118', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('42000000-0000-0000-0000-00000000034b', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000032a', '42000000-0000-0000-0000-00000000034a',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000032a'),
        'OF-118', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('42000000-0000-0000-0000-00000000034c', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000031a', '42000000-0000-0000-0000-00000000034a',
        '42000000-0000-0000-0000-00000000034b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('42000000-0000-0000-0000-00000000034d', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000031a', '42000000-0000-0000-0000-00000000034a',
        '42000000-0000-0000-0000-00000000034b', '42000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000032a'),
        'PREP-118', 'Prep 118', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('42000000-0000-0000-0000-00000000035a', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000031a', '42000000-0000-0000-0000-00000000034d',
        '42000000-0000-0000-0000-00000000034a', '42000000-0000-0000-0000-00000000034b',
        '42000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000032a'),
        'CTR-118', 'executed', 'spot', 'CT-118', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('42000000-0000-0000-0000-00000000036a', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000031a', '42000000-0000-0000-0000-00000000035a',
        '42000000-0000-0000-0000-00000000034a', '42000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '42000000-0000-0000-0000-00000000032a'),
        'SH-118', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('42000000-0000-0000-0000-00000000030a', '42000000-0000-0000-0000-00000000033a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('42000000-0000-0000-0000-00000000033a', '42000000-0000-0000-0000-00000000030a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('42000000-0000-0000-0000-00000000037a', '42000000-0000-0000-0000-00000000030a',
        '42000000-0000-0000-0000-00000000033a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Build the full flow.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000030a',
                     'organization_id','42000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000301', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '42000000-0000-0000-0000-00000000036a',
    p_capacity_listing_id => '42000000-0000-0000-0000-00000000037a'
  );
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000030a',
                     'organization_id','42000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000302', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(
    (select id from marketplace.booking_requests
      where shipment_id = '42000000-0000-0000-0000-00000000036a' limit 1),
    null
  );
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000030a',
                     'organization_id','42000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000301', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(
    (select id from marketplace.booking_requests
      where shipment_id = '42000000-0000-0000-0000-00000000036a' limit 1)
  );
end $$;

select plan(6);

-- 1. Exactly 3 events recorded across the full flow.
select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000036a'),
  3, 'three events recorded across the create→accept→confirm flow');

-- 2. Direct INSERT into booking_events as authenticated is denied (no INSERT policy).
select throws_ok(
  $$ insert into marketplace.booking_events (
       tenant_id, booking_request_id, to_status, event_type, actor_party
     )
     select tenant_id, id, 'expired'::marketplace.booking_status, 'spoof', 'system'
       from marketplace.booking_requests
       where shipment_id = '42000000-0000-0000-0000-00000000036a' limit 1 $$,
  '42501', NULL,
  'direct INSERT into booking_events as authenticated is denied');

-- 3. UPDATE denied.
select throws_ok(
  $$ update marketplace.booking_events set reason = 'tamper'
       where booking_request_id in (
         select id from marketplace.booking_requests
          where shipment_id = '42000000-0000-0000-0000-00000000036a'
       ) $$,
  '42501', NULL,
  'UPDATE on booking_events is denied');

-- 4. DELETE denied.
select throws_ok(
  $$ delete from marketplace.booking_events
       where booking_request_id in (
         select id from marketplace.booking_requests
          where shipment_id = '42000000-0000-0000-0000-00000000036a'
       ) $$,
  '42501', NULL,
  'DELETE on booking_events is denied');

-- 5. Buyer can SELECT the events via RLS.
select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000036a'),
  3, 'buyer can SELECT all 3 events under RLS');

-- 6. Carrier can SELECT the events via RLS (switch roles).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','42000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','42000000-0000-0000-0000-00000000030a',
                     'organization_id','42000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '42000000-0000-0000-0000-000000000302', true);
set local role authenticated;

select is(
  (select count(*)::int from marketplace.booking_events e
    join marketplace.booking_requests br on br.id = e.booking_request_id
   where br.shipment_id = '42000000-0000-0000-0000-00000000036a'),
  3, 'carrier can SELECT all 3 events under RLS');

reset role;
select * from finish();
rollback;
