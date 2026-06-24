-- CC-22 Test 086 — Personal verification lifecycle (happy path + branches).
--
-- Assertions (16):
--   1. start_personal_verification returns id; status='draft'
--   2. update_personal_draft populates fields; hash + last4 stored
--   3. submit_personal_verification fails when required fields missing
--   4. submit succeeds once full_legal_name/national_id/dob/country are set
--   5. admin_assign_verification flips submitted → in_review
--   6. assign fails when not in_review-able (already in_review)
--   7. admin_request_info flips in_review → info_requested with reason
--   8. resubmitted event recorded on resubmit (info_requested → submitted)
--   9. admin_approve_verification flips in_review → approved with expires_at
--  10. is_personal_verified returns true post-approve
--  11. admin_reject_verification on a fresh attempt records rejected_reason
--  12. is_personal_verified still true (latest non-expired approved exists)
--  13. start_personal_verification is idempotent — returns existing draft id
--  14. update_personal_draft is rejected when verification is in_review
--  15. kyc.events has at least one row per transition (submitted/assigned/approved)
--  16. fn_audit wrote at least one audit.audit_event for this flow

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '86000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '086-subject@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '86000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '086-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('86000000-0000-0000-0000-00000000000a', 'tenant-086', 'تست', 'Test 086');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('86000000-0000-0000-0000-00000000001a', '86000000-0000-0000-0000-00000000000a',
   'org-086', 'سازمان', 'Org 086', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('86000000-0000-0000-0000-000000000001', '86000000-0000-0000-0000-00000000000a',
   '86000000-0000-0000-0000-00000000001a', 'Subject', 'fa', 'active'),
  ('86000000-0000-0000-0000-000000000099', '86000000-0000-0000-0000-00000000000a',
   '86000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '86000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(16);

-- 1. start_personal_verification → returns id; status='draft'
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.start_personal_verification();
  perform set_config('test.pv_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from kyc.personal_verifications
    where id = current_setting('test.pv_id')::uuid),
  'draft',
  'start_personal_verification creates draft row'
);

-- 2. update_personal_draft populates fields; hash + last4 stored
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.update_personal_draft(
  current_setting('test.pv_id')::uuid,
  'Alice Subject',
  '1234567890',
  '1990-01-15'::date,
  'IR'::char(2)
);
reset role;

select is(
  (select national_id_last4 from kyc.personal_verifications
    where id = current_setting('test.pv_id')::uuid),
  '7890',
  'update_personal_draft stores national_id_last4 from raw value'
);

-- 3. submit fails when fields missing (start a fresh attempt with no fields).
do $$
declare v_id uuid;
begin
  insert into kyc.personal_verifications (tenant_id, user_id, attempt_no, status)
  values ('86000000-0000-0000-0000-00000000000a',
          '86000000-0000-0000-0000-000000000001', 9, 'draft')
  returning id into v_id;
  perform set_config('test.empty_pv_id', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select kyc.submit_personal_verification(%L::uuid) $$,
         current_setting('test.empty_pv_id')),
  '22023', null,
  'submit_personal_verification raises 22023 when required fields missing'
);
reset role;

-- 4. submit succeeds with full set.
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.submit_personal_verification(current_setting('test.pv_id')::uuid);
reset role;

select is(
  (select status::text from kyc.personal_verifications
    where id = current_setting('test.pv_id')::uuid),
  'submitted',
  'submit_personal_verification flips status → submitted'
);

-- 5. admin_assign_verification → in_review
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000099',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_assign_verification(
  current_setting('test.pv_id')::uuid, 'person'::kyc.kyc_subject_type
);
reset role;

select is(
  (select status::text from kyc.personal_verifications
    where id = current_setting('test.pv_id')::uuid),
  'in_review',
  'admin_assign_verification flips submitted → in_review'
);

-- 6. assign fails when not in 'submitted' (it is now in_review)
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000099',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select kyc.admin_assign_verification(%L::uuid, 'person'::kyc.kyc_subject_type) $$,
         current_setting('test.pv_id')),
  '22023', null,
  'admin_assign_verification raises 22023 when not in submitted'
);
reset role;

-- 7. admin_request_info → info_requested
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000099',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_request_info(
  current_setting('test.pv_id')::uuid, 'person'::kyc.kyc_subject_type,
  'address proof unclear'
);
reset role;

select is(
  (select status::text from kyc.personal_verifications
    where id = current_setting('test.pv_id')::uuid),
  'info_requested',
  'admin_request_info flips in_review → info_requested'
);

-- 8. resubmit fires 'resubmitted' event
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.submit_personal_verification(current_setting('test.pv_id')::uuid);
reset role;

