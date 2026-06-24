-- CC-08 Test 021 — Commodity RLS + grants matrix.
--
-- Assertions (12):
--   1-6: RLS enabled on all 6 commodity tables
--   7  : no INSERT/UPDATE/DELETE direct grants on commodity.* tables
--   8  : anon cannot SELECT commodity.products (no grant — authenticated only)
--   9  : anon sees 0 commodity.supplier_product_capabilities (grant + RLS=0)
--  10  : authenticated CAN SELECT commodity.products (10 seeded)
--  11  : authenticated CAN SELECT commodity.categories (9 seeded)
--  12  : authenticated unrelated org sees 0 supplier_product_capabilities

set search_path = extensions, public, identity, organization, audit, supplier, commodity, tests;
begin;

select plan(12);

-- 1-6. RLS enabled on every commodity table
select is(
  (select relrowsecurity from pg_class c
     join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='commodity' and c.relname='categories'),
  true, 'commodity.categories has RLS enabled');

select is(
  (select relrowsecurity from pg_class c
     join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='commodity' and c.relname='products'),
  true, 'commodity.products has RLS enabled');

select is(
  (select relrowsecurity from pg_class c
     join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='commodity' and c.relname='product_aliases'),
  true, 'commodity.product_aliases has RLS enabled');

select is(
  (select relrowsecurity from pg_class c
     join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='commodity' and c.relname='product_specifications'),
  true, 'commodity.product_specifications has RLS enabled');

select is(
  (select relrowsecurity from pg_class c
     join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='commodity' and c.relname='product_document_requirements'),
  true, 'commodity.product_document_requirements has RLS enabled');

select is(
  (select relrowsecurity from pg_class c
     join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='commodity' and c.relname='supplier_product_capabilities'),
  true, 'commodity.supplier_product_capabilities has RLS enabled');

-- 7. No direct INSERT/UPDATE/DELETE grants on commodity.*
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='commodity'
      and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0,
  'no direct INSERT/UPDATE/DELETE grants on commodity.* tables'
);

-- Fixtures for exposure tests --------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '60100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '021-orphan@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '60100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '021-other@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('60100000-0000-0000-0000-00000000000a', 'tenant-021a', 'الف', 'A'),
  ('60100000-0000-0000-0000-00000000000b', 'tenant-021b', 'ب',  'B');

-- Org A supplier (trigger creates supplier shell)
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('60100000-0000-0000-0000-00000000001a', '60100000-0000-0000-0000-00000000000a',
   'sup-021a', 'تأمین الف', 'Supplier A', 'supplier', 'active'),
  ('60100000-0000-0000-0000-00000000001b', '60100000-0000-0000-0000-00000000000b',
   'sup-021b', 'تأمین ب',  'Supplier B', 'supplier', 'active');

-- User 2 is supplier_admin in org B
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('60100000-0000-0000-0000-000000000002', '60100000-0000-0000-0000-00000000000b',
   '60100000-0000-0000-0000-00000000001b', 'B', 'fa', 'active');
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '60100000-0000-0000-0000-00000000000b', '60100000-0000-0000-0000-00000000001b',
       '60100000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

-- Seed a capability for supplier A so unrelated user B should NOT see it.
do $$
declare v_sup_a uuid; v_prod uuid;
begin
  select id into v_sup_a from supplier.suppliers
   where organization_id = '60100000-0000-0000-0000-00000000001a';
  select id into v_prod from commodity.products where code = 'methanol';
  insert into commodity.supplier_product_capabilities (
    tenant_id, organization_id, supplier_id, product_id, capability_status
  ) values (
    '60100000-0000-0000-0000-00000000000a',
    '60100000-0000-0000-0000-00000000001a',
    v_sup_a, v_prod, 'active'
  );
end;
$$;

-- 8. anon cannot SELECT commodity.products (no grant to anon)
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select count(*) from commodity.products $$,
  '42501', null,
  'anon cannot SELECT commodity.products (no grant)'
);

-- 9. anon sees 0 commodity.supplier_product_capabilities (grant + RLS)
select is(
  (select count(*) from commodity.supplier_product_capabilities),
  0::bigint,
  'anon sees 0 commodity.supplier_product_capabilities (RLS filtering)'
);
reset role;

-- 10. authenticated CAN SELECT commodity.products (10 seeded)
select tests.authenticate_as('60100000-0000-0000-0000-000000000001');
set local role authenticated;
select is(
  (select count(*) from commodity.products where status = 'active'),
  10::bigint,
  'authenticated sees 10 active seeded products'
);

-- 11. authenticated CAN SELECT commodity.categories (9 seeded)
select is(
  (select count(*) from commodity.categories),
  9::bigint,
  'authenticated sees 9 seeded categories'
);
reset role;

-- 12. authenticated in unrelated org B cannot see supplier A's capability
select tests.authenticate_as(
  '60100000-0000-0000-0000-000000000002',
  '60100000-0000-0000-0000-00000000000b',
  '60100000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select is(
  (select count(*) from commodity.supplier_product_capabilities
    where organization_id = '60100000-0000-0000-0000-00000000001a'),
  0::bigint,
  'authenticated in unrelated org cannot see another supplier capability'
);
reset role;

select * from finish();
rollback;
