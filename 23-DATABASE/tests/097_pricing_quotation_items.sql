-- CC-23 Test 097 — Quotation items: totals recompute + position.
--
-- Assertions (8):
--   1. portal_add_quotation_item returns id; line_total = qty*price - discount
--   2. quotation subtotal/discount/total recomputed after add
--   3. quantity <= 0 rejected (22023)
--   4. unit_price < 0 rejected (22023)
--   5. line_total < 0 (over-discount) rejected (22023)
--   6. items default position auto-incremented
--   7. compute_quote_totals is idempotent — second call yields same totals
--   8. cannot add item to a sent quotation (22023)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '97000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '097-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('97000000-0000-0000-0000-00000000000a', 'tenant-097', 'تست', 'Test 097');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('97000000-0000-0000-0000-00000000001a', '97000000-0000-0000-0000-00000000000a',
   'sup-org-097', 'تامین', 'Sup Org 097', 'buyer', 'active'),
  ('97000000-0000-0000-0000-00000000001b', '97000000-0000-0000-0000-00000000000a',
   'buyer-org-097', 'خریدار', 'Buyer Org 097', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('97000000-0000-0000-0000-000000000001', '97000000-0000-0000-0000-00000000000a',
   '97000000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '97000000-0000-0000-0000-00000000000a',
       '97000000-0000-0000-0000-00000000001a',
       '97000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('97000000-0000-0000-0000-00000000aaaa',
   '97000000-0000-0000-0000-00000000000a',
   '97000000-0000-0000-0000-00000000001a', 'approved', 'verified');

insert into commodity.categories (id, code, name_fa, name_en) values
  ('97000000-0000-0000-0000-00000000bbbb', 'cat-097', 'دسته', 'Cat 097');
insert into commodity.products (id, category_id, code, slug, name_fa, name_en, status, unit_of_trade) values
  ('97000000-0000-0000-0000-00000000ccc1',
   '97000000-0000-0000-0000-00000000bbbb',
   'prod-097-a', 'prod-097-a', 'محصول الف', 'Product 097-A', 'active', 'kg'),
  ('97000000-0000-0000-0000-00000000ccc2',
   '97000000-0000-0000-0000-00000000bbbb',
   'prod-097-b', 'prod-097-b', 'محصول ب', 'Product 097-B', 'active', 'kg');

select plan(8);

select tests.authenticate_as(
  '97000000-0000-0000-0000-000000000001',
  '97000000-0000-0000-0000-00000000000a',
  '97000000-0000-0000-0000-00000000001a'
);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := pricing.portal_create_quotation(
    '97000000-0000-0000-0000-00000000aaaa'::uuid,
    '97000000-0000-0000-0000-00000000001b'::uuid,
    'Q-097-001', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform set_config('test.q_id', v_id::text, false);
end;
$$;

-- 1. Add an item with discount; line_total expected = qty*price - discount = 100*5 - 50 = 450
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_add_quotation_item(
    current_setting('test.q_id')::uuid,
    '97000000-0000-0000-0000-00000000ccc1'::uuid,
    100, 'kg', 5, 50, 'volume', null
  );
  perform set_config('test.item_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select line_total from pricing.quotation_items
    where id = current_setting('test.item_id')::uuid),
  450::numeric(20,4),
  'line_total = quantity × unit_price − discount_amount'
);

-- 2. quotation totals recomputed
select is(
  (select total_amount from pricing.quotations where id = current_setting('test.q_id')::uuid),
  450::numeric(20,4),
  'quotation total recomputed from line items'
);

-- 3. quantity <= 0 rejected
select tests.authenticate_as(
  '97000000-0000-0000-0000-000000000001',
  '97000000-0000-0000-0000-00000000000a',
  '97000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_add_quotation_item(%L::uuid,
            '97000000-0000-0000-0000-00000000ccc2'::uuid, 0, 'kg', 5, 0, null, null) $$,
         current_setting('test.q_id')),
  '22023', null,
  'quantity <= 0 rejected (22023)'
);

-- 4. unit_price < 0 rejected
select throws_ok(
  format($$ select pricing.portal_add_quotation_item(%L::uuid,
            '97000000-0000-0000-0000-00000000ccc2'::uuid, 10, 'kg', -1, 0, null, null) $$,
         current_setting('test.q_id')),
  '22023', null,
  'unit_price < 0 rejected (22023)'
);

-- 5. over-discount → negative line_total → rejected
select throws_ok(
  format($$ select pricing.portal_add_quotation_item(%L::uuid,
            '97000000-0000-0000-0000-00000000ccc2'::uuid, 1, 'kg', 5, 100, null, null) $$,
         current_setting('test.q_id')),
  '22023', null,
  'line_total cannot be negative (over-discount) → 22023'
);
reset role;

-- 6. position auto-increment
select tests.authenticate_as(
  '97000000-0000-0000-0000-000000000001',
  '97000000-0000-0000-0000-00000000000a',
  '97000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_add_quotation_item(
    current_setting('test.q_id')::uuid,
    '97000000-0000-0000-0000-00000000ccc2'::uuid,
    10, 'kg', 3, 0, 'second', null
  );
  perform set_config('test.item2_id', v_id::text, false);
end;
$$;
reset role;

select cmp_ok(
  (select position from pricing.quotation_items where id = current_setting('test.item2_id')::uuid),
  '>=', 1,
  'second item position auto-incremented (≥ 1)'
);

-- 7. compute_quote_totals idempotent
do $$
declare v_t1 numeric; v_t2 numeric;
begin
  select total_amount into v_t1 from pricing.quotations where id = current_setting('test.q_id')::uuid;
  perform pricing.compute_quote_totals(current_setting('test.q_id')::uuid);
  select total_amount into v_t2 from pricing.quotations where id = current_setting('test.q_id')::uuid;
  perform set_config('test.t1', v_t1::text, false);
  perform set_config('test.t2', v_t2::text, false);
end;
$$;

select is(
  current_setting('test.t1')::numeric,
  current_setting('test.t2')::numeric,
  'compute_quote_totals is idempotent — totals stable on second call'
);

-- 8. cannot add to sent quotation
select tests.authenticate_as(
  '97000000-0000-0000-0000-000000000001',
  '97000000-0000-0000-0000-00000000000a',
  '97000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select pricing.portal_send_quotation(current_setting('test.q_id')::uuid);
select throws_ok(
  format($$ select pricing.portal_add_quotation_item(%L::uuid,
            '97000000-0000-0000-0000-00000000ccc1'::uuid, 1, 'kg', 1, 0, null, null) $$,
         current_setting('test.q_id')),
  '22023', null,
  'cannot add item to a sent quotation (22023)'
);
reset role;

select * from finish();
rollback;
