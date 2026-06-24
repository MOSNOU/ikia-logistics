-- CC-07 Security Acceptance Test 020 — Supplier audit event behavior.
--
-- Assertions (4):
--   1. portal_submit_my_profile_for_review writes exactly one row to
--      audit.audit_event with action_code = 'supplier.submitted'.
--   2. admin_start_review writes one row with action_code = 'supplier.review_started'.
--   3. admin_approve_supplier writes one row with action_code = 'supplier.approved'.
--   4. supplier.fn_audit body contains an exception handler that swallows
--      audit failures (audit writes never block lifecycle RPCs).
--      Verified by static inspection of pg_get_functiondef.

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '50100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '020-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '50100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '020-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('50100000-0000-0000-0000-00000000000a', 'tenant-020', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('50100000-0000-0000-0000-00000000001a', '50100000-0000-0000-0000-00000000000a',
   'sup-020', 'تأمین', 'Sup', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('50100000-0000-0000-0000-000000000001', '50100000-0000-0000-0000-00000000000a',
   '50100000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active'),
  ('50100000-0000-0000-0000-000000000002', '50100000-0000-0000-0000-00000000000a',
   '50100000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '50100000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '50100000-0000-0000-0000-000000000002', r.id, 'organization', '50100000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare v_sid uuid;
begin
  select id into v_sid from supplier.suppliers where organization_id = '50100000-0000-0000-0000-00000000001a';
  perform set_config('test.sid', v_sid::text, false);
end;
$$;

select plan(4);

-- 1. supplier_admin calls portal_submit → one 'supplier.submitted' event.
select tests.authenticate_as(
  '50100000-0000-0000-0000-000000000002',
  '50100000-0000-0000-0000-00000000000a',
  '50100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select supplier.portal_submit_my_profile_for_review();
reset role;

select is(
  (select count(*) from audit.audit_event
    where resource_id   = current_setting('test.sid')::uuid
      and action_code   = 'supplier.submitted'
      and actor_user_id = '50100000-0000-0000-0000-000000000002'),
  1::bigint,
  'portal_submit_my_profile_for_review writes one supplier.submitted event'
);

-- 2. platform_admin calls admin_start_review → one 'supplier.review_started'.
select tests.authenticate_as(
  '50100000-0000-0000-0000-000000000001',
  '50100000-0000-0000-0000-00000000000a',
  '50100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select supplier.admin_start_review(current_setting('test.sid')::uuid);
reset role;

select is(
  (select count(*) from audit.audit_event
    where resource_id   = current_setting('test.sid')::uuid
      and action_code   = 'supplier.review_started'
      and actor_user_id = '50100000-0000-0000-0000-000000000001'),
  1::bigint,
  'admin_start_review writes one supplier.review_started event'
);

-- 3. platform_admin approves → one 'supplier.approved'.
select tests.authenticate_as(
  '50100000-0000-0000-0000-000000000001',
  '50100000-0000-0000-0000-00000000000a',
  '50100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select supplier.admin_approve_supplier(current_setting('test.sid')::uuid);
reset role;

select is(
  (select count(*) from audit.audit_event
    where resource_id   = current_setting('test.sid')::uuid
      and action_code   = 'supplier.approved'
      and actor_user_id = '50100000-0000-0000-0000-000000000001'),
  1::bigint,
  'admin_approve_supplier writes one supplier.approved event'
);

-- 4. Static check: supplier.fn_audit body contains the exception handler.
select ok(
  pg_get_functiondef('supplier.fn_audit'::regproc::oid) ilike '%exception when others%',
  'supplier.fn_audit body contains exception handler (audit failures never block lifecycle RPCs)'
);

select * from finish();
rollback;
