-- CC-23 Test 100 — Helper RPCs: get_active_unit_price, convert_amount, compute_quote_totals.
--
-- Assertions (8):
--   1. get_active_unit_price returns unit_price for active list
--   2. get_active_unit_price returns NULL when list is draft (not active)
--   3. get_active_unit_price returns NULL when product not on any list
--   4. convert_amount returns same amount when from = to
--   5. convert_amount uses inserted rate (USD → EUR direct)
--   6. convert_amount inverts when only inverse rate exists (EUR → USD via inverse of USD→EUR)
--   7. convert_amount raises P0002 when no rate exists for the pair
--   8. compute_quote_totals updates parent totals to match items

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '100-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '100-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('10000000-0000-0000-0000-00000000000a', 'tenant-100', 'تست', 'Test 100');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('10000000-0000-0000-0000-00000000001a', '10000000-0000-0000-0000-00000000000a',
   'sup-org-100', 'تامین', 'Sup Org 100', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-00000000000a',
   '10000000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active'),
  ('10000000-0000-0000-0000-000000000099', '10000000-0000-0000-0000-00000000000a',
   '10000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '10000000-0000-0000-0000-00000000000a',
       '10000000-0000-0000-0000-00000000001a',
       '10000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '10000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('10000000-0000-0000-0000-00000000aaaa',
   '10000000-0000-0000-0000-00000000000a',
   '10000000-0000-0000-0000-00000000001a', 'approved', 'verified');

insert into commodity.categories (id, code, name_fa, name_en) values
  ('10000000-0000-0000-0000-00000000bbbb', 'cat-100', 'دسته', 'Cat 100');
insert into commodity.products (id, category_id, code, slug, name_fa, name_en, status, unit_of_trade) values
  ('10000000-0000-0000-0000-00000000ccc1',
   '10000000-0000-0000-0000-00000000bbbb',
   'prod-100-a', 'prod-100-a', 'الف', 'A', 'active', 'kg'),
  ('10000000-0000-0000-0000-00000000ccc2',
   '10000000-0000-0000-0000-00000000bbbb',
   'prod-100-b', 'prod-100-b', 'ب', 'B', 'active', 'kg');

-- Active price list with prod-100-a at 9.99 USD.
insert into pricing.price_lists (id, tenant_id, supplier_id, organization_id, code,
                                 name_en, name_fa, currency_code, status, effective_from)
values ('10000000-0000-0000-0000-00000000aaa1',
        '10000000-0000-0000-0000-00000000000a',
        '10000000-0000-0000-0000-00000000aaaa',
        '10000000-0000-0000-0000-00000000001a',
        'STD-100', 'Standard', 'استاندارد', 'USD', 'active', now() - interval '1 day');
insert into pricing.price_list_items (tenant_id, price_list_id, product_id, unit_price, unit_of_measure)
values ('10000000-0000-0000-0000-00000000000a',
        '10000000-0000-0000-0000-00000000aaa1',
        '10000000-0000-0000-0000-00000000ccc1', 9.99, 'kg');

-- Draft price list with prod-100-a at 100 USD (should be ignored).
insert into pricing.price_lists (id, tenant_id, supplier_id, organization_id, code,
                                 name_en, name_fa, currency_code, status)
values ('10000000-0000-0000-0000-00000000aaa2',
        '10000000-0000-0000-0000-00000000000a',
        '10000000-0000-0000-0000-00000000aaaa',
        '10000000-0000-0000-0000-00000000001a',
        'DRAFT-100', 'Draft', 'پیش‌نویس', 'USD', 'draft');
insert into pricing.price_list_items (tenant_id, price_list_id, product_id, unit_price, unit_of_measure)
values ('10000000-0000-0000-0000-00000000000a',
        '10000000-0000-0000-0000-00000000aaa2',
        '10000000-0000-0000-0000-00000000ccc2', 100, 'kg');

select plan(8);

-- 1. active list price returned
select is(
  pricing.get_active_unit_price(
    '10000000-0000-0000-0000-00000000aaaa'::uuid,
    '10000000-0000-0000-0000-00000000ccc1'::uuid,
    'USD'::char(3), null
  ),
  9.99::numeric(20,4),
  'get_active_unit_price returns active price for prod-100-a'
);

-- 2. draft list ignored
select is(
  pricing.get_active_unit_price(
    '10000000-0000-0000-0000-00000000aaaa'::uuid,
    '10000000-0000-0000-0000-00000000ccc2'::uuid,
    'USD'::char(3), null
  ),
  null::numeric,
  'get_active_unit_price returns NULL when only list is draft'
);

-- 3. NULL when no list at all (use a fresh product id)
select is(
  pricing.get_active_unit_price(
    '10000000-0000-0000-0000-00000000aaaa'::uuid,
    '10000000-0000-0000-0000-00000000fff0'::uuid,
    'USD'::char(3), null
  ),
  null::numeric,
  'get_active_unit_price returns NULL when product has no price line'
);

-- 4. convert same currency
select is(
  pricing.convert_amount(100, 'USD'::char(3), 'USD'::char(3), null),
  100::numeric,
  'convert_amount returns same amount when from = to'
);

-- 5. Insert USD→EUR rate and convert
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000099',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.admin_set_currency_rate(
    'USD'::char(3), 'EUR'::char(3), 0.9, now() - interval '1 hour', null, 'manual'
  );
end;
$$;
reset role;

select is(
  pricing.convert_amount(100, 'USD'::char(3), 'EUR'::char(3), null),
  90::numeric,
  'convert_amount applies USD→EUR rate'
);

-- 6. inverse via EUR→USD lookup (only USD→EUR rate exists). Rounded because
-- 1/0.9 is a repeating decimal that PostgreSQL truncates at numeric precision.
select cmp_ok(
  round(pricing.convert_amount(90, 'EUR'::char(3), 'USD'::char(3), null))::int,
  '=', 100,
  'convert_amount inverts USD→EUR rate for EUR→USD (rounded ≈ 100)'
);

-- 7. no rate available raises P0002
select throws_ok(
  $$ select pricing.convert_amount(100, 'IRR'::char(3), 'EUR'::char(3), null) $$,
  'P0002', null,
  'convert_amount raises P0002 when no rate is available'
);

-- 8. compute_quote_totals updates parent
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_q uuid;
begin
  v_q := pricing.portal_create_quotation(
    '10000000-0000-0000-0000-00000000aaaa'::uuid,
    '10000000-0000-0000-0000-00000000001a'::uuid,    -- buyer = same org for simplicity
    'Q-100', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform pricing.portal_add_quotation_item(v_q,
    '10000000-0000-0000-0000-00000000ccc1'::uuid,
    20, 'kg', 5, 0, null, null);
  perform pricing.portal_add_quotation_item(v_q,
    '10000000-0000-0000-0000-00000000ccc2'::uuid,
    10, 'kg', 7, 5, null, null);
  perform set_config('test.q_id', v_q::text, false);
end;
$$;
reset role;

-- subtotal = 20*5 + 10*7 = 170 ; discount = 0+5 = 5 ; total = 100 + (70-5) = 165
select is(
  (select total_amount from pricing.quotations where id = current_setting('test.q_id')::uuid),
  165::numeric(20,4),
  'compute_quote_totals updates parent total = sum(line_total)'
);

select * from finish();
rollback;
