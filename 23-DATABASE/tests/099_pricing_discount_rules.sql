-- CC-23 Test 099 — discount_rules: catalog-only RLS + supplier scoping.
--
-- Assertions (6):
--   1. supplier-org member sees own discount_rules via RLS
--   2. non-member of supplier cannot see foreign discount_rules
--   3. anon cannot SELECT discount_rules (42501)
--   4. unique (tenant_id, supplier_id, lower(code)) — duplicate insert rejected (23505)
--   5. discount_rules.kind/application accept all 3 enum values
--   6. discount_rules is informational only — quotation totals are NOT auto-reduced by an active rule

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '99000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '099-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '99000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '099-other@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('99000000-0000-0000-0000-00000000000a', 'tenant-099', 'تست', 'Test 099');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('99000000-0000-0000-0000-00000000001a', '99000000-0000-0000-0000-00000000000a',
   'sup-org-099', 'تامین', 'Sup Org 099', 'buyer', 'active'),
  ('99000000-0000-0000-0000-00000000001b', '99000000-0000-0000-0000-00000000000a',
   'other-org-099', 'دیگر', 'Other Org 099', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('99000000-0000-0000-0000-000000000001', '99000000-0000-0000-0000-00000000000a',
   '99000000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active'),
  ('99000000-0000-0000-0000-000000000002', '99000000-0000-0000-0000-00000000000a',
   '99000000-0000-0000-0000-00000000001b', 'Other', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '99000000-0000-0000-0000-00000000000a',
       '99000000-0000-0000-0000-00000000001a',
       '99000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '99000000-0000-0000-0000-00000000000a',
       '99000000-0000-0000-0000-00000000001b',
       '99000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('99000000-0000-0000-0000-00000000aaaa',
   '99000000-0000-0000-0000-00000000000a',
   '99000000-0000-0000-0000-00000000001a', 'approved', 'verified');

-- Seed three discount rules (one per enum kind).
insert into pricing.discount_rules (id, tenant_id, supplier_id, code, name_en, name_fa,
                                    kind, application, threshold_qty, amount, currency_code, active)
values
  ('99000000-0000-0000-0000-00000000ddd1',
   '99000000-0000-0000-0000-00000000000a',
   '99000000-0000-0000-0000-00000000aaaa',
   'TIER-100', 'Volume tier 100', 'پلهٔ ۱۰۰',
   'volume_tier', 'percent_off', 100, 5, 'USD', true),
  ('99000000-0000-0000-0000-00000000ddd2',
   '99000000-0000-0000-0000-00000000000a',
   '99000000-0000-0000-0000-00000000aaaa',
   'CONTRACT-A', 'Contract A', 'قرارداد آ',
   'contract_term', 'fixed_amount_off', null, 250, 'USD', true),
  ('99000000-0000-0000-0000-00000000ddd3',
   '99000000-0000-0000-0000-00000000000a',
   '99000000-0000-0000-0000-00000000aaaa',
   'MAN-OVR', 'Manual override', 'دستی',
   'manual', 'unit_price_override', null, 7.5, 'USD', true);

select plan(6);

-- 1. supplier-org member sees own rules
select tests.authenticate_as(
  '99000000-0000-0000-0000-000000000001',
  '99000000-0000-0000-0000-00000000000a',
  '99000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from pricing.discount_rules
    where supplier_id = '99000000-0000-0000-0000-00000000aaaa'),
  3, 'supplier-org member sees 3 own discount_rules'
);
reset role;

-- 2. non-member cannot see foreign rules
select tests.authenticate_as(
  '99000000-0000-0000-0000-000000000002',
  '99000000-0000-0000-0000-00000000000a',
  '99000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select is(
  (select count(*)::int from pricing.discount_rules
    where supplier_id = '99000000-0000-0000-0000-00000000aaaa'),
  0, 'non-supplier-org member sees 0 foreign discount_rules'
);
reset role;

-- 3. anon → 42501
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select count(*) from pricing.discount_rules $$,
  '42501', null,
  'anon has no SELECT privilege on pricing.discount_rules'
);
reset role;

-- 4. duplicate code (same tenant + supplier + lower(code)) rejected
select throws_ok(
  $$ insert into pricing.discount_rules
       (tenant_id, supplier_id, code, name_en, name_fa, kind, application)
     values ('99000000-0000-0000-0000-00000000000a',
             '99000000-0000-0000-0000-00000000aaaa',
             'tier-100', 'dup', 'تکراری',
             'volume_tier', 'percent_off') $$,
  '23505', null,
  'duplicate (tenant, supplier, lower(code)) rejected by unique index (23505)'
);

-- 5. all 3 kinds accepted
select is(
  (select count(distinct kind)::int from pricing.discount_rules
    where supplier_id = '99000000-0000-0000-0000-00000000aaaa'),
  3, 'all 3 discount kinds (volume_tier, contract_term, manual) accepted'
);

-- 6. Catalog-only: a quotation total ignores rule existence (Q7=A).
-- Build a quotation; total is the sum of line totals, not reduced by discount_rules.
insert into commodity.categories (id, code, name_fa, name_en) values
  ('99000000-0000-0000-0000-00000000bbbb', 'cat-099', 'دسته', 'Cat 099');
insert into commodity.products (id, category_id, code, slug, name_fa, name_en, status, unit_of_trade) values
  ('99000000-0000-0000-0000-00000000cccc',
   '99000000-0000-0000-0000-00000000bbbb',
   'prod-099', 'prod-099', 'محصول', 'Product 099', 'active', 'kg');

select tests.authenticate_as(
  '99000000-0000-0000-0000-000000000001',
  '99000000-0000-0000-0000-00000000000a',
  '99000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_q uuid; v_i uuid;
begin
  v_q := pricing.portal_create_quotation(
    '99000000-0000-0000-0000-00000000aaaa'::uuid,
    '99000000-0000-0000-0000-00000000001b'::uuid,
    'Q-099', 'USD'::char(3), null, now() + interval '7 days'
  );
  v_i := pricing.portal_add_quotation_item(
    v_q, '99000000-0000-0000-0000-00000000cccc'::uuid,
    150, 'kg', 10, 0, null, null
  );
  -- expected total = 150 * 10 - 0 = 1500 ; volume_tier rule of 5% off NOT auto-applied
  perform set_config('test.q_id', v_q::text, false);
end;
$$;
reset role;

select is(
  (select total_amount from pricing.quotations where id = current_setting('test.q_id')::uuid),
  1500::numeric(20,4),
  'quotation total ignores volume_tier rule existence (Q7=A: catalog-only)'
);

select * from finish();
rollback;
