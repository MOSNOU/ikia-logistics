-- CC-06 Test 008 — admin_create_organization returns a uuid and the new row
-- carries the supplied tenant_id.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '80000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated', '008-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('80000000-0000-0000-0000-000000000010', 'tenant-008', 'تست', 'Test');

insert into identity.user_profiles (id, tenant_id, full_name, locale, status) values
  ('80000000-0000-0000-0000-000000000001', '80000000-0000-0000-0000-000000000010',
   'Admin', 'fa', 'active');
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '80000000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(1);

select tests.authenticate_as('80000000-0000-0000-0000-000000000001',
                             '80000000-0000-0000-0000-000000000010');
set local role authenticated;

-- Call the RPC in its own statement so the side-effect INSERT fires once.
select identity.admin_create_organization(
  '80000000-0000-0000-0000-000000000010',
  'org-008',
  'سازمان ۸',
  'Org 8',
  'buyer'
);

reset role;

-- Verify the row landed with the supplied tenant_id (lookup by unique code).
select is(
  (select tenant_id from organization.organizations where code = 'org-008'),
  '80000000-0000-0000-0000-000000000010'::uuid,
  'admin_create_organization creates org with correct tenant_id'
);

select * from finish();
rollback;
