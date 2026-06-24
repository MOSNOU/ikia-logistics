-- CC-06 Test 010 — admin_list_audit_events row scoping.
--   platform_admin    → sees events across all tenants
--   compliance_officer → sees only events whose tenant_id matches their JWT
--                        (silent zero rows on cross-tenant events).

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Two tenants.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   'a0000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated', '010-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   'a0000000-0000-0000-0000-000000000002',
   'authenticated', 'authenticated', '010-compliance@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('a0000000-0000-0000-0000-00000000000a', 'tenant-010a', 'الف', 'A'),
  ('a0000000-0000-0000-0000-00000000000b', 'tenant-010b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('a0000000-0000-0000-0000-00000000001a', 'a0000000-0000-0000-0000-00000000000a',
   'org-010a', 'سازمان الف', 'Org A', 'platform', 'active'),
  ('a0000000-0000-0000-0000-00000000001b', 'a0000000-0000-0000-0000-00000000000b',
   'org-010b', 'سازمان ب', 'Org B', 'platform', 'active');

-- Admin in tenant A
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a',
   'a0000000-0000-0000-0000-00000000001a', 'Platform Admin', 'fa', 'active'),
  ('a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-00000000000a',
   'a0000000-0000-0000-0000-00000000001a', 'Compliance Officer A', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select 'a0000000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select 'a0000000-0000-0000-0000-000000000002', r.id, 'organization',
       'a0000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'compliance_officer';

-- Seed audit events: one in tenant A, one in tenant B.
insert into audit.audit_event (tenant_id, organization_id, action_code, occurred_at) values
  ('a0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-00000000001a',
   'test_a', now() - interval '1 minute'),
  ('a0000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-00000000001b',
   'test_b', now() - interval '2 minutes');

select plan(2);

-- 1. platform_admin: sees both events
select tests.authenticate_as(
  'a0000000-0000-0000-0000-000000000001',
  'a0000000-0000-0000-0000-00000000000a',
  'a0000000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select is(
  (select count(*) from identity.admin_list_audit_events(100, 0, null)
    where action_code in ('test_a', 'test_b')),
  2::bigint,
  'platform_admin sees events from both tenants'
);

reset role;

-- 2. compliance_officer with tenant A JWT: sees test_a only
select tests.authenticate_as(
  'a0000000-0000-0000-0000-000000000002',
  'a0000000-0000-0000-0000-00000000000a',
  'a0000000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select is(
  (select count(*) from identity.admin_list_audit_events(100, 0, null)
    where action_code in ('test_a', 'test_b')),
  1::bigint,
  'compliance_officer sees own-tenant events only'
);

reset role;
select * from finish();
rollback;
