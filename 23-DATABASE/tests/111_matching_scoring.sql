-- CC-41 Test 111 — Matching scoring correctness.
--
-- Builds one shipment plus a carrier with three capacity rows that hit each
-- bucket of the scoring model, then verifies the totals and ordering.
--
-- Assertions (7):
--   1. perfect-match listing scores 100
--   2. transport-mode mismatch zeroes the mode component (other criteria still
--      contribute under the soft-weights model)
--   3. partial-origin (country-only) loses the city refinement (5 pts)
--   4. listing outside availability window scores -15 vs full
--   5. find_matching_carriers ranks the perfect carrier first
--   6. profile-only fallback caps at 10
--   7. find_matching_capacity sorts by score descending

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', '111-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('41000000-0000-0000-0000-00000000020a', 'tenant-111', 'تست', 'Test 111');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('41000000-0000-0000-0000-00000000021a', '41000000-0000-0000-0000-00000000020a',
   'buy-111', 'خریدار', 'Buyer 111', 'buyer', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000022a', '41000000-0000-0000-0000-00000000020a',
   'sup-111', 'تأمین', 'Supplier 111', 'supplier', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000023a', '41000000-0000-0000-0000-00000000020a',
   'carr-111', 'حمل', 'Carrier 111', 'carrier', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000023b', '41000000-0000-0000-0000-00000000020a',
   'carr-111b', 'حمل ب', 'Carrier 111B', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('41000000-0000-0000-0000-000000000201', '41000000-0000-0000-0000-00000000020a',
   '41000000-0000-0000-0000-00000000021a', 'Buyer', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '41000000-0000-0000-0000-00000000020a', '41000000-0000-0000-0000-00000000021a',
       '41000000-0000-0000-0000-000000000201', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '41000000-0000-0000-0000-000000000201', r.id, 'organization', '41000000-0000-0000-0000-00000000021a'
  from identity.roles r where r.code = 'buyer_admin';

-- Minimal shipment chain (rfq + offer + contract + shipment).
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status,
                          visibility, preferred_currency)
values ('41000000-0000-0000-0000-00000000025a',
        '41000000-0000-0000-0000-00000000020a',
        '41000000-0000-0000-0000-00000000021a',
        '41000000-0000-0000-0000-000000000201',
        'RFQ-111', 'Stub', 'submitted', 'private_invited', 'USD');

insert into offer.supplier_offers (id, tenant_id, organization_id, request_id,
                                    supplier_id, offer_code, currency, status)
values ('41000000-0000-0000-0000-00000000025b',
        '41000000-0000-0000-0000-00000000020a',
        '41000000-0000-0000-0000-00000000022a',
        '41000000-0000-0000-0000-00000000025a',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000022a'),
        'OF-111', 'USD', 'submitted');

insert into evaluation.offer_decisions (id, tenant_id, organization_id,
                                        request_id, offer_id, decision_status)
values ('41000000-0000-0000-0000-00000000025c',
        '41000000-0000-0000-0000-00000000020a',
        '41000000-0000-0000-0000-00000000021a',
        '41000000-0000-0000-0000-00000000025a',
        '41000000-0000-0000-0000-00000000025b',
        'selected_for_contract');

insert into contract.contract_preparations (id, tenant_id, organization_id,
                                             request_id, offer_id, decision_id,
                                             supplier_id, preparation_code,
                                             title, status)
values ('41000000-0000-0000-0000-00000000025d',
        '41000000-0000-0000-0000-00000000020a',
        '41000000-0000-0000-0000-00000000021a',
        '41000000-0000-0000-0000-00000000025a',
        '41000000-0000-0000-0000-00000000025b',
        '41000000-0000-0000-0000-00000000025c',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000022a'),
        'PREP-111', 'Prep 111', 'ready_for_contract');

insert into contract.executed_contracts (id, tenant_id, organization_id,
                                          preparation_id, request_id, offer_id,
                                          decision_id, supplier_id, contract_code,
                                          status, contract_type, title, currency,
                                          executed_at)
values ('41000000-0000-0000-0000-00000000026a',
        '41000000-0000-0000-0000-00000000020a',
        '41000000-0000-0000-0000-00000000021a',
        '41000000-0000-0000-0000-00000000025d',
        '41000000-0000-0000-0000-00000000025a',
        '41000000-0000-0000-0000-00000000025b',
        '41000000-0000-0000-0000-00000000025c',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000022a'),
        'CTR-111', 'executed', 'spot', 'CT-111', 'USD', now());

-- Shipment IR Tehran → DE Berlin via road, pickup in 7 days.
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id,
                                 request_id, offer_id, supplier_id, shipment_code,
                                 status, transport_mode,
                                 origin_country, origin_city,
                                 destination_country, destination_city,
                                 planned_pickup_date)
