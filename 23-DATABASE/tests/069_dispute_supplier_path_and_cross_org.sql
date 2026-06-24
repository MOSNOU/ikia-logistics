-- CC-18 Test 069 — Supplier dispute path via CC-17 trigger + cross-org isolation:
--   * settlement.supplier_open_dispute (CC-17) fires Q7-A trigger and creates a
--     dispute.disputes row automatically (no CC-17 RPC patched)
--   * supplier sees own dispute via supplier_list_my_disputes
--   * unrelated supplier blocked (42501)
--   * cross-org buyer blocked from buyer_open_dispute on someone else's settlement (42501)
--   * supplier_submit_evidence on own dispute succeeds

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '25000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '069-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '25000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '069-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '25000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '069-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '25000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', '069-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('25000000-0000-0000-0000-00000000000a', 'tenant-069a', 'الف', 'A'),
  ('25000000-0000-0000-0000-00000000000b', 'tenant-069b', 'ب', 'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('25000000-0000-0000-0000-00000000001a', '25000000-0000-0000-0000-00000000000a',
   'buyer-069a', 'الف', 'Buyer A', 'buyer', 'active'),
  ('25000000-0000-0000-0000-00000000001b', '25000000-0000-0000-0000-00000000000b',
   'buyer-069b', 'ب', 'Buyer B', 'buyer', 'active'),
  ('25000000-0000-0000-0000-00000000002a', '25000000-0000-0000-0000-00000000000a',
   'sup-069-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('25000000-0000-0000-0000-00000000002b', '25000000-0000-0000-0000-00000000000a',
   'sup-069-Y', 'وای', 'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('25000000-0000-0000-0000-000000000001', '25000000-0000-0000-0000-00000000000a',
   '25000000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('25000000-0000-0000-0000-000000000002', '25000000-0000-0000-0000-00000000000b',
   '25000000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('25000000-0000-0000-0000-000000000003', '25000000-0000-0000-0000-00000000000a',
   '25000000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('25000000-0000-0000-0000-000000000004', '25000000-0000-0000-0000-00000000000a',
   '25000000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '25000000-0000-0000-0000-00000000000a', '25000000-0000-0000-0000-00000000001a',
       '25000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '25000000-0000-0000-0000-00000000000b', '25000000-0000-0000-0000-00000000001b',
       '25000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '25000000-0000-0000-0000-00000000000a', '25000000-0000-0000-0000-00000000002a',
       '25000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '25000000-0000-0000-0000-00000000000a', '25000000-0000-0000-0000-00000000002b',
       '25000000-0000-0000-0000-000000000004', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '25000000-0000-0000-0000-000000000001', r.id, 'organization', '25000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '25000000-0000-0000-0000-000000000002', r.id, 'organization', '25000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '25000000-0000-0000-0000-000000000003', r.id, 'organization', '25000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '25000000-0000-0000-0000-000000000004', r.id, 'organization', '25000000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

-- Build a released settlement on buyer A + supplier X.
do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '25000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','25000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','25000000-0000-0000-0000-00000000000a',
                       'organization_id','25000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '25000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for supplier dispute');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','25000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','25000000-0000-0000-0000-00000000000a',
                       'organization_id','25000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '25000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','25000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','25000000-0000-0000-0000-00000000000a',
                       'organization_id','25000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '25000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'sup dispute prep');
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
    jsonb_build_object('sub','25000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','25000000-0000-0000-0000-00000000000a',
                       'organization_id','25000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '25000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','25000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','25000000-0000-0000-0000-00000000000a',
                       'organization_id','25000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '25000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_supX, p_currency => 'USD');
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Payment', p_amount => 1000
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  reset role;

  perform set_config('test.settlement', v_set::text, false);
end;
$$;

select plan(6);

-- 1. Supplier X opens dispute via CC-17 RPC; Q7-A trigger auto-creates dispute.disputes.
select tests.authenticate_as(
  '25000000-0000-0000-0000-000000000003',
  '25000000-0000-0000-0000-00000000000a',
  '25000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select settlement.supplier_open_dispute(
  current_setting('test.settlement')::uuid,
  p_reason => 'late delivery; wants partial refund'
);
reset role;

select is(
  (select count(*)::int from dispute.disputes
    where settlement_id = current_setting('test.settlement')::uuid and deleted_at is null),
  1,
  'Q7-A trigger auto-created dispute.disputes row from settlement.supplier_open_dispute'
);

-- 2. Supplier sees own dispute.
select tests.authenticate_as(
  '25000000-0000-0000-0000-000000000003',
  '25000000-0000-0000-0000-00000000000a',
  '25000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from dispute.supplier_list_my_disputes(null, 100, 0)),
  '>=', 1,
  'supplier X sees own dispute via supplier_list_my_disputes'
);

-- 3. Supplier submits evidence on own dispute.
do $$
declare v_d uuid; v_e uuid;
begin
  select id into v_d from dispute.disputes
   where settlement_id = current_setting('test.settlement')::uuid and deleted_at is null limit 1;
  v_e := dispute.supplier_submit_evidence(
    p_dispute_id => v_d,
    p_evidence_kind => 'document'::dispute.evidence_kind,
    p_title => 'Shipping records',
    p_narrative => 'see attached BoL'
  );
  perform set_config('test.dispute', v_d::text, false);
  perform set_config('test.evidence', v_e::text, false);
end;
$$;
reset role;

select is(
  (select submitter_party_role::text from dispute.dispute_evidence where id = current_setting('test.evidence')::uuid),
  'supplier',
  'supplier_submit_evidence creates evidence with submitter_party_role=supplier'
);

-- 4. Unrelated supplier Y cannot see dispute.
select tests.authenticate_as(
  '25000000-0000-0000-0000-000000000004',
  '25000000-0000-0000-0000-00000000000a',
  '25000000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select is(
  (select count(*)::int from dispute.supplier_list_my_disputes(null, 100, 0)),
  0,
  'unrelated supplier Y sees 0 disputes'
);

select throws_ok(
  format($$ select dispute.supplier_get_my_dispute(%L::uuid) $$, current_setting('test.dispute')),
  '42501', null,
  'unrelated supplier blocked from supplier_get_my_dispute (42501)'
);
reset role;

-- 5. Cross-org buyer B cannot open dispute on buyer A's settlement.
select tests.authenticate_as(
  '25000000-0000-0000-0000-000000000002',
  '25000000-0000-0000-0000-00000000000b',
  '25000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select dispute.buyer_open_dispute(%L::uuid, 'tamper') $$, current_setting('test.settlement')),
  '42501', null,
  'cross-org buyer B blocked from buyer_open_dispute on buyer A''s settlement (42501)'
);
reset role;

select * from finish();
rollback;
