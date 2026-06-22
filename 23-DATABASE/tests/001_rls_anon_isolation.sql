-- CC-05 Test 001 — anonymous role sees zero rows on every user-facing table.
-- No fixtures needed; CC-03/CC-04 seed RBAC, and the anon role's RLS evaluates
-- to "no rows" on all of these.

set search_path = extensions, public, identity, organization, audit, tests;
begin;

select plan(4);

select tests.set_anon();
set local role anon;

select is(
  (select count(*) from identity.tenants),
  0::bigint,
  'anon sees 0 tenants'
);

select is(
  (select count(*) from identity.user_profiles),
  0::bigint,
  'anon sees 0 user_profiles'
);

select is(
  (select count(*) from organization.organizations),
  0::bigint,
  'anon sees 0 organizations'
);

select is(
  (select count(*) from organization.memberships),
  0::bigint,
  'anon sees 0 memberships'
);

reset role;
select * from finish();
rollback;
