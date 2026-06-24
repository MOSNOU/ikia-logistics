-- CC-05 Test 003 — platform_admin sees soft-deleted rows via *_select_deleted;
-- compliance_officer sees soft-deleted rows; regular RLS still blocks them
-- from being seen by the active *_select policy.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixtures -------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000', '30000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '003-platform@example.com'),
  ('00000000-0000-0000-0000-000000000000', '30000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '003-compliance@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('30000000-0000-0000-0000-000000000010', 'tenant-003a',  'فعال',     'Active'),
  ('30000000-0000-0000-0000-000000000011', 'tenant-003-d', 'حذف‌شده', 'Deleted');

update identity.tenants
   set deleted_at = now()
 where id = '30000000-0000-0000-0000-000000000011';

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('30000000-0000-0000-0000-000000000020', '30000000-0000-0000-0000-000000000010', 'org-003', 'سازمان', 'Org', 'platform', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('30000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000020', 'Platform Admin',     'fa', 'active'),
  ('30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000020', 'Compliance Officer', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '30000000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '30000000-0000-0000-0000-000000000002', r.id, 'organization', '30000000-0000-0000-0000-000000000020'
  from identity.roles r where r.code = 'compliance_officer';

-- Assertions -----------------------------------------------------------------
select plan(3);

-- 1. platform_admin sees the soft-deleted tenant via *_select_deleted
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000010',
  '30000000-0000-0000-0000-000000000020'
);
set local role authenticated;

select is(
  (select count(*) from identity.tenants
    where id = '30000000-0000-0000-0000-000000000011'),
  1::bigint,
  'platform_admin sees soft-deleted tenant via *_select_deleted'
);

reset role;

-- 2. compliance_officer also sees soft-deleted tenant
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000002',
  '30000000-0000-0000-0000-000000000010',
  '30000000-0000-0000-0000-000000000020'
);
set local role authenticated;

select is(
  (select count(*) from identity.tenants
    where id = '30000000-0000-0000-0000-000000000011'),
  1::bigint,
  'compliance_officer sees soft-deleted tenant via *_select_deleted'
);

reset role;

-- 3. A user without platform_admin or compliance_officer sees ZERO
--    soft-deleted rows even if they share the active tenant.
-- Use User A (no compliance role) impersonation via plain JWT (no roles).
-- Insert a throwaway user with no roles so the test is explicit.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000', '30000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '003-rookie@example.com');
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('30000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000020', 'Rookie', 'fa', 'active');

select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000003',
  '30000000-0000-0000-0000-000000000010',
  '30000000-0000-0000-0000-000000000020'
);
set local role authenticated;

select is(
  (select count(*) from identity.tenants
    where id = '30000000-0000-0000-0000-000000000011'),
  0::bigint,
  'unprivileged user does NOT see soft-deleted tenant'
);

reset role;
select * from finish();
rollback;
