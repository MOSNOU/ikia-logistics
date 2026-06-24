-- CC-22 Test 091 — Helper RPCs + expire_due_verifications batch flow.
--
-- Assertions (8):
--   1. is_personal_verified returns false when no approved attempt exists
--   2. is_organization_verified returns false initially
--   3. After seeded approved (unexpired) personal row, helper returns true
--   4. After seeded approved (unexpired) organization row, helper returns true
--   5. expire_due_verifications flips approved-but-due rows to expired
--   6. is_personal_verified returns false after expiry
--   7. is_organization_verified returns false after expiry
--   8. kyc.events records an 'expired' row for each flipped attempt

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '91000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '091-user@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '91000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '091-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('91000000-0000-0000-0000-00000000000a', 'tenant-091', 'تست', 'Test 091');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('91000000-0000-0000-0000-00000000001a', '91000000-0000-0000-0000-00000000000a',
   'org-091', 'سازمان', 'Org 091', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('91000000-0000-0000-0000-000000000001', '91000000-0000-0000-0000-00000000000a',
   '91000000-0000-0000-0000-00000000001a', 'User', 'fa', 'active'),
  ('91000000-0000-0000-0000-000000000099', '91000000-0000-0000-0000-00000000000a',
   '91000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '91000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(8);

-- 1. No approved attempt yet → false
select is(
  kyc.is_personal_verified('91000000-0000-0000-0000-000000000001'::uuid),
  false,
  'is_personal_verified false when no approved attempt exists'
);

-- 2. No approved org yet → false
select is(
  kyc.is_organization_verified('91000000-0000-0000-0000-00000000001a'::uuid),
  false,
  'is_organization_verified false when no approved attempt exists'
);

-- 3. Seed approved + unexpired personal attempt → true
insert into kyc.personal_verifications (
  id, tenant_id, user_id, attempt_no, status,
  full_legal_name, national_id_number_hash, national_id_last4,
  date_of_birth, country_code,
  submitted_at, reviewed_at, approved_at, expires_at
) values (
  '91000000-0000-0000-0000-000000000aa1',
  '91000000-0000-0000-0000-00000000000a',
  '91000000-0000-0000-0000-000000000001', 1, 'approved',
  'Verified Person', 'hash', '0001',
  '1985-04-04'::date, 'IR',
  now() - interval '5 days', now() - interval '4 days',
  now() - interval '4 days', now() + interval '11 months'
);

select is(
  kyc.is_personal_verified('91000000-0000-0000-0000-000000000001'::uuid),
  true,
  'is_personal_verified true after approved unexpired attempt seeded'
);

-- 4. Seed approved + unexpired organization attempt → true
insert into kyc.organization_verifications (
  id, tenant_id, organization_id, attempt_no, status,
  legal_name, registration_number, country_code,
  submitted_at, reviewed_at, approved_at, expires_at
) values (
  '91000000-0000-0000-0000-000000000bb1',
  '91000000-0000-0000-0000-00000000000a',
  '91000000-0000-0000-0000-00000000001a', 1, 'approved',
  'Verified Co', 'REG-091', 'IR',
  now() - interval '5 days', now() - interval '4 days',
  now() - interval '4 days', now() + interval '11 months'
);

select is(
  kyc.is_organization_verified('91000000-0000-0000-0000-00000000001a'::uuid),
  true,
  'is_organization_verified true after approved unexpired attempt seeded'
);

-- 5. Flip expires_at into the past, call expire_due_verifications.
update kyc.personal_verifications
   set expires_at = now() - interval '1 hour'
 where id = '91000000-0000-0000-0000-000000000aa1';
update kyc.organization_verifications
   set expires_at = now() - interval '1 hour'
 where id = '91000000-0000-0000-0000-000000000bb1';

select tests.authenticate_as(
  '91000000-0000-0000-0000-000000000099',
  '91000000-0000-0000-0000-00000000000a',
  '91000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_count int;
begin
  v_count := kyc.expire_due_verifications();
  perform set_config('test.expired_count', v_count::text, false);
end;
$$;
reset role;

select cmp_ok(
  current_setting('test.expired_count')::int,
  '>=', 2,
  'expire_due_verifications flipped ≥ 2 attempts (1 personal + 1 organization)'
);

-- 6. is_personal_verified false after expiry
select is(
  kyc.is_personal_verified('91000000-0000-0000-0000-000000000001'::uuid),
  false,
  'is_personal_verified false after expiry tick'
);

-- 7. is_organization_verified false after expiry
select is(
  kyc.is_organization_verified('91000000-0000-0000-0000-00000000001a'::uuid),
  false,
  'is_organization_verified false after expiry tick'
);

-- 8. kyc.events has 'expired' rows for both flipped attempts
select cmp_ok(
  (select count(*)::int from kyc.events
    where event_kind = 'expired'
      and (personal_verification_id = '91000000-0000-0000-0000-000000000aa1'
           or organization_verification_id = '91000000-0000-0000-0000-000000000bb1')),
  '>=', 2,
  'kyc.events recorded expired events for both flipped attempts'
);

select * from finish();
rollback;
