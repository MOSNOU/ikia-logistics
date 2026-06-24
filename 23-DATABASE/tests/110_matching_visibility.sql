-- CC-41 Test 110 — Matching RPC shipment visibility.
--
-- Assertions (5):
--   1. unknown shipment id → find_matching_capacity raises P0002
--   2. supplier_admin (Q4=A no supplier visibility) → 42501
--   3. buyer_admin on a different org → 42501
--   4. buyer_admin on the owning org → succeeds (returns 0 rows when no listing exists)
--   5. non-admin caller cannot invoke admin_matching_summary (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '110-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '110-other-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '110-supplier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '41000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '110-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('41000000-0000-0000-0000-00000000000a', 'tenant-110', 'تست', 'Test 110');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('41000000-0000-0000-0000-00000000001a', '41000000-0000-0000-0000-00000000000a',
   'buy-110', 'خریدار', 'Buyer 110', 'buyer', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000001b', '41000000-0000-0000-0000-00000000000a',
   'buy-110b', 'خریدار ب', 'Buyer 110B', 'buyer', 'active', 'IR'),
  ('41000000-0000-0000-0000-00000000002a', '41000000-0000-0000-0000-00000000000a',
   'sup-110', 'تأمین', 'Supplier 110', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('41000000-0000-0000-0000-000000000001', '41000000-0000-0000-0000-00000000000a',
   '41000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('41000000-0000-0000-0000-000000000002', '41000000-0000-0000-0000-00000000000a',
   '41000000-0000-0000-0000-00000000001b', 'OtherBuyer', 'fa', 'active'),
  ('41000000-0000-0000-0000-000000000003', '41000000-0000-0000-0000-00000000000a',
   '41000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active'),
  ('41000000-0000-0000-0000-000000000099', '41000000-0000-0000-0000-00000000000a',
   '41000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '41000000-0000-0000-0000-00000000000a', '41000000-0000-0000-0000-00000000001a',
       '41000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '41000000-0000-0000-0000-000000000001', r.id, 'organization', '41000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '41000000-0000-0000-0000-00000000000a', '41000000-0000-0000-0000-00000000001b',
       '41000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '41000000-0000-0000-0000-000000000002', r.id, 'organization', '41000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '41000000-0000-0000-0000-00000000000a', '41000000-0000-0000-0000-00000000002a',
       '41000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '41000000-0000-0000-0000-000000000003', r.id, 'organization', '41000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '41000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Build a minimal shipment via direct insert to avoid running the buyer
-- create-shipment RPC pipeline (which needs RFQ/offer/contract chain). The
-- matching gate cares only about visibility and shipment existence.
-- Build the chain (rfq → offer → decision → preparation → executed_contract)
-- with minimal stub rows to satisfy the shipment.shipments FK constraints.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status,
                          visibility, preferred_currency)
values ('41000000-0000-0000-0000-00000000004a',
        '41000000-0000-0000-0000-00000000000a',
        '41000000-0000-0000-0000-00000000001a',
        '41000000-0000-0000-0000-000000000001',
        'RFQ-110', 'Stub RFQ', 'submitted', 'private_invited', 'USD');

insert into offer.supplier_offers (id, tenant_id, organization_id, request_id,
                                    supplier_id, offer_code, currency, status)
values ('41000000-0000-0000-0000-00000000004b',
        '41000000-0000-0000-0000-00000000000a',
        '41000000-0000-0000-0000-00000000002a',
        '41000000-0000-0000-0000-00000000004a',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000002a'),
        'OF-110', 'USD', 'submitted');

insert into evaluation.offer_decisions (id, tenant_id, organization_id,
                                        request_id, offer_id, decision_status)
values ('41000000-0000-0000-0000-00000000004c',
        '41000000-0000-0000-0000-00000000000a',
        '41000000-0000-0000-0000-00000000001a',
        '41000000-0000-0000-0000-00000000004a',
        '41000000-0000-0000-0000-00000000004b',
        'selected_for_contract');

insert into contract.contract_preparations (id, tenant_id, organization_id,
                                             request_id, offer_id, decision_id,
                                             supplier_id, preparation_code,
                                             title, status)
values ('41000000-0000-0000-0000-00000000004d',
        '41000000-0000-0000-0000-00000000000a',
        '41000000-0000-0000-0000-00000000001a',
        '41000000-0000-0000-0000-00000000004a',
        '41000000-0000-0000-0000-00000000004b',
        '41000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000002a'),
        'PREP-110', 'Prep 110', 'ready_for_contract');

