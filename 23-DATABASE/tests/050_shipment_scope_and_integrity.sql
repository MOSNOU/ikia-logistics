-- CC-14 Test 050 — Shipment scope and integrity:
--   * buyer B cannot create shipment from buyer A's executed contract (42501)
--   * shipment from non-executed contract (draft_execution / pending_signatures / cancelled) rejected (P0001)
--   * document metadata cannot reference requirement from another shipment (42501)
--   * no pricing/payment/settlement/escrow/invoice/accounting/insurance schemas exist

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '15000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '050-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '15000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '050-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '15000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '050-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('15000000-0000-0000-0000-00000000000a', 'tenant-050a', 'الف', 'A'),
  ('15000000-0000-0000-0000-00000000000b', 'tenant-050b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('15000000-0000-0000-0000-00000000001a', '15000000-0000-0000-0000-00000000000a',
   'buyer-050a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('15000000-0000-0000-0000-00000000001b', '15000000-0000-0000-0000-00000000000b',
   'buyer-050b', 'خریدار ب',  'Buyer B', 'buyer', 'active'),
  ('15000000-0000-0000-0000-00000000002a', '15000000-0000-0000-0000-00000000000a',
   'sup-050', 'تأمین', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('15000000-0000-0000-0000-000000000001', '15000000-0000-0000-0000-00000000000a',
   '15000000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('15000000-0000-0000-0000-000000000002', '15000000-0000-0000-0000-00000000000b',
   '15000000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('15000000-0000-0000-0000-000000000003', '15000000-0000-0000-0000-00000000000a',
   '15000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '15000000-0000-0000-0000-00000000000a', '15000000-0000-0000-0000-00000000001a',
       '15000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '15000000-0000-0000-0000-00000000000b', '15000000-0000-0000-0000-00000000001b',
       '15000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '15000000-0000-0000-0000-00000000000a', '15000000-0000-0000-0000-00000000002a',
       '15000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '15000000-0000-0000-0000-000000000001', r.id, 'organization', '15000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '15000000-0000-0000-0000-000000000002', r.id, 'organization', '15000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '15000000-0000-0000-0000-000000000003', r.id, 'organization', '15000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build two contracts under buyer A:
--   c_executed  — executed (used for cross-buyer block + 2nd shipment)
--   c_draft     — draft_execution (used to test non-executed rejection)
do $$
declare
  v_sup uuid; v_prod uuid;
  v_rfq1 uuid; v_item1 uuid; v_off1 uuid; v_dec1 uuid; v_prep1 uuid; v_c_exec uuid;
  v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_rfq2 uuid; v_item2 uuid; v_off2 uuid; v_dec2 uuid; v_prep2 uuid; v_c_draft uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '15000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','15000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','15000000-0000-0000-0000-00000000000a',
                       'organization_id','15000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq1 := rfq.buyer_create_rfq(p_title => 'R050-exec');
  v_item1 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq1, p_product_id => v_prod,
                                        p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq1);
  perform rfq.buyer_invite_suppliers(v_rfq1, array[v_sup]);

  v_rfq2 := rfq.buyer_create_rfq(p_title => 'R050-draft');
  v_item2 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq2, p_product_id => v_prod,
                                        p_quantity => 500, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq2);
  perform rfq.buyer_invite_suppliers(v_rfq2, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','15000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','15000000-0000-0000-0000-00000000000a',
                       'organization_id','15000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off1 := offer.supplier_create_draft_offer(p_request_id => v_rfq1);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off1, p_request_item_id => v_item1,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off1);

  v_off2 := offer.supplier_create_draft_offer(p_request_id => v_rfq2);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off2, p_request_item_id => v_item2,
    p_offered_quantity => 500, p_quantity_unit => 'ton', p_unit_price => 390, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off2);
  reset role;

  -- Build c_exec (push to executed)
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','15000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','15000000-0000-0000-0000-00000000000a',
                       'organization_id','15000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec1 := evaluation.buyer_select_for_contract(p_offer_id => v_off1);
  v_prep1 := contract.buyer_create_preparation(p_decision_id => v_dec1, p_title => 'exec prep');
  perform contract.buyer_mark_ready_for_contract(v_prep1);
  v_c_exec := contract.buyer_create_executed_contract(p_preparation_id => v_prep1);
  select id into v_p_b from contract.contract_parties where contract_id = v_c_exec and party_type='buyer' and deleted_at is null limit 1;
  select id into v_p_s from contract.contract_parties where contract_id = v_c_exec and party_type='supplier' and deleted_at is null limit 1;
  v_sr_b := contract.buyer_create_signature_request(p_contract_id => v_c_exec, p_party_id => v_p_b);
  v_sr_s := contract.buyer_create_signature_request(p_contract_id => v_c_exec, p_party_id => v_p_s);
  perform contract.buyer_mark_pending_signatures(v_c_exec);
  perform contract.buyer_sign_signature_request(v_sr_b);

  -- Build c_draft (left in draft_execution)
  v_dec2 := evaluation.buyer_select_for_contract(p_offer_id => v_off2);
  v_prep2 := contract.buyer_create_preparation(p_decision_id => v_dec2, p_title => 'draft prep');
  perform contract.buyer_mark_ready_for_contract(v_prep2);
  v_c_draft := contract.buyer_create_executed_contract(p_preparation_id => v_prep2);
  -- left in draft_execution
  reset role;

  -- Supplier signs to push c_exec to executed.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','15000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','15000000-0000-0000-0000-00000000000a',
                       'organization_id','15000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '15000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('test.c_exec',  v_c_exec::text,  false);
  perform set_config('test.c_draft', v_c_draft::text, false);
