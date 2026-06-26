-- CC-72 Test 144 — identity.admin_get_dashboard_summary()
--
-- Assertions (8):
--   1. function exists with zero arguments
--   2. function is SECURITY DEFINER
--   3. function has search_path = '' (empty string)
--   4. authenticated has EXECUTE
--   5. anon does NOT have EXECUTE
--   6. function has zero parameters (no scope override)
--   7. platform_admin caller receives a jsonb with expected count keys
--   8. non-admin caller is blocked with errcode 42501

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

-- Fixtures: one admin user and one non-admin (buyer) user.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000a44', 'authenticated', 'authenticated',
   '144-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000b44', 'authenticated', 'authenticated',
   '144-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000c44a', 'tenant-144', 'تست', 'Test 144');

insert into organization.organizations
  (id, tenant_id, code, name_fa, name_en, type, status, country_code)
values
  ('53000000-0000-0000-0000-00000000c44b',
   '53000000-0000-0000-0000-00000000c44a',
   'org-144', 'سازمان', 'Org 144', 'buyer', 'active', 'IR');

insert into identity.user_profiles
  (id, tenant_id, primary_organization_id, full_name, locale, status)
values
  ('53000000-0000-0000-0000-000000000a44',
   '53000000-0000-0000-0000-00000000c44a',
   null, 'Test Admin 144', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000b44',
   '53000000-0000-0000-0000-00000000c44a',
   '53000000-0000-0000-0000-00000000c44b', 'Test Buyer 144', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000a44', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000b44', r.id,
       'organization', '53000000-0000-0000-0000-00000000c44b'
  from identity.roles r where r.code = 'buyer_admin';

select plan(8);

-- 1. function exists with zero args
select has_function(
  'identity', 'admin_get_dashboard_summary', array[]::text[],
  'function exists with zero arguments');

-- 2. SECURITY DEFINER
select is(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='identity' and p.proname='admin_get_dashboard_summary'),
  true, 'function is SECURITY DEFINER');

-- 3. search_path = ''
select is(
  (select unnest(proconfig) from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='identity' and p.proname='admin_get_dashboard_summary'),
  'search_path=""',
  'function has search_path set to the empty string');

-- 4. authenticated has EXECUTE
select is(
  has_function_privilege(
    'authenticated', 'identity.admin_get_dashboard_summary()', 'EXECUTE'),
  true, 'authenticated has EXECUTE');

-- 5. anon does NOT have EXECUTE
select is(
  has_function_privilege(
    'anon', 'identity.admin_get_dashboard_summary()', 'EXECUTE'),
  false, 'anon does not have EXECUTE');

-- 6. zero parameters (no override)
select is(
  (select pronargs::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='identity' and p.proname='admin_get_dashboard_summary'),
  0, 'function has zero parameters');

-- 7. platform_admin caller receives jsonb with expected keys
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object(
      'sub', '53000000-0000-0000-0000-000000000a44',
      'role','authenticated'
    )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000a44', true);
  set local role authenticated;
end $$;

select ok(
  (
    select identity.admin_get_dashboard_summary() ? 'organizationsCount'
       and identity.admin_get_dashboard_summary() ? 'activeUsersCount'
       and identity.admin_get_dashboard_summary() ? 'suppliersCount'
       and identity.admin_get_dashboard_summary() ? 'recentAuditEventsCount'
       and identity.admin_get_dashboard_summary() ? 'recentAuditEvents'
  ),
  'admin call: jsonb contains all expected keys');

reset role;

-- 8. non-admin (buyer) call raises 42501
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object(
      'sub', '53000000-0000-0000-0000-000000000b44',
      'role','authenticated'
    )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000b44', true);
  set local role authenticated;
end $$;

select throws_ok(
  $q$select identity.admin_get_dashboard_summary()$q$,
  '42501', null,
  'non-admin caller is blocked with errcode 42501');

reset role;
select * from finish();
rollback;
