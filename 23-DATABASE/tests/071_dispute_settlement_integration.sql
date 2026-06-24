-- CC-18 Test 071 — Settlement-integration via fn_apply_decision_to_settlement:
--   * split decision writes 3 escrow entries (release + debit for supplier,
--     reverse for buyer share) — Q10
--   * split: settlement.status='released' + metadata.dispute_resolution.split=true (Q4)
--   * split: settlement.dispute_status='resolved_supplier' (no new enum, Q4)
--   * reverse_to_buyer: writes 1 reverse entry, settlement.status='cancelled'
--   * no_change: no escrow entries written, settlement.status preserved,
--     settlement.dispute_status='withdrawn'

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '27000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '071-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '27000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '071-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '27000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '071-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('27000000-0000-0000-0000-00000000000a', 'tenant-071', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('27000000-0000-0000-0000-00000000001a', '27000000-0000-0000-0000-00000000000a',
   'buyer-071', 'خریدار', 'Buyer 071', 'buyer', 'active'),
  ('27000000-0000-0000-0000-00000000002a', '27000000-0000-0000-0000-00000000000a',
   'sup-071', 'تأمین', 'Supplier 071', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('27000000-0000-0000-0000-000000000001', '27000000-0000-0000-0000-00000000000a',
   '27000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('27000000-0000-0000-0000-000000000002', '27000000-0000-0000-0000-00000000000a',
   '27000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active'),
  ('27000000-0000-0000-0000-000000000099', '27000000-0000-0000-0000-00000000000a',
   '27000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '27000000-0000-0000-0000-00000000000a', '27000000-0000-0000-0000-00000000001a',
       '27000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '27000000-0000-0000-0000-00000000000a', '27000000-0000-0000-0000-00000000002a',
       '27000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '27000000-0000-0000-0000-000000000001', r.id, 'organization', '27000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '27000000-0000-0000-0000-000000000002', r.id, 'organization', '27000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '27000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Build base scenario: one executed contract + escrow; we'll create three
-- separate holding settlements and resolve each with a different action.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid;
  v_set_split uuid; v_set_rev uuid; v_set_nc uuid;
  v_d_split uuid; v_d_rev uuid; v_d_nc uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '27000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','27000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','27000000-0000-0000-0000-00000000000a',
                       'organization_id','27000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '27000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for settlement integration');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','27000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','27000000-0000-0000-0000-00000000000a',
                       'organization_id','27000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '27000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','27000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','27000000-0000-0000-0000-00000000000a',
                       'organization_id','27000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '27000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'integ prep');
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
    jsonb_build_object('sub','27000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','27000000-0000-0000-0000-00000000000a',
                       'organization_id','27000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '27000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','27000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','27000000-0000-0000-0000-00000000000a',
                       'organization_id','27000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '27000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');

  -- Settlement #1 (target for split): holding 1000.
  v_set_split := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set_split, p_description => 'Split target', p_amount => 1000
  );
  perform settlement.buyer_mark_settlement_ready(v_set_split);
  perform settlement.buyer_hold_settlement(v_set_split);

  -- Settlement #2 (target for reverse_to_buyer): holding 500.
  v_set_rev := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set_rev, p_description => 'Reverse target', p_amount => 500
  );
  perform settlement.buyer_mark_settlement_ready(v_set_rev);
  perform settlement.buyer_hold_settlement(v_set_rev);

  -- Settlement #3 (target for no_change): released 300, supplier already reconciled.
  v_set_nc := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set_nc, p_description => 'NoChange target', p_amount => 300
  );
  perform settlement.buyer_mark_settlement_ready(v_set_nc);
  perform settlement.buyer_hold_settlement(v_set_nc);
  perform settlement.buyer_release_settlement(v_set_nc, p_reason => 'pre-dispute');

  -- Open disputes on each.
  v_d_split := dispute.buyer_open_dispute(v_set_split, 'Split scenario');
  v_d_rev   := dispute.buyer_open_dispute(v_set_rev,   'Reverse scenario');
  v_d_nc    := dispute.buyer_open_dispute(v_set_nc,    'No-change scenario');
  reset role;

  perform set_config('test.set_split', v_set_split::text, false);
  perform set_config('test.set_rev',   v_set_rev::text,   false);
  perform set_config('test.set_nc',    v_set_nc::text,    false);
  perform set_config('test.d_split',   v_d_split::text,   false);
  perform set_config('test.d_rev',     v_d_rev::text,     false);
  perform set_config('test.d_nc',      v_d_nc::text,      false);
  perform set_config('test.escrow',    v_esc::text,       false);
