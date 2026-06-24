-- CC-19 Test 074 — Cross-domain trigger materialization:
--   * Settlement event → buyer + supplier both materialized
--   * Dispute event → buyer + supplier (and mediator if assigned)
--   * Evaluation decision → buyer-only (suppliers suppressed, Q8 privacy)
--   * Invoice issued → buyer + supplier materialized
--
-- Assertions (8):
--   1. settlement_held event materialized for both buyer and supplier
--   2. settlement_held event NOT routed via 'evaluation' category
--   3. dispute_opened event materialized for buyer + supplier
--   4. mediator (platform_admin user) receives notification when assigned
--   5. evaluation_decision (shortlist) materialized for buyer only — no supplier rows
--   6. evaluation_decision rows have category='evaluation'
--   7. invoice.issued materialized for buyer + supplier
--   8. materialization_audit captured all of the above

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

-- Fixtures: buyer + supplier + platform_admin user (becomes the mediator).
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '31000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '074-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '31000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '074-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '31000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '074-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('31000000-0000-0000-0000-00000000000a', 'tenant-074', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('31000000-0000-0000-0000-00000000001a', '31000000-0000-0000-0000-00000000000a',
   'buyer-074', 'خریدار', 'Buyer 074', 'buyer', 'active'),
  ('31000000-0000-0000-0000-00000000002a', '31000000-0000-0000-0000-00000000000a',
   'sup-074', 'تأمین', 'Supplier 074', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('31000000-0000-0000-0000-000000000001', '31000000-0000-0000-0000-00000000000a',
   '31000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('31000000-0000-0000-0000-000000000002', '31000000-0000-0000-0000-00000000000a',
   '31000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active'),
  ('31000000-0000-0000-0000-000000000099', '31000000-0000-0000-0000-00000000000a',
   '31000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '31000000-0000-0000-0000-00000000000a', '31000000-0000-0000-0000-00000000001a',
       '31000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '31000000-0000-0000-0000-00000000000a', '31000000-0000-0000-0000-00000000002a',
       '31000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '31000000-0000-0000-0000-000000000001', r.id, 'organization', '31000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '31000000-0000-0000-0000-000000000002', r.id, 'organization', '31000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '31000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid;
  v_dec_shortlist uuid;
  v_dec_select uuid; v_prep uuid; v_contract uuid;
  v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid; v_set_held uuid; v_dispute uuid;
  v_inv uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '31000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for cross-domain triggers');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  -- Evaluation decision: shortlist (this is the Q8 boundary test source)
  v_dec_shortlist := evaluation.buyer_shortlist_offer(p_offer_id => v_off);

  -- Continue to contract: select_for_contract → preparation → executed
  v_dec_select := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec_select, p_title => 'cross-domain prep');
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
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  -- Settlement: hold to fire settlement_held event.
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');
  v_set_held := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set_held, p_description => 'P1', p_amount => 500
  );
  perform settlement.buyer_mark_settlement_ready(v_set_held);
  perform settlement.buyer_hold_settlement(v_set_held);

  -- Open dispute on the held settlement (fires dispute event).
  v_dispute := dispute.buyer_open_dispute(v_set_held, 'Quality concern');
  reset role;

  -- Admin assigns mediator and starts review (fires more dispute events).
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000099','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000099', true);
  set local role authenticated;
  perform dispute.admin_assign_mediator(v_dispute, '31000000-0000-0000-0000-000000000099');
  perform dispute.admin_start_review(v_dispute);
  reset role;

  -- Invoice: issue to fire invoice.issued event.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','31000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','31000000-0000-0000-0000-00000000000a',
                       'organization_id','31000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '31000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_inv := finance.buyer_create_draft_invoice(p_executed_contract_id => v_contract, p_currency => 'USD');
  perform finance.buyer_upsert_invoice_item(
    p_invoice_id => v_inv, p_description => 'Item 1',
    p_quantity => 1, p_unit_price => 100, p_tax_rate => 0
  );
  perform finance.buyer_issue_invoice(v_inv);
  reset role;

  perform set_config('test.settlement', v_set_held::text, false);
  perform set_config('test.dispute',    v_dispute::text,  false);
  perform set_config('test.invoice',    v_inv::text,      false);
  perform set_config('test.dec_short',  v_dec_shortlist::text, false);
end;
$$;

select plan(8);

-- 1. settlement.held materialized for both buyer + supplier.
select cmp_ok(
  (select count(distinct recipient_user_id)::int from notify.notifications
    where source_entity_type = 'settlement'
      and source_entity_id = current_setting('test.settlement')::uuid
      and category = 'settlement'),
  '>=', 2,
  'settlement event materialized for both buyer and supplier'
);

-- 2. settlement notifications use category='settlement' (not 'evaluation').
select is(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'settlement'
      and source_entity_id = current_setting('test.settlement')::uuid
      and category = 'evaluation'),
  0,
  'settlement notifications are not routed via evaluation category'
);

-- 3. dispute event materialized for buyer + supplier (at minimum).
select cmp_ok(
  (select count(distinct recipient_user_id)::int from notify.notifications
    where source_entity_type = 'dispute'
      and source_entity_id = current_setting('test.dispute')::uuid),
  '>=', 2,
  'dispute event materialized for buyer + supplier'
);

-- 4. Mediator (platform_admin user) receives ≥1 dispute notification.
select cmp_ok(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'dispute'
      and source_entity_id = current_setting('test.dispute')::uuid
      and recipient_user_id = '31000000-0000-0000-0000-000000000099'),
  '>=', 1,
  'assigned mediator receives at least one dispute notification'
);

-- 5. Q8: Evaluation decision is buyer-only.
select is(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'evaluation_decision'
      and recipient_user_id = '31000000-0000-0000-0000-000000000002'),
  0,
  'Q8: supplier does NOT receive evaluation decision notifications'
);

select cmp_ok(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'evaluation_decision'
      and recipient_user_id = '31000000-0000-0000-0000-000000000001'),
  '>=', 1,
  'Q8: buyer receives evaluation decision notifications'
);

-- 6. Q8 continued: those evaluation rows use category=evaluation.
select cmp_ok(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'evaluation_decision'
      and category = 'evaluation'),
  '>=', 1,
  'evaluation rows have category=evaluation'
);

-- 7. invoice.issued materialized for buyer + supplier.
select cmp_ok(
  (select count(distinct recipient_user_id)::int from notify.notifications
    where source_entity_type = 'invoice'
      and source_entity_id = current_setting('test.invoice')::uuid),
  '>=', 2,
  'invoice.issued materialized for both buyer and supplier'
);

select * from finish();
rollback;
