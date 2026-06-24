-- CC-15 Test 056 — Cross-domain entity visibility:
--   * supplier can list files attached to their own shipment via
--     portal_list_files_for_entity even though the file's owning org is the buyer
--   * unrelated supplier sees 0 / 42501
--   * direct UPDATE/DELETE on file_associations blocked (no grant)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '1a000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '056-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1a000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '056-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1a000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '056-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('1a000000-0000-0000-0000-00000000000a', 'tenant-056', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('1a000000-0000-0000-0000-00000000001a', '1a000000-0000-0000-0000-00000000000a',
   'buyer-056', 'خریدار', 'Buyer 056', 'buyer', 'active'),
  ('1a000000-0000-0000-0000-00000000002a', '1a000000-0000-0000-0000-00000000000a',
   'sup-056-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('1a000000-0000-0000-0000-00000000002b', '1a000000-0000-0000-0000-00000000000a',
   'sup-056-Y', 'وای', 'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('1a000000-0000-0000-0000-000000000001', '1a000000-0000-0000-0000-00000000000a',
   '1a000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('1a000000-0000-0000-0000-000000000002', '1a000000-0000-0000-0000-00000000000a',
   '1a000000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('1a000000-0000-0000-0000-000000000003', '1a000000-0000-0000-0000-00000000000a',
   '1a000000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1a000000-0000-0000-0000-00000000000a', '1a000000-0000-0000-0000-00000000001a',
       '1a000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1a000000-0000-0000-0000-00000000000a', '1a000000-0000-0000-0000-00000000002a',
       '1a000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1a000000-0000-0000-0000-00000000000a', '1a000000-0000-0000-0000-00000000002b',
       '1a000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1a000000-0000-0000-0000-000000000001', r.id, 'organization', '1a000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1a000000-0000-0000-0000-000000000002', r.id, 'organization', '1a000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1a000000-0000-0000-0000-000000000003', r.id, 'organization', '1a000000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

-- Build chain to an executed contract + shipment, then buyer attaches a file
-- to the shipment.
do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_shipment uuid; v_file uuid; v_res jsonb;
begin
  select id into v_supX from supplier.suppliers where organization_id = '1a000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1a000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1a000000-0000-0000-0000-00000000000a',
                       'organization_id','1a000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1a000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for cross-domain visibility');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1a000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1a000000-0000-0000-0000-00000000000a',
                       'organization_id','1a000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1a000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1a000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1a000000-0000-0000-0000-00000000000a',
                       'organization_id','1a000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1a000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'cross-domain prep');
  perform contract.buyer_mark_ready_for_contract(v_prep);
  v_contract := contract.buyer_create_executed_contract(p_preparation_id => v_prep);
  select id into v_p_b from contract.contract_parties where contract_id = v_contract and party_type='buyer' and deleted_at is null limit 1;
  select id into v_p_s from contract.contract_parties where contract_id = v_contract and party_type='supplier' and deleted_at is null limit 1;
  v_sr_b := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_b);
  v_sr_s := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_s);
  perform contract.buyer_mark_pending_signatures(v_contract);
  perform contract.buyer_sign_signature_request(v_sr_b);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1a000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1a000000-0000-0000-0000-00000000000a',
                       'organization_id','1a000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1a000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1a000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1a000000-0000-0000-0000-00000000000a',
                       'organization_id','1a000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1a000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_shipment := shipment.buyer_create_shipment(p_executed_contract_id => v_contract);
  v_res := app_storage.portal_register_file(p_filename => 'shipping-doc.pdf');
  v_file := (v_res->>'file_id')::uuid;
  perform app_storage.portal_finalize_file_upload(v_file);
  perform app_storage.portal_link_file_to_entity(
    p_file_id => v_file, p_entity_type => 'shipment', p_entity_id => v_shipment, p_role => 'bol'
  );
  reset role;

  perform set_config('test.shipment', v_shipment::text, false);
  perform set_config('test.file',     v_file::text,     false);
end;
$$;

select plan(5);

-- 1. Supplier X can list files attached to their shipment (cross-org access).
select tests.authenticate_as(
  '1a000000-0000-0000-0000-000000000002',
  '1a000000-0000-0000-0000-00000000000a',
  '1a000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from app_storage.portal_list_files_for_entity(
     'shipment', current_setting('test.shipment')::uuid, 100, 0
   )),
  1,
  'supplier sees file attached to own shipment via portal_list_files_for_entity'
);
reset role;

-- 2. Unrelated supplier Y sees 0.
select tests.authenticate_as(
  '1a000000-0000-0000-0000-000000000003',
  '1a000000-0000-0000-0000-00000000000a',
  '1a000000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select throws_ok(
  format($$ select * from app_storage.portal_list_files_for_entity('shipment', %L::uuid, 100, 0) $$,
         current_setting('test.shipment')),
  '42501', null,
  'unrelated supplier blocked from listing files on another supplier''s shipment (42501)'
);

-- 3. Unrelated supplier cannot get the file metadata (file org is buyer org).
select throws_ok(
  format($$ select app_storage.portal_get_file_metadata(%L::uuid) $$, current_setting('test.file')),
  '42501', null,
  'unrelated supplier cannot get file metadata (42501)'
);
reset role;

-- 4. Direct UPDATE on file_associations blocked.
select tests.authenticate_as(
  '1a000000-0000-0000-0000-000000000001',
  '1a000000-0000-0000-0000-00000000000a',
  '1a000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update app_storage.file_associations set role = 'tamper'
            where file_id = %L::uuid $$, current_setting('test.file')),
  '42501', null,
  'direct UPDATE on file_associations is blocked (no grant)'
);

-- 5. Direct DELETE on file_associations blocked.
select throws_ok(
  format($$ delete from app_storage.file_associations where file_id = %L::uuid $$,
         current_setting('test.file')),
  '42501', null,
  'direct DELETE on file_associations is blocked (no grant)'
);
reset role;

select * from finish();
rollback;