values ('41000000-0000-0000-0000-00000000027a',
        '41000000-0000-0000-0000-00000000020a',
        '41000000-0000-0000-0000-00000000021a',
        '41000000-0000-0000-0000-00000000026a',
        '41000000-0000-0000-0000-00000000025a',
        '41000000-0000-0000-0000-00000000025b',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000022a'),
        'SH-111', 'planned', 'road',
        'IR', 'Tehran',
        'DE', 'Berlin',
        now() + interval '7 days');

-- Carrier 111: fully complete profile + public visibility.
insert into marketplace.carrier_profiles (
  tenant_id, organization_id,
  display_name_fa, display_name_en, bio_fa, bio_en,
  transport_modes, service_country_codes, fleet_size_hint, status
) values (
  '41000000-0000-0000-0000-00000000020a',
  '41000000-0000-0000-0000-00000000023a',
  'حمل کامل', 'Full Carrier', 'توضیح', 'desc',
  array['road'::shipment.transport_mode, 'rail'::shipment.transport_mode],
  array['IR'::citext, 'DE'::citext],
  50, 'active'
);
insert into marketplace.carrier_directory_visibility (
  carrier_organization_id, tenant_id, is_public, published_at
) values (
  '41000000-0000-0000-0000-00000000023a',
  '41000000-0000-0000-0000-00000000020a', true, now()
);

-- Carrier 111b: minimal profile, no visibility — used to verify the fallback.
insert into marketplace.carrier_profiles (
  tenant_id, organization_id, display_name_fa, status
) values (
  '41000000-0000-0000-0000-00000000020a',
  '41000000-0000-0000-0000-00000000023b',
  'فقط نام', 'active'
);

-- Listings:
-- L1 (perfect match): road, IR-Tehran → DE-Berlin, window covers pickup.
insert into marketplace.capacity_listings (
  id, tenant_id, carrier_organization_id, transport_mode,
  origin_country_code, origin_city,
  destination_country_code, destination_city,
  valid_from, valid_until, status
) values (
  '41000000-0000-0000-0000-00000000028a',
  '41000000-0000-0000-0000-00000000020a',
  '41000000-0000-0000-0000-00000000023a', 'road',
  'IR'::citext, 'Tehran',
  'DE'::citext, 'Berlin',
  now() - interval '1 day', now() + interval '30 days',
  'active'
);

-- L2 (mode mismatch): air same route, same window → excluded by mode=0.
insert into marketplace.capacity_listings (
  id, tenant_id, carrier_organization_id, transport_mode,
  origin_country_code, origin_city,
  destination_country_code, destination_city,
  valid_from, valid_until, status
) values (
  '41000000-0000-0000-0000-00000000028b',
  '41000000-0000-0000-0000-00000000020a',
  '41000000-0000-0000-0000-00000000023a', 'air',
  'IR'::citext, 'Tehran',
  'DE'::citext, 'Berlin',
  now() - interval '1 day', now() + interval '30 days',
  'active'
);

-- L3 (origin country-only, destination perfect, valid window): origin city
-- mismatch shaves 5 from origin (20 → 15). Total expected: 35 + 15 + 20 + 15 + 5 + 5 = 95.
insert into marketplace.capacity_listings (
  id, tenant_id, carrier_organization_id, transport_mode,
  origin_country_code, origin_city,
  destination_country_code, destination_city,
  valid_from, valid_until, status
) values (
  '41000000-0000-0000-0000-00000000028c',
  '41000000-0000-0000-0000-00000000020a',
  '41000000-0000-0000-0000-00000000023a', 'road',
  'IR'::citext, 'Shiraz',
  'DE'::citext, 'Berlin',
  now() - interval '1 day', now() + interval '30 days',
  'active'
);