end;
$$;

select plan(8);

-- 1. SPLIT (1000 total → supplier 700, buyer 300).
select tests.authenticate_as(
  '27000000-0000-0000-0000-000000000099',
  '27000000-0000-0000-0000-00000000000a',
  '27000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select dispute.admin_assign_mediator(current_setting('test.d_split')::uuid,
  '27000000-0000-0000-0000-000000000099');
select dispute.admin_start_review(current_setting('test.d_split')::uuid);
select dispute.admin_record_decision(
  p_dispute_id => current_setting('test.d_split')::uuid,
  p_outcome => 'split'::dispute.decision_outcome,
  p_settlement_action => 'split'::dispute.settlement_action,
  p_supplier_share_amount => 700,
  p_buyer_share_amount => 300,
  p_reason => 'partial damage'
);
reset role;

-- Split should write 3 escrow entries on this settlement (Q10).
select is(
  (select count(*)::int from settlement.escrow_entries
    where settlement_id = current_setting('test.set_split')::uuid
      and entry_type in ('release','debit','reverse')),
  3,
  'Q10: split writes 3 escrow entries (release + debit for supplier, reverse for buyer)'
);

-- Settlement.status='released' (Q4: no new enum value).
select is(
  (select status::text from settlement.settlements where id = current_setting('test.set_split')::uuid),
  'released',
  'Q4: split settlement.status=released (no new enum value)'
);

-- Metadata flag set (Q4).
select is(
  (select metadata->'dispute_resolution'->>'split' from settlement.settlements
    where id = current_setting('test.set_split')::uuid),
  'true',
  'Q4: settlement metadata.dispute_resolution.split=true'
);

-- Settlement.dispute_status='resolved_supplier' (no new enum value).
select is(
  (select dispute_status::text from settlement.settlements where id = current_setting('test.set_split')::uuid),
  'resolved_supplier',
  'split decision sets settlement.dispute_status=resolved_supplier (existing enum)'
);

-- 2. REVERSE_TO_BUYER (500 → buyer).
select tests.authenticate_as(
  '27000000-0000-0000-0000-000000000099',
  '27000000-0000-0000-0000-00000000000a',
  '27000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select dispute.admin_assign_mediator(current_setting('test.d_rev')::uuid,
  '27000000-0000-0000-0000-000000000099');
select dispute.admin_start_review(current_setting('test.d_rev')::uuid);
select dispute.admin_record_decision(
  p_dispute_id => current_setting('test.d_rev')::uuid,
  p_outcome => 'favor_buyer'::dispute.decision_outcome,
  p_settlement_action => 'reverse_to_buyer'::dispute.settlement_action,
  p_buyer_share_amount => 500,
  p_reason => 'buyer prevailed'
);
reset role;

select is(
  (select count(*)::int from settlement.escrow_entries
    where settlement_id = current_setting('test.set_rev')::uuid
      and entry_type = 'reverse'),
  1,
  'reverse_to_buyer writes 1 reverse entry on the settlement'
);

select is(
  (select status::text from settlement.settlements where id = current_setting('test.set_rev')::uuid),
  'cancelled',
  'reverse_to_buyer flips settlement.status to cancelled'
);

-- 3. NO_CHANGE (300, already released).
select tests.authenticate_as(
  '27000000-0000-0000-0000-000000000099',
  '27000000-0000-0000-0000-00000000000a',
  '27000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select dispute.admin_assign_mediator(current_setting('test.d_nc')::uuid,
  '27000000-0000-0000-0000-000000000099');
select dispute.admin_start_review(current_setting('test.d_nc')::uuid);
select dispute.admin_record_decision(
  p_dispute_id => current_setting('test.d_nc')::uuid,
  p_outcome => 'no_action'::dispute.decision_outcome,
  p_settlement_action => 'no_change'::dispute.settlement_action,
  p_reason => 'No fault found'
);
reset role;

-- No new escrow entries for the no_change settlement.
select is(
  (select count(*)::int from settlement.escrow_entries
    where settlement_id = current_setting('test.set_nc')::uuid
      and entry_type in ('release','debit','reverse')
      and reference_kind like 'dispute_%'),
  0,
  'no_change writes 0 dispute-related escrow entries on the settlement'
);

-- Settlement.dispute_status='withdrawn' (neither prevailed).
select is(
  (select dispute_status::text from settlement.settlements where id = current_setting('test.set_nc')::uuid),
  'withdrawn',
  'no_change sets settlement.dispute_status=withdrawn (neither party prevailed)'
);

select * from finish();
rollback;
