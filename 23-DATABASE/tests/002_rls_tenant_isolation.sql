-- CC-05 Test 002 — buyer A in tenant A cannot see tenant B's organization or
-- User B's profile. User A can see their own profile and own org.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixtures (as postgres, RLS bypassed) ---------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '002a@example.com'),
  ('00000000-0000-0000-0000-000000000000', '20000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '002b@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('20000000-0000-0000-0000-000000000010', 'tenant-002a', 'تننت الف', 'Tenant A'),
  ('20000000-0000-0000-0000-000000000011', 'tenant-002b', 'تننت ب',  'Tenant B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('20000000-0000-0000-0000-000000000020', '20000000-0000-0000-0000-000000000010', 'buyer-002a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('20000000-0000-0000-0000-000000000021', '20000000-0000-0000-0000-000000000011', 'buyer-002b', 'خریدار ب',  'Buyer B', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('20000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000020', 'User A', 'fa', 'active'),
  ('20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000011', '20000000-0000-0000-0000-000000000021', 'User B', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '20000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000020',
       '20000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '20000000-0000-0000-0000-000000000011', '20000000-0000-0000-0000-000000000021',
       '20000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '20000000-0000-0000-0000-000000000001', r.id, 'organization', '20000000-0000-0000-0000-000000000020'
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '20000000-0000-0000-0000-000000000002', r.id, 'organization', '20000000-0000-0000-0000-000000000021'
  from identity.roles r where r.code = 'buyer_admin';

-- Authenticate as User A and run assertions ---------------------------------
select plan(3);

select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-000000000010',
  '20000000-0000-0000-0000-000000000020'
);
set local role authenticated;

select is(
  (select count(*) from organization.organizations),
  1::bigint,
  'User A sees only own organization (tenant isolation)'
);

select is(
  (select count(*) from identity.user_profiles
    where id = '20000000-0000-0000-0000-000000000002'),
  0::bigint,
  'User A cannot see User B profile'
);

select is(
  (select count(*) from identity.user_profiles
    where id = '20000000-0000-0000-0000-000000000001'),
  1::bigint,
  'User A sees own profile'
);

reset role;
select * from finish();
rollback;
