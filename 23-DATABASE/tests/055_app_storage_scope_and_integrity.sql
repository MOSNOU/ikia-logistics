-- CC-15 Test 055 — Cross-org scope and integrity:
--   * buyer B cannot access buyer A's file (42501 via portal_get_file_metadata)
--   * buyer B cannot link buyer A's file (42501)
--   * portal_list_files_for_entity for an entity caller cannot see → 42501
--   * portal_link_file_to_entity rejects entity_type the caller cannot see (42501)
--   * portal_finalize_file_upload on already-uploaded file is rejected (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '19000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '055-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '19000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '055-buyerB@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('19000000-0000-0000-0000-00000000000a', 'tenant-055a', 'الف', 'A'),
  ('19000000-0000-0000-0000-00000000000b', 'tenant-055b', 'ب', 'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('19000000-0000-0000-0000-00000000001a', '19000000-0000-0000-0000-00000000000a',
   'buyer-055a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('19000000-0000-0000-0000-00000000001b', '19000000-0000-0000-0000-00000000000b',
   'buyer-055b', 'خریدار ب', 'Buyer B', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('19000000-0000-0000-0000-000000000001', '19000000-0000-0000-0000-00000000000a',
   '19000000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('19000000-0000-0000-0000-000000000002', '19000000-0000-0000-0000-00000000000b',
   '19000000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '19000000-0000-0000-0000-00000000000a', '19000000-0000-0000-0000-00000000001a',
       '19000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '19000000-0000-0000-0000-00000000000b', '19000000-0000-0000-0000-00000000001b',
       '19000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '19000000-0000-0000-0000-000000000001', r.id, 'organization', '19000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '19000000-0000-0000-0000-000000000002', r.id, 'organization', '19000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';

-- Buyer A creates a file + an RFQ.
do $$
declare v_prod uuid; v_rfq_a uuid; v_rfq_b uuid; v_file_a uuid; v_res jsonb;
begin
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','19000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','19000000-0000-0000-0000-00000000000a',
                       'organization_id','19000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '19000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq_a := rfq.buyer_create_rfq(p_title => 'A RFQ');
  perform rfq.buyer_upsert_rfq_item(p_request_id => v_rfq_a, p_product_id => v_prod,
                                     p_quantity => 100, p_quantity_unit => 'ton');
  v_res := app_storage.portal_register_file(p_filename => 'a.pdf');
  v_file_a := (v_res->>'file_id')::uuid;
  perform app_storage.portal_finalize_file_upload(v_file_a);
  reset role;

  -- Buyer B creates its own RFQ.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','19000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','19000000-0000-0000-0000-00000000000b',
                       'organization_id','19000000-0000-0000-0000-00000000001b')::text, true);
  perform set_config('request.jwt.claim.sub', '19000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_rfq_b := rfq.buyer_create_rfq(p_title => 'B RFQ');
  perform rfq.buyer_upsert_rfq_item(p_request_id => v_rfq_b, p_product_id => v_prod,
                                     p_quantity => 50, p_quantity_unit => 'ton');
  reset role;

  perform set_config('test.rfq_a',  v_rfq_a::text,  false);
  perform set_config('test.rfq_b',  v_rfq_b::text,  false);
  perform set_config('test.file_a', v_file_a::text, false);
end;
$$;

select plan(5);

-- 1. Buyer B cannot access buyer A's file metadata.
select tests.authenticate_as(
  '19000000-0000-0000-0000-000000000002',
  '19000000-0000-0000-0000-00000000000b',
  '19000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select app_storage.portal_get_file_metadata(%L::uuid) $$, current_setting('test.file_a')),
  '42501', null,
  'buyer B cannot get buyer A''s file metadata (42501)'
);

-- 2. Buyer B cannot link buyer A's file even to buyer B's own RFQ.
select throws_ok(
  format($$ select app_storage.portal_link_file_to_entity(%L::uuid, 'rfq', %L::uuid) $$,
         current_setting('test.file_a'), current_setting('test.rfq_b')),
  '42501', null,
  'buyer B cannot link buyer A''s file (42501)'
);

-- 3. Buyer B cannot list files for an entity they cannot see (buyer A's RFQ).
select throws_ok(
  format($$ select * from app_storage.portal_list_files_for_entity('rfq', %L::uuid, 100, 0) $$,
         current_setting('test.rfq_a')),
  '42501', null,
  'portal_list_files_for_entity blocks listing for entities caller cannot see (42501)'
);
reset role;

-- 4. Buyer A cannot link her own file to buyer B's RFQ (entity she cannot see).
select tests.authenticate_as(
  '19000000-0000-0000-0000-000000000001',
  '19000000-0000-0000-0000-00000000000a',
  '19000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select app_storage.portal_link_file_to_entity(%L::uuid, 'rfq', %L::uuid) $$,
         current_setting('test.file_a'), current_setting('test.rfq_b')),
  '42501', null,
  'portal_link_file_to_entity rejects when caller cannot see the target entity (42501)'
);

-- 5. portal_finalize_file_upload on already-uploaded file is rejected (P0001).
select throws_ok(
  format($$ select app_storage.portal_finalize_file_upload(%L::uuid) $$, current_setting('test.file_a')),
  'P0001', null,
  'portal_finalize_file_upload on already-uploaded file is rejected (P0001)'
);
reset role;

select * from finish();
rollback;
