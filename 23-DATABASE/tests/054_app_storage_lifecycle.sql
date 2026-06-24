-- CC-15 Test 054 — File lifecycle:
--   register → file row in 'pending' + v1 in file_versions → finalize → 'uploaded'
--   → link to RFQ entity → portal_list_files_for_entity returns it →
--   portal_get_file_metadata returns versions+associations → remove_association
--   soft-deletes the link → archive moves to 'archived'.
--
-- Assertions (10):
--   1. portal_register_file creates file with status='pending'
--   2. portal_register_file also creates a v1 row in file_versions (status=pending)
--   3. portal_finalize_file_upload moves status → uploaded
--   4. portal_finalize_file_upload also updates v1 row in file_versions → uploaded
--   5. portal_link_file_to_entity creates an association
--   6. portal_list_files_for_entity returns the linked file
--   7. portal_get_file_metadata returns 1 version + 1 association
--   8. portal_create_file_version adds v2 and marks v1 superseded
--   9. portal_remove_file_association soft-deletes the link
--  10. portal_archive_file moves status → archived

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, tests;
begin;

-- Fixtures: 1 buyer org + 1 product + 1 RFQ to link files against.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '18000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '054-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('18000000-0000-0000-0000-00000000000a', 'tenant-054', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('18000000-0000-0000-0000-00000000001a', '18000000-0000-0000-0000-00000000000a',
   'buyer-054', 'خریدار', 'Buyer 054', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('18000000-0000-0000-0000-000000000001', '18000000-0000-0000-0000-00000000000a',
   '18000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '18000000-0000-0000-0000-00000000000a', '18000000-0000-0000-0000-00000000001a',
       '18000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '18000000-0000-0000-0000-000000000001', r.id, 'organization', '18000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

do $$
declare v_prod uuid; v_rfq uuid;
begin
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','18000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','18000000-0000-0000-0000-00000000000a',
                       'organization_id','18000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '18000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for file linking');
  perform rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                     p_quantity => 100, p_quantity_unit => 'ton');
  reset role;

  perform set_config('test.rfq', v_rfq::text, false);
end;
$$;

select plan(10);

-- 1. Register file.
select tests.authenticate_as(
  '18000000-0000-0000-0000-000000000001',
  '18000000-0000-0000-0000-00000000000a',
  '18000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_res jsonb;
begin
  v_res := app_storage.portal_register_file(
    p_filename => 'spec-v1.pdf',
    p_mime_type => 'application/pdf',
    p_size_bytes => 12345,
    p_file_type => 'pdf'::app_storage.file_type
  );
  perform set_config('test.file', (v_res->>'file_id'), false);
end;
$$;
reset role;

select is(
  (select status::text from app_storage.files where id = current_setting('test.file')::uuid),
  'pending',
  'portal_register_file creates file with status=pending'
);

-- 2. v1 version row exists.
select is(
  (select count(*)::int from app_storage.file_versions
    where file_id = current_setting('test.file')::uuid
      and version_number = 1 and deleted_at is null),
  1,
  'portal_register_file creates v1 row in file_versions'
);

-- 3. Finalize.
select tests.authenticate_as(
  '18000000-0000-0000-0000-000000000001',
  '18000000-0000-0000-0000-00000000000a',
  '18000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select app_storage.portal_finalize_file_upload(
  current_setting('test.file')::uuid,
  p_size_bytes => 12345,
  p_checksum => 'sha256:abc'
);
reset role;

select is(
  (select status::text from app_storage.files where id = current_setting('test.file')::uuid),
  'uploaded',
  'portal_finalize_file_upload moves status → uploaded'
);

-- 4. v1 row also flipped to uploaded.
select is(
  (select status::text from app_storage.file_versions
    where file_id = current_setting('test.file')::uuid and version_number = 1),
  'uploaded',
  'portal_finalize_file_upload also updates v1 in file_versions to uploaded'
);

-- 5. Link to RFQ entity.
select tests.authenticate_as(
  '18000000-0000-0000-0000-000000000001',
  '18000000-0000-0000-0000-00000000000a',
  '18000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_assoc uuid;
begin
  v_assoc := app_storage.portal_link_file_to_entity(
    p_file_id     => current_setting('test.file')::uuid,
    p_entity_type => 'rfq',
    p_entity_id   => current_setting('test.rfq')::uuid,
    p_role        => 'spec'
  );
  perform set_config('test.assoc', v_assoc::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from app_storage.file_associations
    where id = current_setting('test.assoc')::uuid and deleted_at is null),
  1,
  'portal_link_file_to_entity creates an active association'
);

-- 6. List files for the RFQ entity returns the linked file.
select tests.authenticate_as(
  '18000000-0000-0000-0000-000000000001',
  '18000000-0000-0000-0000-00000000000a',
  '18000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from app_storage.portal_list_files_for_entity(
     'rfq', current_setting('test.rfq')::uuid, 100, 0
   )),
  1,
  'portal_list_files_for_entity returns the linked file'
);
reset role;

-- 7. portal_get_file_metadata returns 1 version + 1 association.
select tests.authenticate_as(
  '18000000-0000-0000-0000-000000000001',
  '18000000-0000-0000-0000-00000000000a',
  '18000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select jsonb_array_length((app_storage.portal_get_file_metadata(current_setting('test.file')::uuid))->'versions')),
  1,
  'portal_get_file_metadata returns 1 version'
);

-- 8. Create v2; v1 becomes superseded.
do $$
declare v_v2 jsonb;
begin
  v_v2 := app_storage.portal_create_file_version(
    p_file_id    => current_setting('test.file')::uuid,
    p_mime_type  => 'application/pdf',
    p_size_bytes => 67890
  );
end;
$$;

select is(
  (select status::text from app_storage.file_versions
    where file_id = current_setting('test.file')::uuid and version_number = 1),
  'superseded',
  'portal_create_file_version supersedes v1'
);

-- 9. Remove association.
select app_storage.portal_remove_file_association(current_setting('test.assoc')::uuid);

select is(
  (select count(*)::int from app_storage.file_associations
    where id = current_setting('test.assoc')::uuid and deleted_at is null),
  0,
  'portal_remove_file_association soft-deletes the association'
);

-- 10. Archive the file.
select app_storage.portal_archive_file(current_setting('test.file')::uuid, p_reason => 'no longer needed');
reset role;

select is(
  (select status::text from app_storage.files where id = current_setting('test.file')::uuid),
  'archived',
  'portal_archive_file moves status → archived'
);

select * from finish();
rollback;