insert into contract.executed_contracts (id, tenant_id, organization_id,
                                          preparation_id, request_id, offer_id,
                                          decision_id, supplier_id, contract_code,
                                          status, contract_type, title, currency,
                                          executed_at)
values ('41000000-0000-0000-0000-00000000003a',
        '41000000-0000-0000-0000-00000000000a',
        '41000000-0000-0000-0000-00000000001a',
        '41000000-0000-0000-0000-00000000004d',
        '41000000-0000-0000-0000-00000000004a',
        '41000000-0000-0000-0000-00000000004b',
        '41000000-0000-0000-0000-00000000004c',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000002a'),
        'CTR-110', 'executed', 'spot', 'CT-110', 'USD', now());

insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id,
                                 request_id, offer_id, supplier_id, shipment_code,
                                 status, transport_mode,
                                 origin_country, destination_country, planned_pickup_date)
values ('41000000-0000-0000-0000-00000000006a',
        '41000000-0000-0000-0000-00000000000a',
        '41000000-0000-0000-0000-00000000001a',
        '41000000-0000-0000-0000-00000000003a',
        '41000000-0000-0000-0000-00000000004a',
        '41000000-0000-0000-0000-00000000004b',
        (select id from supplier.suppliers where organization_id = '41000000-0000-0000-0000-00000000002a'),
        'SH-110', 'planned', 'road',
        'IR', 'DE', now() + interval '7 days');

select plan(5);

-- 1. Unknown shipment id → P0002.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','41000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','41000000-0000-0000-0000-00000000000a',
                     'organization_id','41000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '41000000-0000-0000-0000-000000000001', true);
set local role authenticated;

select throws_ok(
  $$ select * from marketplace.find_matching_capacity(
       '00000000-0000-0000-0000-000000000000'::uuid
     ) $$,
  'P0002', NULL,
  'unknown shipment id → P0002');

-- 2. Supplier role denied.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','41000000-0000-0000-0000-000000000003','role','authenticated',
                     'tenant_id','41000000-0000-0000-0000-00000000000a',
                     'organization_id','41000000-0000-0000-0000-00000000002a')::text, true);
select set_config('request.jwt.claim.sub', '41000000-0000-0000-0000-000000000003', true);

select throws_ok(
  $$ select * from marketplace.find_matching_capacity(
       '41000000-0000-0000-0000-00000000006a'::uuid
     ) $$,
  '42501', NULL,
  'supplier role denied (Q4=A)');

-- 3. Buyer on a different org denied.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','41000000-0000-0000-0000-000000000002','role','authenticated',
                     'tenant_id','41000000-0000-0000-0000-00000000000a',
                     'organization_id','41000000-0000-0000-0000-00000000001b')::text, true);
select set_config('request.jwt.claim.sub', '41000000-0000-0000-0000-000000000002', true);

select throws_ok(
  $$ select * from marketplace.find_matching_capacity(
       '41000000-0000-0000-0000-00000000006a'::uuid
     ) $$,
  '42501', NULL,
  'buyer on a different org denied');

-- 4. Owning buyer succeeds (no listings yet → 0 rows).
select set_config('request.jwt.claims',
  jsonb_build_object('sub','41000000-0000-0000-0000-000000000001','role','authenticated',
                     'tenant_id','41000000-0000-0000-0000-00000000000a',
                     'organization_id','41000000-0000-0000-0000-00000000001a')::text, true);
select set_config('request.jwt.claim.sub', '41000000-0000-0000-0000-000000000001', true);

select is(
  (select count(*)::int from marketplace.find_matching_capacity(
     '41000000-0000-0000-0000-00000000006a'::uuid
   )),
  0, 'owning buyer can call; no listings yet so 0 matches');

-- 5. Non-admin → admin_matching_summary denied.
select throws_ok(
  $$ select marketplace.admin_matching_summary() $$,
  '42501', NULL,
  'non-admin cannot call admin_matching_summary');

reset role;
select * from finish();
rollback;
