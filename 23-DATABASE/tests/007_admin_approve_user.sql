-- CC-06 Test 007 — admin_approve_user creates user_profiles + memberships +
-- user_roles atomically. Re-calling it does not duplicate user_roles
-- (idempotency check).

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixtures: platform admin + target user + tenant + org.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '70000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated', '007-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '70000000-0000-0000-0000-000000000002',
   'authenticated', 'authenticated', '007-target@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('70000000-0000-0000-0000-000000000010', 'tenant-007', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('70000000-0000-0000-0000-000000000020', '70000000-0000-0000-0000-000000000010',
   'org-007', 'سازمان', 'Org', 'buyer', 'active');

-- Admin profile + platform_admin role.
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('70000000-0000-0000-0000-000000000001', '70000000-0000-0000-0000-000000000010',
   '70000000-0000-0000-0000-000000000020', 'Admin', 'fa', 'active');
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '70000000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(4);

select tests.authenticate_as(
  '70000000-0000-0000-0000-000000000001',
  '70000000-0000-0000-0000-000000000010',
  '70000000-0000-0000-0000-000000000020'
);
set local role authenticated;

-- First approval.
select identity.admin_approve_user(
  '70000000-0000-0000-0000-000000000002',
  '70000000-0000-0000-0000-000000000010',
  '70000000-0000-0000-0000-000000000020',
  'buyer_admin',
  'Approved User',
  'fa'
);

reset role;

select is(
  (select count(*) from identity.user_profiles
    where id = '70000000-0000-0000-0000-000000000002'
      and status = 'active'),
  1::bigint,
  'admin_approve_user creates user_profile with status=active'
);

select is(
  (select count(*) from organization.memberships m
     join identity.roles r on r.id = m.role_id
    where m.user_id = '70000000-0000-0000-0000-000000000002'
      and m.organization_id = '70000000-0000-0000-0000-000000000020'
      and r.code = 'buyer_admin'),
  1::bigint,
  'admin_approve_user creates one membership with chosen role'
);

select is(
  (select count(*) from identity.user_roles ur
     join identity.roles r on r.id = ur.role_id
    where ur.user_id = '70000000-0000-0000-0000-000000000002'
      and r.code = 'buyer_admin'
      and ur.scope_type = 'organization'
      and ur.scope_id = '70000000-0000-0000-0000-000000000020'
      and ur.revoked_at is null
      and ur.deleted_at is null),
  1::bigint,
  'admin_approve_user creates one active user_role for org scope'
);

-- Idempotency: call approve again. Should not create a second user_role row.
select tests.authenticate_as(
  '70000000-0000-0000-0000-000000000001',
  '70000000-0000-0000-0000-000000000010',
  '70000000-0000-0000-0000-000000000020'
);
set local role authenticated;

select identity.admin_approve_user(
  '70000000-0000-0000-0000-000000000002',
  '70000000-0000-0000-0000-000000000010',
  '70000000-0000-0000-0000-000000000020',
  'buyer_admin',
  'Approved User',
  'fa'
);

reset role;

select is(
  (select count(*) from identity.user_roles ur
     join identity.roles r on r.id = ur.role_id
    where ur.user_id = '70000000-0000-0000-0000-000000000002'
      and r.code = 'buyer_admin'
      and ur.scope_type = 'organization'
      and ur.scope_id = '70000000-0000-0000-0000-000000000020'
      and ur.revoked_at is null
      and ur.deleted_at is null),
  1::bigint,
  'idempotent: re-approval does not duplicate user_role'
);

select * from finish();
rollback;
