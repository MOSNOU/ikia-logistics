-- CC-41 Test 112 — Admin matching summary.
--
-- Assertions (4):
--   1. admin_matching_summary returns a jsonb object
--   2. total_match_requests = number of eligible shipments (planned/booked/in_transit)
--   3. unmatched_shipments counts shipments with zero top-score
--   4. top_carriers is a jsonb array (possibly empty)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', '112-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000399', 'authenticated', 'authenticated', '112-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('41000000-0000-0000-0000-00000000030a', 'tenant-112', 'تست', 'Test 112');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('41000000-0000-0000-0000-00000000031a', '41000000-0000-0000-0000-00000000030a',
   'buy-112', 'خریدار', 'Buyer 112', 'buyer', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000032a', '41000000-0000-0000-0000-00000000030a',
   'sup-112', 'تأمین', 'Supplier 112', 'supplier', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000033a', '41000000-0000-0000-0000-00000000030a',
   'carr-112', 'حمل', 'Carrier 112', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('41000000-0000-0000-0000-000000000301', '41000000-0000-0000-0000-00000000030a',
   '41000000-0000-0000-0000-00000000031a', 'Buyer', 'fa', 'active'),
  ('41000000-0000-0000-0000-000000000399', '41000000-0000-0000-0000-00000000030a',
   '41000000-0000-0000-0000-00000000031a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '41000000-0000-0000-0000-000000000399', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status,
                          visibility, preferred_currency)
values ('41000000-0000-0000-0000-00000000035a',
        '41000000-0000-0000-0000-00000000030a',
        '41000000-0000-0000-0000-00000000031a',
        '41000000-0000-0000-0000-000000000301',
        'RFQ-112', 'Stub', 'submitted', 'private_invited', 'USD');

insert into offer.supplier_offers (id, tenant_id, organization_id, request_id,
                                    supplier_id, offer_code, currency, status)
values ('41000000-0000-0000-0000-00000000035b',
        '41000000-0000-0000-0000-00000000030a',
        '41000000-0000-0000-0000-00000000032a',
        '41000000-0000-0000-0000-00000000035a',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000032a'),
        'OF-112', 'USD', 'submitted');

insert into evaluation.offer_decisions (id, tenant_id, organization_id,
                                        request_id, offer_id, decision_status)
values ('41000000-0000-0000-0000-00000000035c',
        '41000000-0000-0000-0000-00000000030a',
        '41000000-0000-0000-0000-00000000031a',
        '41000000-0000-0000-0000-00000000035a',
        '41000000-0000-0000-0000-00000000035b',
        'selected_for_contract');

insert into contract.contract_preparations (id, tenant_id, organization_id,
                                             request_id, offer_id, decision_id,
                                             supplier_id, preparation_code,
                                             title, status)
values ('41000000-0000-0000-0000-00000000035d',
        '41000000-0000-0000-0000-00000000030a',
        '41000000-0000-0000-0000-00000000031a',
        '41000000-0000-0000-0000-00000000035a',
        '41000000-0000-0000-0000-00000000035b',
        '41000000-0000-0000-0000-00000000035c',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000032a'),
        'PREP-112', 'Prep 112', 'ready_for_contract');

insert into contract.executed_contracts (id, tenant_id, organization_id,
                                          preparation_id, request_id, offer_id,
                                          decision_id, supplier_id, contract_code,
                                          status, contract_type, title, currency,
                                          executed_at)
values ('41000000-0000-0000-0000-00000000036a',
        '41000000-0000-0000-0000-00000000030a',
        '41000000-0000-0000-0000-00000000031a',
        '41000000-0000-0000-0000-00000000035d',
        '41000000-0000-0000-0000-00000000035a',
        '41000000-0000-0000-0000-00000000035b',
        '41000000-0000-0000-0000-00000000035c',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000032a'),
        'CTR-112', 'executed', 'spot', 'CT-112', 'USD', now());

-- Two eligible shipments (planned + booked).
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id,
                                 request_id, offer_id, supplier_id, shipment_code,
                                 status, transport_mode,
                                 origin_country, destination_country, planned_pickup_date)
values
  ('41000000-0000-0000-0000-00000000037a',
   '41000000-0000-0000-0000-00000000030a',
   '41000000-0000-0000-0000-00000000031a',
   '41000000-0000-0000-0000-00000000036a',
   '41000000-0000-0000-0000-00000000035a',
   '41000000-0000-0000-0000-00000000035b',
   (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000032a'),
   'SH-112A', 'planned', 'road', 'IR', 'DE', now() + interval '7 days'),
  ('41000000-0000-0000-0000-00000000037b',
   '41000000-0000-0000-0000-00000000030a',
   '41000000-0000-0000-0000-00000000031a',
   '41000000-0000-0000-0000-00000000036a',
   '41000000-0000-0000-0000-00000000035a',
   '41000000-0000-0000-0000-00000000035b',
   (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000032a'),
   'SH-112B', 'booked', 'sea', 'IR', 'DE', now() + interval '14 days');

-- No marketplace data: both shipments will be unmatched because there are no
-- active capacity listings to score against. This isolates the
-- unmatched_shipments KPI from scoring nuance and avoids the soft-weights
-- side effect where partial-match listings still score > 0.

select set_config('request.jwt.claims',
  jsonb_build_object('sub','41000000-0000-0000-0000-000000000399','role','authenticated',
                     'tenant_id','41000000-0000-0000-0000-00000000030a')::text, true);
select set_config('request.jwt.claim.sub', '41000000-0000-0000-0000-000000000399', true);
set local role authenticated;

select plan(4);

-- 1. Result is a jsonb object.
select is(
  jsonb_typeof(marketplace.admin_matching_summary()),
  'object', 'admin_matching_summary returns a jsonb object');

-- 2. total_match_requests = 2 (the two eligible shipments).
select is(
  (marketplace.admin_matching_summary()->>'total_match_requests')::int,
  2, 'total_match_requests counts eligible shipments');

-- 3. unmatched_shipments = 2 (no active listings → both shipments unmatched).
select is(
  (marketplace.admin_matching_summary()->>'unmatched_shipments')::int,
  2, 'unmatched_shipments counts shipments with no scored capacity');

-- 4. top_carriers is a jsonb array.
select is(
  jsonb_typeof(marketplace.admin_matching_summary()->'top_carriers'),
  'array', 'top_carriers is a jsonb array');

reset role;
select * from finish();
rollback;
