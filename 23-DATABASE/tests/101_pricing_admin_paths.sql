-- CC-23 Test 101 — Admin paths: list / capture / expire / governance.
--
-- Assertions (8):
--   1. admin_list_price_lists returns rows
--   2. admin_list_quotations returns rows
--   3. admin_capture_quote with source_quotation_id stores FK
--   4. admin_expire_due_quotations only flips sent (not draft / accepted / expired)
--   5. quote_captured event recorded
--   6. currency_rate_set event recorded
--   7. admin_capture_quote rejects unknown currency (22023)
--   8. admin_set_currency_rate rejects rate <= 0 (22023)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '10100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '101-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '10100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '101-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '10100000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '101-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('10100000-0000-0000-0000-00000000000a', 'tenant-101', 'تست', 'Test 101');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('10100000-0000-0000-0000-00000000001a', '10100000-0000-0000-0000-00000000000a',
   'sup-org-101', 'تامین', 'Sup Org 101', 'buyer', 'active'),
  ('10100000-0000-0000-0000-00000000001b', '10100000-0000-0000-0000-00000000000a',
   'buyer-org-101', 'خریدار', 'Buyer Org 101', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('10100000-0000-0000-0000-000000000001', '10100000-0000-0000-0000-00000000000a',
   '10100000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active'),
  ('10100000-0000-0000-0000-000000000002', '10100000-0000-0000-0000-00000000000a',
   '10100000-0000-0000-0000-00000000001b', 'Buyer', 'fa', 'active'),
  ('10100000-0000-0000-0000-000000000099', '10100000-0000-0000-0000-00000000000a',
   '10100000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '10100000-0000-0000-0000-00000000000a',
       '10100000-0000-0000-0000-00000000001a',
       '10100000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '10100000-0000-0000-0000-00000000000a',
       '10100000-0000-0000-0000-00000000001b',
       '10100000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '10100000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('10100000-0000-0000-0000-00000000aaaa',
   '10100000-0000-0000-0000-00000000000a',
   '10100000-0000-0000-0000-00000000001a', 'approved', 'verified');

insert into commodity.categories (id, code, name_fa, name_en) values
  ('10100000-0000-0000-0000-00000000bbbb', 'cat-101', 'دسته', 'Cat 101');
insert into commodity.products (id, category_id, code, slug, name_fa, name_en, status, unit_of_trade) values
  ('10100000-0000-0000-0000-00000000cccc',
   '10100000-0000-0000-0000-00000000bbbb',
   'prod-101', 'prod-101', 'محصول', 'Product 101', 'active', 'kg');

-- Seed an active price list and a sent quotation.
insert into pricing.price_lists (id, tenant_id, supplier_id, organization_id, code,
                                 name_en, name_fa, currency_code, status, effective_from)
values ('10100000-0000-0000-0000-00000000aaa1',
        '10100000-0000-0000-0000-00000000000a',
        '10100000-0000-0000-0000-00000000aaaa',
        '10100000-0000-0000-0000-00000000001a',
        'STD-101', 'Std', 'استاندارد', 'USD', 'active', now() - interval '1 day');

select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000001',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_q uuid;
begin
  v_q := pricing.portal_create_quotation(
    '10100000-0000-0000-0000-00000000aaaa'::uuid,
    '10100000-0000-0000-0000-00000000001b'::uuid,
    'Q-101', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform pricing.portal_add_quotation_item(v_q,
    '10100000-0000-0000-0000-00000000cccc'::uuid, 10, 'kg', 5, 0, null, null);
  perform pricing.portal_send_quotation(v_q);
  perform set_config('test.q_sent', v_q::text, false);
end;
$$;
reset role;

-- A draft quotation (must NOT be flipped by expire batch).
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000001',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_q uuid;
begin
  v_q := pricing.portal_create_quotation(
    '10100000-0000-0000-0000-00000000aaaa'::uuid,
    '10100000-0000-0000-0000-00000000001b'::uuid,
    'Q-101-DRAFT', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform set_config('test.q_draft', v_q::text, false);
end;
$$;
reset role;

-- Move sent quotation's valid_until into the past.
update pricing.quotations
   set valid_until = now() - interval '1 hour'
 where id = current_setting('test.q_sent')::uuid;
-- Make draft also past — we'll assert it does NOT get flipped.
update pricing.quotations
   set valid_until = now() - interval '1 hour'
 where id = current_setting('test.q_draft')::uuid;

select plan(8);

-- 1. admin_list_price_lists
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from pricing.admin_list_price_lists(
    '10100000-0000-0000-0000-00000000aaaa'::uuid, null, 25, 0)),
  '>=', 1,
  'admin_list_price_lists returns the supplier list'
);
reset role;

-- 2. admin_list_quotations
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from pricing.admin_list_quotations(
    null, '10100000-0000-0000-0000-00000000001b'::uuid, null, 25, 0)),
  '>=', 1,
  'admin_list_quotations returns the buyer-targeted quotations'
);
reset role;

-- 3. admin_capture_quote with quotation FK
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.admin_capture_quote(
    'offer_submission'::pricing.quote_capture_kind,
    '10100000-0000-0000-0000-00000000aaaa'::uuid,
    '10100000-0000-0000-0000-00000000001b'::uuid,
    'USD'::char(3),
    jsonb_build_object('source', 'admin-test'),
    null, null, current_setting('test.q_sent')::uuid
  );
  perform set_config('test.cap_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select source_quotation_id from pricing.quote_captures
    where id = current_setting('test.cap_id')::uuid),
  current_setting('test.q_sent')::uuid,
  'admin_capture_quote stores source_quotation_id FK'
);

-- 4. expire only flips sent
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select pricing.admin_expire_due_quotations();
reset role;

select is(
  (select status::text from pricing.quotations where id = current_setting('test.q_sent')::uuid),
  'expired',
  'admin_expire_due_quotations flipped sent → expired'
);

select is(
  (select status::text from pricing.quotations where id = current_setting('test.q_draft')::uuid),
  'draft',
  'admin_expire_due_quotations did NOT touch draft quotation'
);

-- 5. quote_captured event
select cmp_ok(
  (select count(*)::int from pricing.events
    where event_kind = 'quote_captured'
      and quotation_id = current_setting('test.q_sent')::uuid),
  '>=', 1,
  'quote_captured event recorded'
);

-- 6. currency_rate_set event
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.admin_set_currency_rate(
    'EUR'::char(3), 'IRR'::char(3), 600000, now() - interval '1 hour', null, 'manual'
  );
end;
$$;
reset role;

select cmp_ok(
  (select count(*)::int from pricing.events
    where event_kind = 'currency_rate_set'),
  '>=', 1,
  'currency_rate_set event recorded'
);

-- 7. unknown currency rejected in admin_capture_quote
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.admin_capture_quote(
       'manual_audit'::pricing.quote_capture_kind,
       '10100000-0000-0000-0000-00000000aaaa'::uuid,
       '10100000-0000-0000-0000-00000000001b'::uuid,
       'XYZ'::char(3), '{}'::jsonb, null, null, null) $$,
  '22023', null,
  'admin_capture_quote rejects unknown currency (22023)'
);
reset role;

-- 8. rate <= 0 rejected
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000099',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.admin_set_currency_rate(
       'USD'::char(3), 'IRR'::char(3), 0, null, null, 'manual') $$,
  '22023', null,
  'admin_set_currency_rate rejects rate <= 0 (22023)'
);
reset role;

select * from finish();
rollback;
