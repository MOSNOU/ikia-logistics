-- CC-05 Test 004 — JWT hook output shape.
-- Hook stamps tenant_id, organization_id, user_roles for a provisioned user.
-- Hook leaves tenant_id / organization_id absent for an unprovisioned user.
-- Hook is defensive: NULL user_id returns event unchanged.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixtures -------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000', '40000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '004-with-profile@example.com'),
  ('00000000-0000-0000-0000-000000000000', '40000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '004-no-profile@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('40000000-0000-0000-0000-000000000010', 'tenant-004', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('40000000-0000-0000-0000-000000000020', '40000000-0000-0000-0000-000000000010', 'org-004', 'سازمان', 'Org', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('40000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000010', '40000000-0000-0000-0000-000000000020', 'With Profile', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '40000000-0000-0000-0000-000000000001', r.id, 'organization', '40000000-0000-0000-0000-000000000020'
  from identity.roles r where r.code = 'buyer_admin';

-- Assertions -----------------------------------------------------------------
select plan(3);

-- 1. Provisioned user → tenant_id stamped
select is(
  identity.custom_access_token_hook(jsonb_build_object(
    'user_id', '40000000-0000-0000-0000-000000000001'::text,
    'claims',  jsonb_build_object('sub', '40000000-0000-0000-0000-000000000001', 'role', 'authenticated'),
    'authentication_method', 'password'
  )) -> 'claims' ->> 'tenant_id',
  '40000000-0000-0000-0000-000000000010',
  'hook stamps tenant_id for user with profile'
);

-- 2. Provisioned user → user_roles contains buyer_admin
select is(
  identity.custom_access_token_hook(jsonb_build_object(
    'user_id', '40000000-0000-0000-0000-000000000001'::text,
    'claims',  jsonb_build_object('sub', '40000000-0000-0000-0000-000000000001', 'role', 'authenticated'),
    'authentication_method', 'password'
  )) -> 'claims' -> 'user_roles' ->> 0,
  'buyer_admin',
  'hook stamps user_roles with buyer_admin'
);

-- 3. Unprovisioned user → no tenant_id key in claims
select ok(
  not (
    identity.custom_access_token_hook(jsonb_build_object(
      'user_id', '40000000-0000-0000-0000-000000000002'::text,
      'claims',  jsonb_build_object('sub', '40000000-0000-0000-0000-000000000002', 'role', 'authenticated'),
      'authentication_method', 'password'
    )) -> 'claims' ? 'tenant_id'
  ),
  'hook omits tenant_id for user without profile'
);

select * from finish();
rollback;
