-- CC-17 Test 065 — Supplier reconciliation + dispute scaffolding:
--   * supplier sees own settlement via supplier_list_my_settlements
--   * supplier_confirm_reconciliation moves released → reconciled
--   * supplier_open_dispute on a settled settlement flips dispute_status='opened'
--     and (when held/released) flips settlement.status to 'disputed'
--   * unrelated supplier blocked (42501)
--   * reconciling before release rejected (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '22000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '065-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '22000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '065-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '22000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '065-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('22000000-0000-0000-0000-00000000000a', 'tenant-065', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('22000000-0000-0000-0000-00000000001a', '22000000-0000-0000-0000-00000000000a',
   'buyer-065', 'خریدار', 'Buyer 065', 'buyer', 'active'),
  ('22000000-0000-0000-0000-00000000002a', '22000000-0000-0000-0000-00000000000a',
   'sup-065-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('22000000-0000-0000-0000-00000000002b', '22000000-0000-0000-0000-00000000000a',
   'sup-065-Y', 'وای', 'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('22000000-0000-0000-0000-000000000001', '22000000-0000-0000-0000-00000000000a',
   '22000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('22000000-0000-0000-0000-000000000002', '22000000-0000-0000-0000-00000000000a',
   '22000000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('22000000-0000-0000-0000-000000000003', '22000000-0000-0000-0000-00000000000a',
   '22000000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '22000000-0000-0000-0000-00000000000a', '22000000-0000-0000-0000-00000000001a',
       '22000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '22000000-0000-0000-0000-00000000000a', '22000000-0000-0000-0000-00000000002a',
       '22000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '22000000-0000-0000-0000-00000000000a', '22000000-0000-0000-0000-00000000002b',
       '22000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '22000000-0000-0000-0000-000000000001', r.id, 'organization', '22000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '22000000-0000-0000-0000-000000000002', r.id, 'organization', '22000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '22000000-0000-0000-0000-000000000003', r.id, 'organization', '22000000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

-- Build a chain → release a settlement so we can test reconciliation.
do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid; v_set2 uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '22000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','22000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','22000000-0000-0000-0000-00000000000a',
                       'organization_id','22000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '22000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for reconciliation');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','22000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','22000000-0000-0000-0000-00000000000a',
                       'organization_id','22000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '22000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','22000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','22000000-0000-0000-0000-00000000000a',
                       'organization_id','22000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '22000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'recon prep');
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
    jsonb_build_object('sub','22000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','22000000-0000-0000-0000-00000000000a',
                       'organization_id','22000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '22000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','22000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','22000000-0000-0000-0000-00000000000a',
                       'organization_id','22000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '22000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_supX, p_currency => 'USD');

  -- Released settlement (target for reconciliation).
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Payment 1', p_amount => 500
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  perform settlement.buyer_release_settlement(v_set, p_reason => 'goods received');

  -- Holding settlement (target for dispute → flips to 'disputed').
  v_set2 := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set2, p_description => 'Payment 2', p_amount => 300
  );
  perform settlement.buyer_mark_settlement_ready(v_set2);
  perform settlement.buyer_hold_settlement(v_set2);
  reset role;

  perform set_config('test.settlement',  v_set::text,  false);
  perform set_config('test.settlement2', v_set2::text, false);
end;
$$;

select plan(6);

-- 1. Supplier X sees own settlement.
select tests.authenticate_as(
  '22000000-0000-0000-0000-000000000002',
  '22000000-0000-0000-0000-00000000000a',
  '22000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from settlement.supplier_list_my_settlements(null, 100, 0)),
  '>=', 2,
  'supplier X sees own settlements (>= 2)'
);

-- 2. Supplier X confirms reconciliation on the released settlement.
select settlement.supplier_confirm_reconciliation(
  current_setting('test.settlement')::uuid,
  p_notes => 'received in full'
);
reset role;

select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'reconciled',
  'supplier_confirm_reconciliation moves released → reconciled'
);

-- 3. Supplier X opens dispute on the holding settlement.
select tests.authenticate_as(
  '22000000-0000-0000-0000-000000000002',
  '22000000-0000-0000-0000-00000000000a',
  '22000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select settlement.supplier_open_dispute(
  current_setting('test.settlement2')::uuid,
  p_reason => 'wrong amount held'
);
reset role;

select is(
  (select dispute_status::text from settlement.settlements where id = current_setting('test.settlement2')::uuid),
  'opened',
  'supplier_open_dispute sets dispute_status=opened'
);

-- 4. Disputed settlement (was holding) → status flipped to 'disputed'.
select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement2')::uuid),
  'disputed',
  'opening dispute on a holding settlement flips status to disputed'
);

-- 5. Unrelated supplier Y blocked from reading.
select tests.authenticate_as(
  '22000000-0000-0000-0000-000000000003',
  '22000000-0000-0000-0000-00000000000a',
  '22000000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select throws_ok(
  format($$ select settlement.supplier_get_my_settlement(%L::uuid) $$, current_setting('test.settlement')),
  '42501', null,
  'unrelated supplier blocked from settlement detail (42501)'
);
reset role;

-- 6. Reconciliation before release rejected (P0001).
-- Use a fresh draft settlement.
select tests.authenticate_as(
  '22000000-0000-0000-0000-000000000001',
  '22000000-0000-0000-0000-00000000000a',
  '22000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_set3 uuid;
begin
  v_set3 := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => (select executed_contract_id from settlement.settlements
                                where id = current_setting('test.settlement')::uuid),
    p_currency => 'USD'
  );
  perform set_config('test.settlement3', v_set3::text, false);
end;
$$;
reset role;

select tests.authenticate_as(
  '22000000-0000-0000-0000-000000000002',
  '22000000-0000-0000-0000-00000000000a',
  '22000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select throws_ok(
  format($$ select settlement.supplier_confirm_reconciliation(%L::uuid) $$, current_setting('test.settlement3')),
  'P0001', null,
  'reconciliation rejected on non-released settlement (P0001)'
);
reset role;

select * from finish();
rollback;