-- L4 (outside availability window): valid_until in the past relative to
-- pickup. Will be excluded by the (valid_until > now()) filter at the SQL
-- level because we set valid_until in the past. Use a window that ends 1
-- day after now() but BEFORE the pickup (7 days). Listing remains active and
-- not expired by now() check, but pickup falls outside the window, so
-- availability scores 0. Total = 35 + 20 + 20 + 0 + 5 + 5 = 85.
insert into marketplace.capacity_listings (
  id, tenant_id, carrier_organization_id, transport_mode,
  origin_country_code, origin_city,
  destination_country_code, destination_city,
  valid_from, valid_until, status
) values (
  '41000000-0000-0000-0000-00000000028d',
  '41000000-0000-0000-0000-00000000020a',
  '41000000-0000-0000-0000-00000000023a', 'road',
  'IR'::citext, 'Tehran',
  'DE'::citext, 'Berlin',
  now() - interval '1 day', now() + interval '2 days',
  'active'
);

select set_config('request.jwt.claims',
  jsonb_build_object('sub','41000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','41000000-0000-0000-0000-00000000020a',
                     'organization_id','41000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '41000000-0000-0000-0000-000000000201', true);
set local role authenticated;

select plan(7);

-- 1. Perfect-match listing scores 100.
select is(
  (select score from marketplace.find_matching_capacity(
     '41000000-0000-0000-0000-00000000027a'::uuid, 25)
    where capacity_listing_id = '41000000-0000-0000-0000-00000000028a'),
  100, 'L1 perfect match scores 100');

-- 2. Mode mismatch: mode component zeros (0/35) but the row still surfaces
-- because origin/destination/availability/profile/visibility add up to >0.
-- 0 + 20 + 20 + 15 + 5 + 5 = 65.
select is(
  (select score from marketplace.find_matching_capacity(
     '41000000-0000-0000-0000-00000000027a'::uuid, 25)
    where capacity_listing_id = '41000000-0000-0000-0000-00000000028b'),
  65, 'L2 mode-mismatch listing scores 65 (mode zeroed, others intact)');

-- 3. Origin city mismatch scores 95 (35 + 15 + 20 + 15 + 5 + 5).
select is(
  (select score from marketplace.find_matching_capacity(
     '41000000-0000-0000-0000-00000000027a'::uuid, 25)
    where capacity_listing_id = '41000000-0000-0000-0000-00000000028c'),
  95, 'L3 origin-city mismatch scores 95');

-- 4. Outside window scores 85 (35 + 20 + 20 + 0 + 5 + 5).
select is(
  (select score from marketplace.find_matching_capacity(
     '41000000-0000-0000-0000-00000000027a'::uuid, 25)
    where capacity_listing_id = '41000000-0000-0000-0000-00000000028d'),
  85, 'L4 outside-window listing scores 85');

-- 5. Carrier ranking: full carrier comes first.
select is(
  (select carrier_organization_id from marketplace.find_matching_carriers(
     '41000000-0000-0000-0000-00000000027a'::uuid, 5
   ) limit 1),
  '41000000-0000-0000-0000-00000000023a'::uuid,
  'Carrier 111 is the top-ranked carrier');

-- 6. Profile-only fallback for carrier 111b: profile has display_name only
-- (1 pt) + status active. No visibility. So score = 1 + 0 = 1 (capped at 10).
select is(
  (select score from marketplace.find_matching_carriers(
     '41000000-0000-0000-0000-00000000027a'::uuid, 10)
    where carrier_organization_id = '41000000-0000-0000-0000-00000000023b'),
  1, 'Carrier 111B profile-only fallback scores 1');

-- 7. Capacity rows ordered by score desc.
select ok(
  (
    with rs as (
      select score, row_number() over (order by score desc) rn,
             row_number() over () rn_actual
        from marketplace.find_matching_capacity(
          '41000000-0000-0000-0000-00000000027a'::uuid, 25
        )
    )
    select bool_and(rn = rn_actual) from rs
  ),
  'capacity results sorted by score descending');

reset role;
select * from finish();
rollback;
