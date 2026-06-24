-- CC-08 Test 023 — Commodity portal capability mutation scope.
--
-- Assertions (4):
--   1. supplier_admin in org A calling portal_upsert_my_capability creates a
--      capability for supplier A only (not B).
--   2. supplier_admin in org A calling portal_remove_my_capability(product_id)
--      soft-deletes only their own capability; supplier B's capability is
--      untouched.
--   3. Unauthorized user (no supplier_admin/organization_admin/platform_admin)
--      gets 42501 from portal_upsert_my_capability.
--   4. portal_upsert_my_capability errors with P0002 when the supplier has no
--      profile for the active organization (e.g. JWT org is not a supplier).

set search_path = extensions, public, identity, organization, audit, supplier, commodity, tests;
begin;

-- Two supplier orgs A and B.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '70100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '023-A@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '70100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '023-B@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '70100000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '023-rookie@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('70100000-0000-0000-0000-00000000000a', 'tenant-023a', 'الف', 'A'),
  ('70100000-0000-0000-0000-00000000000b', 'tenant-023b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('70100000-0000-0000-0000-00000000001a', '70100000-0000-0000-0000-00000000000a',
   'sup-023a', 'تأمین الف', 'Supplier A', 'supplier', 'active'),
  ('70100000-0000-0000-0000-00000000001b', '70100000-0000-0000-0000-00000000000b',
   'sup-023b', 'تأمین ب',  'Supplier B', 'supplier', 'active'),
  -- a buyer org for testing "no supplier profile"
  ('70100000-0000-0000-0000-00000000001c', '70100000-0000-0000-0000-00000000000a',
   'buyer-023', 'خریدار', 'Buyer 023', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('70100000-0000-0000-0000-000000000001', '70100000-0000-0000-0000-00000000000a',
   '70100000-0000-0000-0000-00000000001a', 'A', 'fa', 'active'),
  ('70100000-0000-0000-0000-000000000002', '70100000-0000-0000-0000-00000000000b',
   '70100000-0000-0000-0000-00000000001b', 'B', 'fa', 'active'),
  ('70100000-0000-0000-0000-000000000003', '70100000-0000-0000-0000-00000000000a',
   '70100000-0000-0000-0000-00000000001c', 'rookie', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '70100000-0000-0000-0000-00000000000a', '70100000-0000-0000-0000-00000000001a',
       '70100000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '70100000-0000-0000-0000-00000000000b', '70100000-0000-0000-0000-00000000001b',
       '70100000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '70100000-0000-0000-0000-000000000001', r.id, 'organization', '70100000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '70100000-0000-0000-0000-000000000002', r.id, 'organization', '70100000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'supplier_admin';

-- Capture supplier ids and product id.
do $$
declare v_sa uuid; v_sb uuid; v_prod uuid;
begin
  select id into v_sa from supplier.suppliers where organization_id = '70100000-0000-0000-0000-00000000001a';
  select id into v_sb from supplier.suppliers where organization_id = '70100000-0000-0000-0000-00000000001b';
  select id into v_prod from commodity.products where code = 'methanol';
  perform set_config('test.sa', v_sa::text, false);
  perform set_config('test.sb', v_sb::text, false);
  perform set_config('test.prod', v_prod::text, false);

  -- Pre-seed a capability for supplier B so test 2 can verify B's is untouched.
  insert into commodity.supplier_product_capabilities (
    tenant_id, organization_id, supplier_id, product_id, capability_status
  ) values (
    '70100000-0000-0000-0000-00000000000b',
    '70100000-0000-0000-0000-00000000001b',
    v_sb, v_prod, 'active'
  );
end;
$$;

select plan(4);

-- 1. supplier_admin A upserts capability → only supplier A row created.
select tests.authenticate_as(
  '70100000-0000-0000-0000-000000000001',
  '70100000-0000-0000-0000-00000000000a',
  '70100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select commodity.portal_upsert_my_capability(current_setting('test.prod')::uuid);
reset role;

select is(
  (select count(*)::int from commodity.supplier_product_capabilities
    where supplier_id = current_setting('test.sa')::uuid
      and product_id  = current_setting('test.prod')::uuid
      and deleted_at is null),
  1,
  'supplier_admin A creates exactly one capability row for supplier A'
);

-- 2. supplier_admin A removes capability → only A soft-deleted, B untouched.
select tests.authenticate_as(
  '70100000-0000-0000-0000-000000000001',
  '70100000-0000-0000-0000-00000000000a',
  '70100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select commodity.portal_remove_my_capability(current_setting('test.prod')::uuid);
reset role;

select is(
  (
    (select count(*)::int from commodity.supplier_product_capabilities
      where supplier_id = current_setting('test.sa')::uuid
        and deleted_at is null) * 10 +
    (select count(*)::int from commodity.supplier_product_capabilities
      where supplier_id = current_setting('test.sb')::uuid
        and deleted_at is null)
  ),
  1,  -- A=0 active, B=1 active → 0*10+1 = 1
  'portal_remove_my_capability soft-deletes only own supplier A; B untouched'
);

-- 3. Unauthorized user (rookie — no portal role) gets 42501.
select tests.authenticate_as(
  '70100000-0000-0000-0000-000000000003',
  '70100000-0000-0000-0000-00000000000a',
  '70100000-0000-0000-0000-00000000001c'
);
set local role authenticated;
select throws_ok(
  format($$ select commodity.portal_upsert_my_capability(%L::uuid) $$, current_setting('test.prod')),
  '42501', null,
  'unauthorized user rejected by portal_upsert_my_capability'
);
reset role;

-- 4. Portal RPC errors P0002 when JWT org is a buyer org (no supplier profile).
--    Promote rookie to supplier_admin so the role check passes; the org-type
--    check is what should now fire.
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '70100000-0000-0000-0000-000000000003', r.id, 'organization', '70100000-0000-0000-0000-00000000001c'
  from identity.roles r where r.code = 'supplier_admin';

select tests.authenticate_as(
  '70100000-0000-0000-0000-000000000003',
  '70100000-0000-0000-0000-00000000000a',
  '70100000-0000-0000-0000-00000000001c'  -- buyer org
);
set local role authenticated;
select throws_ok(
  format($$ select commodity.portal_upsert_my_capability(%L::uuid) $$, current_setting('test.prod')),
  'P0002', null,
  'portal_upsert_my_capability errors P0002 when JWT org has no supplier profile'
);
reset role;

select * from finish();
rollback;
