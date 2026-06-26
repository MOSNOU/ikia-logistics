-- CC-68B Test 143 — identity.get_current_auth_profile()
--
-- Assertions (10):
--   1.  function exists with the expected zero-arg signature
--   2.  function is SECURITY DEFINER
--   3.  function has search_path = '' (an empty string config setting)
--   4.  authenticated has EXECUTE
--   5.  anon does NOT have EXECUTE (revoked explicitly)
--   6.  function has zero parameters (no p_user_id)
--   7.  with a seeded platform_admin user, roles[] contains 'platform_admin'
--   8.  hasProfile is true when the seeded user_profile exists
--   9.  email is returned correctly for the seeded user
--  10.  an unrelated authenticated caller sees only their own profile
--       (cannot read the admin's data through this RPC)

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture: one admin user + one unrelated buyer-org user.
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000a43', 'authenticated', 'authenticated',
   '143-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000b43', 'authenticated', 'authenticated',
   '143-other@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000c43a', 'tenant-143', 'تست', 'Test 143');

insert into organization.organizations
  (id, tenant_id, code, name_fa, name_en, type, status, country_code)
values
  ('53000000-0000-0000-0000-00000000c43b',
   '53000000-0000-0000-0000-00000000c43a',
   'org-143', 'سازمان', 'Org 143', 'buyer', 'active', 'IR');

insert into identity.user_profiles
  (id, tenant_id, primary_organization_id, full_name, locale, status)
values
  ('53000000-0000-0000-0000-000000000a43',
   '53000000-0000-0000-0000-00000000c43a',
   null, 'Test Admin', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000b43',
   '53000000-0000-0000-0000-00000000c43a',
   '53000000-0000-0000-0000-00000000c43b', 'Test Other', 'fa', 'active');

-- Assign platform_admin to the first user (no scope_id, scope = platform).
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000a43', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- A buyer-org membership for the "other" user (so memberships path exercises).
insert into organization.memberships
  (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000c43a',
       '53000000-0000-0000-0000-00000000c43b',
       '53000000-0000-0000-0000-000000000b43',
       r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

select plan(10);

-- 1. function exists with expected signature (no args)
select has_function(
  'identity', 'get_current_auth_profile', array[]::text[],
  'function exists with zero arguments');

-- 2. SECURITY DEFINER
select is(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='identity' and p.proname='get_current_auth_profile'),
  true, 'function is SECURITY DEFINER');

-- 3. search_path = '' (empty string set as a function config)
select is(
  (select unnest(proconfig) from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='identity' and p.proname='get_current_auth_profile'),
  'search_path=""',
  'function has search_path set to the empty string');

-- 4. authenticated has EXECUTE
select is(
  has_function_privilege(
    'authenticated', 'identity.get_current_auth_profile()', 'EXECUTE'),
  true, 'authenticated has EXECUTE');

-- 5. anon does NOT have EXECUTE
select is(
  has_function_privilege(
    'anon', 'identity.get_current_auth_profile()', 'EXECUTE'),
  false, 'anon does not have EXECUTE');

-- 6. function has zero parameters (no p_user_id and no other arg)
select is(
  (select pronargs::int from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='identity' and p.proname='get_current_auth_profile'),
  0, 'function has zero parameters (no p_user_id)');

-- ---------------------------------------------------------------------------
-- 7 + 8 + 9. Call RPC as the admin user and inspect the JSON.
-- ---------------------------------------------------------------------------
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object(
      'sub', '53000000-0000-0000-0000-000000000a43',
      'role','authenticated',
      'tenant_id','53000000-0000-0000-0000-00000000c43a'
    )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000a43', true);
  set local role authenticated;
end $$;

-- 7. roles contains 'platform_admin'
select is(
  (select (identity.get_current_auth_profile()->'roles') ? 'platform_admin'),
  true, 'admin call: roles contains platform_admin');

-- 8. hasProfile is true
select is(
  (select (identity.get_current_auth_profile()->>'hasProfile')::boolean),
  true, 'admin call: hasProfile is true');

-- 9. email is the seeded admin email
select is(
  (select identity.get_current_auth_profile()->>'email'),
  '143-admin@example.com', 'admin call: email returned correctly');

reset role;

-- ---------------------------------------------------------------------------
-- 10. Switch to the unrelated user and confirm we receive that user's
--     profile, NOT the admin's.
-- ---------------------------------------------------------------------------
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object(
      'sub', '53000000-0000-0000-0000-000000000b43',
      'role','authenticated',
      'tenant_id','53000000-0000-0000-0000-00000000c43a'
    )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000b43', true);
  set local role authenticated;
end $$;

select is(
  (select identity.get_current_auth_profile()->>'userId'),
  '53000000-0000-0000-0000-000000000b43',
  'other call: returns only the calling user''s profile');

reset role;

select * from finish();
rollback;
