-- CC-18 Test 068 — Buyer dispute lifecycle:
--   open dispute from a released settlement → submit evidence → admin assigns
--   mediator (platform_admin user) → admin starts review → admin records decision
--   (release_to_supplier) → settlement.status becomes 'released' (was 'disputed'),
--   settlement.dispute_status='resolved_supplier', dispute case status='resolved_supplier'.
--
-- Assertions (11):
--   1. buyer_open_dispute creates case with status='opened' and buyer party
--   2. settlement.status was flipped to 'disputed' (it was 'released' before)
--   3. settlement.dispute_status='opened'
--   4. Q1: duplicate active dispute on same settlement rejected (23505)
--   5. buyer_submit_evidence adds evidence row in 'submitted'
--   6. admin_assign_mediator sets assigned_mediator_id
--   7. admin_start_review moves opened → under_review
--   8. admin_record_decision creates decision and moves dispute → resolved_supplier
--   9. settlement.dispute_status='resolved_supplier' after decision
--  10. settlement.status='released' after decision (cleared from 'disputed')
--  11. one settlement_action_applied event written

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, tests;
begin;

-- Fixtures: buyer + supplier + admin user with platform_admin role.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '24000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '068-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '24000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '068-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '24000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '068-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('24000000-0000-0000-0000-00000000000a', 'tenant-068', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('24000000-0000-0000-0000-00000000001a', '24000000-0000-0000-0000-00000000000a',
   'buyer-068', 'خریدار', 'Buyer 068', 'buyer', 'active'),
  ('24000000-0000-0000-0000-00000000002a', '24000000-0000-0000-0000-00000000000a',
   'sup-068', 'تأمین', 'Supplier 068', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('24000000-0000-0000-0000-000000000001', '24000000-0000-0000-0000-00000000000a',
   '24000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('24000000-0000-0000-0000-000000000002', '24000000-0000-0000-0000-00000000000a',
   '24000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active'),
  ('24000000-0000-0000-0000-000000000099', '24000000-0000-0000-0000-00000000000a',
   '24000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '24000000-0000-0000-0000-00000000000a', '24000000-0000-0000-0000-00000000001a',
       '24000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '24000000-0000-0000-0000-00000000000a', '24000000-0000-0000-0000-00000000002a',
       '24000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '24000000-0000-0000-0000-000000000001', r.id, 'organization', '24000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '24000000-0000-0000-0000-000000000002', r.id, 'organization', '24000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '24000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Build chain → released settlement.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '24000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','24000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','24000000-0000-0000-0000-00000000000a',
                       'organization_id','24000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '24000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for dispute lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','24000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','24000000-0000-0000-0000-00000000000a',
                       'organization_id','24000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '24000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','24000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','24000000-0000-0000-0000-00000000000a',
                       'organization_id','24000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '24000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'dispute prep');
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
    jsonb_build_object('sub','24000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','24000000-0000-0000-0000-00000000000a',
                       'organization_id','24000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '24000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','24000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','24000000-0000-0000-0000-00000000000a',
                       'organization_id','24000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '24000000-0000-0000-0000-000000000001', true);
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
  perform settlement.buyer_release_settlement(v_set, p_reason => 'goods received');
  reset role;

  perform set_config('test.settlement', v_set::text, false);
end;
$$;

select plan(11);

-- 1. Buyer opens dispute.
select tests.authenticate_as(
  '24000000-0000-0000-0000-000000000001',
  '24000000-0000-0000-0000-00000000000a',
  '24000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_d uuid;
begin
  v_d := dispute.buyer_open_dispute(
    p_settlement_id => current_setting('test.settlement')::uuid,
    p_title => 'Goods damaged on arrival',
    p_description => 'partial quality issue',
    p_amount_in_dispute => 300
  );
  perform set_config('test.dispute', v_d::text, false);
end;
$$;
reset role;

select is(
  (select status::text from dispute.disputes where id = current_setting('test.dispute')::uuid),
  'opened',
  'buyer_open_dispute creates case with status=opened'
);

-- 2. Settlement.status flipped to 'disputed' (was 'released').
select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'disputed',
  'settlement.status flipped to disputed after buyer_open_dispute'
);

-- 3. Settlement.dispute_status='opened'.
select is(
  (select dispute_status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'opened',
  'settlement.dispute_status=opened after buyer_open_dispute'
);

-- 4. Q1: Duplicate active dispute rejected.
select tests.authenticate_as(
  '24000000-0000-0000-0000-000000000001',
  '24000000-0000-0000-0000-00000000000a',
  '24000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select dispute.buyer_open_dispute(%L::uuid, 'Second dispute') $$, current_setting('test.settlement')),
  '23505', null,
  'duplicate active dispute for same settlement rejected (23505) — Q1'
);

-- 5. Buyer submits evidence.
do $$
declare v_e uuid;
begin
  v_e := dispute.buyer_submit_evidence(
    p_dispute_id => current_setting('test.dispute')::uuid,
    p_evidence_kind => 'narrative'::dispute.evidence_kind,
    p_title => 'Inspection notes',
    p_narrative => 'Goods showed signs of damage in 12% of containers'
  );
  perform set_config('test.evidence', v_e::text, false);
end;
$$;
reset role;

select is(
  (select status::text from dispute.dispute_evidence where id = current_setting('test.evidence')::uuid),
  'submitted',
  'buyer_submit_evidence creates evidence row in status=submitted'
);

-- 6. Admin assigns mediator.
select tests.authenticate_as(
  '24000000-0000-0000-0000-000000000099',
  '24000000-0000-0000-0000-00000000000a',
  '24000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select dispute.admin_assign_mediator(
  current_setting('test.dispute')::uuid,
  '24000000-0000-0000-0000-000000000099'
);
reset role;

select is(
  (select assigned_mediator_id from dispute.disputes where id = current_setting('test.dispute')::uuid),
  '24000000-0000-0000-0000-000000000099'::uuid,
  'admin_assign_mediator sets assigned_mediator_id'
);

-- 7. Admin starts review.
select tests.authenticate_as(
  '24000000-0000-0000-0000-000000000099',
  '24000000-0000-0000-0000-00000000000a',
  '24000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select dispute.admin_start_review(current_setting('test.dispute')::uuid);
reset role;

select is(
  (select status::text from dispute.disputes where id = current_setting('test.dispute')::uuid),
  'under_review',
  'admin_start_review moves opened → under_review'
);

-- 8. Admin records decision (release_to_supplier).
select tests.authenticate_as(
  '24000000-0000-0000-0000-000000000099',
  '24000000-0000-0000-0000-00000000000a',
  '24000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_dc uuid;
begin
  v_dc := dispute.admin_record_decision(
    p_dispute_id => current_setting('test.dispute')::uuid,
    p_outcome => 'favor_supplier'::dispute.decision_outcome,
    p_settlement_action => 'release_to_supplier'::dispute.settlement_action,
    p_supplier_share_amount => 1000,
    p_reason => 'Evidence inconclusive; supplier delivered conformant goods'
  );
  perform set_config('test.decision', v_dc::text, false);
end;
$$;
reset role;

select is(
  (select status::text from dispute.disputes where id = current_setting('test.dispute')::uuid),
  'resolved_supplier',
  'admin_record_decision moves dispute → resolved_supplier'
);

-- 9. Settlement.dispute_status='resolved_supplier'.
select is(
  (select dispute_status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'resolved_supplier',
  'settlement.dispute_status=resolved_supplier after decision'
);

-- 10. Settlement.status='released' (cleared from 'disputed').
select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'released',
  'settlement.status=released after release_to_supplier decision'
);

-- 11. settlement_action_applied event written.
select is(
  (select count(*)::int from dispute.dispute_events
    where dispute_id = current_setting('test.dispute')::uuid
      and event_type = 'settlement_action_applied'),
  1,
  'one settlement_action_applied event written'
);

select * from finish();
rollback;
