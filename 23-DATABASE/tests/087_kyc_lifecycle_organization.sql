-- CC-22 Test 087 — Organization verification (KYB) lifecycle.
--
-- Assertions (12):
--   1. start_organization_verification returns id; status='draft'
--   2. caller without org membership cannot start KYB → 42501
--   3. update_organization_draft populates legal_name/registration_number/tax_id
--   4. submit fails when required fields missing
--   5. submit succeeds with full set
--   6. admin_assign_verification flips submitted → in_review
--   7. admin_request_info flips in_review → info_requested
--   8. resubmit + approve flow lands in approved status with expires_at
--   9. is_organization_verified true after approve
--  10. admin_reject_verification works on a separate attempt
--  11. start_organization_verification is idempotent — returns existing draft
--  12. kyc.events records the transitions

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '87000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '087-org-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '87000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '087-outsider@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '87000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '087-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('87000000-0000-0000-0000-00000000000a', 'tenant-087', 'تست', 'Test 087');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('87000000-0000-0000-0000-00000000001a', '87000000-0000-0000-0000-00000000000a',
   'org-087', 'سازمان', 'Org 087', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('87000000-0000-0000-0000-000000000001', '87000000-0000-0000-0000-00000000000a',
   '87000000-0000-0000-0000-00000000001a', 'Org Admin', 'fa', 'active'),
  ('87000000-0000-0000-0000-000000000002', '87000000-0000-0000-0000-00000000000a',
   null, 'Outsider', 'fa', 'active'),
  ('87000000-0000-0000-0000-000000000099', '87000000-0000-0000-0000-00000000000a',
   '87000000-0000-0000-0000-00000000001a', 'Platform Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '87000000-0000-0000-0000-00000000000a',
       '87000000-0000-0000-0000-00000000001a',
       '87000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '87000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(12);

-- 1. start_organization_verification → draft
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000001',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.start_organization_verification('87000000-0000-0000-0000-00000000001a'::uuid);
  perform set_config('test.ov_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from kyc.organization_verifications
    where id = current_setting('test.ov_id')::uuid),
  'draft',
  'start_organization_verification creates draft row'
);

-- 2. Outsider cannot start KYB for an org they are not a member of.
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000002',
  '87000000-0000-0000-0000-00000000000a',
  null
);
set local role authenticated;
select throws_ok(
  $$ select kyc.start_organization_verification('87000000-0000-0000-0000-00000000001a'::uuid) $$,
  '42501', null,
  'outsider start_organization_verification raises 42501'
);
reset role;

-- 3. update_organization_draft populates fields
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000001',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.update_organization_draft(
  current_setting('test.ov_id')::uuid,
  'Acme Logistics Ltd', 'REG-087-001', 'TAX-087', 'IR'::char(2), '2015-06-01'::date
);
reset role;

select is(
  (select legal_name from kyc.organization_verifications
    where id = current_setting('test.ov_id')::uuid),
  'Acme Logistics Ltd',
  'update_organization_draft stores legal_name'
);

-- 4. submit fails when required fields missing.
do $$
declare v_id uuid;
begin
  insert into kyc.organization_verifications (tenant_id, organization_id, attempt_no, status)
  values ('87000000-0000-0000-0000-00000000000a',
          '87000000-0000-0000-0000-00000000001a', 9, 'draft')
  returning id into v_id;
  perform set_config('test.empty_ov_id', v_id::text, false);
end;
$$;
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000001',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select kyc.submit_organization_verification(%L::uuid) $$,
         current_setting('test.empty_ov_id')),
  '22023', null,
  'submit_organization_verification raises 22023 when required fields missing'
);
reset role;

-- 5. submit succeeds.
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000001',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.submit_organization_verification(current_setting('test.ov_id')::uuid);
reset role;

select is(
  (select status::text from kyc.organization_verifications
    where id = current_setting('test.ov_id')::uuid),
  'submitted',
  'submit_organization_verification flips draft → submitted'
);

-- 6. assign → in_review
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000099',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_assign_verification(
  current_setting('test.ov_id')::uuid, 'organization'::kyc.kyc_subject_type
);
reset role;

select is(
  (select status::text from kyc.organization_verifications
    where id = current_setting('test.ov_id')::uuid),
  'in_review',
  'admin_assign_verification flips submitted → in_review (KYB)'
);

-- 7. request_info → info_requested
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000099',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_request_info(
  current_setting('test.ov_id')::uuid, 'organization'::kyc.kyc_subject_type,
  'need tax certificate'
);
reset role;

select is(
  (select status::text from kyc.organization_verifications
    where id = current_setting('test.ov_id')::uuid),
  'info_requested',
  'admin_request_info flips in_review → info_requested (KYB)'
);

-- 8. resubmit + approve → approved
select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000001',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.submit_organization_verification(current_setting('test.ov_id')::uuid);
reset role;

select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000099',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_assign_verification(
  current_setting('test.ov_id')::uuid, 'organization'::kyc.kyc_subject_type
);
select kyc.admin_approve_verification(
  current_setting('test.ov_id')::uuid, 'organization'::kyc.kyc_subject_type, 12
);
reset role;

select is(
  (select status::text from kyc.organization_verifications
    where id = current_setting('test.ov_id')::uuid),
  'approved',
  'admin_approve_verification flips in_review → approved (KYB)'
);

-- 9. is_organization_verified true
select is(
  kyc.is_organization_verified('87000000-0000-0000-0000-00000000001a'::uuid),
  true,
  'is_organization_verified returns true after KYB approval'
);

-- 10. admin_reject_verification on a separate attempt
do $$
declare v_id uuid;
begin
  insert into kyc.organization_verifications (tenant_id, organization_id, attempt_no, status,
                                              legal_name, registration_number, country_code)
  values ('87000000-0000-0000-0000-00000000000a',
          '87000000-0000-0000-0000-00000000001a', 8, 'in_review',
          'Bad Co', 'REG-BAD', 'IR')
  returning id into v_id;
  perform set_config('test.reject_ov_id', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000099',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_reject_verification(
  current_setting('test.reject_ov_id')::uuid,
  'organization'::kyc.kyc_subject_type,
  'forged docs'
);
reset role;

select is(
  (select decision_reason from kyc.organization_verifications
    where id = current_setting('test.reject_ov_id')::uuid),
  'forged docs',
  'admin_reject_verification stores decision_reason (KYB)'
);

-- 11. start_organization_verification idempotent.
do $$
declare v_id uuid;
begin
  insert into kyc.organization_verifications (tenant_id, organization_id, attempt_no, status)
  values ('87000000-0000-0000-0000-00000000000a',
          '87000000-0000-0000-0000-00000000001a', 11, 'draft')
  returning id into v_id;
  perform set_config('test.idem_draft_ov', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '87000000-0000-0000-0000-000000000001',
  '87000000-0000-0000-0000-00000000000a',
  '87000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.start_organization_verification('87000000-0000-0000-0000-00000000001a'::uuid);
  perform set_config('test.idem_returned_ov', v_id::text, false);
end;
$$;
reset role;

select is(
  current_setting('test.idem_returned_ov')::uuid,
  current_setting('test.idem_draft_ov')::uuid,
  'start_organization_verification returns existing draft id (idempotent)'
);

-- 12. transitions recorded in kyc.events
select cmp_ok(
  (select count(*)::int from kyc.events
    where organization_verification_id = current_setting('test.ov_id')::uuid
      and event_kind in ('submitted','assigned','info_requested','resubmitted','approved')),
  '>=', 4,
  'kyc.events recorded KYB lifecycle transitions'
);

select * from finish();
rollback;
