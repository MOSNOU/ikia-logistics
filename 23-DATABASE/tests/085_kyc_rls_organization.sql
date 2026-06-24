-- CC-22 Test 085 — RLS isolation on kyc.organization_verifications.
--
-- Assertions (6):
--   1. org member sees own organization_verification row
--   2. user in a different org sees 0 rows
--   3. anon sees 0 rows
--   4. platform_admin sees all rows
--   5. authenticated cannot INSERT directly (42501)
--   6. authenticated member cannot UPDATE own org row directly (0 rows affected)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

-- Fixtures
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '085-orgA-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '085-orgB-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '85000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '085-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('85000000-0000-0000-0000-00000000000a', 'tenant-085', 'تست', 'Test 085');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('85000000-0000-0000-0000-00000000001a', '85000000-0000-0000-0000-00000000000a',
   'org-A-085', 'سازمان آ', 'Org A 085', 'buyer', 'active'),
  ('85000000-0000-0000-0000-00000000001b', '85000000-0000-0000-0000-00000000000a',
   'org-B-085', 'سازمان ب', 'Org B 085', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('85000000-0000-0000-0000-000000000001', '85000000-0000-0000-0000-00000000000a',
   '85000000-0000-0000-0000-00000000001a', 'OrgA User', 'fa', 'active'),
  ('85000000-0000-0000-0000-000000000002', '85000000-0000-0000-0000-00000000000a',
   '85000000-0000-0000-0000-00000000001b', 'OrgB User', 'fa', 'active'),
  ('85000000-0000-0000-0000-000000000099', '85000000-0000-0000-0000-00000000000a',
   '85000000-0000-0000-0000-00000000001a', 'Platform Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '85000000-0000-0000-0000-00000000000a',
       '85000000-0000-0000-0000-00000000001a',
       '85000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '85000000-0000-0000-0000-00000000000a',
       '85000000-0000-0000-0000-00000000001b',
       '85000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '85000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Seed an organization_verification per org.
insert into kyc.organization_verifications (id, tenant_id, organization_id, attempt_no, status, legal_name) values
  ('85000000-0000-0000-0000-000000000aa1',
   '85000000-0000-0000-0000-00000000000a',
   '85000000-0000-0000-0000-00000000001a', 1, 'draft', 'Org A Legal Name'),
  ('85000000-0000-0000-0000-000000000aa2',
   '85000000-0000-0000-0000-00000000000a',
   '85000000-0000-0000-0000-00000000001b', 1, 'draft', 'Org B Legal Name');

select plan(6);

-- 1. Org-A member sees Org-A row.
select tests.authenticate_as(
  '85000000-0000-0000-0000-000000000001',
  '85000000-0000-0000-0000-00000000000a',
  '85000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from kyc.organization_verifications
    where organization_id = '85000000-0000-0000-0000-00000000001a'),
  1, 'Org-A member sees own organization_verification (1 row)'
);
reset role;

-- 2. Org-A member cannot see Org-B row.
select tests.authenticate_as(
  '85000000-0000-0000-0000-000000000001',
  '85000000-0000-0000-0000-00000000000a',
  '85000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from kyc.organization_verifications
    where organization_id = '85000000-0000-0000-0000-00000000001b'),
  0, 'Org-A member cannot see Org-B organization_verification'
);
reset role;

-- 3. Anonymous has no SELECT grant on kyc.organization_verifications.
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select count(*) from kyc.organization_verifications $$,
  '42501', null,
  'anon has no SELECT privilege on kyc.organization_verifications'
);
reset role;

-- 4. Platform admin sees all.
select tests.authenticate_as(
  '85000000-0000-0000-0000-000000000099',
  '85000000-0000-0000-0000-00000000000a',
  '85000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from kyc.organization_verifications
    where tenant_id = '85000000-0000-0000-0000-00000000000a'),
  2, 'platform_admin sees both organization_verifications'
);
reset role;

-- 5. Direct INSERT rejected for authenticated.
select tests.authenticate_as(
  '85000000-0000-0000-0000-000000000001',
  '85000000-0000-0000-0000-00000000000a',
  '85000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ insert into kyc.organization_verifications (tenant_id, organization_id, attempt_no, status)
     values ('85000000-0000-0000-0000-00000000000a',
             '85000000-0000-0000-0000-00000000001a', 2, 'draft') $$,
  '42501', null,
  'authenticated direct INSERT into kyc.organization_verifications fails (42501)'
);
reset role;

-- 6. Direct UPDATE by org member fails — no UPDATE grant.
select tests.authenticate_as(
  '85000000-0000-0000-0000-000000000001',
  '85000000-0000-0000-0000-00000000000a',
  '85000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ update kyc.organization_verifications
       set legal_name = 'attempted rename'
     where id = '85000000-0000-0000-0000-000000000aa1' $$,
  '42501', null,
  'org member UPDATE on kyc.organization_verifications fails (42501) — RPC-only writes'
);
reset role;

select * from finish();
rollback;
