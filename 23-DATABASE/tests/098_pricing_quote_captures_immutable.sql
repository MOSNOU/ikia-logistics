-- CC-23 Test 098 — quote_captures: admin-only INSERT; UPDATE / DELETE forbidden.
--
-- Assertions (6):
--   1. admin_capture_quote inserts a row
--   2. non-admin authenticated cannot call admin_capture_quote (42501)
--   3. authenticated cannot UPDATE quote_captures (42501)
--   4. authenticated cannot DELETE quote_captures (42501)
--   5. supplier-org member sees own captures via RLS
--   6. capture_quote requires a non-null snapshot (22023)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '98000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '098-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '98000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '098-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('98000000-0000-0000-0000-00000000000a', 'tenant-098', 'تست', 'Test 098');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('98000000-0000-0000-0000-00000000001a', '98000000-0000-0000-0000-00000000000a',
   'sup-org-098', 'تامین', 'Sup Org 098', 'buyer', 'active'),
  ('98000000-0000-0000-0000-00000000001b', '98000000-0000-0000-0000-00000000000a',
   'buyer-org-098', 'خریدار', 'Buyer Org 098', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('98000000-0000-0000-0000-000000000001', '98000000-0000-0000-0000-00000000000a',
   '98000000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active'),
  ('98000000-0000-0000-0000-000000000099', '98000000-0000-0000-0000-00000000000a',
   '98000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '98000000-0000-0000-0000-00000000000a',
       '98000000-0000-0000-0000-00000000001a',
       '98000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '98000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('98000000-0000-0000-0000-00000000aaaa',
   '98000000-0000-0000-0000-00000000000a',
   '98000000-0000-0000-0000-00000000001a', 'approved', 'verified');

select plan(6);

-- 1. admin capture
select tests.authenticate_as(
  '98000000-0000-0000-0000-000000000099',
  '98000000-0000-0000-0000-00000000000a',
  '98000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.admin_capture_quote(
    'manual_audit'::pricing.quote_capture_kind,
    '98000000-0000-0000-0000-00000000aaaa'::uuid,
    '98000000-0000-0000-0000-00000000001b'::uuid,
    'USD'::char(3),
    jsonb_build_object('items', jsonb_build_array(jsonb_build_object(
      'product_code', 'prod-098', 'qty', 100, 'unit_price', 5))),
    null, null, null
  );
  perform set_config('test.cap_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select kind::text from pricing.quote_captures where id = current_setting('test.cap_id')::uuid),
  'manual_audit',
  'admin_capture_quote inserts a row with kind=manual_audit'
);

-- 2. non-admin cannot call
select tests.authenticate_as(
  '98000000-0000-0000-0000-000000000001',
  '98000000-0000-0000-0000-00000000000a',
  '98000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.admin_capture_quote(
       'manual_audit'::pricing.quote_capture_kind,
       '98000000-0000-0000-0000-00000000aaaa'::uuid,
       '98000000-0000-0000-0000-00000000001b'::uuid,
       'USD'::char(3),
       '{}'::jsonb, null, null, null) $$,
  '42501', null,
  'non-admin cannot call admin_capture_quote (42501)'
);
reset role;

-- 3. UPDATE forbidden
select tests.authenticate_as(
  '98000000-0000-0000-0000-000000000001',
  '98000000-0000-0000-0000-00000000000a',
  '98000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update pricing.quote_captures
              set snapshot = '{}'::jsonb where id = %L::uuid $$,
         current_setting('test.cap_id')),
  '42501', null,
  'UPDATE quote_captures forbidden for authenticated (42501)'
);

-- 4. DELETE forbidden
select throws_ok(
  format($$ delete from pricing.quote_captures where id = %L::uuid $$,
         current_setting('test.cap_id')),
  '42501', null,
  'DELETE quote_captures forbidden for authenticated (42501)'
);
reset role;

-- 5. supplier-org member SELECT visible
select tests.authenticate_as(
  '98000000-0000-0000-0000-000000000001',
  '98000000-0000-0000-0000-00000000000a',
  '98000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from pricing.quote_captures
    where supplier_id = '98000000-0000-0000-0000-00000000aaaa'),
  '>=', 1,
  'supplier-org member sees own quote_captures via RLS'
);
reset role;

-- 6. null snapshot rejected
select tests.authenticate_as(
  '98000000-0000-0000-0000-000000000099',
  '98000000-0000-0000-0000-00000000000a',
  '98000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.admin_capture_quote(
       'manual_audit'::pricing.quote_capture_kind,
       '98000000-0000-0000-0000-00000000aaaa'::uuid,
       '98000000-0000-0000-0000-00000000001b'::uuid,
       'USD'::char(3), null, null, null, null) $$,
  '22023', null,
  'admin_capture_quote rejects null snapshot (22023)'
);
reset role;

select * from finish();
rollback;
