-- CC-22 Test 084 — RLS isolation on kyc.personal_verifications.
--
-- Assertions (6):
--   1. subject user sees own personal_verification row
--   2. peer user sees 0 personal_verification rows
--   3. anon role sees 0 personal_verification rows
--   4. platform_admin sees all personal_verification rows
--   5. no direct INSERT permitted to authenticated (RLS rejects)
--   6. UPDATE attempted as subject is rejected (RLS forbids non-admin writes)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

-- Fixtures
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '84000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '084-subject@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '84000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '084-peer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '84000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '084-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('84000000-0000-0000-0000-00000000000a', 'tenant-084', 'تست', 'Test 084');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('84000000-0000-0000-0000-00000000001a', '84000000-0000-0000-0000-00000000000a',
   'org-084', 'سازمان', 'Org 084', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('84000000-0000-0000-0000-000000000001', '84000000-0000-0000-0000-00000000000a',
   '84000000-0000-0000-0000-00000000001a', 'Subject', 'fa', 'active'),
  ('84000000-0000-0000-0000-000000000002', '84000000-0000-0000-0000-00000000000a',
   '84000000-0000-0000-0000-00000000001a', 'Peer', 'fa', 'active'),
  ('84000000-0000-0000-0000-000000000099', '84000000-0000-0000-0000-00000000000a',
   '84000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '84000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Seed two personal verifications (one per subject) directly (DDL allowed at setup).
insert into kyc.personal_verifications (id, tenant_id, user_id, attempt_no, status, full_legal_name) values
  ('84000000-0000-0000-0000-000000000aa1',
   '84000000-0000-0000-0000-00000000000a',
   '84000000-0000-0000-0000-000000000001', 1, 'draft', 'Subject Person'),
  ('84000000-0000-0000-0000-000000000aa2',
   '84000000-0000-0000-0000-00000000000a',
   '84000000-0000-0000-0000-000000000002', 1, 'draft', 'Peer Person');

select plan(6);

-- 1. Subject sees own row.
select tests.authenticate_as(
  '84000000-0000-0000-0000-000000000001',
  '84000000-0000-0000-0000-00000000000a',
  '84000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from kyc.personal_verifications),
  1, 'subject sees own personal_verification (1 row)'
);
reset role;

-- 2. Peer sees 0 rows for subject.
select tests.authenticate_as(
  '84000000-0000-0000-0000-000000000002',
  '84000000-0000-0000-0000-00000000000a',
  '84000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from kyc.personal_verifications
    where user_id = '84000000-0000-0000-0000-000000000001'),
  0, 'peer cannot see subject personal_verification'
);
reset role;

-- 3. Anonymous has no SELECT grant on kyc.personal_verifications.
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select count(*) from kyc.personal_verifications $$,
  '42501', null,
  'anon has no SELECT privilege on kyc.personal_verifications'
);
reset role;

-- 4. Platform admin sees all rows.
select tests.authenticate_as(
  '84000000-0000-0000-0000-000000000099',
  '84000000-0000-0000-0000-00000000000a',
  '84000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from kyc.personal_verifications
    where tenant_id = '84000000-0000-0000-0000-00000000000a'),
  2, 'platform_admin sees both personal_verifications'
);
reset role;

-- 5. Authenticated cannot INSERT directly (RLS rejects via no admin_modify match).
select tests.authenticate_as(
  '84000000-0000-0000-0000-000000000001',
  '84000000-0000-0000-0000-00000000000a',
  '84000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ insert into kyc.personal_verifications (tenant_id, user_id, attempt_no, status)
     values ('84000000-0000-0000-0000-00000000000a',
             '84000000-0000-0000-0000-000000000001', 2, 'draft') $$,
  '42501', null,
  'authenticated direct INSERT into kyc.personal_verifications fails (42501)'
);
reset role;

-- 6. Authenticated subject cannot UPDATE own row directly — no UPDATE grant.
select tests.authenticate_as(
  '84000000-0000-0000-0000-000000000001',
  '84000000-0000-0000-0000-00000000000a',
  '84000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ update kyc.personal_verifications
       set full_legal_name = 'attempted rename'
     where id = '84000000-0000-0000-0000-000000000aa1' $$,
  '42501', null,
  'subject UPDATE on kyc.personal_verifications fails (42501) — RPC-only writes'
);
reset role;

select * from finish();
rollback;
