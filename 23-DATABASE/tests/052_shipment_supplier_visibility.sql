-- CC-14 Test 052 — Supplier visibility:
--   * supplier X sees own shipment via supplier_list_my_shipments
--   * supplier X gets shipment detail
--   * unrelated supplier Y sees 0 shipments
--   * unrelated supplier Y cannot get shipment detail (42501)
--   * supplier cannot see shipment document requirements (buyer-private)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '17000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '052-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '17000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '052-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '17000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '052-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('17000000-0000-0000-0000-00000000000a', 'tenant-052', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('17000000-0000-0000-0000-00000000001a', '17000000-0000-0000-0000-00000000000a',
   'buyer-052', 'خریدار', 'Buyer 052', 'buyer', 'active'),
  ('17000000-0000-0000-0000-00000000002a', '17000000-0000-0000-0000-00000000000a',
   'sup-052-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('17000000-0000-0000-0000-00000000002b', '17000000-0000-0000-0000-00000000000a',
   'sup-052-Y', 'وای',  'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('17000000-0000-0000-0000-000000000001', '17000000-0000-0000-0000-00000000000a',
   '17000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('17000000-0000-0000-0000-000000000002', '17000000-0000-0000-0000-00000000000a',
   '17000000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('17000000-0000-0000-0000-000000000003', '17000000-0000-0000-0000-00000000000a',
   '17000000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '17000000-0000-0000-0000-00000000000a', '17000000-0000-0000-0000-00000000001a',
       '17000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '17000000-0000-0000-0000-00000000000a', '17000000-0000-0000-0000-00000000002a',
       '17000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '17000000-0000-0000-0000-00000000000a', '17000000-0000-0000-0000-00000000002b',
       '17000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '17000000-0000-0000-0000-000000000001', r.id, 'organization', '17000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '17000000-0000-0000-0000-000000000002', r.id, 'organization', '17000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '17000000-0000-0000-0000-000000000003', r.id, 'organization', '17000000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_shipment uuid; v_req uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '17000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','17000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','17000000-0000-0000-0000-00000000000a',
                       'organization_id','17000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for supplier visibility');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 500, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','17000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','17000000-0000-0000-0000-00000000000a',
                       'organization_id','17000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 500, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','17000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','17000000-0000-0000-0000-00000000000a',
                       'organization_id','17000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'sup vis prep');
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
    jsonb_build_object('sub','17000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','17000000-0000-0000-0000-00000000000a',
                       'organization_id','17000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','17000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','17000000-0000-0000-0000-00000000000a',
                       'organization_id','17000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '17000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_shipment := shipment.buyer_create_shipment(p_executed_contract_id => v_contract);
  v_req := shipment.buyer_upsert_doc_requirement(
    p_shipment_id => v_shipment,
    p_document_kind => 'bill_of_lading'::shipment.document_kind
  );
  reset role;

  perform set_config('test.shipment',    v_shipment::text, false);
  perform set_config('test.requirement', v_req::text,      false);
end;
$$;

select plan(5);

-- 1. Supplier X sees own shipment.
select tests.authenticate_as(
  '17000000-0000-0000-0000-000000000002',
  '17000000-0000-0000-0000-00000000000a',
  '17000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from shipment.supplier_list_my_shipments(null, 100, 0)),
  1,
  'supplier X sees own shipment via supplier_list_my_shipments'
);
reset role;

-- 2. Supplier X gets detail.
select tests.authenticate_as(
  '17000000-0000-0000-0000-000000000002',
  '17000000-0000-0000-0000-00000000000a',
  '17000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select isnt(
  (shipment.supplier_get_my_shipment(current_setting('test.shipment')::uuid))->>'id',
  null,
  'supplier_get_my_shipment returns shipment detail for own supplier'
);
reset role;

-- 3. Unrelated supplier Y sees 0.
select tests.authenticate_as(
  '17000000-0000-0000-0000-000000000003',
  '17000000-0000-0000-0000-00000000000a',
  '17000000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select is(
  (select count(*)::int from shipment.supplier_list_my_shipments(null, 100, 0)),
  0,
  'unrelated supplier Y sees 0 shipments'
);

-- 4. Unrelated supplier Y cannot get shipment detail (42501).
select throws_ok(
  format($$ select shipment.supplier_get_my_shipment(%L::uuid) $$, current_setting('test.shipment')),
  '42501', null,
  'unrelated supplier cannot get shipment detail (42501)'
);
reset role;

-- 5. Supplier cannot see shipment document requirements (buyer-private).
select tests.authenticate_as(
  '17000000-0000-0000-0000-000000000002',
  '17000000-0000-0000-0000-00000000000a',
  '17000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from shipment.shipment_document_requirements
    where id = current_setting('test.requirement')::uuid),
  0,
  'supplier cannot see shipment document requirements (RLS blocks — buyer-private)'
);
reset role;

select * from finish();
rollback;
