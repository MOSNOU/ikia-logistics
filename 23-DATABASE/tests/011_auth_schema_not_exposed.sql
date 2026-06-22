-- CC-06 Security Acceptance Test 011 — auth schema is never exposed.
-- Both anon and authenticated must hit a permission-denied error (SQLSTATE
-- 42501) when attempting to SELECT from auth.users. The only sanctioned read
-- path is identity.admin_list_users() / identity.admin_get_user().

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixture: one auth.users row so the failure is at the grant layer,
-- not because the table is empty.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   'b0000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated', '011-fixture@example.com');

select plan(2);

-- 1. anon
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select id from auth.users limit 1 $$,
  '42501',
  null,
  'anon cannot SELECT from auth.users'
);
reset role;

-- 2. authenticated (JWT carrying sub of the fixture user)
select tests.authenticate_as('b0000000-0000-0000-0000-000000000001');
set local role authenticated;
select throws_ok(
  $$ select id from auth.users limit 1 $$,
  '42501',
  null,
  'authenticated cannot SELECT from auth.users'
);
reset role;

select * from finish();
rollback;
