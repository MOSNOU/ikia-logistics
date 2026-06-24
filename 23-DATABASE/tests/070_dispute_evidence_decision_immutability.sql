-- CC-18 Test 070 — Evidence + decision lifecycle + Q6 confidentiality + immutability:
--   * Q6: buyer-flagged confidential narrative HIDDEN from supplier via RLS
--   * Q3: duplicate active decision rejected (23505)
--   * admin_void_decision flips voided_at; admin_record_decision then succeeds
--   * direct UPDATE on dispute_events blocked
--   * direct DELETE on dispute_decisions blocked
--   * Q5: withdrawal after decision rejected (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '26000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '070-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '26000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '070-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '26000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '070-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('26000000-0000-0000-0000-00000000000a', 'tenant-070', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('26000000-0000-0000-0000-00000000001a', '26000000-0000-0000-0000-00000000000a',
   'buyer-070', 'خریدار', 'Buyer 070', 'buyer', 'active'),
  ('26000000-0000-0000-0000-00000000002a', '26000000-0000-0000-0000-00000000000a',
   'sup-070', 'تأمین', 'Supplier 070', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('26000000-0000-0000-0000-000000000001', '26000000-0000-0000-0000-00000000000a',
   '26000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('26000000-0000-0000-0000-000000000002', '26000000-0000-0000-0000-00000000000a',
   '26000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active'),
  ('26000000-0000-0000-0000-000000000099', '26000000-0000-0000-0000-00000000000a',
   '26000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '26000000-0000-0000-0000-00000000000a', '26000000-0000-0000-0000-00000000001a',
       '26000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '26000000-0000-0000-0000-00000000000a', '26000000-0000-0000-0000-00000000002a',
       '26000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '26000000-0000-0000-0000-000000000001', r.id, 'organization', '26000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '26000000-0000-0000-0000-000000000002', r.id, 'organization', '26000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '26000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Build full chain → released settlement → buyer opens dispute → confidential evidence.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid; v_d uuid; v_e_conf uuid; v_e_open uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '26000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','26000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','26000000-0000-0000-0000-00000000000a',
                       'organization_id','26000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '26000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for immutability');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','26000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','26000000-0000-0000-0000-00000000000a',
                       'organization_id','26000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '26000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','26000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','26000000-0000-0000-0000-00000000000a',
                       'organization_id','26000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '26000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'imm prep');
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
    jsonb_build_object('sub','26000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','26000000-0000-0000-0000-00000000000a',
                       'organization_id','26000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '26000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','26000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','26000000-0000-0000-0000-00000000000a',
                       'organization_id','26000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '26000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Payment', p_amount => 1000
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  perform settlement.buyer_release_settlement(v_set);
  v_d := dispute.buyer_open_dispute(v_set, 'Disagreement', 'unspecified');
  v_e_conf := dispute.buyer_submit_evidence(
    v_d, 'narrative'::dispute.evidence_kind, 'Confidential note',
    p_narrative => 'BUYER PRIVATE STRATEGY: target supplier weak spot',
    p_metadata => jsonb_build_object('confidential', true)
  );
  v_e_open := dispute.buyer_submit_evidence(
    v_d, 'narrative'::dispute.evidence_kind, 'Open note',
    p_narrative => 'Standard note visible to both sides'
  );
  reset role;

  perform set_config('test.dispute',  v_d::text,  false);
  perform set_config('test.evid_conf', v_e_conf::text, false);
  perform set_config('test.evid_open', v_e_open::text, false);
end;
$$;

select plan(8);

-- 1. Q6 — buyer-flagged confidential narrative is HIDDEN from supplier via RLS.
select tests.authenticate_as(
  '26000000-0000-0000-0000-000000000002',
  '26000000-0000-0000-0000-00000000000a',
  '26000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from dispute.dispute_evidence
    where id = current_setting('test.evid_conf')::uuid),
  0,
  'Q6: supplier cannot see buyer-flagged confidential evidence (RLS hides)'
);

-- 2. Supplier CAN see non-confidential buyer evidence.
select is(
  (select count(*)::int from dispute.dispute_evidence
    where id = current_setting('test.evid_open')::uuid),
  1,
  'supplier sees non-confidential buyer evidence (no metadata.confidential)'
);
reset role;

-- 3. Buyer sees both (own org).
select tests.authenticate_as(
  '26000000-0000-0000-0000-000000000001',
  '26000000-0000-0000-0000-00000000000a',
  '26000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from dispute.dispute_evidence
    where dispute_id = current_setting('test.dispute')::uuid),
  2,
  'buyer sees both own evidence rows including confidential one'
);
reset role;

-- 4. Admin: assign mediator, start review, record decision, then duplicate decision blocked.
select tests.authenticate_as(
  '26000000-0000-0000-0000-000000000099',
  '26000000-0000-0000-0000-00000000000a',
  '26000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select dispute.admin_assign_mediator(current_setting('test.dispute')::uuid,
  '26000000-0000-0000-0000-000000000099');
select dispute.admin_start_review(current_setting('test.dispute')::uuid);
do $$
declare v_dc uuid;
begin
  v_dc := dispute.admin_record_decision(
    p_dispute_id => current_setting('test.dispute')::uuid,
    p_outcome => 'favor_buyer'::dispute.decision_outcome,
    p_settlement_action => 'reverse_to_buyer'::dispute.settlement_action,
    p_buyer_share_amount => 1000,
    p_reason => 'Buyer evidence prevailed'
  );
  perform set_config('test.decision', v_dc::text, false);
end;
$$;

-- Q3: duplicate active decision rejected (case is now resolved_buyer; force back to under_review
-- via admin_force then try a second decision — but actually the dispute is now resolved, so
-- the better test is: void + try same decision twice).
-- Simpler: bring it back to under_review via admin_force_dispute_status; then try a second
-- record_decision while the old one is still active → 23505.
select dispute.admin_force_dispute_status(current_setting('test.dispute')::uuid, 'under_review'::dispute.dispute_case_status);

select throws_ok(
  format($$ select dispute.admin_record_decision(%L::uuid, 'favor_supplier'::dispute.decision_outcome, 'release_to_supplier'::dispute.settlement_action) $$,
         current_setting('test.dispute')),
  '23505', null,
  'Q3: duplicate active decision rejected (23505)'
);

-- 5. admin_void_decision then a fresh decision succeeds.
select dispute.admin_void_decision(current_setting('test.decision')::uuid, p_reason => 'correction');

do $$
declare v_dc2 uuid;
begin
  v_dc2 := dispute.admin_record_decision(
    p_dispute_id => current_setting('test.dispute')::uuid,
    p_outcome => 'favor_supplier'::dispute.decision_outcome,
    p_settlement_action => 'release_to_supplier'::dispute.settlement_action,
    p_supplier_share_amount => 1000,
    p_reason => 'Re-decided in supplier favour'
  );
  perform set_config('test.decision2', v_dc2::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from dispute.dispute_decisions
    where dispute_id = current_setting('test.dispute')::uuid and voided_at is null),
  1,
  'admin_void_decision + fresh admin_record_decision yields exactly one active decision'
);

-- 6. Direct UPDATE on dispute_events blocked.
select tests.authenticate_as(
  '26000000-0000-0000-0000-000000000001',
  '26000000-0000-0000-0000-00000000000a',
  '26000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update dispute.dispute_events set reason = 'tamper'
            where dispute_id = %L::uuid $$, current_setting('test.dispute')),
  '42501', null,
  'direct UPDATE on dispute_events is blocked (no grant)'
);

-- 7. Direct DELETE on dispute_decisions blocked.
select throws_ok(
  format($$ delete from dispute.dispute_decisions
            where dispute_id = %L::uuid $$, current_setting('test.dispute')),
  '42501', null,
  'direct DELETE on dispute_decisions is blocked (no grant)'
);

-- 8. Q5 — buyer withdrawal blocked after decision recorded.
select throws_ok(
  format($$ select dispute.buyer_withdraw_dispute(%L::uuid) $$, current_setting('test.dispute')),
  'P0001', null,
  'Q5: buyer_withdraw_dispute blocked once decision recorded (P0001)'
);
reset role;

select * from finish();
rollback;
