-- CC-23 Test 093 — Currencies & FX rates RLS.
--
-- Assertions (6):
--   1. authenticated user can SELECT currencies (≥ 3 seed rows)
--   2. anon cannot SELECT currencies (42501)
--   3. authenticated user can SELECT currency_rates (admin-inserted)
--   4. admin can insert a currency_rate via admin_set_currency_rate
--   5. non-admin cannot insert a currency_rate via admin_set_currency_rate (42501)
--   6. currency_rates check rejects base_code = quote_code

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '93000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '093-user@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '93000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '093-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('93000000-0000-0000-0000-00000000000a', 'tenant-093', 'تست', 'Test 093');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('93000000-0000-0000-0000-00000000001a', '93000000-0000-0000-0000-00000000000a',
   'org-093', 'سازمان', 'Org 093', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('93000000-0000-0000-0000-000000000001', '93000000-0000-0000-0000-00000000000a',
   '93000000-0000-0000-0000-00000000001a', 'User', 'fa', 'active'),
  ('93000000-0000-0000-0000-000000000099', '93000000-0000-0000-0000-00000000000a',
   '93000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '93000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(6);

-- 1. authenticated reads currencies
select tests.authenticate_as(
  '93000000-0000-0000-0000-000000000001',
  '93000000-0000-0000-0000-00000000000a',
  '93000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from pricing.currencies),
  '>=', 3,
  'authenticated user reads ≥ 3 seed currencies'
);
reset role;

-- 2. anon cannot SELECT currencies
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select count(*) from pricing.currencies $$,
  '42501', null,
  'anon has no SELECT privilege on pricing.currencies'
);
reset role;

-- 4. admin inserts a USD→EUR rate
select tests.authenticate_as(
  '93000000-0000-0000-0000-000000000099',
  '93000000-0000-0000-0000-00000000000a',
  '93000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.admin_set_currency_rate(
    'USD'::char(3), 'EUR'::char(3), 0.93, now() - interval '1 hour', null, 'manual'
  );
  perform set_config('test.fx_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select rate from pricing.currency_rates where id = current_setting('test.fx_id')::uuid),
  0.93::numeric(20, 10),
  'admin_set_currency_rate inserts USD→EUR rate'
);

-- 3. authenticated reads currency_rates
select tests.authenticate_as(
  '93000000-0000-0000-0000-000000000001',
  '93000000-0000-0000-0000-00000000000a',
  '93000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from pricing.currency_rates),
  '>=', 1,
  'authenticated user reads currency_rates'
);
reset role;

-- 5. non-admin cannot set rate via RPC
select tests.authenticate_as(
  '93000000-0000-0000-0000-000000000001',
  '93000000-0000-0000-0000-00000000000a',
  '93000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.admin_set_currency_rate('USD'::char(3), 'IRR'::char(3), 50000, null, null, 'manual') $$,
  '42501', null,
  'non-admin cannot call admin_set_currency_rate (42501)'
);
reset role;

-- 6. base = quote rejected
select tests.authenticate_as(
  '93000000-0000-0000-0000-000000000099',
  '93000000-0000-0000-0000-00000000000a',
  '93000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.admin_set_currency_rate('USD'::char(3), 'USD'::char(3), 1.0, null, null, 'manual') $$,
  '22023', null,
  'admin_set_currency_rate rejects base = quote (22023)'
);
reset role;

select * from finish();
rollback;
