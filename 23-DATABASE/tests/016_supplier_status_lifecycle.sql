-- CC-07 Test 016 — Happy-path supplier status lifecycle.
--   1. Trigger creates draft on supplier-type org insert
--   2. portal_submit moves draft → submitted (as supplier_admin)
--   3. admin_start_review moves submitted → under_review
--   4. admin_approve_supplier moves under_review → approved

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '10100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '016-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '10100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '016-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('10100000-0000-0000-0000-00000000000a', 'tenant-016', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('10100000-0000-0000-0000-00000000001a', '10100000-0000-0000-0000-00000000000a',
   'sup-016', 'تأمین‌کننده', 'Supplier', 'supplier', 'active');
-- Trigger creates a draft supplier shell.

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('10100000-0000-0000-0000-000000000001', '10100000-0000-0000-0000-00000000000a',
   '10100000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active'),
  ('10100000-0000-0000-0000-000000000002', '10100000-0000-0000-0000-00000000000a',
   '10100000-0000-0000-0000-00000000001a', 'Supplier Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '10100000-0000-0000-0000-000000000001', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '10100000-0000-0000-0000-000000000002', r.id, 'organization', '10100000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'supplier_admin';

select plan(4);

-- 1. Trigger created a draft supplier on the supplier-type org insert.
select is(
  (select status::text from supplier.suppliers
    where organization_id = '10100000-0000-0000-0000-00000000001a'),
  'draft',
  'trigger created draft supplier shell on org type=supplier insert'
);

-- 2. supplier_admin submits for review → status='submitted'.
select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000002',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select supplier.portal_submit_my_profile_for_review();
reset role;

select is(
  (select status::text from supplier.suppliers
    where organization_id = '10100000-0000-0000-0000-00000000001a'),
  'submitted',
  'portal_submit_my_profile_for_review moves draft → submitted'
);

-- 3. platform_admin starts review → status='under_review'.
do $$
declare v_sid uuid;
begin
  select id into v_sid from supplier.suppliers
   where organization_id = '10100000-0000-0000-0000-00000000001a';
  perform set_config('test.supplier_id', v_sid::text, false);
end;
$$;

select tests.authenticate_as(
  '10100000-0000-0000-0000-000000000001',
  '10100000-0000-0000-0000-00000000000a',
  '10100000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select supplier.admin_start_review(current_setting('test.supplier_id')::uuid);

select is(
  (select status::text from supplier.suppliers
    where id = current_setting('test.supplier_id')::uuid),
  'under_review',
  'admin_start_review moves submitted → under_review'
);

-- 4. platform_admin approves → status='approved'.
select supplier.admin_approve_supplier(current_setting('test.supplier_id')::uuid);

select is(
  (select status::text from supplier.suppliers
    where id = current_setting('test.supplier_id')::uuid),
  'approved',
  'admin_approve_supplier moves under_review → approved'
);

reset role;
select * from finish();
rollback;
