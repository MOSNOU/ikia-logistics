-- CC-06 Test 009 — admin_add_membership inserts a membership whose tenant_id
-- is derived from the target organization, not from the caller.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Two tenants. Admin's primary tenant differs from the target org's tenant.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '90000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated', '009-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '90000000-0000-0000-0000-000000000002',
   'authenticated', 'authenticated', '009-target@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('90000000-0000-0000-0000-00000000000a', 'tenant-009a', 'الف', 'A'),
  ('90000000-0000-0000-0000-00000000000b', 'tenant-009b', 'ب',  'B');

-- Target org lives in tenant B.
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('90000000-0000-0000-0000-00000000002b', '90000000-0000-0000-0000-00000000000b',
   'org-b', 'سازمان ب', 'Org B', 'buyer', 'active');

-- Admin sits in tenant A but mutates a membership in tenant B's org.
insert into identity.user_profiles (id, tenant_id, full_name, locale, status) values
  ('90000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-00000000000a',
   'Admin', 'fa', 'active');
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '90000000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(1);

select tests.authenticate_as('90000000-0000-0000-0000-000000000001',
                             '90000000-0000-0000-0000-00000000000a');
set local role authenticated;

select identity.admin_add_membership(
  '90000000-0000-0000-0000-00000000002b',
  '90000000-0000-0000-0000-000000000002',
  'buyer_admin'
);

reset role;

select is(
  (select tenant_id from organization.memberships
    where organization_id = '90000000-0000-0000-0000-00000000002b'
      and user_id = '90000000-0000-0000-0000-000000000002'),
  '90000000-0000-0000-0000-00000000000b'::uuid,
  'admin_add_membership derives tenant_id from organization, not from caller'
);

select * from finish();
rollback;
