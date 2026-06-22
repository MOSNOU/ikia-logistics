-- CC-06 Security Acceptance Test 012 — audit.* tables are never exposed.
-- Both anon and authenticated must hit a permission-denied error (SQLSTATE
-- 42501) on every audit.* SELECT. The only sanctioned read path is
-- identity.admin_list_audit_events().

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixture: an auth.users row + a seeded audit row in each of the 3 tables.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   'c0000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated', '012-fixture@example.com');

insert into audit.audit_event (action_code, actor_user_id) values
  ('test_012', 'c0000000-0000-0000-0000-000000000001');

insert into audit.audit_entity (entity_schema, entity_table, entity_id, action) values
  ('identity', 'tenants', 'c0000000-0000-0000-0000-000000000002', 'insert');

insert into audit.audit_access (actor_user_id, resource_type, access_type) values
  ('c0000000-0000-0000-0000-000000000001', 'test_resource', 'read');

select plan(4);

-- 1. anon -> audit.audit_event
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select id from audit.audit_event limit 1 $$,
  '42501',
  null,
  'anon cannot SELECT from audit.audit_event'
);
reset role;

-- 2. authenticated -> all three audit tables
select tests.authenticate_as('c0000000-0000-0000-0000-000000000001');
set local role authenticated;

select throws_ok(
  $$ select id from audit.audit_event limit 1 $$,
  '42501',
  null,
  'authenticated cannot SELECT from audit.audit_event'
);

select throws_ok(
  $$ select id from audit.audit_entity limit 1 $$,
  '42501',
  null,
  'authenticated cannot SELECT from audit.audit_entity'
);

select throws_ok(
  $$ select id from audit.audit_access limit 1 $$,
  '42501',
  null,
  'authenticated cannot SELECT from audit.audit_access'
);

reset role;
select * from finish();
rollback;