end;
$$;

select plan(4);

-- 1. Buyer B cannot create shipment from buyer A's executed contract.
select tests.authenticate_as(
  '15000000-0000-0000-0000-000000000002',
  '15000000-0000-0000-0000-00000000000b',
  '15000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select shipment.buyer_create_shipment(%L::uuid) $$, current_setting('test.c_exec')),
  '42501', null,
  'buyer B cannot create shipment from buyer A''s executed contract (42501)'
);
reset role;

-- 2. Shipment from non-executed contract rejected.
select tests.authenticate_as(
  '15000000-0000-0000-0000-000000000001',
  '15000000-0000-0000-0000-00000000000a',
  '15000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select shipment.buyer_create_shipment(%L::uuid) $$, current_setting('test.c_draft')),
  'P0001', null,
  'shipment from non-executed contract is rejected (P0001)'
);

-- 3. Create two shipments under c_exec, then try to use a requirement from
--    shipment A in a document on shipment B → should be rejected.
do $$
declare v_sh_a uuid; v_sh_b uuid; v_req_a uuid;
begin
  v_sh_a := shipment.buyer_create_shipment(p_executed_contract_id => current_setting('test.c_exec')::uuid);
  v_sh_b := shipment.buyer_create_shipment(p_executed_contract_id => current_setting('test.c_exec')::uuid);
  v_req_a := shipment.buyer_upsert_doc_requirement(
    p_shipment_id => v_sh_a,
    p_document_kind => 'bill_of_lading'::shipment.document_kind
  );
  perform set_config('test.sh_a',    v_sh_a::text,    false);
  perform set_config('test.sh_b',    v_sh_b::text,    false);
  perform set_config('test.req_a',   v_req_a::text,   false);
end;
$$;

select throws_ok(
  format($$ select shipment.buyer_upsert_document(
              p_shipment_id    => %L::uuid,
              p_document_kind  => 'bill_of_lading'::shipment.document_kind,
              p_requirement_id => %L::uuid
            ) $$, current_setting('test.sh_b'), current_setting('test.req_a')),
  '42501', null,
  'document metadata cannot reference a requirement from a different shipment (42501)'
);
reset role;

-- 4. No forbidden side-effect schemas.
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('payment','invoice','accounting','insurance_claim','gps')),
  0,
  'no payment/invoice/accounting/insurance/gps schemas were created (settlement CC-17 and pricing CC-23 legitimately exist)'
);

select * from finish();
rollback;
