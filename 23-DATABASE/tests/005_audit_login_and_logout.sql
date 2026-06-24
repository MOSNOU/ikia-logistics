-- CC-05 Test 005 — sign-in produces a 'login' row in audit.audit_event,
-- record_logout() produces a 'logout' row.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixtures -------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000', '50000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '005-user@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('50000000-0000-0000-0000-000000000010', 'tenant-005', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('50000000-0000-0000-0000-000000000020', '50000000-0000-0000-0000-000000000010', 'org-005', 'سازمان', 'Org', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('50000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000010', '50000000-0000-0000-0000-000000000020', 'Test', 'fa', 'active');

-- Assertions -----------------------------------------------------------------
select plan(2);

-- 1. Hook writes login event when called with authentication_method = 'password'
select identity.custom_access_token_hook(jsonb_build_object(
  'user_id', '50000000-0000-0000-0000-000000000001'::text,
  'claims',  jsonb_build_object('sub', '50000000-0000-0000-0000-000000000001', 'role', 'authenticated'),
  'authentication_method', 'password'
));

select is(
  (select count(*) from audit.audit_event
    where actor_user_id = '50000000-0000-0000-0000-000000000001'
      and action_code = 'login'),
  1::bigint,
  'hook writes one login event for password authentication'
);

-- 2. record_logout() writes a logout event for the authenticated user
select tests.authenticate_as(
  '50000000-0000-0000-0000-000000000001',
  '50000000-0000-0000-0000-000000000010',
  '50000000-0000-0000-0000-000000000020'
);
set local role authenticated;

select identity.record_logout();

reset role;

select is(
  (select count(*) from audit.audit_event
    where actor_user_id = '50000000-0000-0000-0000-000000000001'
      and action_code = 'logout'),
  1::bigint,
  'record_logout writes one logout event'
);

select * from finish();
rollback;
