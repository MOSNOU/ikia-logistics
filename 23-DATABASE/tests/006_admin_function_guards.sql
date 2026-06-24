-- CC-06 Test 006 — every admin_* RPC rejects unprivileged authenticated callers.
-- 8 assertions: one per RPC. Caller has no roles, so is_platform_admin() and
-- has_role('compliance_officer') both return false.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

-- Fixture: an authenticated user with NO roles assigned.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '60000000-0000-0000-0000-000000000001',
   'authenticated', 'authenticated',
   '006-rookie@example.com');

select plan(8);

select tests.authenticate_as('60000000-0000-0000-0000-000000000001');
set local role authenticated;

select throws_ok(
  $$ select * from identity.admin_list_users(25, 0, null); $$,
  '42501',
  null,
  'admin_list_users rejects non-admin'
);

select throws_ok(
  $$ select * from identity.admin_get_user('60000000-0000-0000-0000-000000000001'); $$,
  '42501',
  null,
  'admin_get_user rejects non-admin'
);

select throws_ok(
  $$ select * from identity.admin_list_audit_events(50, 0, null); $$,
  '42501',
  null,
  'admin_list_audit_events rejects non-admin / non-compliance'
);

select throws_ok(
  $$ select identity.admin_create_organization(
       '00000000-0000-0000-0000-000000000001',
       'bad', 'بد', 'Bad', 'buyer'); $$,
  '42501',
  null,
  'admin_create_organization rejects non-admin'
);

select throws_ok(
  $$ select identity.admin_add_membership(
       '00000000-0000-0000-0000-000000000002',
       '60000000-0000-0000-0000-000000000001',
       'buyer_admin'); $$,
  '42501',
  null,
  'admin_add_membership rejects non-admin'
);

select throws_ok(
  $$ select identity.admin_approve_user(
       '60000000-0000-0000-0000-000000000001',
       '00000000-0000-0000-0000-000000000001',
       '00000000-0000-0000-0000-000000000002',
       'buyer_admin'); $$,
  '42501',
  null,
  'admin_approve_user rejects non-admin'
);

select throws_ok(
  $$ select identity.admin_set_user_status(
       '60000000-0000-0000-0000-000000000001', 'suspended'); $$,
  '42501',
  null,
  'admin_set_user_status rejects non-admin'
);

select throws_ok(
  $$ select identity.admin_assign_role(
       '60000000-0000-0000-0000-000000000001',
       'buyer_admin', 'organization',
       '00000000-0000-0000-0000-000000000002'); $$,
  '42501',
  null,
  'admin_assign_role rejects non-admin'
);

reset role;
select * from finish();
rollback;