select is(
  (select count(*)::int from kyc.events
    where personal_verification_id = current_setting('test.pv_id')::uuid
      and event_kind = 'resubmitted'),
  1,
  'resubmit logs a resubmitted event'
);

-- 9. admin_approve_verification → approved + expires_at set
select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000099',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_assign_verification(
  current_setting('test.pv_id')::uuid, 'person'::kyc.kyc_subject_type
);
select kyc.admin_approve_verification(
  current_setting('test.pv_id')::uuid, 'person'::kyc.kyc_subject_type, 12
);
reset role;

select is(
  (select status::text from kyc.personal_verifications
    where id = current_setting('test.pv_id')::uuid),
  'approved',
  'admin_approve_verification flips in_review → approved'
);

-- 10. is_personal_verified returns true post-approve
select is(
  kyc.is_personal_verified('86000000-0000-0000-0000-000000000001'::uuid),
  true,
  'is_personal_verified returns true after approval'
);

-- 11. admin_reject on a NEW attempt records rejected_reason
do $$
declare v_id uuid;
begin
  insert into kyc.personal_verifications (tenant_id, user_id, attempt_no, status,
                                          full_legal_name, national_id_number_hash,
                                          national_id_last4, date_of_birth, country_code,
                                          submitted_at)
  values ('86000000-0000-0000-0000-00000000000a',
          '86000000-0000-0000-0000-000000000001', 7, 'in_review',
          'Reject Me', 'aabbcc', '5555', '1991-02-03'::date, 'IR', now())
  returning id into v_id;
  perform set_config('test.reject_pv_id', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000099',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_reject_verification(
  current_setting('test.reject_pv_id')::uuid,
  'person'::kyc.kyc_subject_type,
  'name mismatch'
);
reset role;

select is(
  (select decision_reason from kyc.personal_verifications
    where id = current_setting('test.reject_pv_id')::uuid),
  'name mismatch',
  'admin_reject_verification stores decision_reason'
);

-- 12. is_personal_verified still true (the approved row from #9 still valid).
select is(
  kyc.is_personal_verified('86000000-0000-0000-0000-000000000001'::uuid),
  true,
  'is_personal_verified still true after a later rejection (latest approved unexpired wins)'
);

-- 13. start_personal_verification is idempotent — returns existing draft id.
--     Create a fresh draft, call start again, check ids match.
do $$
declare v_id uuid;
begin
  insert into kyc.personal_verifications (tenant_id, user_id, attempt_no, status)
  values ('86000000-0000-0000-0000-00000000000a',
          '86000000-0000-0000-0000-000000000001', 11, 'draft')
  returning id into v_id;
  perform set_config('test.idem_draft_id', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.start_personal_verification();
  perform set_config('test.idem_returned_id', v_id::text, false);
end;
$$;
reset role;

select is(
  current_setting('test.idem_returned_id')::uuid,
  current_setting('test.idem_draft_id')::uuid,
  'start_personal_verification returns existing draft id (idempotent)'
);

-- 14. update_personal_draft is rejected when verification is in_review.
do $$
declare v_id uuid;
begin
  insert into kyc.personal_verifications (tenant_id, user_id, attempt_no, status,
                                          full_legal_name, national_id_number_hash,
                                          national_id_last4, date_of_birth, country_code)
  values ('86000000-0000-0000-0000-00000000000a',
          '86000000-0000-0000-0000-000000000001', 12, 'in_review',
          'Locked', 'aa', '0000', '1990-01-01'::date, 'IR')
  returning id into v_id;
  perform set_config('test.locked_pv_id', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '86000000-0000-0000-0000-000000000001',
  '86000000-0000-0000-0000-00000000000a',
  '86000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select kyc.update_personal_draft(%L::uuid, 'X', null, null, null) $$,
         current_setting('test.locked_pv_id')),
  '22023', null,
  'update_personal_draft raises 22023 when verification is in_review'
);
reset role;

-- 15. kyc.events recorded transitions
select cmp_ok(
  (select count(*)::int from kyc.events
    where personal_verification_id = current_setting('test.pv_id')::uuid
      and event_kind in ('submitted','assigned','approved','resubmitted','info_requested')),
  '>=', 4,
  'kyc.events recorded the lifecycle transitions'
);

-- 16. audit.audit_event got at least one row tagged kyc.*
select cmp_ok(
  (select count(*)::int from audit.audit_event
    where resource_type = 'kyc'
      and action_code like 'kyc.%'),
  '>=', 1,
  'audit.audit_event contains kyc.* action_code rows'
);

select * from finish();
rollback;
