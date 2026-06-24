-- CC-07 Security Acceptance Test 019 — Portal mutation scope.
--
-- Assertions (5):
--   1. No supplier.portal_* RPC accepts a p_supplier_id parameter
--      (supplier is derived from current_organization_id; no ID-manipulation
--       attack surface).
--   2. supplier_admin in org A calling portal_upsert_my_profile updates ONLY
--      supplier A. Supplier B is left unchanged.
--   3. organization_admin in own supplier org CAN call portal_upsert_my_profile
--      (correction C — already covered in 015 but reasserted in acceptance).
--   4. platform_admin with JWT.organization_id pointing at a supplier org CAN
--      call portal_upsert_my_profile.
--   5. platform_admin WITHOUT a current_organization_id in JWT raises P0002
--      ('no active organization in JWT').

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '40100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '019-supA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '40100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '019-orgA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '40100000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '019-plat@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('40100000-0000-0000-0000-00000000000a', 'tenant-019a', 'الف', 'A'),
  ('40100000-0000-0000-0000-00000000000b', 'tenant-019b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('40100000-0000-0000-0000-00000000001a', '40100000-0000-0000-0000-00000000000a',
   'sup-019a', 'تأمین الف', 'Supplier A', 'supplier', 'active'),
  ('40100000-0000-0000-0000-00000000001b', '40100000-0000-0000-0000-00000000000b',
   'sup-019b', 'تأمین ب',  'Supplier B', 'supplier', 'active');
-- Trigger created two supplier shells.

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('40100000-0000-0000-0000-000000000001', '40100000-0000-0000-0000-00000000000a',
   '40100000-0000-0000-0000-00000000001a', 'A-Sup', 'fa', 'active'),
  ('40100000-0000-0000-0000-000000000002', '40100000-0000-0000-0000-00000000000a',
   '40100000-0000-0000-0000-00000000001a', 'A-Org', 'fa', 'active'),
  ('40100000-0000-0000-0000-000000000003', '40100000-0000-0000-0000-00000000000a',
   '40100000-0000-0000-0000-00000000001a', 'Platform', 'fa', 'active');

-- supplier_admin of org A
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '40100000-0000-0000-0000-000000000001', r.id, 'organization', '40100000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'supplier_admin';
-- organization_admin of org A
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '40100000-0000-0000-0000-000000000002', r.id, 'organization', '40100000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'organization_admin';
-- platform_admin
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '40100000-0000-0000-0000-000000000003', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(5);

-- 1. STATIC INTROSPECTION: no portal_* RPC accepts a p_supplier_id arg.
select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'supplier'
      and p.proname like 'portal_%'
      and p.proargnames is not null
      and 'p_supplier_id' = any(p.proargnames)),
  0,
  'no supplier.portal_* RPC accepts a p_supplier_id parameter'
);

-- Capture supplier_id values for verification.
do $$
declare v_a uuid; v_b uuid;
begin
  select id into v_a from supplier.suppliers where organization_id = '40100000-0000-0000-0000-00000000001a';
  select id into v_b from supplier.suppliers where organization_id = '40100000-0000-0000-0000-00000000001b';
  perform set_config('test.sid_a', v_a::text, false);
  perform set_config('test.sid_b', v_b::text, false);
end;
$$;

-- 2. supplier_admin in A: portal_upsert touches only supplier A.
select tests.authenticate_as(
  '40100000-0000-0000-0000-000000000001',
  '40100000-0000-0000-0000-00000000000a',
  '40100000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select supplier.portal_upsert_my_profile('BRAND-A', null, null, null, null, null, null);

reset role;

select is(
  (select display_name from supplier.suppliers where id = current_setting('test.sid_a')::uuid)
    || '|' ||
  coalesce((select display_name from supplier.suppliers where id = current_setting('test.sid_b')::uuid),
           'تأمین ب'),  -- supplier B should keep its trigger-default name
  'BRAND-A|تأمین ب',
  'supplier_admin updates only own supplier; unrelated supplier untouched'
);

-- 3. organization_admin in own org A: portal_upsert succeeds.
select tests.authenticate_as(
  '40100000-0000-0000-0000-000000000002',
  '40100000-0000-0000-0000-00000000000a',
  '40100000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select lives_ok(
  $$ select supplier.portal_upsert_my_profile('ORG-A-EDIT', null, null, null, null, null, null) $$,
  'organization_admin in own supplier organization can call portal_upsert_my_profile'
);

reset role;

-- 4. platform_admin with JWT.org = supplier org A: portal_upsert succeeds.
select tests.authenticate_as(
  '40100000-0000-0000-0000-000000000003',
  '40100000-0000-0000-0000-00000000000a',
  '40100000-0000-0000-0000-00000000001a'
);
set local role authenticated;

select lives_ok(
  $$ select supplier.portal_upsert_my_profile('PLATFORM-EDIT', null, null, null, null, null, null) $$,
  'platform_admin with JWT.organization_id set to a supplier org can call portal_upsert_my_profile'
);

reset role;

-- 5. platform_admin WITHOUT JWT.organization_id raises P0002.
select tests.authenticate_as('40100000-0000-0000-0000-000000000003');  -- sub only, no org
set local role authenticated;

select throws_ok(
  $$ select supplier.portal_upsert_my_profile('SHOULD-FAIL', null, null, null, null, null, null) $$,
  'P0002', null,
  'platform_admin without current_organization_id cannot call portal_upsert_my_profile'
);

reset role;
select * from finish();
rollback;
