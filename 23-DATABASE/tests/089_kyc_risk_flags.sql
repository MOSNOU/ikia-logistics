-- CC-22 Test 089 — Risk flags: raise / resolve / xor / admin-only RLS.
--
-- Assertions (8):
--   1. admin_raise_risk_flag (person) inserts open flag
--   2. admin_raise_risk_flag (organization) inserts open flag
--   3. admin_raise_risk_flag requires a code → 22023
--   4. admin_raise_risk_flag with subject_type='person' requires user_id
--   5. admin_resolve_risk_flag flips open → mitigated with note
--   6. resolve refuses non-open flag (22023)
--   7. xor check: person flag with both user_id + organization_id → 23514
--   8. non-admin authenticated cannot SELECT risk_flags (RLS)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '89000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '089-user@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '89000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '089-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('89000000-0000-0000-0000-00000000000a', 'tenant-089', 'تست', 'Test 089');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('89000000-0000-0000-0000-00000000001a', '89000000-0000-0000-0000-00000000000a',
   'org-089', 'سازمان', 'Org 089', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('89000000-0000-0000-0000-000000000001', '89000000-0000-0000-0000-00000000000a',
   '89000000-0000-0000-0000-00000000001a', 'User', 'fa', 'active'),
  ('89000000-0000-0000-0000-000000000099', '89000000-0000-0000-0000-00000000000a',
   '89000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '89000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(8);

-- 1. Raise person flag
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000099',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.admin_raise_risk_flag(
    'person'::kyc.kyc_subject_type,
    '89000000-0000-0000-0000-000000000001'::uuid,
    null,
    'address_mismatch',
    'medium'::kyc.kyc_risk_severity,
    'address does not match utility bill',
    'manual'
  );
  perform set_config('test.person_flag_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from kyc.risk_flags
    where id = current_setting('test.person_flag_id')::uuid),
  'open',
  'admin_raise_risk_flag (person) inserts open flag'
);

-- 2. Raise organization flag
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000099',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.admin_raise_risk_flag(
    'organization'::kyc.kyc_subject_type,
    null,
    '89000000-0000-0000-0000-00000000001a'::uuid,
    'tax_id_unverified',
    'high'::kyc.kyc_risk_severity,
    'tax ID format invalid',
    'manual'
  );
  perform set_config('test.org_flag_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from kyc.risk_flags
    where id = current_setting('test.org_flag_id')::uuid),
  'open',
  'admin_raise_risk_flag (organization) inserts open flag'
);

-- 3. Empty code → 22023
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000099',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select kyc.admin_raise_risk_flag(
       'person'::kyc.kyc_subject_type,
       '89000000-0000-0000-0000-000000000001'::uuid,
       null, '', 'low'::kyc.kyc_risk_severity, null, 'manual') $$,
  '22023', null,
  'admin_raise_risk_flag rejects empty code (22023)'
);
reset role;

-- 4. Person subject without user_id → 22023
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000099',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select kyc.admin_raise_risk_flag(
       'person'::kyc.kyc_subject_type,
       null, null, 'oops', 'low'::kyc.kyc_risk_severity, null, 'manual') $$,
  '22023', null,
  'admin_raise_risk_flag person requires user_id (22023)'
);
reset role;

-- 5. Resolve: open → mitigated
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000099',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_resolve_risk_flag(
  current_setting('test.person_flag_id')::uuid,
  'mitigated'::kyc.kyc_risk_status,
  'subject provided updated proof of address'
);
reset role;

select is(
  (select status::text from kyc.risk_flags
    where id = current_setting('test.person_flag_id')::uuid),
  'mitigated',
  'admin_resolve_risk_flag flips open → mitigated'
);

-- 6. Re-resolving a non-open flag → 22023
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000099',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select kyc.admin_resolve_risk_flag(%L::uuid, 'dismissed'::kyc.kyc_risk_status, null) $$,
         current_setting('test.person_flag_id')),
  '22023', null,
  'admin_resolve_risk_flag on non-open flag raises 22023'
);
reset role;

-- 7. xor: person flag with both fields → 23514
select throws_ok(
  $$ insert into kyc.risk_flags (tenant_id, subject_type, user_id, organization_id,
                                  source, severity, code)
     values ('89000000-0000-0000-0000-00000000000a', 'person',
             '89000000-0000-0000-0000-000000000001',
             '89000000-0000-0000-0000-00000000001a',
             'manual', 'low', 'both_set') $$,
  '23514', null,
  'risk_flags xor check rejects rows with both user_id and organization_id'
);

-- 8. Non-admin authenticated has no SELECT grant on kyc.risk_flags.
select tests.authenticate_as(
  '89000000-0000-0000-0000-000000000001',
  '89000000-0000-0000-0000-00000000000a',
  '89000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select count(*) from kyc.risk_flags $$,
  '42501', null,
  'non-admin authenticated has no SELECT privilege on kyc.risk_flags'
);
reset role;

select * from finish();
rollback;
