-- CC-07 Test 013 — Supplier RLS isolation + category exposure (correction B/E).
--   * anon cannot see supplier.suppliers
--   * authenticated without org/JWT context cannot see supplier.suppliers
--   * authenticated unrelated org cannot see another supplier
--   * supplier_admin in tenant A sees own supplier
--   * platform_admin sees both
--   * anon cannot SELECT supplier.categories
--   * authenticated CAN SELECT supplier.categories (12 seeded)

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

-- Two tenants, two supplier-type orgs. Trigger auto-creates supplier shells.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   'd0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '013-a@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   'd0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '013-b@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   'd0000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '013-admin@example.com'),
  -- Orphan: authenticated but has no membership in any organization.
  ('00000000-0000-0000-0000-000000000000',
   'd0000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', '013-orphan@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('d0000000-0000-0000-0000-00000000000a', 'tenant-013a', 'الف', 'A'),
  ('d0000000-0000-0000-0000-00000000000b', 'tenant-013b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('d0000000-0000-0000-0000-00000000001a', 'd0000000-0000-0000-0000-00000000000a',
   'sup-a', 'تأمین‌کننده الف', 'Supplier A', 'supplier', 'active'),
  ('d0000000-0000-0000-0000-00000000001b', 'd0000000-0000-0000-0000-00000000000b',
   'sup-b', 'تأمین‌کننده ب',  'Supplier B', 'supplier', 'active');

-- Trigger has created two supplier rows. Pick up their ids.
-- User A is supplier_admin of org A. User B is unrelated org. User admin is platform_admin.
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('d0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-00000000000a',
   'd0000000-0000-0000-0000-00000000001a', 'User A', 'fa', 'active'),
  ('d0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-00000000000b',
   'd0000000-0000-0000-0000-00000000001b', 'User B', 'fa', 'active'),
  ('d0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-00000000000a',
   'd0000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select 'd0000000-0000-0000-0000-00000000000a', 'd0000000-0000-0000-0000-00000000001a',
       'd0000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select 'd0000000-0000-0000-0000-00000000000b', 'd0000000-0000-0000-0000-00000000001b',
       'd0000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select 'd0000000-0000-0000-0000-000000000001', r.id, 'organization', 'd0000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select 'd0000000-0000-0000-0000-000000000002', r.id, 'organization', 'd0000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select 'd0000000-0000-0000-0000-000000000003', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(7);

-- 1. anon sees 0 suppliers.
select tests.set_anon();
set local role anon;
select is(
  (select count(*) from supplier.suppliers),
  0::bigint,
  'anon sees 0 supplier.suppliers'
);

-- 1b. anon cannot SELECT supplier.categories (correction B: no grant to anon).
select throws_ok(
  $$ select count(*) from supplier.categories $$,
  '42501',
  null,
  'anon cannot SELECT supplier.categories (correction B)'
);
reset role;

-- 2. Authenticated orphan (no memberships, no tenant/org JWT claims) sees
--    0 suppliers — membership-based RLS gates the read.
select tests.authenticate_as('d0000000-0000-0000-0000-000000000004');
set local role authenticated;
select is(
  (select count(*) from supplier.suppliers),
  0::bigint,
  'authenticated orphan (no organization context) sees 0 suppliers'
);

-- 2b. The same authenticated orphan CAN SELECT supplier.categories (12 seeded).
select is(
  (select count(*) from supplier.categories),
  12::bigint,
  'authenticated sees 12 seeded supplier.categories'
);
reset role;

-- 3. User B (unrelated to org A) cannot see supplier A.
select tests.authenticate_as(
  'd0000000-0000-0000-0000-000000000002',
  'd0000000-0000-0000-0000-00000000000b',
  'd0000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select is(
  (select count(*) from supplier.suppliers
    where organization_id = 'd0000000-0000-0000-0000-00000000001a'),
  0::bigint,
  'User B in tenant B cannot see Supplier A'
);
reset role;

-- 4. User A (supplier_admin of org A) sees own supplier (1 row).
select tests.authenticate_as(
  'd0000000-0000-0000-0000-000000000001',
  'd0000000-0000-0000-0000-00000000000a',
  'd0000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*) from supplier.suppliers),
  1::bigint,
  'supplier_admin sees exactly own organization supplier'
);
reset role;

-- 5. platform_admin sees both suppliers.
select tests.authenticate_as(
  'd0000000-0000-0000-0000-000000000003',
  'd0000000-0000-0000-0000-00000000000a',
  'd0000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*) from supplier.suppliers),
  2::bigint,
  'platform_admin sees all suppliers across tenants'
);
reset role;

select * from finish();
rollback;
