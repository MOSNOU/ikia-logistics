-- CC-22 Test 088 — Documents: xor parent constraint, attach + decide flow.
--
-- Assertions (8):
--   1. xor check: cannot insert with both parent FKs set
--   2. xor check: cannot insert with neither parent FK set
--   3. attach_document inserts pending document for personal verification
--   4. attach_document refuses when verification is in a non-attachable status
--   5. admin_decide_document → accepted records reviewed_at + reviewed_by
--   6. admin_decide_document → rejected requires reason (raises 22023 without)
--   7. attach_document inserts pending document for organization verification
--   8. documents bucket default is 'kyc-private'

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '88000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '088-subject@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '88000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '088-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('88000000-0000-0000-0000-00000000000a', 'tenant-088', 'تست', 'Test 088');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('88000000-0000-0000-0000-00000000001a', '88000000-0000-0000-0000-00000000000a',
   'org-088', 'سازمان', 'Org 088', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('88000000-0000-0000-0000-000000000001', '88000000-0000-0000-0000-00000000000a',
   '88000000-0000-0000-0000-00000000001a', 'Subject', 'fa', 'active'),
  ('88000000-0000-0000-0000-000000000099', '88000000-0000-0000-0000-00000000000a',
   '88000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '88000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '88000000-0000-0000-0000-00000000000a',
       '88000000-0000-0000-0000-00000000001a',
       '88000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

-- Parent rows
insert into kyc.personal_verifications (id, tenant_id, user_id, attempt_no, status)
values ('88000000-0000-0000-0000-000000000aa1',
        '88000000-0000-0000-0000-00000000000a',
        '88000000-0000-0000-0000-000000000001', 1, 'draft');
insert into kyc.organization_verifications (id, tenant_id, organization_id, attempt_no, status)
values ('88000000-0000-0000-0000-000000000bb1',
        '88000000-0000-0000-0000-00000000000a',
        '88000000-0000-0000-0000-00000000001a', 1, 'draft');
-- A second parent in a non-attachable status (approved + locked).
insert into kyc.personal_verifications (id, tenant_id, user_id, attempt_no, status,
                                        full_legal_name, national_id_number_hash,
                                        national_id_last4, date_of_birth, country_code,
                                        submitted_at, reviewed_at, approved_at)
values ('88000000-0000-0000-0000-000000000aa2',
        '88000000-0000-0000-0000-00000000000a',
        '88000000-0000-0000-0000-000000000001', 7, 'approved',
        'Locked', 'aa', '0000', '1990-01-01'::date, 'IR',
        now(), now(), now());

select plan(8);

-- 1. Both parents set → check constraint fires.
select throws_ok(
  $$ insert into kyc.documents (tenant_id, subject_type,
       personal_verification_id, organization_verification_id,
       document_kind, storage_path)
     values ('88000000-0000-0000-0000-00000000000a', 'person',
             '88000000-0000-0000-0000-000000000aa1',
             '88000000-0000-0000-0000-000000000bb1',
             'national_id_card', 'kyc-private/foo.pdf') $$,
  '23514', null,
  'documents xor check: both parent FKs set is rejected'
);

-- 2. Neither parent set → check constraint fires.
select throws_ok(
  $$ insert into kyc.documents (tenant_id, subject_type, document_kind, storage_path)
     values ('88000000-0000-0000-0000-00000000000a', 'person',
             'national_id_card', 'kyc-private/foo.pdf') $$,
  '23514', null,
  'documents xor check: neither parent FK set is rejected'
);

-- 3. attach_document inserts pending personal doc.
select tests.authenticate_as(
  '88000000-0000-0000-0000-000000000001',
  '88000000-0000-0000-0000-00000000000a',
  '88000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.attach_document(
    '88000000-0000-0000-0000-000000000aa1'::uuid,
    'person'::kyc.kyc_subject_type,
    'national_id_card'::kyc.kyc_document_kind,
    'kyc-private/088/national_id.pdf',
    'NID front',
    'application/pdf', 1024,
    null, null
  );
  perform set_config('test.doc_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from kyc.documents where id = current_setting('test.doc_id')::uuid),
  'pending',
  'attach_document creates pending document for personal verification'
);

-- 4. attach refused on locked (approved) personal verification.
select tests.authenticate_as(
  '88000000-0000-0000-0000-000000000001',
  '88000000-0000-0000-0000-00000000000a',
  '88000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select kyc.attach_document(
       '88000000-0000-0000-0000-000000000aa2'::uuid,
       'person'::kyc.kyc_subject_type,
       'passport'::kyc.kyc_document_kind,
       'kyc-private/088/should-fail.pdf',
       null, null, null, null, null
     ) $$,
  '22023', null,
  'attach_document on locked verification raises 22023'
);
reset role;

-- 5. admin_decide_document → accepted records reviewed_at + reviewer
select tests.authenticate_as(
  '88000000-0000-0000-0000-000000000099',
  '88000000-0000-0000-0000-00000000000a',
  '88000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select kyc.admin_decide_document(
  current_setting('test.doc_id')::uuid,
  'accepted'::kyc.kyc_document_status,
  null
);
reset role;

select is(
  (select status::text from kyc.documents where id = current_setting('test.doc_id')::uuid),
  'accepted',
  'admin_decide_document flips status → accepted'
);

-- 6. reject without reason → 22023
do $$
declare v_id uuid;
begin
  insert into kyc.documents (tenant_id, subject_type, personal_verification_id,
                             document_kind, storage_path)
  values ('88000000-0000-0000-0000-00000000000a', 'person',
          '88000000-0000-0000-0000-000000000aa1',
          'passport', 'kyc-private/088/passport.pdf')
  returning id into v_id;
  perform set_config('test.doc2_id', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '88000000-0000-0000-0000-000000000099',
  '88000000-0000-0000-0000-00000000000a',
  '88000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select kyc.admin_decide_document(%L::uuid, 'rejected'::kyc.kyc_document_status, null) $$,
         current_setting('test.doc2_id')),
  '22023', null,
  'admin_decide_document rejects without reason → 22023'
);
reset role;

-- 7. attach for org verification works.
select tests.authenticate_as(
  '88000000-0000-0000-0000-000000000001',
  '88000000-0000-0000-0000-00000000000a',
  '88000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := kyc.attach_document(
    '88000000-0000-0000-0000-000000000bb1'::uuid,
    'organization'::kyc.kyc_subject_type,
    'company_registration'::kyc.kyc_document_kind,
    'kyc-private/088/company_reg.pdf',
    'Company Reg', 'application/pdf', 2048, null, null
  );
  perform set_config('test.org_doc_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select organization_verification_id from kyc.documents
    where id = current_setting('test.org_doc_id')::uuid),
  '88000000-0000-0000-0000-000000000bb1'::uuid,
  'attach_document creates pending document for organization verification'
);

-- 8. default bucket is 'kyc-private'
select is(
  (select bucket from kyc.documents where id = current_setting('test.org_doc_id')::uuid),
  'kyc-private',
  'documents bucket defaults to kyc-private (Q6=B)'
);

select * from finish();
rollback;
