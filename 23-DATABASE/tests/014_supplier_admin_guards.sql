-- CC-07 Test 014 — every supplier.admin_* RPC rejects non-admin callers (42501).

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

-- Fixture: a single unprivileged authenticated user (no platform_admin role).
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   'e0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '014-rookie@example.com');

select plan(9);

select tests.authenticate_as('e0000000-0000-0000-0000-000000000001');
set local role authenticated;

select throws_ok(
  $$ select * from supplier.admin_list_suppliers(25, 0, null, null); $$,
  '42501', null,
  'admin_list_suppliers rejects non-admin'
);

select throws_ok(
  $$ select * from supplier.admin_get_supplier('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'admin_get_supplier rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_start_review('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'admin_start_review rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_approve_supplier('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'admin_approve_supplier rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_reject_supplier('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'admin_reject_supplier rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_suspend_supplier('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'admin_suspend_supplier rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_reactivate_supplier('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'admin_reactivate_supplier rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_set_verification_status(
       '00000000-0000-0000-0000-000000000099', 'verified', null); $$,
  '42501', null,
  'admin_set_verification_status rejects non-admin'
);

select throws_ok(
  $$ select supplier.admin_set_document_status(
       '00000000-0000-0000-0000-000000000099', 'verified', null); $$,
  '42501', null,
  'admin_set_document_status rejects non-admin'
);

reset role;
select * from finish();
rollback;
