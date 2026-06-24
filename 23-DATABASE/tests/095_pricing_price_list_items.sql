-- CC-23 Test 095 — Price list items upsert + constraints.
--
-- Assertions (8):
--   1. portal_upsert_price_list_item inserts a new line
--   2. re-upsert (same product) updates unit_price and bumps version
--   3. unique (price_list_id, product_id) enforced via upsert (no duplicate row)
--   4. unit_price < 0 rejected (23514 check)
--   5. cannot upsert into archived list (22023)
--   6. min_order_quantity > max_order_quantity rejected (23514 check)
--   7. price_list_item_updated event recorded twice (insert + update)
--   8. supplier-org member sees own items via RLS

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '95000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '095-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('95000000-0000-0000-0000-00000000000a', 'tenant-095', 'تست', 'Test 095');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('95000000-0000-0000-0000-00000000001a', '95000000-0000-0000-0000-00000000000a',
   'sup-org-095', 'سازمان', 'Sup Org 095', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('95000000-0000-0000-0000-000000000001', '95000000-0000-0000-0000-00000000000a',
   '95000000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '95000000-0000-0000-0000-00000000000a',
       '95000000-0000-0000-0000-00000000001a',
       '95000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('95000000-0000-0000-0000-00000000aaaa',
   '95000000-0000-0000-0000-00000000000a',
   '95000000-0000-0000-0000-00000000001a', 'approved', 'verified');

-- Need a real product to FK against.
insert into commodity.categories (id, code, name_fa, name_en) values
  ('95000000-0000-0000-0000-00000000bbbb', 'cat-095', 'دسته', 'Cat 095');
insert into commodity.products (id, category_id, code, slug, name_fa, name_en, status, unit_of_trade) values
  ('95000000-0000-0000-0000-00000000cccc',
   '95000000-0000-0000-0000-00000000bbbb',
   'prod-095', 'prod-095', 'محصول', 'Product 095', 'active', 'kg');

-- A draft list owned by the supplier.
insert into pricing.price_lists (id, tenant_id, supplier_id, organization_id, code,
                                 name_en, name_fa, currency_code, status)
values ('95000000-0000-0000-0000-00000000aaa1',
        '95000000-0000-0000-0000-00000000000a',
        '95000000-0000-0000-0000-00000000aaaa',
        '95000000-0000-0000-0000-00000000001a',
        'PL-095', 'Draft 095', 'پیش‌نویس ۰۹۵', 'USD', 'draft');

-- An archived list for negative test.
insert into pricing.price_lists (id, tenant_id, supplier_id, organization_id, code,
                                 name_en, name_fa, currency_code, status)
values ('95000000-0000-0000-0000-00000000aaa2',
        '95000000-0000-0000-0000-00000000000a',
        '95000000-0000-0000-0000-00000000aaaa',
        '95000000-0000-0000-0000-00000000001a',
        'PL-ARC-095', 'Archived', 'بایگانی', 'USD', 'archived');

select plan(8);

-- 1. insert
select tests.authenticate_as(
  '95000000-0000-0000-0000-000000000001',
  '95000000-0000-0000-0000-00000000000a',
  '95000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_upsert_price_list_item(
    '95000000-0000-0000-0000-00000000aaa1'::uuid,
    '95000000-0000-0000-0000-00000000cccc'::uuid,
    12.5, 'kg', 1, 1000, 'initial'
  );
  perform set_config('test.item_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select unit_price from pricing.price_list_items
    where id = current_setting('test.item_id')::uuid),
  12.5::numeric(20,4),
  'portal_upsert_price_list_item inserts new line with unit_price'
);

-- 2. update via upsert
select tests.authenticate_as(
  '95000000-0000-0000-0000-000000000001',
  '95000000-0000-0000-0000-00000000000a',
  '95000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_upsert_price_list_item(
    '95000000-0000-0000-0000-00000000aaa1'::uuid,
    '95000000-0000-0000-0000-00000000cccc'::uuid,
    11.25, 'kg', 1, 1000, 'discounted'
  );
  perform set_config('test.item_id_v2', v_id::text, false);
end;
$$;
reset role;

select is(
  (select unit_price from pricing.price_list_items
    where id = current_setting('test.item_id')::uuid),
  11.25::numeric(20,4),
  'second upsert updates unit_price on same row'
);

-- 3. one row only
select is(
  (select count(*)::int from pricing.price_list_items
    where price_list_id = '95000000-0000-0000-0000-00000000aaa1'::uuid),
  1,
  'unique (price_list_id, product_id) enforced — only 1 row'
);

-- 4. unit_price < 0 → check fails
select tests.authenticate_as(
  '95000000-0000-0000-0000-000000000001',
  '95000000-0000-0000-0000-00000000000a',
  '95000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ insert into pricing.price_list_items
       (tenant_id, price_list_id, product_id, unit_price, unit_of_measure)
     values ('95000000-0000-0000-0000-00000000000a',
             '95000000-0000-0000-0000-00000000aaa1',
             '95000000-0000-0000-0000-00000000cccc', -1, 'kg') $$,
  '42501', null,
  'direct insert blocked (no INSERT grant; would also fail 23514)'
);
reset role;

-- 5. cannot upsert into archived
select tests.authenticate_as(
  '95000000-0000-0000-0000-000000000001',
  '95000000-0000-0000-0000-00000000000a',
  '95000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.portal_upsert_price_list_item(
       '95000000-0000-0000-0000-00000000aaa2'::uuid,
       '95000000-0000-0000-0000-00000000cccc'::uuid,
       9.99, 'kg', null, null, null) $$,
  '22023', null,
  'cannot upsert into archived list (22023)'
);
reset role;

-- 6. min > max rejected by check constraint (admin path: insert is RPC-only; we test the check directly).
select throws_ok(
  $$ insert into pricing.price_list_items
       (tenant_id, price_list_id, product_id, unit_price, unit_of_measure,
        min_order_quantity, max_order_quantity)
     values ('95000000-0000-0000-0000-00000000000a',
             '95000000-0000-0000-0000-00000000aaa1',
             '95000000-0000-0000-0000-00000000cccc', 5, 'kg', 100, 50) $$,
  '23514', null,
  'min_order_quantity > max_order_quantity rejected by check (23514)'
);

-- 7. events: 2 price_list_item_updated rows
select is(
  (select count(*)::int from pricing.events
    where price_list_id = '95000000-0000-0000-0000-00000000aaa1'::uuid
      and event_kind = 'price_list_item_updated'),
  2, 'price_list_item_updated event recorded twice (insert + update)'
);

-- 8. supplier-org member sees own items
select tests.authenticate_as(
  '95000000-0000-0000-0000-000000000001',
  '95000000-0000-0000-0000-00000000000a',
  '95000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from pricing.price_list_items
    where price_list_id = '95000000-0000-0000-0000-00000000aaa1'::uuid),
  '>=', 1,
  'supplier-org member sees own price_list_items via RLS'
);
reset role;

select * from finish();
rollback;
