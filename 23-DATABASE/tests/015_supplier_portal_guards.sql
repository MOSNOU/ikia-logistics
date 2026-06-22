-- CC-07 Test 015 — supplier.portal_* RPC guards (correction C).
--   * Reject authenticated users without supplier_admin / organization_admin / platform_admin
--   * Positive: organization_admin CAN call portal_upsert_my_profile (correction C)

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

-- Fixtures ------------------------------------------------------------------
-- Two users: an unrelated authenticated (no relevant role) + an org_admin user.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   'f0000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '015-rookie@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   'f0000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '015-orgadm@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('f0000000-0000-0000-0000-00000000000a', 'tenant-015', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('f0000000-0000-0000-0000-00000000001a', 'f0000000-0000-0000-0000-00000000000a',
   'sup-015', 'تأمین‌کننده', 'Supplier', 'supplier', 'active');
-- Trigger creates supplier shell.

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('f0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-00000000000a',
   'f0000000-0000-0000-0000-00000000001a', 'Rookie', 'fa', 'active'),
  ('f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-00000000000a',
   'f0000000-0000-0000-0000-00000000001a', 'Org Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select 'f0000000-0000-0000-0000-000000000002', r.id, 'organization', 'f0000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'organization_admin';

-- Lookup ids of a real category and (later) the auto-created supplier.
-- These are used inside throws_ok queries via $$ ... $$ so they need to be
-- literal — we capture them via configurations.
do $$
declare
  v_cat uuid;
begin
  select id into v_cat from supplier.categories order by code limit 1;
  perform set_config('test.cat_id', v_cat::text, false);
end;
$$;

select plan(7);

-- Negative: rookie (no role) is rejected by every portal RPC.
select tests.authenticate_as(
  'f0000000-0000-0000-0000-000000000001',
  'f0000000-0000-0000-0000-00000000000a',
  'f0000000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select throws_ok(
  $$ select supplier.portal_upsert_my_profile(null, null, null, null, null, null, null); $$,
  '42501', null,
  'portal_upsert_my_profile rejects user without portal role'
);

select throws_ok(
  format('select supplier.portal_add_my_category(%L);', current_setting('test.cat_id')),
  '42501', null,
  'portal_add_my_category rejects user without portal role'
);

select throws_ok(
  format('select supplier.portal_remove_my_category(%L);', current_setting('test.cat_id')),
  '42501', null,
  'portal_remove_my_category rejects user without portal role'
);

select throws_ok(
  $$ select supplier.portal_add_my_document('license', 'x', null, null, null, null); $$,
  '42501', null,
  'portal_add_my_document rejects user without portal role'
);

select throws_ok(
  $$ select supplier.portal_remove_my_document('00000000-0000-0000-0000-000000000099'); $$,
  '42501', null,
  'portal_remove_my_document rejects user without portal role'
);

select throws_ok(
  $$ select supplier.portal_submit_my_profile_for_review(); $$,
  '42501', null,
  'portal_submit_my_profile_for_review rejects user without portal role'
);

reset role;

-- Positive: organization_admin (correction C) CAN call portal_upsert_my_profile.
select tests.authenticate_as(
  'f0000000-0000-0000-0000-000000000002',
  'f0000000-0000-0000-0000-00000000000a',
  'f0000000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select lives_ok(
  $$ select supplier.portal_upsert_my_profile(
       'Brand Name', 'desc', 'https://example.com', 'a@b.com', null, 'IR', 2020); $$,
  'organization_admin can call portal_upsert_my_profile (correction C)'
);

reset role;
select * from finish();
rollback;
